# VoluntApp 🤝 - Documentación Estructural para Sustentación

Plataforma MVP para conectar **voluntarios** con **fundaciones** en Colombia.
Este documento detalla la arquitectura general y la estructura de carpetas del proyecto, diseñado como guía para sustentaciones y entendimiento global del sistema.

---

## Arquitectura General

El proyecto está construido bajo una arquitectura **Cliente-Servidor (Client-Server)** desacoplada:
1. **Backend (Servidor):** Desarrollado en **PHP** con el framework **Laravel**. Actúa como una API RESTful que procesa las reglas de negocio, maneja la base de datos (PostgreSQL) y gestiona la autenticación mediante tokens JWT (JSON Web Tokens).
2. **Frontend (Cliente):** Desarrollado en **JavaScript** utilizando el framework **Vue 3** y empaquetado con **Vite**. Es una Single Page Application (SPA) que consume los endpoints de la API de Laravel para renderizar la interfaz de usuario de forma dinámica.

---

## Estructura del Proyecto

El repositorio contiene tanto el Backend como el Frontend en un formato de monorepositorio (Monorepo). A continuación se explica la función de cada directorio y archivo clave:

```text
Proyecto/                   ← Raíz principal del proyecto
├── app/                    ← LÓGICA DEL BACKEND (LARAVEL)
│   ├── Http/               ← Manejo de peticiones web y API
│   │   ├── Controllers/    ← Controladores: Reciben la petición del frontend, llaman a los servicios/modelos y devuelven una respuesta (JSON).
│   │   └── Middleware/     ← Filtros intermedios (ej. verificar si el usuario está autenticado antes de dejarlo pasar).
│   ├── Models/             ← Representación de las tablas de la base de datos en código (ORM Eloquent). Definen las relaciones entre tablas.
│   ├── Services/           ← Lógica de negocio compleja. Aquí se procesa información antes de guardarla para no sobrecargar los Controladores.
│   ├── Policies/           ← Reglas de autorización (ej. "Sólo una fundación puede editar su propia convocatoria").
│   └── Enums/              ← Tipos de datos fijos (ej. Roles: ADMIN, VOLUNTARIO, FUNDACION).
│
├── config/                 ← Archivos de configuración global de Laravel (base de datos, correos, sesiones, CORS).
│
├── database/               ← ESTRUCTURA Y DATOS DE LA BASE DE DATOS
│   ├── migrations/         ← Archivos que crean y modifican las tablas de la base de datos de forma versionada (como un control de versiones para la DB).
│   └── seeders/            ← Scripts para llenar la base de datos con información inicial o de prueba (datos falsos o catálogos por defecto).
│
├── frontend/               ← INTERFAZ DE USUARIO (VUE 3 + VITE)
│   ├── src/                ← Código fuente de la aplicación visual
│   │   ├── assets/         ← Imágenes, iconos SVG y archivos CSS globales (ej. style.css con variables de diseño).
│   │   ├── components/     ← Piezas reutilizables de la interfaz (botones, modales, tarjetas, barras de navegación).
│   │   ├── layouts/        ← Estructuras base de la página (ej. DashboardLayout con menú lateral, AuthLayout para login).
│   │   ├── pages/views/    ← Las pantallas completas que ve el usuario (Página de Inicio, Perfil, Lista de Convocatorias).
│   │   ├── router/         ← Gestor de navegación. Define qué componente se muestra según la URL ingresada.
│   │   ├── services/       ← Funciones que se encargan exclusivamente de hacer peticiones HTTP (Axios) hacia el Backend de Laravel.
│   │   └── stores/         ← Gestor de estado global (Pinia). Guarda información que se usa en muchas pantallas (ej. los datos del usuario logueado).
│   ├── package.json        ← Lista de dependencias y scripts de Node.js para el frontend.
│   └── vite.config.js      ← Configuración del empaquetador del frontend (incluye proxy para comunicarse con el backend en desarrollo).
│
├── public/                 ← Carpeta pública del servidor. Contiene el `index.php` (punto de entrada principal de Laravel) y archivos estáticos.
│
├── resources/              ← Vistas clásicas de Laravel (Blade), en este caso poco usadas ya que el frontend está en Vue.
│
├── routes/                 ← ENRUTAMIENTO DEL BACKEND
│   ├── api.php             ← Define las URLs de la API REST que consume el frontend (ej. /api/v1/login).
│   ├── web.php             ← Rutas tradicionales web (generalmente redirigen al frontend Vue).
│   └── channels.php        ← Define los canales para WebSockets (Notificaciones en tiempo real).
│
├── storage/                ← Archivos guardados por el sistema (logs de errores, imágenes subidas por los usuarios, caché).
│
├── tests/                  ← Pruebas automatizadas (PestPHP) para asegurar que el código funciona correctamente.
│
├── vendor/                 ← Librerías de terceros instaladas por Composer (Backend).
│
├── .env                    ← Variables de entorno privadas (Contraseñas de Base de datos, claves secretas JWT). ¡Nunca se sube a repositorios!
├── .env.example            ← Plantilla de ejemplo de las variables de entorno.
├── composer.json           ← Lista de dependencias principales del Backend (PHP).
└── README.md               ← Archivo principal de documentación técnica del repositorio.
```

---

## Flujo de Datos (Cómo funciona una interacción)

Para sustentar cómo se conectan las partes, este es el viaje de una petición común (ej. Iniciar sesión):

1. **Frontend (Usuario):** El usuario ingresa su correo y contraseña en la vista de Login en Vue (`src/views`).
2. **Frontend (Servicio):** El archivo en `src/services` toma esos datos y hace una petición HTTP `POST` hacia la ruta `/api/v1/auth/login`.
3. **Backend (Ruta):** Laravel recibe la petición en `routes/api.php` y la envía al `AuthController`.
4. **Backend (Controlador):** El Controlador verifica los datos, se comunica con la Base de Datos a través del `Model` (usuario) para ver si existe y la contraseña es correcta.
5. **Backend (Respuesta):** Si es exitoso, Laravel genera un Token JWT y lo devuelve al frontend en formato JSON.
6. **Frontend (Store):** Vue recibe el Token, lo guarda en el `store` (Pinia) y en el almacenamiento del navegador, y el `router` redirige al usuario a su Dashboard.

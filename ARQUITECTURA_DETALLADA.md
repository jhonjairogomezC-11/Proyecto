# Arquitectura y Diseño Detallado de VoluntApp 🏢

Este documento técnico extenso describe a profundidad la arquitectura, patrones de diseño, estructura de directorios, y la funcionalidad de cada componente individual dentro de la plataforma VoluntApp. Está diseñado para ser la referencia técnica definitiva del proyecto.

---

## 1. Visión General del Sistema

VoluntApp es una plataforma digital MVP que conecta a **Voluntarios** con **Fundaciones** en Colombia.
El sistema opera bajo un modelo **Cliente-Servidor (Client-Server Architecture)** estrictamente desacoplado.

1. **Backend (Servidor API RESTful):** Construido en **PHP 8.2+** utilizando el framework **Laravel 12**. Su principal responsabilidad es la gestión de la base de datos (PostgreSQL), la ejecución de reglas de negocio, la validación de datos, y la emisión de respuestas estructuradas en formato JSON. Actúa bajo el patrón de diseño MVC (Modelo-Vista-Controlador), aunque la capa de "Vista" se reemplaza por respuestas de API.
2. **Frontend (Cliente SPA):** Construido con **JavaScript** utilizando **Vue.js 3** (Composition API) y empaquetado con **Vite**. Es una Single Page Application (SPA) que maneja toda la interfaz de usuario, interactividad, rutas en el navegador, y consume el backend mediante peticiones HTTP asíncronas (AJAX) usando Axios.

### Patrones Clave de Diseño y Arquitectura
- **API-First Design:** Todo el intercambio de datos se hace mediante JSON a través de endpoints RESTful.
- **Stateless Authentication (JWT):** Las sesiones se manejan sin estado en el servidor. El backend genera un JSON Web Token (JWT) usando `jwt-auth` y Laravel Sanctum, que el frontend debe adjuntar en el header `Authorization: Bearer <token>` de cada petición protegida.
- **Component-Based Architecture (CBA):** El frontend está dividido en piezas reutilizables de UI (Componentes Vue).
- **Service Layer Pattern (Backend):** Lógica compleja abstraída de los controladores hacia clases de Servicio.
- **State Management Pattern (Frontend):** Uso de Pinia para mantener una fuente única de verdad en el cliente (Store).

---

## 2. Estructura y Componentes del Backend (Laravel)

El backend reside en la raíz del proyecto. A continuación, se detalla exhaustivamente cada capa y sus archivos correspondientes.

### 2.1. Capa de Modelos y Datos (`app/Models/`)
Los Modelos utilizan **Eloquent ORM** (Object-Relational Mapping). Representan las tablas de PostgreSQL y gestionan las relaciones entre ellas.

* **Núcleo de Usuarios:**
  * `Usuario.php`: La tabla central de autenticación. Maneja credenciales, email, y el `Rol` (ADMIN, VOLUNTARIO, FUNDACION).
  * `Voluntario.php`: Extensión del perfil del usuario (One-to-One con Usuario). Guarda la biografía, teléfono, fecha de nacimiento y género del voluntario.
  * `Fundacion.php`: Extensión del perfil para organizaciones (One-to-One con Usuario). Almacena NIT, nombre de la entidad, descripción, página web y estado de aprobación (Pendiente, Aprobada, Rechazada).

* **Núcleo de Actividad (Convocatorias):**
  * `Publicacion.php`: Representa una convocatoria de voluntariado creada por una fundación. Tiene relaciones con la Fundación creadora, el área de impacto, y las postulaciones.
  * `PublicacionImagen.php`: Gestiona la galería de imágenes (URL y orden) asociada a una publicación.
  * `Postulacion.php`: Tabla pivote con estado (Pendiente, Aceptada, Rechazada, Asistió). Une a un `Voluntario` con una `Publicacion`.

* **Núcleo de Gamificación y Retención:**
  * `VoluntarioPuntos.php`: Total de puntos acumulados por un voluntario.
  * `TransaccionPuntos.php`: Historial de cómo se ganaron los puntos (ej. "Postulación exitosa: +50 pts").
  * `Logro.php` y `VoluntarioLogro.php`: Sistema de medallas. Relación Many-to-Many entre Voluntarios y Logros desbloqueados.
  * `VoluntarioFavorito.php`: Permite a los voluntarios "Guardar" publicaciones o fundaciones de su interés.

* **Núcleo de Administración y Control:**
  * `Reporte.php`: Reportes generados por usuarios hacia contenido inapropiado o perfiles sospechosos.
  * `AdminPerfil.php` y `AdminAccion.php`: Perfiles de administradores y logs de auditoría sobre acciones de moderación.
  * `AdvertenciaVoluntario.php`: Penalizaciones aplicadas por administradores a voluntarios que incumplen las normas.
  * `HistorialEstadoFundacion.php` / `HistorialEstadoVoluntario.php`: Logs inmutables que registran cuándo y por qué se suspendió o aprobó una cuenta.

* **Núcleo de Catálogos (Tablas Maestras):**
  * `Departamento.php` y `Municipio.php`: Distribución geográfica de Colombia.
  * `Habilidad.php`, `Interes.php`, `AreaImpacto.php`: Etiquetas estandarizadas para conectar perfiles con publicaciones.

### 2.2. Capa de Controladores de API (`app/Http/Controllers/Api/V1/`)
Los controladores reciben peticiones HTTP, validan los *Requests*, delegan en los Modelos/Servicios y retornan *Responses* JSON.

* **`Auth/AuthController.php`**: Endpoints públicos y protegidos de sesión. `register`, `login` (genera JWT), `me` (retorna el perfil del token actual), `logout`, `refresh` y recuperación de contraseñas.
* **`CatalogoController.php`**: Endpoints públicos de solo lectura para poblar selects del frontend (departamentos, áreas de impacto).
* **`PublicacionController.php`**: CRUD de Convocatorias. Diferencia lógica si es un visitante público (ver lista) o si es una fundación (crear, editar, subir imágenes, cancelar).
* **`FundacionController.php`**: CRUD de Perfil de fundación.
* **`VoluntarioController.php`**: CRUD de Perfil de voluntario y acceso a su Dashboard personal de datos.
* **`PostulacionController.php`**: Orquesta el flujo de postulación. Permite al voluntario postularse/retirarse, y a la fundación aceptar/rechazar postulantes y confirmar su asistencia (lo cual dispara la asignación de puntos).
* **`GamificacionController.php`**: Retorna rankings globales, puntos actuales y logros desbloqueados por el usuario.
* **`FavoritoController.php`**: Lógica de añadir/quitar "Likes" o "Bookmarks" a publicaciones.
* **`NotificacionController.php`**: Marca alertas como leídas en tiempo real.
* **`Admin/*`**: Subcarpeta con Controladores exclusivos para administradores (`AdminFundacionController`, `AdminVoluntarioController`, `AdminPublicacionController`, `AdminReporteController`), permitiendo aprobar cuentas, suspender usuarios, moderar contenido y ver historiales.

### 2.3. Enrutamiento (`routes/`)
* **`api.php`**: Todo el mapa de rutas. Agrupa endpoints bajo prefijos (ej. `/v1/auth`, `/v1/admin`) y les aplica Middlewares.
  * **Middlewares aplicados:** `auth:api` (Exige un JWT válido), `role:VOLUNTARIO|FUNDACION|ADMIN` (Exige que el JWT pertenezca a un rol específico).
* **`channels.php`**: Define canales para Laravel Echo. Permite enviar notificaciones en tiempo real (ej. "¡Tu postulación fue aceptada!") a través de WebSockets (Reverb).

### 2.4. Base de Datos (`database/`)
* **`migrations/`**: Archivos ordenados cronológicamente que contienen código PHP para generar tablas SQL. Garantizan que cualquier desarrollador pueda reconstruir la BD con `php artisan migrate`.
* **`seeders/`**: Scripts como `CatalogosSeeder` (llena Colombia y habilidades) y `DemoSeeder` (crea usuarios de prueba) para poblar la BD mediante `php artisan db:seed`.

---

## 3. Estructura y Componentes del Frontend (Vue 3 + Vite)

El frontend reside íntegramente dentro de la carpeta `frontend/`. Utiliza el enfoque **Composition API** de Vue 3, priorizando la legibilidad y la reutilización de código lógico (Composables).

### 3.1. Vistas y Módulos (`src/views/`)
Las Vistas representan las "Páginas" a las que se asocia una URL. Están organizadas por dominios de negocio:

* **`auth/` (Autenticación):**
  * `LoginView.vue`: Formulario de inicio de sesión.
  * `RegisterView.vue`: Flujo de registro. Implementa lógica condicional para mostrar campos distintos si el usuario selecciona rol "Voluntario" o "Fundación".
  * `ForgotPasswordView.vue`: Recuperación de cuenta.
* **`voluntario/` (Módulo Voluntario):**
  * `VoluntarioPerfilView.vue`: Formulario para editar información personal, foto, habilidades y ubicación.
  * `VoluntarioPostulacionesView.vue`: Historial de convocatorias a las que aplicó y sus estados.
  * `VoluntarioLogrosView.vue`: Tablero de medallas y puntos ganados.
* **`fundacion/` (Módulo Fundación):**
  * `FundacionPerfilView.vue`: Gestión de datos corporativos (NIT, Misión, etc.).
  * `GestionPublicacionesView.vue`: Tabla de administración de convocatorias creadas por la fundación.
  * `CrearPublicacionView.vue` / `EditarPublicacionView.vue`: Formularios complejos con manejo de fechas, cupos y carga de imágenes.
  * `PostulantesView.vue`: Pantalla donde la fundación ve quiénes aplicaron, revisa sus perfiles, y los acepta/rechaza.
* **`admin/` (Módulo Administrador):**
  * Vistas dedicadas (`AdminFundacionesView.vue`, `AdminVoluntariosView.vue`, etc.) con tablas de datos extensas, filtros y modales para suspender cuentas o aprobar entidades pendientes.
* **Vistas Globales:**
  * `DashboardView.vue`: Panel de control principal tras iniciar sesión. El contenido cambia radicalmente según el rol del usuario conectado.
  * `NotificacionesView.vue`: Centro de alertas del usuario.

### 3.2. Componentes UI (`src/components/`)
La biblioteca de componentes internos (Design System) del proyecto. Promueven el principio DRY (Don't Repeat Yourself).

* **`AppAlert.vue` / `AppToast.vue`:** Componentes de retroalimentación para mostrar errores de validación o éxitos.
* **`AppModal.vue`:** Contenedor genérico para ventanas emergentes (diálogos de confirmación, formularios rápidos).
* **`AppSpinner.vue`:** Indicador de carga animado para peticiones HTTP.
* **`AppPagination.vue`:** Controles numéricos para navegar listas largas provenientes del backend.
* **`BadgeEstado.vue`:** Pequeño componente visual que renderiza colores distintos según un estado (Verde = Aprobado, Rojo = Rechazado, Amarillo = Pendiente).
* **`GradientStatCard.vue`:** Tarjetas de estadísticas visualmente atractivas usadas en el Dashboard.
* **`ImageCarousel.vue`:** Visualizador de galerías de fotos para el detalle de las convocatorias.

### 3.3. Gestor de Estado (`src/stores/`)
Utilizando **Pinia**, el estado global sobrevive a los cambios de ruta sin necesidad de recargar de la API repetidamente.
* **`auth.store.js`:** Es el archivo más crítico del frontend.
  - Guarda el `token` (JWT) en memoria y en `localStorage`.
  - Guarda el `user` (datos del perfil actual).
  - Define acciones (`login()`, `register()`, `logout()`) que hacen las peticiones a la API y mutan el estado local basándose en la respuesta.
  - Expone *Getters* como `isAuthenticated` y `hasRole(roleName)`.

### 3.4. Servicios y Conexión (`src/services/`)
* **`api.js`**: Instancia central de Axios.
  - Contiene **Interceptors**. Antes de cada petición, el *Request Interceptor* inyecta el `Bearer Token` en los headers de autorización si existe.
  - El *Response Interceptor* captura errores globalmente. Si recibe un código `401 Unauthorized` (token expirado), puede intentar renovarlo o forzar un deslogueo automático en el frontend.

### 3.5. Enrutamiento del Cliente (`src/router/`)
* **`index.js`**: Define el árbol de navegación.
  - Utiliza **Route Meta Fields** (ej. `meta: { requiresAuth: true, role: 'ADMIN' }`).
  - Utiliza un **Global Before Guard** (`router.beforeEach`). Si un usuario intenta acceder a `/dashboard` pero el Store de autenticación dice que no está logueado, el Guard intercepta la navegación y lo redirige forzosamente a `/login`.

### 3.6. Estilos y Sistema de Diseño (`src/assets/style.css`)
El proyecto no depende de pesados frameworks CSS externos como Bootstrap, sino de un diseño personalizado moderno basado en variables CSS nativas (`:root`).
- Define paletas de colores (`--primary`, `--surface`, `--background`), tipografías, sombras suaves (`box-shadow`), y radios de borde redondeados para un aspecto "Glassmorphism" limpio y profesional.

---

## 4. Flujos de Integración (Casos de Uso a Profundidad)

### Flujo A: Autenticación Segura (Login)
1. El usuario llena el formulario en `LoginView.vue` y hace submit.
2. La vista llama a `authStore.login(credenciales)`.
3. El store usa Axios (`api.js`) enviando `POST /api/v1/auth/login`.
4. En Laravel, `AuthController` valida el formato del correo. Si la contraseña (hasheada con bcrypt en la BD) coincide, genera un JWT codificado con el `APP_KEY` secreto.
5. Laravel responde `200 OK` con `{ "access_token": "eyJh...", "user": {...} }`.
6. El frontend guarda el token, actualiza la interfaz (muestra menú logueado) y redirige al Dashboard.

### Flujo B: El Ciclo de Vida de una Postulación y Gamificación
1. **Descubrimiento:** Un Voluntario navega por `PublicacionController@index` (filtrando por municipio e intereses).
2. **Aplicación:** Hace clic en "Postularse". El frontend envía `POST /api/v1/postulaciones`. El backend crea un registro en la tabla `postulaciones` con estado `Pendiente`.
3. **Revisión:** La Fundación entra a su panel, y llama a `PostulacionController@postulacionesDeFundacion`. Ve al voluntario y presiona "Aceptar". El backend actualiza a `Aceptada`.
4. **Asistencia y Puntos:** El día del evento, la Fundación marca al voluntario como "Asistió". El backend actualiza la postulación y, dentro de la misma transacción de BD, llama al Servicio de Gamificación, insertando puntos en `TransaccionPuntos`, sumando el saldo en `VoluntarioPuntos`, y evaluando si debe insertar un nuevo `Logro` (ej. "Primer voluntariado completado").
5. **Notificación:** Durante este proceso, Laravel dispara eventos que Reverb/Echo envían por WebSockets, mostrando un `AppToast` en la pantalla del voluntario al instante: "¡Has ganado 50 puntos!".

---
*Este documento establece los cimientos técnicos de VoluntApp. Cualquier adición de la aplicación móvil (Flutter) simplemente actuará como un nuevo "Cliente" (igual que Vue), consumiendo exactamente la misma API RESTful y JWT descritos en la sección 2.*

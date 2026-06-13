# VoluntApp 🤝

Plataforma MVP para conectar **voluntarios** con **fundaciones** en Colombia.  
Gestiona convocatorias, postulaciones, verificación de organizaciones y notificaciones en tiempo real.

---

## Tecnologías

| Capa | Tecnología | Versión |
|---|---|---|
| Backend | Laravel | ^12.0 |
| Runtime PHP | PHP | ^8.2 |
| Frontend | Vue 3 + Vite | Vue ^3.5, Vite ^8 |
| Estado global | Pinia | ^3.0 |
| Router | Vue Router | ^4.6 |
| HTTP client | Axios | ^1.17 |
| Base de datos | PostgreSQL | 14+ |
| Autenticación | Laravel Sanctum | ^4.3 |
| Tests | PestPHP | ^3.8 |

---

## Estructura del repositorio

```
voluntapp/                  ← raíz del monorepo
├── app/                    ← lógica del backend (Laravel)
│   ├── Http/Controllers/
│   ├── Models/
│   ├── Services/
│   ├── Policies/
│   └── Enums/
├── database/
│   ├── migrations/         ← estructura de la BD
│   └── seeders/            ← datos iniciales y demo
├── frontend/               ← aplicación Vue 3 (SPA)
│   ├── src/
│   │   ├── views/          ← páginas por rol
│   │   ├── components/     ← componentes reutilizables
│   │   ├── layouts/        ← layouts de página
│   │   ├── stores/         ← estado global (Pinia)
│   │   ├── services/       ← cliente API (axios)
│   │   └── router/         ← rutas y guards
│   └── vite.config.js
├── routes/
│   └── api.php             ← 42 endpoints REST
├── voluntapp_mvp.sql       ← script SQL original (referencia)
├── .env.example            ← plantilla de variables de entorno
└── README.md
```

---

## Requisitos previos

Asegúrate de tener instalado en tu máquina:

| Herramienta | Versión mínima | Verificar |
|---|---|---|
| PHP | 8.2+ | `php --version` |
| Composer | 2.x | `composer --version` |
| Node.js | 18+ | `node --version` |
| npm | 9+ | `npm --version` |
| PostgreSQL | 14+ | `psql --version` |
| Git | cualquiera | `git --version` |

---

## Instalación desde cero

### 1. Clonar el repositorio

```bash
git clone https://github.com/TU_USUARIO/voluntapp.git
cd voluntapp
```

### 2. Instalar dependencias del backend

```bash
composer install
```

### 3. Configurar variables de entorno del backend

```bash
cp .env.example .env
php artisan key:generate
```

Abre `.env` y configura los datos de tu PostgreSQL:

```env
DB_DATABASE=voluntapp
DB_USERNAME=postgres
DB_PASSWORD=tu_contraseña
```

### 4. Crear la base de datos en PostgreSQL

Conéctate a PostgreSQL y ejecuta:

```sql
CREATE DATABASE voluntapp;
```

O desde la terminal:

```bash
psql -U postgres -c "CREATE DATABASE voluntapp;"
```

### 5. Ejecutar migraciones y cargar datos iniciales

```bash
# Crea todas las tablas
php artisan migrate

# Carga catálogos (departamentos, municipios, habilidades, etc.) y el admin inicial
php artisan db:seed --class=CatalogosSeeder
php artisan db:seed --class=AdminSeeder
```

**Opcional** — cargar datos de demostración (3 fundaciones, 5 voluntarios, publicaciones):

```bash
php artisan db:seed --class=DemoSeeder
```

O cargar todo de una vez:

```bash
php artisan db:seed
```

### 6. Instalar dependencias del frontend

```bash
cd frontend
npm install
cd ..
```

---

## Ejecutar en desarrollo

Necesitas **dos terminales** abiertas simultáneamente:

**Terminal 1 — Backend:**

```bash
php artisan serve
# Disponible en http://localhost:8000
```

**Terminal 2 — Frontend:**

```bash
cd frontend
npm run dev
# Disponible en http://localhost:5173
```

Abre el navegador en **http://localhost:5173**

---

## Credenciales de acceso

| Rol | Email | Contraseña |
|---|---|---|
| Administrador | `admin@voluntapp.co` | `Admin1234!` |
| Voluntario demo | `voluntario1@demo.com` | `password` |
| Fundación demo | `fundacion1@demo.com` | `password` |

> Las credenciales demo solo están disponibles si ejecutaste `DemoSeeder`.

---

## Variables de entorno

### Backend (`.env`)

| Variable | Descripción | Ejemplo |
|---|---|---|
| `APP_KEY` | Clave de encriptación (auto-generada) | `base64:...` |
| `APP_URL` | URL base del backend | `http://localhost:8000` |
| `DB_DATABASE` | Nombre de la base de datos | `voluntapp` |
| `DB_USERNAME` | Usuario de PostgreSQL | `postgres` |
| `DB_PASSWORD` | Contraseña de PostgreSQL | `tu_contraseña` |
| `MAIL_MAILER` | Driver de email (`log` en dev) | `log` |
| `SANCTUM_STATEFUL_DOMAINS` | Dominios permitidos para CORS | `localhost:5173` |

### Frontend (`frontend/.env`)

En desarrollo no es necesario crear este archivo — el proxy de Vite redirige automáticamente `/api` al backend. Ver `frontend/vite.config.js`.

---

## Endpoints de la API

La API está disponible en `http://localhost:8000/api/v1/`.  
Ver lista completa ejecutando:

```bash
php artisan route:list --path=api
```

Resumen de módulos:

| Módulo | Rutas |
|---|---|
| Autenticación | `POST /auth/register`, `POST /auth/login`, `POST /auth/logout` |
| Catálogos | `GET /catalogos/departamentos`, `/municipios`, `/habilidades`, etc. |
| Voluntarios | `GET/POST/PUT /voluntario` |
| Fundaciones | `GET/POST/PUT /fundaciones` |
| Publicaciones | `GET/POST/PUT /publicaciones` + publicar/cancelar |
| Postulaciones | Postular, responder, retirar, confirmar asistencia |
| Notificaciones | Listar, marcar leídas |
| Admin | Gestionar fundaciones y reportes |

---

## Ejecutar pruebas

```bash
php artisan test
# 28 pruebas — todas deben pasar
```

---

## Base de datos — información adicional

Las migraciones de Laravel crean la estructura completa desde cero.  
El archivo `voluntapp_mvp.sql` es el **script SQL original de referencia** del diseño del sistema — no es necesario ejecutarlo si usas las migraciones.

Tablas principales: `usuarios`, `voluntarios`, `fundaciones`, `publicaciones`, `postulaciones`, `notificaciones`, `admin_perfiles`, `admin_acciones`, `reportes`, `configuracion_sistema` y tablas de geografía y catálogos.

---

## Docker

**En esta etapa del proyecto no se usa Docker.** La justificación técnica es:

- El stack (PHP + PostgreSQL) se instala de forma estándar en cualquier OS
- Las migraciones de Laravel garantizan reproducibilidad de la BD
- Agregar Docker en MVP añade complejidad sin beneficio real para un equipo pequeño
- El `.env.example` cubre toda la configuración necesaria

Se recomienda dockerizar cuando el proyecto escale a múltiples servicios o se configure un pipeline CI/CD.

---

## Estrategia de ramas (Git Flow simplificado)

```
main          ← código estable, listo para producción
develop       ← rama de integración, siempre funcional
feature/*     ← nuevas funcionalidades (feature/nombre-funcionalidad)
fix/*         ← correcciones de bugs (fix/descripcion-del-bug)
```

### Flujo de trabajo recomendado

```bash
# Crear nueva funcionalidad
git checkout develop
git pull origin develop
git checkout -b feature/mi-nueva-funcionalidad

# ... trabajar y hacer commits ...

git push origin feature/mi-nueva-funcionalidad
# Crear Pull Request hacia develop en GitHub
# Revisar, aprobar y hacer merge
```

### Convención de commits

```
feat: descripción corta del cambio
fix: corrección de bug específico
docs: cambios solo en documentación
refactor: mejora de código sin cambiar funcionalidad
test: adición o corrección de pruebas
chore: tareas de mantenimiento (deps, config, etc.)
```

---

## Flujo de una contribución

1. Haz fork del repositorio o crea una rama desde `develop`
2. Sigue los pasos de instalación de este README
3. Implementa tu cambio en una rama `feature/*` o `fix/*`
4. Ejecuta `php artisan test` — todos deben pasar
5. Abre un Pull Request hacia `develop` con descripción clara del cambio

---

## Licencia

MIT — uso libre con atribución.

# VoluntApp 🤝

Plataforma MVP para conectar **voluntarios** con **fundaciones** en Colombia.
Incluye gestión de convocatorias, postulaciones, verificación de organizaciones, notificaciones en tiempo real y roles de administrador.

---

## Tecnologías principales

| Capa | Tecnología | Versión |
|---|---|---|
| Backend | Laravel | ^12.0 |
| Runtime PHP | PHP | ^8.2 |
| Frontend | Vue 3 + Vite | Vue ^3.5, Vite ^8 |
| Estado global | Pinia | ^3.0 |
| Router | Vue Router | ^4.6 |
| HTTP client | Axios | ^1.17 |
| Transmisión en tiempo real | Laravel Echo + Reverb/Pusher | ^2.3, ^8.5 |
| Base de datos | PostgreSQL | 14+ |
| Autenticación | Laravel Sanctum + JWT | ^4.3, 2.8 |
| Tests | PestPHP | ^3.8 |

---

## Estructura del repositorio

```
Proyecto/                   ← raíz del proyecto
├── app/                    ← backend Laravel
│   ├── Http/Controllers/
│   ├── Models/
│   ├── Services/
│   ├── Policies/
│   └── Enums/
├── config/                 ← configuración de Laravel
├── database/               ← migraciones y seeders
│   ├── migrations/
│   └── seeders/
├── frontend/               ← aplicación Vue 3 + Vite
│   ├── src/
│   │   ├── views/
│   │   ├── components/
│   │   ├── layouts/
│   │   ├── stores/
│   │   ├── services/
│   │   └── router/
│   └── vite.config.js
├── public/                 ← punto de entrada web del backend
├── routes/                 ← definición de API y canales
│   ├── api.php
│   └── channels.php
├── .env.example            ← plantilla de variables de entorno
├── composer.json
├── frontend/package.json
├── voluntapp_mvp.sql       ← referencia SQL histórica
└── README.md
```

---

## Requisitos previos

Asegúrate de tener instaladas estas herramientas:

| Herramienta | Versión mínima | Verificar |
|---|---|---|
| PHP | 8.2+ | `php --version` |
| Composer | 2.x | `composer --version` |
| Node.js | 18+ | `node --version` |
| npm | 9+ | `npm --version` |
| PostgreSQL | 14+ | `psql --version` |
| Git | cualquier | `git --version` |

---

## Instalación desde cero

### 1. Clonar el repositorio

```bash
git clone https://github.com/TU_USUARIO/voluntapp.git
cd Proyecto
```

### 2. Instalar dependencias del backend

```bash
composer install
```

### 3. Configurar variables de entorno del backend

```bash
copy .env.example .env
php artisan key:generate
```

Abre `.env` y ajusta los valores de PostgreSQL según tu entorno:

```env
DB_CONNECTION=pgsql
DB_DATABASE=voluntapp
DB_USERNAME=postgres
DB_PASSWORD=tu_contraseña
```

### 4. Crear la base de datos en PostgreSQL

```bash
psql -U postgres -c "CREATE DATABASE voluntapp;"
```

### 5. Ejecutar migraciones y seeders

```bash
php artisan migrate
php artisan db:seed
```

Si prefieres cargar solo datos iniciales mínimos:

```bash
php artisan db:seed --class=CatalogosSeeder
php artisan db:seed --class=AdminSeeder
```

Para cargar datos de demostración adicionales:

```bash
php artisan db:seed --class=DemoSeeder
```

### 6. Instalar dependencias del frontend

```bash
cd frontend
npm install
cd ..
```

---

## Ejecutar en desarrollo

Se recomienda usar dos terminales abiertas:

**Terminal 1 — Backend:**

```bash
php artisan serve
```

**Terminal 2 — Frontend:**

```bash
cd frontend
npm run dev
```

Accede a la aplicación en **http://localhost:5173**.

> El frontend usa proxy Vite para redirigir `/api` al backend de Laravel.

---

## Credenciales de ejemplo

| Rol | Email | Contraseña |
|---|---|---|
| Administrador | `admin@voluntapp.co` | `Admin1234!` |
| Voluntario demo | `voluntario1@demo.com` | `password` |
| Fundación demo | `fundacion1@demo.com` | `password` |

> Estas credenciales funcionan solo si ejecutaste `DemoSeeder` o se cargó el seeder de demo.

---

## Variables de entorno

### Backend (`.env`)

| Variable | Descripción | Ejemplo |
|---|---|---|
| `APP_NAME` | Nombre de la aplicación | `VoluntApp` |
| `APP_URL` | URL base del backend | `http://localhost:8000` |
| `DB_CONNECTION` | Driver de base de datos | `pgsql` |
| `DB_DATABASE` | Nombre de la base de datos | `voluntapp` |
| `DB_USERNAME` | Usuario de PostgreSQL | `postgres` |
| `DB_PASSWORD` | Contraseña de PostgreSQL | `tu_contraseña` |
| `SESSION_DRIVER` | Driver de sesión | `database` |
| `BROADCAST_CONNECTION` | Driver de broadcast | `log` |
| `SANCTUM_STATEFUL_DOMAINS` | Dominios permitidos para cookies/CORS | `localhost:5173,localhost:8000` |

### Frontend (`frontend/.env`)

No es obligatorio en desarrollo, porque `vite.config.js` ya configura proxy al backend.
Usa `frontend/.env` solo si necesitas personalizar variables de Vite o la conexión a Reverb/Pusher.

---

## API base

La API principal se expone en `http://localhost:8000/api/v1/`.
Puedes ver las rutas disponibles con:

```bash
php artisan route:list --path=api
```

### Rutas principales

| Módulo | Ejemplos |
|---|---|
| Auth | `POST /api/v1/auth/login`, `POST /api/v1/auth/register`, `POST /api/v1/auth/refresh` |
| Catálogos | `GET /api/v1/catalogos/departamentos`, `GET /api/v1/catalogos/municipios` |
| Publicaciones públicas | `GET /api/v1/publicaciones`, `GET /api/v1/fundaciones` |
| Usuario autenticado | `GET /api/v1/auth/me`, `POST /api/v1/auth/logout` |
| Voluntario | `/api/v1/voluntario`, `/api/v1/postulaciones`, `/api/v1/mis-postulaciones` |
| Fundación | `/api/v1/fundaciones`, `/api/v1/publicaciones`, `/api/v1/mi-fundacion` |
| Admin | `/api/v1/admin/publicaciones`, `/api/v1/admin/fundaciones`, `/api/v1/admin/reportes` |

---

## Pruebas

```bash
php artisan test
```

---

## Notas importantes

- El backend usa `laravel/sanctum` para compatibilidad con SPA y `php-open-source-saver/jwt-auth` para tokens JWT.
- El frontend se conecta a un backend Laravel a través de `axios` y mantiene sesión JWT en `localStorage`.
- El driver de broadcast por defecto es `log`; para habilitar WebSockets configura `BROADCAST_CONNECTION` y los parámetros de Reverb/Pusher en `.env`.
- El archivo `voluntapp_mvp.sql` es una referencia histórica y no se necesita cuando usas migraciones de Laravel.

---

## Docker

Este proyecto no incluye un entorno Docker oficial en su versión actual.
El desarrollo se ejecuta localmente con PHP, PostgreSQL y Vite.

---

## Git Flow recomendado

```
main       ← código estable listo para producción
develop    ← integración continua y nuevas funcionalidades
feature/*  ← nuevas caracteristicas
fix/*      ← correcciones de bugs
```

### Flujo recomendado

```bash
git checkout develop
git pull origin develop
git checkout -b feature/nueva-funcionalidad
```

---

## Convenciones de commit

- `feat:` nueva funcionalidad
- `fix:` corrección de bug
- `docs:` cambios en documentación
- `refactor:` mejora de código sin cambiar comportamiento
- `test:` adición o ajuste de pruebas
- `chore:` tareas de mantenimiento

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

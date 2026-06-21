# VoluntApp 🤝

**Plataforma completa para conectar voluntarios con fundaciones en Colombia**

Sistema integral que incluye gestión de convocatorias, postulaciones, verificación de organizaciones, notificaciones en tiempo real, gamificación con ranking, panel administrativo y aplicación móvil Flutter. 

> 🚀 **¡Incluye datos masivos realistas para simular un entorno de producción!**  
> Con un solo comando puedes desplegar +3,000 usuarios, 600 publicaciones y 2,914 postulaciones.

---

## 📱 Características Principales

### ✨ **Interfaz Optimizada**
- **Listas compactas expandibles** en panel administrativo
- **Vista compacta/completa alternativa** para publicaciones 
- **Fotos de perfil reales** en ranking y listas de usuarios
- **Diseño responsive** para web y móvil

### 🎮 **Sistema de Gamificación**
- **Ranking de voluntarios** con puntos y logros
- **Sistema de dificultades** para actividades (Fácil, Media, Difícil)
- **Fotos de perfil públicas** en clasificaciones
- **Logros y badges** por participación

### 🔧 **Panel Administrativo Avanzado**
- **Gestión masiva de usuarios** con estados variados
- **Aprobación/rechazo de fundaciones** con historial
- **Suspensión y bloqueo** de usuarios con motivos
- **Vista compacta con expansión** para mejor rendimiento

### 📊 **Datos Masivos Incluidos**
- **1,688 usuarios** con perfiles completos
- **331 fundaciones** en diferentes estados
- **600 publicaciones** variadas y realistas  
- **2,914 postulaciones** con estados diversos
- **Fotos de perfil automáticas** usando APIs públicas

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
| Autenticación | JWT (php-open-source-saver/jwt-auth) | 2.8 |
| Mobile | Flutter + Riverpod + Dio | SDK 3.3+ |
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
├── mobile/                 ← aplicación Flutter (Android / iOS)
│   ├── lib/
│   ├── test/
│   ├── scripts/setup.ps1
│   └── pubspec.yaml
├── docs/
│   ├── GUIA_MAESTRA_FLUTTER.md
│   └── mobile/
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
| Flutter | 3.22+ (solo mobile) | `flutter --version` |
| Git | cualquier | `git --version` |

> **Importante para Windows (Flutter):** Debes activar el **Modo de desarrollador** en la configuración de Windows (`start ms-settings:developers`) para que Flutter pueda crear enlaces simbólicos al compilar con plugins.

---

## 🚀 Instalación Completa (Recomendada)

**¿Quieres tener el proyecto completo funcionando con datos realistas en menos de 10 minutos?**

### Opción A: Instalación Automática con Datos Masivos

```bash
# 1. Clonar repositorio
git clone https://github.com/TU_USUARIO/voluntapp.git
cd Proyecto

# 2. Instalar dependencias backend
composer install

# 3. Configurar entorno
copy .env.example .env
php artisan key:generate

# 4. Configurar base de datos en .env
# (ver sección "Configuración de Base de Datos" abajo)

# 5. 🚀 COMANDO MÁGICO - Crea todo automáticamente
php artisan db:populate-massive --fresh

# 6. Frontend
cd frontend && npm install && cd ..

# 7. Flutter (opcional)
cd mobile && flutter pub get && cd ..
```

**¡Listo!** Con el comando `db:populate-massive --fresh` tienes:
- ✅ Base de datos migrada
- ✅ +3,000 usuarios realistas  
- ✅ 600 publicaciones variadas
- ✅ 2,914 postulaciones
- ✅ 6 administradores listos
- ✅ Fotos de perfil automáticas

### Opción B: Instalación Manual Paso a Paso

Si prefieres control total sobre el proceso:

#### 1. Requisitos Previos

| Herramienta | Versión mínima | Verificar |
|---|---|---|
| PHP | 8.2+ | `php --version` |
| Composer | 2.x | `composer --version` |
| Node.js | 18+ | `node --version` |
| PostgreSQL | 14+ | `psql --version` |
| Flutter | 3.22+ (opcional) | `flutter --version` |

#### 2. Configuración Backend

```bash
# Clonar e instalar
git clone https://github.com/TU_USUARIO/voluntapp.git
cd Proyecto
composer install

# Configurar entorno
copy .env.example .env
php artisan key:generate
```

#### 3. Configuración de Base de Datos

Edita `.env` con tus credenciales de PostgreSQL:

```env
APP_NAME=VoluntApp
APP_URL=http://localhost:8000

DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=voluntapp
DB_USERNAME=postgres
DB_PASSWORD=tu_contraseña_aqui

SANCTUM_STATEFUL_DOMAINS=localhost:5173,localhost:8000
SESSION_DRIVER=database
BROADCAST_CONNECTION=log
```

```bash
# Crear base de datos
psql -U postgres -c "CREATE DATABASE voluntapp;"

# ELEGIR UNA OPCIÓN:

# Opción A: Solo estructura básica
php artisan migrate
php artisan db:seed --class=CatalogosSeeder
php artisan db:seed --class=AdminSeeder

# Opción B: Incluir datos de demostración
php artisan migrate
php artisan db:seed

# Opción C: 🔥 DATOS MASIVOS REALISTAS (RECOMENDADO)
php artisan migrate
php artisan db:populate-massive
```

#### 4. Frontend (Aplicación Web)

```bash
cd frontend
npm install

# Opcional: configurar variables específicas
copy .env.example .env  # Solo si necesitas personalizar
```

#### 5. Mobile (Flutter) - Opcional

```bash
cd mobile

# Windows con PowerShell (recomendado)
.\scripts\setup.ps1

# O manualmente
flutter pub get
flutter doctor  # Verificar configuración
```

---

## 🖥️ Ejecutar en Desarrollo

### Opción Rápida - Script Todo en Uno

Crea un archivo `start-dev.bat` (Windows) o `start-dev.sh` (Mac/Linux):

**Windows (`start-dev.bat`):**
```batch
@echo off
echo 🚀 Iniciando VoluntApp en modo desarrollo...

echo 📡 Iniciando backend Laravel...
start "Backend" cmd /k "cd /d %~dp0 && php artisan serve --host=0.0.0.0 --port=8000"

timeout /t 3 > nul

echo 🌐 Iniciando frontend Vue...  
start "Frontend" cmd /k "cd /d %~dp0\frontend && npm run dev"

echo ✅ VoluntApp iniciado!
echo 📱 Web: http://localhost:5173
echo 🔧 API: http://localhost:8000
echo 📋 Admin: http://localhost:5173/admin

pause
```

**Mac/Linux (`start-dev.sh`):**
```bash
#!/bin/bash
echo "🚀 Iniciando VoluntApp en modo desarrollo..."

# Backend en background
echo "📡 Iniciando backend Laravel..."
php artisan serve --host=0.0.0.0 --port=8000 &
BACKEND_PID=$!

sleep 3

# Frontend en background  
echo "🌐 Iniciando frontend Vue..."
cd frontend && npm run dev &
FRONTEND_PID=$!

echo "✅ VoluntApp iniciado!"
echo "📱 Web: http://localhost:5173"
echo "🔧 API: http://localhost:8000"  
echo "📋 Admin: http://localhost:5173/admin"

# Manejar interrupción
trap "kill $BACKEND_PID $FRONTEND_PID" INT
wait
```

### Opción Manual - Terminales Separadas

**Terminal 1 — Backend Laravel:**
```bash
# Desde la raíz del proyecto
php artisan serve --host=0.0.0.0 --port=8000
```

**Terminal 2 — Frontend Vue:**
```bash
cd frontend
npm run dev
```

**Terminal 3 — Mobile Flutter (Opcional):**
```bash
cd mobile

# Para Windows Desktop:
flutter run -d windows --dart-define=ENV=dev --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1

# Para Android Emulador:
flutter run --dart-define=ENV=dev --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1

# Para dispositivo físico (reemplaza IP):
flutter run --dart-define=ENV=dev --dart-define=API_BASE_URL=http://TU_IP_LOCAL:8000/api/v1
```

### 🌐 URLs de Acceso

| Servicio | URL | Descripción |
|---|---|---|
| **Frontend Web** | http://localhost:5173 | Aplicación principal |
| **Panel Admin** | http://localhost:5173/admin | Administración |
| **API Backend** | http://localhost:8000/api/v1 | API REST |
| **Mobile App** | Emulador/Device | Flutter nativo |

---

## 🔑 Credenciales de Acceso

### 📋 Credenciales Principales

El proyecto incluye credenciales predefinidas para probar todas las funcionalidades:

| Tipo | Email | Contraseña | Descripción |
|---|---|---|---|
| **Super Admin** | `maria.rodriguez@voluntapp.co` | `Admin1234!` | Directora General |
| **Admin Operativo** | `carlos.martinez@voluntapp.co` | `Coord2024!` | Coordinador |
| **Admin Legacy** | `admin@voluntapp.co` | `Admin1234!` | Administrador original |

### 👥 Usuarios de Prueba (password123)

**Voluntarios Verificados:**
- `luis.lopez1782063718@hotmail.com` 
- `jose.martin1782063720@gmail.com`
- `carmen.sanchez1782063721@protonmail.com`

**Fundaciones Aprobadas:**
- `cruz.verde.colombia1782064741@yahoo.com`
- `fundacion.ninos.felices1782064743@gmail.com`
- `organizacion.manos.solidarias1782064744@yahoo.com`

> 📁 **Archivo completo:** Ver `CREDENCIALES_ACCESO.md` en la raíz del proyecto para lista completa con 10 voluntarios y 10 fundaciones.

### 🎯 Casos de Uso Recomendados

**Como Administrador:**
1. Login con `maria.rodriguez@voluntapp.co` / `Admin1234!`
2. Ir a **Voluntarios** → Ver lista compacta con fotos
3. Hacer clic en un voluntario para expandir acciones
4. Probar suspender/reactivar (sin errores)
5. Ir a **Fundaciones** → Aprobar fundaciones pendientes

**Como Voluntario:**
1. Login con `luis.lopez1782063718@hotmail.com` / `password123`
2. Ver **Actividades** → Usar botón cambio de vista (compacta ↔ completa)
3. Ver **Ranking** → Comprobar fotos de perfil reales
4. Postularse a actividades variadas

**Como Fundación:**
1. Login con `cruz.verde.colombia1782064741@yahoo.com` / `password123`
2. Crear nueva **Publicación**
3. Ver **Postulantes** con fotos de perfil
4. Gestionar estados de postulaciones

---

## 🗄️ Comandos de Datos Masivos

### 📊 Estadísticas del Sistema

Con el comando de datos masivos tendrás exactamente:

| Entidad | Cantidad | Detalles |
|---------|----------|----------|
| **Usuarios Totales** | 1,688 | Incluye voluntarios, fundaciones y admins |
| **Voluntarios** | 1,351 | 125 activos, 15 suspendidos, 10 bloqueados |
| **Fundaciones** | 331 | 25 aprobadas, 8 pendientes, 4 rechazadas, 3 suspendidas |
| **Publicaciones** | 600 | Variedad en modalidad, estado y dificultad |
| **Postulaciones** | 2,914 | Estados diversos: pendiente, aceptado, rechazado, etc. |
| **Administradores** | 6 | Diferentes niveles y especialidades |

### 🚀 Comando Principal

```bash
# COMANDO COMPLETO - Borra todo y crea desde cero
php artisan db:populate-massive --fresh

# COMANDO INCREMENTAL - Solo agrega datos (mantiene existentes)
php artisan db:populate-massive
```

### 📁 Generación de Credenciales

```bash
# Crear archivo con credenciales actualizadas
php artisan app:generate-credentials

# Esto genera:
# - CREDENCIALES_ACCESO.md (formato tabla completo)
# - CREDENCIALES_RAPIDAS.txt (copy-paste rápido)
```

### 🔄 Comandos por Partes (Opcionales)

```bash
# Solo catálogos básicos (departamentos, municipios, etc.)
php artisan db:seed --class=CatalogosSeeder

# Solo administradores
php artisan db:seed --class=AdminSeeder

# Solo datos de demostración básicos
php artisan db:seed --class=DemoSeeder

# Solo datos masivos (requiere catálogos primero)
php artisan db:seed --class=MassiveDataSeeder
```

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

---

## 📱 Nuevas Funcionalidades UI

### ✨ Mejoras Implementadas

**🖼️ Fotos de Perfil Reales:**
- **Ranking de voluntarios**: Muestra fotos de perfil junto a puntos y posiciones
- **Panel administrativo**: Listas compactas con avatares de usuarios
- **Componente reutilizable**: `AvatarImage` widget para toda la app
- **APIs automáticas**: Generación de avatares realistas con servicios públicos

**📱 Vistas Compactas:**
- **Admin Voluntarios/Fundaciones**: Listas expandibles en lugar de tarjetas grandes
- **Publicaciones**: Botón toggle entre vista completa y compacta
- **Mejor rendimiento**: Más elementos visibles por pantalla
- **UX mejorada**: Expansión/contracción para ver detalles

**🔧 Correcciones Técnicas:**
- **Error suspensión Flutter**: Solucionado `dependents.isEmpty is not true`
- **Navegación segura**: Verificación `if (!mounted) return` en widgets
- **Compatibilidad enums**: Valores corregidos para base de datos masiva

### 📂 Archivos Modificados

```
mobile/lib/features/shared/widgets/avatar_image.dart          ← Nuevo widget avatares
mobile/lib/features/ranking/presentation/screens/            ← Fotos en ranking
mobile/lib/features/admin/presentation/screens/              ← Listas compactas admin
mobile/lib/features/publicaciones/presentation/widgets/      ← Vista compacta publicaciones
mobile/lib/features/publicaciones/presentation/screens/      ← Toggle vista
```

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

## 🧪 Pruebas

### Ejecutar Tests Backend

```bash
# Todas las pruebas
php artisan test

# Solo pruebas de características específicas
php artisan test --filter=AuthTest
php artisan test --filter=VoluntarioTest
php artisan test --filter=FundacionTest

# Con coverage (si tienes xdebug)
php artisan test --coverage-html coverage-report
```

### Ejecutar Tests Flutter

```bash
cd mobile

# Todas las pruebas
flutter test

# Pruebas con coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Pruebas específicas
flutter test test/features/auth/
flutter test test/features/voluntario/
```

---

## 🚨 Solución de Problemas Comunes

### Backend Laravel

**Error: `Class 'App\Enum\EstadoUsuario' not found`**
```bash
composer dump-autoload
php artisan config:clear
php artisan cache:clear
```

**Error: Database connection refused**
```bash
# Verificar PostgreSQL está corriendo
sudo systemctl status postgresql  # Linux
net start postgresql-x64-14       # Windows

# Verificar credenciales en .env
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=voluntapp
DB_USERNAME=postgres
DB_PASSWORD=tu_contraseña
```

**Error: 'users' table doesn't exist**
```bash
# Ejecutar migraciones
php artisan migrate

# O usar comando completo
php artisan db:populate-massive --fresh
```

### Frontend Vue

**Error: Cannot resolve '@/...' imports**
```bash
cd frontend
rm -rf node_modules package-lock.json
npm install
```

**Error: CORS policy blocking requests**
- Verificar `SANCTUM_STATEFUL_DOMAINS=localhost:5173,localhost:8000` en `.env`
- Verificar backend corriendo en puerto 8000
- Verificar frontend corriendo en puerto 5173

### Flutter Mobile

**Error: `dependents.isEmpty is not true`**
✅ **Ya corregido** - Agregados checks `if (!mounted) return` en widgets

**Error: Gradle build failed**
```bash
cd mobile
flutter clean
flutter pub get
flutter run
```

**Error: Unable to connect to API**
- Verificar URL correcta según dispositivo:
  - Emulador Android: `http://10.0.2.2:8000/api/v1`
  - Dispositivo físico: `http://TU_IP_LOCAL:8000/api/v1`
  - Windows Desktop: `http://127.0.0.1:8000/api/v1`

**Error: Missing Android SDK/Flutter Doctor issues**
```bash
flutter doctor -v  # Ver todos los problemas
flutter doctor --android-licenses  # Aceptar licencias Android
```

### Base de Datos

**Error: role "postgres" does not exist**
```bash
# Crear usuario PostgreSQL
createuser -s -r postgres
psql -c "ALTER USER postgres PASSWORD 'tu_contraseña';"
```

**Error: database "voluntapp" does not exist**
```bash
psql -U postgres -c "CREATE DATABASE voluntapp;"
```

**Performance lenta con datos masivos**
```bash
# Regenerar solo estructura sin datos masivos
php artisan migrate:fresh
php artisan db:seed --class=CatalogosSeeder
php artisan db:seed --class=AdminSeeder
php artisan db:seed --class=DemoSeeder  # Solo datos básicos
```

---

## 🌐 Despliegue en Producción

### Backend (Laravel)

**1. Servidor (Apache/Nginx + PHP-FPM)**
```bash
# Clonar proyecto
git clone https://github.com/TU_USUARIO/voluntapp.git
cd Proyecto

# Instalar dependencias
composer install --optimize-autoloader --no-dev

# Configurar entorno
cp .env.example .env
nano .env  # Editar configuración producción

# Configurar permisos
chmod -R 775 storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache

# Optimizar para producción
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan optimize

# Migrar base de datos
php artisan migrate --force
php artisan db:populate-massive --fresh --force  # Solo si quieres datos masivos
```

**2. Variables de entorno producción (`.env`)**
```env
APP_ENV=production
APP_DEBUG=false
APP_URL=https://tu-dominio.com

DB_CONNECTION=pgsql
DB_HOST=tu-host-postgres
DB_DATABASE=voluntapp_prod
DB_USERNAME=usuario_prod
DB_PASSWORD=contraseña_segura

# SSL/HTTPS configuración
SANCTUM_STATEFUL_DOMAINS=tu-dominio.com
SESSION_SECURE_COOKIE=true
SESSION_SAME_SITE=none

# Backup/Storage
FILESYSTEM_DISK=s3  # O tu provider preferido
```

### Frontend (Vue SPA)

**1. Build para producción**
```bash
cd frontend
npm install
npm run build

# Configurar servidor web (nginx/apache)
# Servir archivos de 'dist/' folder
# Configurar rewrite rules para SPA routing
```

**2. Configuración Nginx**
```nginx
server {
    listen 80;
    server_name tu-dominio.com;
    root /path/to/proyecto/frontend/dist;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    location /api {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Flutter Mobile

**1. Android APK/Bundle**
```bash
cd mobile

# Debug APK (testing)
flutter build apk --debug

# Release APK (distribución)
flutter build apk --release

# Android App Bundle (Google Play)
flutter build appbundle --release
```

**2. iOS (requiere macOS + Xcode)**
```bash
cd mobile

# iOS Simulator
flutter build ios --debug

# iOS Device/App Store
flutter build ios --release
```

---

## 📂 Archivos de Credenciales

El proyecto incluye archivos de credenciales generados automáticamente:

| Archivo | Descripción | Comando para regenerar |
|---------|-------------|------------------------|
| `CREDENCIALES_ACCESO.md` | Lista completa con tablas organizadas | `php artisan app:generate-credentials` |
| `CREDENCIALES_RAPIDAS.txt` | Formato copy-paste para pruebas rápidas | `php artisan app:generate-credentials` |

### 🔄 Regenerar Credenciales

```bash
# Crear nuevos archivos con credenciales actualizadas
php artisan app:generate-credentials

# Esto actualiza ambos archivos con:
# - Todos los administradores actuales
# - 10 voluntarios aleatorios activos  
# - 10 fundaciones aprobadas aleatorias
# - Estadísticas actuales del sistema
```

---

## 🚀 Scripts de Inicio Rápido

### 📋 Validar Instalación

**Antes de comenzar**, verifica que tu entorno esté correctamente configurado:

**Windows:**
```batch
validate-setup.bat
```

**Mac/Linux:**
```bash
chmod +x validate-setup.sh
./validate-setup.sh
```

Este script verifica:
- ✅ PHP 8.2+, Composer, Node.js, PostgreSQL
- ✅ Archivos del proyecto (composer.json, package.json)
- ⚠️ Configuración opcional (Flutter, .env)

### 🚀 Iniciar Desarrollo

**Windows:**
```batch
start-dev.bat
```

**Mac/Linux:**
```bash
chmod +x start-dev.sh
./start-dev.sh
```

Estos scripts:
- 🖥️ Inician backend Laravel en puerto 8000
- 🌐 Inician frontend Vue en puerto 5173  
- 📋 Muestran URLs de acceso
- ⚡ Permiten desarrollo simultáneo

### Windows (`start-dev.bat`)

Crea este archivo en la raíz del proyecto:

```batch
@echo off
echo 🚀 Iniciando VoluntApp en modo desarrollo...

echo 📡 Iniciando backend Laravel...
start "Backend" cmd /k "cd /d %~dp0 && php artisan serve --host=0.0.0.0 --port=8000"

timeout /t 3 > nul

echo 🌐 Iniciando frontend Vue...  
start "Frontend" cmd /k "cd /d %~dp0\frontend && npm run dev"

echo ✅ VoluntApp iniciado!
echo 📱 Web: http://localhost:5173
echo 🔧 API: http://localhost:8000
echo 📋 Admin: http://localhost:5173/admin

pause
```

### Mac/Linux (`start-dev.sh`)

```bash
#!/bin/bash
echo "🚀 Iniciando VoluntApp en modo desarrollo..."

# Backend en background
echo "📡 Iniciando backend Laravel..."
php artisan serve --host=0.0.0.0 --port=8000 &
BACKEND_PID=$!

sleep 3

# Frontend en background  
echo "🌐 Iniciando frontend Vue..."
cd frontend && npm run dev &
FRONTEND_PID=$!

echo "✅ VoluntApp iniciado!"
echo "📱 Web: http://localhost:5173"
echo "🔧 API: http://localhost:8000"  
echo "📋 Admin: http://localhost:5173/admin"

# Manejar interrupción
trap "kill $BACKEND_PID $FRONTEND_PID" INT
wait
```

## ⚠️ Notas importantes

- El backend usa `laravel/sanctum` para compatibilidad con SPA y `php-open-source-saver/jwt-auth` para tokens JWT.
- El frontend se conecta a un backend Laravel a través de `axios` y mantiene sesión JWT en `localStorage`.
- El driver de broadcast por defecto es `log`; para habilitar WebSockets configura `BROADCAST_CONNECTION` y los parámetros de Reverb/Pusher en `.env`.
- El archivo `voluntapp_mvp.sql` es una referencia histórica y no se necesita cuando usas migraciones de Laravel.
- **Datos masivos**: El comando `db:populate-massive --fresh` crea exactamente los mismos datos en cualquier instalación nueva
- **UI mejorada**: Incluye vistas compactas, fotos de perfil reales y correcciones de errores Flutter
- **Flutter Windows**: Requiere activar "Modo desarrollador" en Windows para enlaces simbólicos

### 🔒 Seguridad en Producción

- Cambiar **todas las contraseñas** antes de desplegar
- Configurar SSL/HTTPS obligatorio
- Usar `APP_DEBUG=false` en producción  
- Configurar backup automático de base de datos
- Usar variables de entorno seguras (no commitear `.env`)

---

## 🐳 Docker

Este proyecto no incluye un entorno Docker oficial en su versión actual.
El desarrollo se ejecuta localmente con PHP, PostgreSQL y Vite.

**Para crear contenedorización personalizada:**
- Backend Laravel: PHP 8.2+ + PostgreSQL
- Frontend Vue: Node.js 18+ build + nginx/apache
- Mobile Flutter: No requiere contenedor (build nativo)

---

## 🌿 Git Flow recomendado

```
main       ← código estable listo para producción
develop    ← integración continua y nuevas funcionalidades
feature/*  ← nuevas caracteristicas
fix/*      ← correcciones de bugs
```

### Flujo de trabajo recomendado

```bash
# Crear nueva funcionalidad
git checkout develop
git pull origin develop
git checkout -b feature/mi-nueva-funcionalidad

# ... trabajar y hacer commits ...

git push origin feature/mi-nueva-funcionalidad
# Crear Pull Request hacia develop en GitHub/GitLab
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

## 🤝 Flujo de contribución

1. Haz fork del repositorio o crea una rama desde `develop`
2. Sigue los pasos de instalación de este README
3. Implementa tu cambio en una rama `feature/*` o `fix/*`
4. Ejecuta `php artisan test` — todos deben pasar
5. Ejecuta `flutter test` si modificaste código móvil
6. Abre un Pull Request hacia `develop` con descripción clara del cambio
7. Revisar feedback y hacer ajustes si es necesario

### 📋 Checklist para PRs

- [ ] Código sigue convenciones del proyecto
- [ ] Tests pasan (backend y mobile si aplica)
- [ ] Documentación actualizada si es necesario
- [ ] No hay credenciales hardcodeadas
- [ ] Cambios probados en entorno de desarrollo

---

## 📄 Licencia

**MIT License** — Uso libre con atribución.

```
Copyright (c) 2024 VoluntApp

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
```

---

## 📞 Soporte y Contacto

- **Issues**: Reportar bugs o solicitar funcionalidades en GitHub Issues
- **Documentación**: Consultar archivos en `/docs/` para guías detalladas
- **Credenciales**: Ver `CREDENCIALES_ACCESO.md` para acceso de prueba
- **Configuración**: Ver `MASSIVE_DATA_SETUP.md` para detalles de datos masivos

### 🔗 Enlaces útiles

- [Documentación Laravel](https://laravel.com/docs)
- [Documentación Vue 3](https://vuejs.org/guide/)
- [Documentación Flutter](https://docs.flutter.dev)
- [PostgreSQL Docs](https://www.postgresql.org/docs/)

---

**¡Gracias por usar VoluntApp! 🚀**

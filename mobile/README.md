# VoluntApp Mobile (Flutter)

Aplicación móvil Android/iOS del monorepo VoluntApp.

Documentación maestra: [`../docs/GUIA_MAESTRA_FLUTTER.md`](../docs/GUIA_MAESTRA_FLUTTER.md)

## Requisitos

| Herramienta | Versión |
|-------------|---------|
| Flutter SDK | 3.22+ |
| Dart | 3.3+ |
| Android Studio / Xcode | Para emuladores |

Verificar: `flutter doctor` (debe salir todo en verde).

### Windows: Modo desarrollador (obligatorio para plugins)

Flutter necesita crear symlinks al compilar con plugins (`flutter_secure_storage`, etc.).

1. Abre **Configuración → Privacidad y seguridad → Para desarrolladores**
2. Activa **Modo de desarrollador**
3. Cierra y vuelve a abrir la terminal

Comando rápido: `start ms-settings:developers`

## Setup inicial (primera vez)

```powershell
# Desde la raíz del monorepo
cd mobile
.\scripts\setup.ps1
flutter pub get
```

El script `setup.ps1` ejecuta `flutter create` para generar carpetas `android/` e `ios/` si no existen.

## Ejecutar en desarrollo

1. Levantar backend Laravel en `0.0.0.0:8000`:

```bash
php artisan serve --host=0.0.0.0 --port=8000
```

2. Emulador Android (API apunta a host machine):

```bash
flutter run --dart-define=ENV=dev --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

3. Dispositivo físico (usar IP LAN de tu PC):

```bash
flutter run --dart-define=ENV=dev --dart-define=API_BASE_URL=http://192.168.1.X:8000/api/v1
```

4. Windows desktop (sin emulador):

```bash
flutter run -d windows --dart-define=ENV=dev --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

## Estructura (Fase 1)

```
lib/
├── app/           # MaterialApp, theme, router
├── core/          # config, network, storage, providers
└── features/
    ├── auth/
    ├── bootstrap/
    └── home/
```

## Estado actual — Fase 1 / Sprint 1

- [x] Proyecto `mobile/` en monorepo
- [x] Config por `--dart-define`
- [x] Dio + AuthInterceptor + RefreshInterceptor
- [x] Secure token storage + session storage
- [x] go_router + bootstrap splash
- [x] Tema alineado a web (índigo/violeta)
- [x] Plataformas generadas (`android/`, `ios/`, `windows/`, etc.)
- [x] `flutter pub get` + tests base OK
- [x] Sprint 2: Login, Register, Forgot/Reset password
- [x] AuthRepository + guards go_router + pantalla blocked
- [x] Sprint 3: Catálogos Hive + Screen 06 perfil + bottom nav 5 tabs
- [x] Sprint 4: Dashboard voluntario (Screen 05A)
- [x] Sprint 5: Convocatorias + Mis Postulaciones (Screens 07-08)
- [x] Sprint 6: Favoritos + Logros + Ranking (Screens 09-11)
- [x] Sprint 7: Módulo fundación (Screens 12-13)
- [x] Sprint 8: Notificaciones (Screen 18)
- [x] Admin (Sprint 9): panel admin Screens 14-17 + dashboard 05C
- [x] Screen 17.1: crear reporte (`POST /reportes`) desde convocatorias
- [x] Admin: historial fundaciones/voluntarios
- [x] Sprint 10 (parcial): banner sin conexión (S21)
- [x] Sprint 10: integration tests locales (auth + navegación)

## Clonar el repo en otra PC (uso local)

Desde la **raíz del monorepo**:

### 1. Backend Laravel

```powershell
composer install
copy .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve --host=0.0.0.0 --port=8000
```

Los seeders crean usuarios demo:

| Rol | Email | Contraseña |
|-----|-------|------------|
| Voluntario | `voluntario1@demo.com` | `password` |
| Fundación | `fundacion1@demo.com` | `password` |
| Admin | `admin@voluntapp.co` | `Admin1234!` |

### 2. App Flutter (Windows)

```powershell
cd mobile
.\scripts\setup.ps1
flutter pub get
flutter run -d windows --dart-define=ENV=dev --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

> **Modo desarrollador** en Windows es obligatorio (symlinks de plugins). Ver sección anterior.

## Tests

### Unitarios y widgets (sin backend)

```bash
flutter test
flutter analyze
```

### Integration tests (requieren backend corriendo)

**Cierra `flutter run` antes de ejecutarlos** (evita bloqueo de Hive en Windows).

```powershell
cd mobile
.\scripts\run_integration_tests.ps1
```

Flujos cubiertos:
- Login / logout voluntario, fundación y admin
- Navegación bottom nav del voluntario (Actividades → Postulaciones)

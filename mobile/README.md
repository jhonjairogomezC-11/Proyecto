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
- [ ] Convocatorias (Sprint 5)

## Tests

```bash
flutter test
flutter analyze
```

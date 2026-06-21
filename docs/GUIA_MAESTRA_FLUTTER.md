# Guía Maestra de Implementación — VoluntApp Mobile (Flutter)

**Documento:** GUIA_MAESTRA_FLUTTER.md  
**Versión:** 1.0.0  
**Fecha:** 2026-06-20  
**Alcance:** Aplicación móvil Flutter consumiendo backend Laravel existente  
**Audiencia:** Arquitectos, desarrolladores Flutter, agentes de IA, QA, DevOps  

---

## Control del documento

| Campo | Valor |
|-------|-------|
| Backend existente | Laravel 12, PHP 8.2, PostgreSQL |
| Frontend web existente | Vue 3 + Vite (referencia funcional, no reimplementar lógica) |
| API base | `/api/v1` |
| Autenticación API | JWT (`php-open-source-saver/jwt-auth`) + refresh tokens custom |
| Roles | `VOLUNTARIO`, `FUNDACION`, `ADMIN` |
| Estado endpoints | **71 rutas REST documentadas** — mayoría lista para consumo móvil |
| Punto de retoma | Cada paso incluye ID único `STEP-X.Y.Z` |

### Convención de pasos

Cada paso incluye obligatoriamente:

- **Objetivo**
- **Descripción**
- **Qué analizar**
- **Qué construir**
- **Dependencias**
- **Riesgos**
- **Resultado esperado**
- **Checklist de validación**
- **Criterios de aceptación**

---

## Índice

1. [FASE 0 — Análisis del backend actual](#fase-0--análisis-del-backend-actual)
2. [FASE 1 — Preparación de arquitectura móvil](#fase-1--preparación-de-arquitectura-móvil)
3. [FASE 2 — Exposición y ajuste de APIs](#fase-2--exposición-y-ajuste-de-apis)
4. [FASE 3 — Autenticación móvil](#fase-3--autenticación-móvil)
5. [FASE 4 — Infraestructura Flutter](#fase-4--infraestructura-flutter)
6. [FASE 5 — Implementación de módulos y pantallas](#fase-5--implementación-de-módulos-y-pantallas)
7. [FASE 6 — Pruebas](#fase-6--pruebas)
8. [FASE 7 — Despliegue](#fase-7--despliegue)
9. [FASE 8 — Mantenimiento](#fase-8--mantenimiento)
10. [Catálogo de pantallas (Screen 01–18+)](#catálogo-de-pantallas)
11. [Roadmap de sprints](#roadmap-de-sprints)
12. [Inventario completo de APIs](#inventario-completo-de-apis)
13. [Anexos técnicos](#anexos-técnicos)

---

# FASE 0 — Análisis del backend actual

> **Estado:** COMPLETADO EN ESTE DOCUMENTO (baseline 2026-06-20)  
> **Próximo agente:** Validar contra `routes/api.php` si hubo cambios posteriores.

---

## STEP-0.1 — Inventario de estado actual del backend

### Objetivo
Establecer la línea base técnica del backend antes de escribir una línea de Flutter.

### Descripción
Documentar stack, estructura de carpetas, convenciones y puntos de entrada del API REST existente.

### Qué analizar

| Área | Ubicación | Hallazgo |
|------|-----------|----------|
| Rutas API | `routes/api.php` | Prefijo `/api/v1`, 71 endpoints |
| Controladores | `app/Http/Controllers/Api/V1/` | 13 controllers + 4 admin |
| Servicios | `app/Services/` | Lógica de negocio centralizada |
| Resources | `app/Http/Resources/` | Serialización JSON consistente |
| Policies | `app/Policies/` | `PublicacionPolicy`, `FundacionPolicy` |
| Middleware | `app/Http/Middleware/CheckRole.php` | Control por rol + estado cuenta |
| Excepciones | `bootstrap/app.php` | 401/403/404/422 estandarizados |
| Migraciones | `database/migrations/` | 20+ tablas de dominio |
| Tests | `tests/Feature/ApiV1Test.php` | Cobertura parcial API v1 |

### Stack confirmado

```
PHP 8.2 + Laravel 12
PostgreSQL (pgsql)
JWT Auth (guard api)
Queue: database
Cache: database
Mail: log (dev)
Storage: local + public disk
Broadcast: Reverb (opcional, no activo por defecto)
```

### Qué construir
- Archivo `docs/mobile/BASELINE_BACKEND.md` (copia resumida de este STEP) actualizable por commit.
- Tabla de endpoints exportada a CSV/JSON para generación de clientes Dart (opcional Sprint 1).

### Dependencias
Ninguna.

### Riesgos
- Documentación desactualizada si el backend cambia sin actualizar esta guía.
- Sanctum instalado pero **no usado** — puede confundir implementadores.

### Resultado esperado
Equipo y agentes comparten la misma foto del backend.

### Checklist de validación
- [ ] `php artisan route:list --path=api` coincide con inventario Sección 12
- [ ] `.env.example` revisado contra variables JWT/Reverb
- [ ] Tests existentes pasan: `php artisan test`

### Criterios de aceptación
Baseline firmada por líder técnico; inventario de 71 endpoints verificado.

---

## STEP-0.2 — Módulos existentes

### Objetivo
Mapear módulos de negocio → controllers → services → tablas.

### Módulos identificados

| Módulo | Tablas principales | Controller(s) | Service(s) |
|--------|-------------------|-----------------|------------|
| Auth | `usuarios`, `refresh_tokens`, `verificacion_email`, `recuperacion_password` | `AuthController` | `AuthService` |
| Catálogos | `departamentos`, `municipios`, `habilidades`, `intereses`, `areas_impacto` | `CatalogoController` | — |
| Voluntario | `voluntarios`, pivots habilidades/intereses | `VoluntarioController` | `VoluntarioDashboardService` |
| Fundación | `fundaciones`, `fundacion_areas`, `fundacion_documentos` | `FundacionController` | `AdminFundacionService` |
| Publicaciones | `publicaciones`, `publicacion_habilidades`, `publicacion_imagenes` | `PublicacionController` | `PublicacionService`, `PublicacionImagenService` |
| Postulaciones | `postulaciones` | `PostulacionController` | `PostulacionService` |
| Gamificación | `voluntario_puntos`, `transacciones_puntos`, `logros`, `voluntario_logros` | `GamificacionController` | `PuntoService`, `NivelVoluntarioService` |
| Favoritos | `voluntario_favoritos` | `FavoritoController` | `FavoritoService` |
| Notificaciones | `notificaciones` | `NotificacionController` | Varios (side-effect) |
| Reportes | `reportes` | `AdminReporteController` | — |
| Admin | `admin_perfiles`, `admin_acciones`, historiales | Admin* controllers | Admin* services |

### Qué construir
Diagrama de dependencias módulo → pantalla móvil (Anexo A).

### Dependencias
STEP-0.1

### Riesgos
Duplicar lógica de gamificación en Flutter en lugar de consumir `/voluntario/dashboard`.

### Resultado esperado
Matriz módulo ↔ endpoints ↔ pantallas Flutter definida.

### Checklist
- [ ] Cada módulo tiene owner backend identificado
- [ ] No hay módulo web-only sin equivalente API (excepto reportes POST — gap documentado)

### Criterios de aceptación
Matriz completa en Sección 5 y Catálogo de pantallas.

---

## STEP-0.3 — Roles y permisos

### Objetivo
Definir matriz de acceso móvil por rol.

### Roles

| Rol | Valor enum | Middleware | Pantallas móviles |
|-----|------------|------------|-------------------|
| Voluntario | `VOLUNTARIO` | `role:VOLUNTARIO` | Screens 05–11, 18 |
| Fundación | `FUNDACION` | `role:FUNDACION` | Screens 05, 12–13, 18 |
| Admin | `ADMIN` | `role:ADMIN` | Screens 05, 14–17, 18 |

### Estados de cuenta (`estado` en JWT claims)

| Estado | HTTP | Comportamiento móvil |
|--------|------|---------------------|
| ACTIVO | 200 | Normal |
| SUSPENDIDO | 403 | Pantalla bloqueo + logout |
| BLOQUEADO | 403 | Pantalla bloqueo + logout |

### Policies adicionales
- Editar publicación: dueño fundación o ADMIN.
- Editar fundación: dueño usuario o ADMIN.

### Qué construir en Flutter
- `RoleGuard` en router.
- `AuthInterceptor` que interpreta 403 por estado cuenta.
- Shell de navegación distinto por rol (3 layouts raíz).

### Dependencias
STEP-0.2

### Riesgos
Admin granular (`admin_perfiles.permisos`) **no enforced** — app móvil admin asume rol ADMIN completo.

### Resultado esperado
Router Flutter con 3 árboles de navegación aislados.

### Checklist
- [ ] Usuario VOLUNTARIO no accede rutas FUNDACION
- [ ] 403 muestra mensaje del backend sin crash

### Criterios de aceptación
Pruebas de navegación por rol en Sprint 2.

---

## STEP-0.4 — Sistema de autenticación actual

### Objetivo
Documentar flujo JWT existente para replicarlo en Flutter.

### Flujo actual

```
POST /auth/register  → { usuario, token, refresh_token, token_type, expires_in }
POST /auth/login     → idem
POST /auth/refresh   → body: { refresh_token } → rota refresh (single-use)
POST /auth/logout    → blacklist JWT (refresh NO revocado)
GET  /auth/me        → UsuarioResource
```

### Headers móvil obligatorios
```
Authorization: Bearer {access_token}
Accept: application/json
Content-Type: application/json
```

### Qué analizar
- `app/Services/AuthService.php`
- `config/jwt.php` — TTL default 60 min
- Tabla `refresh_tokens` — expiración 30 días

### Gaps identificados para móvil

| Gap | Prioridad | Acción Fase 2 |
|-----|-----------|---------------|
| Logout no revoca refresh_token | Alta | Endpoint `POST /auth/revoke-refresh` o marcar todos usados |
| Google OAuth sin endpoint | Media | Fase posterior |
| Email verify/reset sin envío real | Alta móvil | Deep links + envío mail en staging |
| `GET /auth/me` no usado en web | Baja | Usar en Flutter al cold start |

### Qué construir
Nada en backend en Fase 0 — solo documentación.

### Dependencias
STEP-0.1

### Riesgos
Almacenar tokens en `SharedPreferences` sin cifrado — usar `flutter_secure_storage`.

### Resultado esperado
Especificación auth lista para Sprint 2.

### Checklist
- [ ] Refresh automático en 401 documentado (patrón ya en `frontend/src/services/api.js`)
- [ ] Cola de requests pendientes durante refresh definida

### Criterios de aceptación
Diagrama de secuencia login → refresh → logout aprobado.

---

## STEP-0.5 — Estructura de base de datos

### Objetivo
Confirmar entidades persistidas relevantes para serialización móvil.

### Tablas (resumen)

**Auth:** `usuarios`, `refresh_tokens`, `verificacion_email`, `recuperacion_password`  
**Geo:** `departamentos`, `municipios`  
**Voluntario:** `voluntarios`, `voluntario_habilidades`, `voluntario_intereses`, `voluntario_puntos`, `transacciones_puntos`, `voluntario_logros`, `voluntario_favoritos`, `advertencias_voluntario`, `historial_estados_voluntario`  
**Fundación:** `fundaciones`, `fundacion_areas`, `fundacion_documentos`, `historial_estados_fundacion`  
**Core:** `publicaciones`, `publicacion_habilidades`, `publicacion_imagenes`, `postulaciones`, `notificaciones`  
**Catálogos:** `habilidades`, `intereses`, `areas_impacto`, `logros`, `configuracion_sistema`  
**Admin:** `admin_perfiles`, `admin_acciones`, `reportes`  

### Qué construir
Modelos Dart generados manualmente alineados a `Http/Resources/*` (no a tablas SQL directamente).

### Dependencias
STEP-0.2

### Riesgos
Enums PostgreSQL (`estado_postulacion`, etc.) — mapear como `String` en Dart.

### Resultado esperado
Lista de DTOs Dart requeridos (~25 clases).

### Checklist
- [ ] Cada Resource Laravel tiene DTO Dart correspondiente planificado

### Criterios de aceptación
Archivo `docs/mobile/DTO_MAPPING.md` creado en Sprint 1.

---

## STEP-0.6 — Flujo de navegación web actual (referencia)

### Objetivo
Usar el frontend Vue como **mapa funcional**, no como código a portar.

### Árbol de rutas web → móvil

```
/auth/login, register, forgot, reset
/dashboard (role-specific home)
  VOLUNTARIO: convocatorias, mis-postulaciones, favoritos, mis-logros, ranking, perfil-voluntario
  FUNDACION:  perfil-fundacion, mis-convocatorias
  ADMIN:      admin/fundaciones, admin/publicaciones, admin/voluntarios, admin/reportes
  ALL:        notificaciones
```

### Qué construir
Wireframes móvil equivalentes (bottom nav voluntario: Dashboard | Actividades | Postulaciones | Favoritos | Perfil).

### Dependencias
Auditoría frontend completada.

### Riesgos
Copiar layout web 1:1 — móvil requiere patrones nativos (tabs, sheets, pull-to-refresh).

### Resultado esperado
Mapa navegación Flutter aprobado en Fase 1.

### Checklist
- [ ] Cada ruta Vue tiene screen ID móvil asignado

### Criterios de aceptación
Catálogo Screen 01–18 completo (Sección dedicada).

---

## STEP-0.7 — Dependencias críticas

| Dependencia | Tipo | Impacto móvil |
|-------------|------|---------------|
| PostgreSQL | Infra | Backend only |
| JWT secret | Config | Obligatorio en todos los ambientes |
| `storage:link` | Deploy | URLs `/storage/...` para imágenes |
| Reverb WebSocket | Opcional | Tiempo real; fallback polling notificaciones |
| Queue worker | Async | Emails/notificaciones background |
| PHP built-in server | Dev only | No usar en prod móvil QA |

### Qué construir
Checklist de infra mínima para ambiente QA móvil.

### Riesgos
Probar móvil contra `localhost` del dev — usar IP LAN o túnel (ngrok) en dispositivo físico.

---

## STEP-0.8 — Servicios externos

| Servicio | Estado | Móvil |
|----------|--------|-------|
| Mail | `MAIL_MAILER=log` | Reset/verify requieren SMTP en staging+ |
| S3 | Config vacía | Futuro CDN imágenes |
| FCM/APNs | **NO EXISTE** | Crear en Fase 2 |
| Google OAuth | Enum only | Futuro |

---

## STEP-0.9 — Riesgos de migración (web → móvil)

| # | Riesgo | Mitigación |
|---|--------|------------|
| R1 | Asumir Sanctum | Usar JWT Bearer exclusivamente |
| R2 | WebSocket sin auth route | Polling `/notificaciones/no-leidas` en v1 móvil |
| R3 | Paginación fija (15/20) | Infinite scroll con `page` param existente |
| R4 | Imágenes URL relativas | Base URL configurable + proxy CDN |
| R5 | Multipart uploads | `dio` + `FormData` nativo |
| R6 | Refresh token en logout | Implementar revocación backend Sprint 1 |
| R7 | Sin OpenAPI | Generar spec en Fase 2 |
| R8 | Admin en móvil | Decidir: v1 solo VOLUNTARIO+FUNDACION o incluir ADMIN |

**Recomendación v1 móvil:** Priorizar **VOLUNTARIO** completo, **FUNDACION** completo, **ADMIN** en v1.1.

---

# FASE 1 — Preparación de arquitectura móvil

---

## STEP-1.1 — Decisión de estructura de repositorio

### Objetivo
Definir dónde vive el código Flutter y cómo convive con Laravel/Vue.

### Opciones analizadas

#### Opción A — Monorepo (recomendada)

```
Proyecto/
├── app/                    # Laravel backend (existente)
├── config/
├── database/
├── routes/
├── tests/
├── frontend/               # Vue web (existente)
├── mobile/                 # Flutter (NUEVO)
│   ├── android/
│   ├── ios/
│   ├── lib/
│   ├── test/
│   ├── integration_test/
│   └── pubspec.yaml
├── docs/
│   ├── GUIA_MAESTRA_FLUTTER.md
│   └── mobile/
└── README.md
```

| Ventaja | Desventaja |
|---------|------------|
| Un solo PR puede tocar API + móvil | Repo más pesado |
| Versionado alineado API v1 ↔ app | CI más complejo |
| Agentes ven contexto completo | Flutter SDK requerido en CI |
| Misma convención que `frontend/` | — |

#### Opción B — Repositorio separado

```
voluntapp-api/     (este repo sin mobile/)
voluntapp-mobile/  (repo nuevo)
```

| Ventaja | Desventaja |
|---------|------------|
| CI/CD independiente | Drift API ↔ app |
| Permisos de equipo separados | Duplicar documentación |
| Releases móvil desacoplados | Contratos API deben publicarse aparte |

#### Opción C — Backend como subcarpeta

```
voluntapp/
├── backend/
├── web/
└── mobile/
```

Requiere reorganización masiva del repo actual — **descartada**.

### Recomendación final

**Opción A — Monorepo con carpeta `mobile/`** al mismo nivel que `frontend/`.

**Justificación:**
1. El proyecto ya usa monorepo implícito (`frontend/` separado de Laravel root).
2. El equipo conoce un solo repositorio SENA.
3. Cambios de API (imágenes, favoritos, dashboard) se coordinan en un commit.
4. Agentes IA retoman contexto leyendo `routes/api.php` + `mobile/lib/` en un workspace.

### Qué construir
- Crear carpeta `mobile/` con `flutter create . --org co.voluntapp --project-name voluntapp_mobile`
- Actualizar `README.md` raíz con sección Mobile
- `.gitignore` entries: `mobile/.dart_tool/`, `mobile/build/`, `mobile/.flutter-plugins*`

### Dependencias
Fase 0 completa.

### Riesgos
Mezclar dependencias npm/composer/flutter en scripts — mantener scripts separados.

### Resultado esperado
Proyecto Flutter vacío compila en Android/iOS.

### Checklist
- [ ] `cd mobile && flutter doctor` sin errores críticos
- [ ] `flutter analyze` pasa en proyecto vacío
- [ ] README actualizado

### Criterios de aceptación
APK debug generado: `flutter build apk --debug`

---

## STEP-1.2 — Estrategia de ambientes

### Objetivo
Definir configuración por entorno para la app móvil.

### Ambientes

| Ambiente | API URL ejemplo | Uso |
|----------|-----------------|-----|
| dev | `http://10.0.2.2:8000/api/v1` (Android emulator) | Desarrollo local |
| dev | `http://127.0.0.1:8000/api/v1` (iOS sim) | Desarrollo local |
| qa | `https://qa-api.voluntapp.co/api/v1` | QA interno |
| staging | `https://staging-api.voluntapp.co/api/v1` | Pre-prod |
| prod | `https://api.voluntapp.co/api/v1` | Producción |

### Qué construir

```
mobile/lib/core/config/
├── app_config.dart
├── env_dev.dart
├── env_qa.dart
├── env_staging.dart
└── env_prod.dart
```

Flavoring Flutter:
```bash
flutter run --dart-define=ENV=dev --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

### Dependencias
STEP-1.1

### Riesgos
HTTP cleartext bloqueado en Android 9+ — `network_security_config.xml` solo en dev.

### Resultado esperado
App arranca mostrando ambiente activo en debug banner.

### Checklist
- [ ] Cambiar ENV cambia base URL
- [ ] Prod fuerza HTTPS

### Criterios de aceptación
4 flavors configurados en CI.

---

## STEP-1.3 — Arquitectura Flutter empresarial (decisión)

### Objetivo
Seleccionar stack Flutter production-ready alineado al backend REST.

### Decisiones

| Aspecto | Elección | Justificación |
|---------|----------|---------------|
| Patrón | **Clean Architecture + Feature-first** | Escalable, testeable, equipos paralelos |
| Estado | **Riverpod 2.x** | DI nativa, async, test friendly |
| Navegación | **go_router** | Deep links auth reset, guards declarativos |
| HTTP | **dio** | Interceptors JWT, multipart, cancel tokens |
| Modelos | **freezed + json_serializable** | Inmutabilidad, copyWith, JSON |
| Storage seguro | **flutter_secure_storage** | Tokens |
| Storage cache | **hive** o **shared_preferences** | Catálogos offline |
| Imágenes | **cached_network_image** | Convocatorias con carrusel |
| i18n | **flutter_localizations** | es-CO default |
| Errores | **Either pattern (fpdart)** o sealed classes | 422 field errors |

### Estructura de carpetas (producción)

```
mobile/lib/
├── main.dart
├── main_dev.dart
├── main_prod.dart
├── app/
│   ├── app.dart                    # MaterialApp.router
│   ├── router/
│   │   ├── app_router.dart
│   │   ├── routes.dart
│   │   └── guards/
│   │       ├── auth_guard.dart
│   │       └── role_guard.dart
│   └── theme/
│       ├── app_theme.dart
│       ├── app_colors.dart
│       └── app_typography.dart
├── core/
│   ├── config/
│   ├── constants/
│   ├── network/
│   │   ├── dio_client.dart
│   │   ├── auth_interceptor.dart
│   │   ├── refresh_interceptor.dart
│   │   └── api_exception.dart
│   ├── storage/
│   │   ├── secure_token_storage.dart
│   │   └── cache_storage.dart
│   ├── utils/
│   └── widgets/                    # Design system compartido
│       ├── app_button.dart
│       ├── app_text_field.dart
│       ├── loading_overlay.dart
│       ├── empty_state.dart
│       ├── error_view.dart
│       ├── badge_estado.dart
│       └── image_carousel.dart
└── features/
    ├── auth/
    │   ├── data/
    │   │   ├── datasources/auth_remote_datasource.dart
    │   │   ├── models/
    │   │   └── repositories/auth_repository_impl.dart
    │   ├── domain/
    │   │   ├── entities/
    │   │   ├── repositories/auth_repository.dart
    │   │   └── usecases/
    │   └── presentation/
    │       ├── providers/
    │       ├── screens/
    │       └── widgets/
    ├── voluntario/
    │   ├── dashboard/
    │   ├── convocatorias/
    │   ├── postulaciones/
    │   ├── favoritos/
    │   ├── logros/
    │   ├── ranking/
    │   └── perfil/
    ├── fundacion/
    │   ├── perfil/
    │   └── convocatorias/
    ├── admin/
    │   ├── fundaciones/
    │   ├── publicaciones/
    │   ├── voluntarios/
    │   └── reportes/
    ├── notificaciones/
    └── catalogos/                  # Shared catalog cache
```

### Capas y responsabilidades

```
Presentation → Providers/Controllers → UseCases → Repository → DataSource → Dio
```

**Regla:** Ningún widget importa `dio` directamente.

### Qué construir
Scaffold completo en Sprint 1 (ver Roadmap).

### Dependencias
STEP-1.1, STEP-1.2

### Riesgos
Over-engineering — empezar con features verticales completas, no horizontal prematura.

### Resultado esperado
`flutter analyze` limpio con estructura base.

### Checklist
- [ ] Dependencias en `pubspec.yaml` fijadas con versiones
- [ ] `build_runner` configurado para freezed
- [ ] Tema alineado a web (índigo/violeta `#6366f1`)

### Criterios de aceptación
Arquitectura revisada y mergeada a `main`.

---

# FASE 2 — Exposición y ajuste de APIs

> Objetivo: **No reinventar** — extender solo lo necesario para móvil.

---

## STEP-2.1 — Inventario: APIs existentes vs faltantes vs modificar

### APIs EXISTENTES (listas para consumo móvil) — 71 endpoints

Ver **Sección 12 — Inventario completo**.

### APIs FALTANTES (crear)

| ID | Endpoint | Método | Prioridad | Sprint |
|----|----------|--------|-----------|--------|
| API-M01 | `/auth/revoke-refresh` | POST | Alta | 1 |
| API-M02 | `/auth/me` uso + validación sesión | GET | Media | 2 |
| API-M03 | `/dispositivos/registrar` | POST | Alta | 8 |
| API-M04 | `/dispositivos/{id}` | DELETE | Media | 8 |
| API-M05 | `/voluntario/foto-perfil` | POST multipart | Media | 5 |
| API-M06 | `/fundaciones/{id}/logo` | POST multipart | Baja | 6 |
| API-M07 | `/reportes` UI móvil (POST ya existe) | POST | Media | 9 |
| API-M08 | `/broadcasting/auth` | POST | Baja | 9 |
| API-M09 | `/catalogos/version` | GET | Baja | 4 |
| API-M10 | OpenAPI `/docs/openapi.json` | GET | Media | 1 |

**Tabla nueva requerida para push:**

```sql
-- API-M03
CREATE TABLE dispositivos_push (
  id UUID PRIMARY KEY,
  usuario_id UUID NOT NULL REFERENCES usuarios(id),
  token VARCHAR(500) NOT NULL,
  plataforma VARCHAR(20) NOT NULL, -- android | ios
  activo BOOLEAN DEFAULT true,
  fecha_creacion TIMESTAMP DEFAULT NOW(),
  UNIQUE(usuario_id, token)
);
```

### APIs a MODIFICAR

| ID | Endpoint | Cambio | Razón |
|----|----------|--------|-------|
| API-MOD01 | `GET /publicaciones` | Aceptar `?per_page=` (max 50) | Scroll infinito móvil |
| API-MOD02 | `GET /mis-postulaciones` | Aceptar `?per_page=` | Idem |
| API-MOD03 | `GET /notificaciones` | Aceptar `?per_page=` | Idem |
| API-MOD04 | `POST /auth/logout` | Revocar refresh tokens del usuario | Seguridad multi-dispositivo |
| API-MOD05 | Resources imágenes | URL absoluta opcional `?absolute=1` | Evitar joins URL en móvil |
| API-MOD06 | `GET /ranking` | Incluir auth opcional Bearer | `mi_posicion` siempre |

### Qué construir (backend)
Un PR por grupo: seguridad (MOD04, M01), paginación (MOD01-03), push (M03-04), docs (M10).

### Dependencias
Fase 0.

### Riesgos
Cambiar paginación puede afectar web Vue — mantener default 15.

### Resultado esperado
Contrato API v1.1 documentado retrocompatible.

### Checklist
- [ ] Tests Pest para cada endpoint nuevo
- [ ] Migración `dispositivos_push` en staging

### Criterios de aceptación
OpenAPI publicado; Flutter consume sin workarounds críticos.

---

## STEP-2.2 — Convenciones de respuesta API

### Formato estándar

**Recurso único:**
```json
{ "id": "uuid", "campo": "valor" }
```

**Colección paginada:**
```json
{
  "data": [ ... ],
  "links": { "first", "last", "prev", "next" },
  "meta": { "current_page", "last_page", "per_page", "total" }
}
```

**Colección sin paginar (catálogos, favoritos):**
```json
[ { "id": 1, "nombre": "..." } ]
```
o `{ "data": [...] }` según endpoint — **Flutter debe normalizar en DataSource**.

**Respuestas compuestas (dashboard, puntos, ranking):**
Objeto plano sin wrapper — mapear DTO específico.

### Enums
Siempre **string** (`PENDIENTE`, `ACEPTADO`, `VOLUNTARIO`).

### Fechas
ISO 8601 strings (`2026-06-20T12:00:00.000000Z` o date-only para convocatorias).

### Qué construir en Flutter
`ResponseNormalizer` en `core/network/` para unificar paginación.

---

## STEP-2.3 — Manejo de errores API

| HTTP | Body | Acción Flutter |
|------|------|----------------|
| 401 | `{ "message": "No autenticado." }` | Refresh → retry; si falla → login |
| 403 | `{ "message": "..." }` | SnackBar + redirect si cuenta suspendida |
| 404 | `{ "message": "Recurso no encontrado." }` | Empty/error state |
| 422 | `{ "message", "errors": { "campo": ["msg"] } }` | Mostrar en form fields |
| 500 | Laravel default | Pantalla error genérica + reintentar |

### Qué construir
```dart
sealed class ApiFailure {
  NetworkFailure | UnauthorizedFailure | ForbiddenFailure |
  ValidationFailure(Map<String,String>) | NotFoundFailure | ServerFailure
}
```

---

## STEP-2.4 — Versionado

### Estrategia
- **v1 actual:** sin breaking changes; solo adiciones retrocompatibles.
- **v2 futuro:** solo si se rompe contrato (no planificado).
- Header opcional: `X-Client-Version: 1.0.0+1`
- Header opcional: `X-Platform: android|ios`

### Qué construir
Middleware Laravel `LogClientInfo` (opcional) para analytics.

---

## STEP-2.5 — Seguridad API móvil

| Control | Implementación |
|---------|----------------|
| TLS | Obligatorio prod; certificate pinning opcional v1.1 |
| Token storage | `flutter_secure_storage` |
| Refresh rotation | Ya existe — respetar single-use |
| Rate limit | `ThrottleRequests:api` en Laravel — 60/min por IP |
| Multipart | Validar MIME server-side (ya existe) |
| Logs | No loguear tokens en Flutter (kDebugMode only metadata) |

---

# FASE 3 — Autenticación móvil

---

## STEP-3.1 — Estrategia de autenticación

### Decisión
**Reutilizar JWT existente** — NO implementar Sanctum en móvil.

### Flujo cold start

```
1. App launch
2. Leer secure storage: access_token, refresh_token, user_json
3. Si access_token existe:
   a. GET /auth/me (validar)
   b. Si 401 → refresh → retry
   c. Si refresh falla → Screen 01 Login
4. Si no tokens → Screen 01
5. Router → dashboard según user.rol
```

### Qué construir
- `AuthRepository`, `RefreshTokenInterceptor`
- `AuthState` sealed: initial | authenticated(Usuario) | unauthenticated

---

## STEP-3.2 — Gestión de sesiones y tokens

| Token | Storage | TTL |
|-------|---------|-----|
| access (JWT) | Secure storage | ~60 min |
| refresh | Secure storage | 30 días |
| user | Hive/shared_prefs (no sensible) | Hasta logout |

### Refresh interceptor (pseudo)

```
on 401:
  if already retried: logout
  if refresh in progress: queue request
  else:
    POST /auth/refresh
    save new tokens
    retry all queued
```

Referencia implementación web: `frontend/src/services/api.js`.

---

## STEP-3.3 — Cierre de sesión

```
1. POST /auth/logout (Bearer access)
2. POST /auth/revoke-refresh (NUEVO — opcional body all_devices)
3. Clear secure storage + cache
4. Navigate login
```

---

## STEP-3.4 — Múltiples dispositivos

- Cada dispositivo = refresh token independiente (tabla `refresh_tokens`).
- Logout local revoca solo JWT actual hasta implementar MOD04.
- **Fase 2 MOD04:** al logout, marcar refresh tokens del usuario.

---

## STEP-3.5 — Recuperación de contraseña

### Flujo móvil

```
Screen 03 Forgot → POST /auth/forgot-password { email }
Screen 04 Reset → deep link voluntapp://reset?token=&email=
               → POST /auth/reset-password
```

### Qué construir backend (staging+)
- Envío real de email (`MAIL_MAILER=smtp`)
- Template con deep link o universal link

### Android/iOS
- `AndroidManifest` intent-filter
- iOS `Associated Domains` + Universal Links

---

## STEP-3.6 — Registro

```
POST /auth/register
{
  "rol": "VOLUNTARIO" | "FUNDACION",
  "nombre", "email", "telefono?", "password", "password_confirmation"
}
```

Tras registro → auto-login con tokens retornados → dashboard rol correspondiente.

---

# FASE 4 — Infraestructura Flutter

---

## STEP-4.1 — Bootstrap del proyecto

### Comandos

```bash
cd Proyecto
flutter create mobile --org co.voluntapp --project-name voluntapp_mobile
cd mobile
flutter pub add flutter_riverpod go_router dio flutter_secure_storage \
  freezed_annotation json_annotation cached_network_image \
  intl fpdart connectivity_plus
flutter pub add --dev build_runner freezed json_serializable \
  riverpod_generator mocktail flutter_test integration_test
```

### Qué construir
- `main.dart` entry con `ProviderScope`
- `AppConfig.fromEnvironment()`
- Tema light (matching web índigo/violeta)

### Checklist
- [ ] Android minSdk 21+
- [ ] iOS 13+
- [ ] Permisos internet en manifests

---

## STEP-4.2 — Cliente HTTP (Dio)

```dart
// core/network/dio_client.dart
final dio = Dio(BaseOptions(
  baseUrl: config.apiBaseUrl,
  connectTimeout: Duration(seconds: 15),
  receiveTimeout: Duration(seconds: 30),
  headers: {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  },
));
dio.interceptors.addAll([
  AuthInterceptor(tokenStorage),
  RefreshInterceptor(...),
  LogInterceptor(requestBody: kDebugMode),
]);
```

---

## STEP-4.3 — Navegación (go_router)

```dart
// Rutas principales
/login
/register
/forgot-password
/reset-password
/voluntario/dashboard
/voluntario/convocatorias
/voluntario/postulaciones
/voluntario/favoritos
/voluntario/logros
/voluntario/ranking
/voluntario/perfil
/fundacion/dashboard
/fundacion/perfil
/fundacion/convocatorias
/admin/...
/notificaciones
/blocked-account
```

### Shell routes
- `VoluntarioShell` — BottomNavigationBar 5 tabs
- `FundacionShell` — 3 tabs
- `AdminShell` — Drawer navigation

---

## STEP-4.4 — Design system móvil

Componentes mínimos (paridad web):

| Componente web | Widget Flutter |
|----------------|----------------|
| `AppSpinner` | `LoadingIndicator` |
| `AppAlert` | `AppBanner` |
| `AppModal` | `showModalBottomSheet` / `Dialog` |
| `AppPagination` | Infinite scroll + pull refresh |
| `BadgeEstado` | `EstadoChip` |
| `GradientStatCard` | `StatCard` |
| `ImageCarousel` | `PageView` + indicators |
| `AppToast` | `ScaffoldMessenger` / overlay |

### Animaciones
- `AnimatedSwitcher` en tabs
- Hero en imágenes convocatoria
- Shimmer skeleton en listas

---

## STEP-4.5 — Catálogos offline

```
Al login exitoso:
  GET /catalogos/departamentos
  GET /catalogos/habilidades
  GET /catalogos/intereses
  GET /catalogos/areas-impacto
→ Cache Hive 24h
→ Municipios lazy por departamento_id
```

---

# FASE 5 — Implementación de módulos y pantallas

---

## Orden de implementación recomendado

```
Sprint 1  → Infra + auth
Sprint 2  → Auth screens + guards
Sprint 3  → Catálogos + perfil voluntario
Sprint 4  → Dashboard voluntario
Sprint 5  → Convocatorias + postulaciones
Sprint 6  → Favoritos + logros + ranking
Sprint 7  → Fundación módulo completo
Sprint 8  → Notificaciones + push
Sprint 9  → Admin (opcional v1.1)
Sprint 10 → Hardening + stores
```

---

# Catálogo de pantallas

> Numeración alineada al frontend Vue existente + extensiones móvil.

---

## Screen 01 — Login

| Campo | Detalle |
|-------|---------|
| **Objetivo** | Autenticar usuario existente |
| **Rol** | Guest |
| **APIs** | `POST /auth/login` |
| **Datos UI** | email, password |
| **Validaciones client** | campos requeridos, email formato |
| **Errores** | 401 credenciales; 403 cuenta suspendida |
| **Navegación éxito** | `/dashboard` según rol |
| **Widgets** | Logo, TextFields, CTA, links register/forgot |

### Checklist
- [ ] Loading state en botón
- [ ] Keyboard dismiss
- [ ] Secure password field

### Criterios aceptación
Login exitoso persiste tokens; kill app → sigue logueado.

---

## Screen 02 — Register

| Campo | Detalle |
|-------|---------|
| **APIs** | `POST /auth/register` |
| **Datos** | rol (segmented control), nombre, email, teléfono, password, confirmación |
| **Validaciones** | password ≥8, match confirmation |
| **Navegación** | Auto dashboard post-registro |

---

## Screen 03 — Forgot Password

| Campo | Detalle |
|-------|---------|
| **APIs** | `POST /auth/forgot-password` |
| **UX** | Mensaje éxito aunque email no exista (seguridad) |

---

## Screen 04 — Reset Password

| Campo | Detalle |
|-------|---------|
| **APIs** | `POST /auth/reset-password` |
| **Deep link** | `token`, `email` query params |
| **Validaciones** | password ≥8, match |

---

## Screen 05 — Dashboard (role-aware)

### 05A — Dashboard Voluntario

| Campo | Detalle |
|-------|---------|
| **APIs** | `GET /voluntario` (perfil check), `GET /voluntario/dashboard` |
| **Secciones UI** | Hero banner, 4 stat cards, pills postulaciones, próximas actividades, progreso nivel/logro |
| **Referencia web** | `components/VoluntarioDashboard.vue` |
| **Navegación** | Ver todas → Screen 08; Explorar → Screen 07 |

**DTO `DashboardVoluntario`:**
```dart
actividadesCompletadas: { total, estaSemana, esteMes }
puntos: { saldo, totalHistorico }
nivel: { nivelActual, nivelSiguiente, puntosFaltan, porcentaje }
logros: { desbloqueados, recientes[] }
ranking: { posicion, total, topPercent }
proximasActividades: Postulacion[]
postulacionesResumen: { pendientes, aceptadas, rechazadas }
progresoMensual: { completadas, meta, faltan, porcentaje }
```

### 05B — Dashboard Fundación

| APIs | `GET /mi-fundacion`, `GET /mis-publicaciones`, `GET /publicaciones/{id}/postulaciones` (agregado) |
| UI | Stats publicaciones/postulaciones, acciones rápidas |

### 05C — Dashboard Admin

| APIs | `GET /admin/fundaciones?estado=PENDIENTE`, `GET /admin/reportes?estado=PENDIENTE` |

---

## Screen 06 — Perfil Voluntario

| APIs | `GET/POST/PUT /voluntario`, catálogos geo/habilidades/intereses |
| Modos | Crear (404 inicial) / Editar |
| Pickers | DatePicker nacimiento, dropdowns cascada dept→muni |
| Tags | Multi-select habilidades e intereses |

---

## Screen 07 — Actividades disponibles (Convocatorias)

| APIs | |
|------|--|
| List | `GET /publicaciones?buscar=&categoria_id=&modalidad=&municipio_id=&page=` |
| Apply | `POST /postulaciones` |
| Fav pub | `POST /voluntario/favoritos/publicacion/{id}` |
| Fav fund | `POST /voluntario/favoritos/fundacion/{id}` |
| State | `GET /voluntario/favoritos/ids`, `GET /mis-postulaciones?per_page=100` |

**UI:**
- Barra búsqueda sticky
- Chips filtros (bottom sheet)
- Grid cards con `ImageCarousel`
- FAB filtros
- Bottom sheet detalle convocatoria
- Botón postular + corazón favorito

**WebSocket (opcional v1.1):** canal `convocatorias` evento `.NuevaPublicacion` → refresh page 1

---

## Screen 08 — Mis Postulaciones

| APIs | `GET /mis-postulaciones?page=`, `POST /postulaciones/{id}/retirar` |
| Tabs | Todas, Pendientes, Aceptadas, Rechazadas, Completadas |
| Acciones | Ver detalle (bottom sheet), Retirar (confirm dialog) |
| WS | `.PostulacionActualizada` en canal `usuario.{id}` |

---

## Screen 09 — Favoritos

| APIs | `GET /voluntario/favoritos`, `DELETE /voluntario/favoritos/{id}` |
| Tabs | Actividades \| Fundaciones |
| Empty states | CTA → Screen 07 |

---

## Screen 10 — Logros y Puntos

| APIs | `GET /voluntario/puntos`, `GET /voluntario/logros` |
| UI | Banner saldo, grid logros obtenidos, lista progreso pendientes, transacciones recientes |

---

## Screen 11 — Ranking

| APIs | `GET /ranking?top=10|25|50` |
| UI | Podio top 3, lista, badge "Tú", posición fuera del top |

---

## Screen 12 — Perfil Fundación

| APIs | `GET /mi-fundacion`, `POST /fundaciones`, `PUT /fundaciones/{id}` |
| Estados | Sin perfil / Pendiente aprobación / Aprobada |

---

## Screen 13 — Mis Convocatorias (Fundación)

| APIs | CRUD publicaciones, imágenes, publicar, cancelar, postulantes, responder, confirmar asistencia |
| Upload | `POST /publicaciones/{id}/imagenes` multipart max 5 |
| WS | Canales `fundacion.{id}` |

**Sub-pantallas:**
- Screen 13.1 — Formulario convocatoria
- Screen 13.2 — Lista postulantes
- Screen 13.3 — Confirmar asistencia + calificación

---

## Screen 14 — Admin Fundaciones

| APIs | `/admin/fundaciones/*` |
| Acciones | Aprobar, rechazar, suspender, reactivar, historial |

---

## Screen 15 — Admin Publicaciones

| APIs | `/admin/publicaciones/*` |
| Tabs | Pendientes, publicadas, borradores |

---

## Screen 16 — Admin Voluntarios

| APIs | `/admin/voluntarios/*` |

---

## Screen 17 — Admin Reportes

| APIs | `GET /admin/reportes`, `PUT /admin/reportes/{id}/resolver` |
| Gap | Crear reporte: `POST /reportes` — agregar Screen 17.1 en v1.1 |

---

## Screen 18 — Notificaciones (shared)

| APIs | `GET /notificaciones?page=`, `PUT /{id}/marcar-leida`, `POST /marcar-todas-leidas` |
| Badge | `GET /notificaciones/no-leidas` en app bar |
| v1 | Polling cada 60s en foreground |
| v1.1 | FCM push |

---

## Pantallas adicionales móvil (infra)

| Screen | Propósito |
|--------|-----------|
| S19 | Splash / bootstrap auth |
| S20 | Account blocked (403 suspendido/bloqueado) |
| S21 | No connectivity |
| S22 | Force update (store version check — futuro) |
| S23 | Onboarding voluntario (opcional) |

---

# Roadmap de sprints

---

## Sprint 1 — Configuración inicial (2 semanas)

| Tarea | Entregable |
|-------|------------|
| Crear proyecto `mobile/` | Repo scaffold |
| Config ambientes | Flavors dev/qa/prod |
| Core network + interceptors | Dio funcional |
| OpenAPI spec generado | `docs/mobile/openapi.yaml` |
| Backend: revoke refresh + per_page | PR backend |
| CI: flutter analyze + test | GitHub Actions |

**Dependencias:** Fase 0-1  
**Riesgos:** Flutter SDK version mismatch en equipo  
**Tiempo:** 10 días hábiles  

---

## Sprint 2 — Autenticación (2 semanas)

| Tarea | Entregable |
|-------|------------|
| Screens 01-04 | Auth flow completo |
| Secure storage | Tokens cifrados |
| go_router guards | Role redirect |
| Screen S19 Splash | Cold start |
| Screen S20 Blocked | 403 handling |
| Tests unit auth repo | 80% coverage repo |

**Entregables:** APK auth demo  
**Riesgos:** Deep link reset incompleto en Android  
**Tiempo:** 10 días  

---

## Sprint 3 — Perfil voluntario + catálogos (1.5 semanas)

| Tarea | Entregable |
|-------|------------|
| Catalog cache | Hive |
| Screen 06 | CRUD perfil |
| Validación 422 | Field errors |
| Bottom nav shell | 5 tabs placeholder |

**Tiempo:** 7 días  

---

## Sprint 4 — Dashboard voluntario (1.5 semanas)

| Tarea | Entregable |
|-------|------------|
| Screen 05A | Paridad `VoluntarioDashboard.vue` |
| DTOs dashboard | freezed models |
| Pull to refresh | |

**Tiempo:** 7 días  

---

## Sprint 5 — Convocatorias y postulaciones (2 semanas)

| Tarea | Entregable |
|-------|------------|
| Screen 07 | Lista + filtros + carrusel |
| Screen 08 | Tabs + retirar |
| Postulación flow | Modal mensaje |
| Infinite scroll | Paginación |

**Tiempo:** 10 días  

---

## Sprint 6 — Favoritos, logros, ranking (1.5 semanas)

| Tarea | Entregable |
|-------|------------|
| Screens 09-11 | Gamificación completa |
| Animaciones stat cards | |

**Tiempo:** 7 días  

---

## Sprint 7 — Módulo fundación (2 semanas)

| Tarea | Entregable |
|-------|------------|
| Screens 12-13 | Fundación completa |
| Image picker multi | max 5 fotos |
| Confirmar asistencia | Calificación estrellas |

**Tiempo:** 10 días  

---

## Sprint 8 — Notificaciones (1.5 semanas)

| Tarea | Entregable |
|-------|------------|
| Screen 18 | Lista + mark read |
| Badge polling | |
| Backend FCM | API-M03, M04 |
| firebase_messaging | Push tap → deep route |

**Tiempo:** 7 días  

---

## Sprint 9 — Admin + reportes (2 semanas, opcional v1.1)

| Tarea | Entregable |
|-------|------------|
| Screens 14-17 | Admin tablet layout |
| Screen 17.1 | Crear reporte |

**Tiempo:** 10 días  

---

## Sprint 10 — Optimización y publicación (2 semanas)

| Tarea | Entregable |
|-------|------------|
| Performance profiling | <16ms frames listas |
| Integration tests | Flujos críticos |
| Security review | OWASP mobile |
| Store assets | Screenshots, descripción |
| Play Console + App Store Connect | Builds release |

**Tiempo:** 10 días  

---

**Estimación total v1 (voluntario + fundación + notificaciones):** ~14 semanas  
**Con admin v1.1:** ~16 semanas  

---

# FASE 6 — Pruebas

---

## STEP-6.1 — Pruebas unitarias

| Capa | Herramienta | Qué probar |
|------|-------------|------------|
| UseCases | `flutter test` + mocktail | Lógica negocio pura |
| Repositories | mock DataSource | Mapeo DTO→Entity |
| Providers | riverpod test | Estados async |
| Interceptors | mock Dio | Refresh queue |

**Meta coverage:** 70% domain+data layers.

---

## STEP-6.2 — Pruebas de integración

```dart
// integration_test/auth_flow_test.dart
testWidgets('login → dashboard voluntario', (tester) async {
  await tester.pumpWidget(App());
  // mock server o ambiente QA
});
```

Flujos críticos:
1. Login → dashboard → logout
2. Browse → postular → ver en mis postulaciones
3. Fundación crear convocatoria → subir imagen → publicar

---

## STEP-6.3 — Pruebas funcionales / E2E

- **Patrol** o **integration_test** contra ambiente QA
- Matriz dispositivos: Android 12+, iOS 16+
- Tamaños: phone small, phone large, tablet (admin)

---

## STEP-6.4 — Pruebas de APIs (backend)

Existente: `tests/Feature/ApiV1Test.php` — extender con:
- Favoritos
- Dashboard voluntario
- Upload imágenes
- Revoke refresh

Contrato: **Pest + validación JSON Schema** contra OpenAPI.

---

## STEP-6.5 — Pruebas de seguridad

| Check | Método |
|-------|--------|
| Tokens no en logs | Manual + lint rule |
| Root/jailbreak detection | Opcional `flutter_jailbreak_detection` |
| SSL pinning | Opcional v1.1 |
| OWASP MASVS L1 | Checklist |

---

## STEP-6.6 — Pruebas de rendimiento

- Flutter DevTools timeline en listas 100+ items
- API: respuesta <500ms p95 en QA
- Tamaño APK/AAB < 30MB
- Imagen cache limitada

---

# FASE 7 — Despliegue

---

## STEP-7.1 — Configuración de entornos

| Ambiente | Backend | Mobile flavor | Base URL |
|----------|---------|---------------|----------|
| dev | `php artisan serve` | dev | LAN/emulator |
| qa | VPS/docker | qa | qa-api.* |
| staging | Pre-prod DB | staging | staging-api.* |
| prod | HA Laravel | prod | api.* |

### Backend checklist prod
- [ ] `APP_DEBUG=false`
- [ ] `JWT_SECRET` rotado
- [ ] PostgreSQL backups
- [ ] Queue worker systemd/supervisor
- [ ] `php artisan storage:link`
- [ ] CORS restrictivo (no `*` en prod)
- [ ] Rate limiting activo

---

## STEP-7.2 — Android

```bash
# Keystore (una vez)
keytool -genkey -v -keystore upload-keystore.jks ...

# Build
flutter build appbundle --dart-define=ENV=prod --release
```

- Play App Signing habilitado
- `minSdkVersion 21`, `targetSdkVersion` latest
- Permisos: INTERNET, POST_NOTIFICATIONS (Android 13+)
- Política privacidad URL obligatoria

---

## STEP-7.3 — iOS

```bash
flutter build ipa --dart-define=ENV=prod --release
```

- Apple Developer Program
- Provisioning profiles
- Push Notifications capability (Sprint 8)
- App Transport Security — HTTPS only prod

---

## STEP-7.4 — CI/CD recomendado

```yaml
# .github/workflows/mobile.yml
jobs:
  analyze: flutter analyze
  test: flutter test
  build-android: flutter build apk --dart-define=ENV=qa
  build-ios: flutter build ios --no-codesign (en macOS runner)
```

---

# FASE 8 — Mantenimiento

---

## STEP-8.1 — Escalabilidad

| Área | Estrategia |
|------|------------|
| API | Cache Redis catálogos (futuro) |
| Imágenes | CDN CloudFront/S3 |
| Push | FCM batch |
| App | Feature flags `remote_config` |

---

## STEP-8.2 — Monitoreo

| Herramienta | Uso |
|-------------|-----|
| Sentry Flutter | Crashes + breadcrumbs |
| Firebase Analytics | Eventos pantalla |
| Laravel Telescope (staging) | Debug API |
| Laravel Pulse (prod) | Queue, slow queries |

---

## STEP-8.3 — Logs

- **Flutter:** `logger` package; no PII en prod
- **Backend:** `LOG_LEVEL=warning` prod; request ID header `X-Request-Id`

---

## STEP-8.4 — Versionamiento app

```
MAJOR.MINOR.PATCH+BUILD
1.0.0+1 — release inicial
```

- Semantic Versioning
- Changelog `mobile/CHANGELOG.md`
- Force update si `GET /config/app` `min_version` > current (API futuro)

---

## STEP-8.5 — Buenas prácticas continuas

1. Todo cambio API → actualizar OpenAPI + DTOs Dart mismo PR
2. Feature flags para módulos incompletos
3. Backward compatibility API mínimo 2 versiones app
4. Code review obligatorio `mobile/lib/features/`
5. Retrospectiva por sprint contra esta guía

---

# Inventario completo de APIs

> Base: `/api/v1` — Bearer JWT excepto rutas públicas.

## Auth

| Método | Ruta | Auth | Rol |
|--------|------|------|-----|
| POST | `/auth/register` | — | — |
| POST | `/auth/login` | — | — |
| POST | `/auth/refresh` | — | — |
| POST | `/auth/forgot-password` | — | — |
| POST | `/auth/reset-password` | — | — |
| GET | `/auth/verify-email/{token}` | — | — |
| POST | `/auth/logout` | JWT | any |
| GET | `/auth/me` | JWT | any |

## Catálogos (público)

| GET | `/catalogos/departamentos` |
| GET | `/catalogos/municipios?departamento_id=` |
| GET | `/catalogos/habilidades` |
| GET | `/catalogos/intereses` |
| GET | `/catalogos/areas-impacto` |

## Público

| GET | `/publicaciones?buscar=&categoria_id=&modalidad=&municipio_id=&page=` |
| GET | `/publicaciones/{id}` |
| GET | `/fundaciones` |
| GET | `/fundaciones/{id}` |
| GET | `/ranking?top=N` |

## Voluntario

| GET/POST/PUT | `/voluntario` |
| GET | `/voluntario/dashboard` |
| GET | `/voluntario/puntos` |
| GET | `/voluntario/logros` |
| GET | `/voluntario/favoritos?tipo=` |
| GET | `/voluntario/favoritos/ids` |
| POST | `/voluntario/favoritos/publicacion/{id}` |
| POST | `/voluntario/favoritos/fundacion/{id}` |
| DELETE | `/voluntario/favoritos/{id}` |
| POST | `/postulaciones` |
| GET | `/mis-postulaciones?page=` |
| POST | `/postulaciones/{id}/retirar` |

## Fundación

| GET | `/mi-fundacion` |
| POST | `/fundaciones` |
| PUT | `/fundaciones/{id}` |
| POST/PUT | `/publicaciones`, `/publicaciones/{id}` |
| POST | `/publicaciones/{id}/publicar` |
| POST | `/publicaciones/{id}/cancelar` |
| POST | `/publicaciones/{id}/imagenes` (multipart) |
| DELETE | `/publicaciones/{id}/imagenes/{imgId}` |
| GET | `/mis-publicaciones?page=` |
| GET | `/publicaciones/{id}/postulaciones?page=` |
| PUT | `/postulaciones/{id}/responder` |
| POST | `/postulaciones/{id}/confirmar-asistencia` |

## Notificaciones (any auth)

| GET | `/notificaciones?page=` |
| GET | `/notificaciones/no-leidas` |
| PUT | `/notificaciones/{id}/marcar-leida` |
| POST | `/notificaciones/marcar-todas-leidas` |

## Reportes

| POST | `/reportes` |

## Admin

| GET/PUT/POST | `/admin/fundaciones/*` |
| GET/PUT | `/admin/publicaciones/*` |
| GET/PUT/POST | `/admin/voluntarios/*` |
| GET/PUT | `/admin/reportes/*` |

---

# Anexos técnicos

## Anexo A — Mapeo DTO Dart ↔ Laravel Resource

| Resource PHP | DTO Dart | Feature |
|--------------|----------|---------|
| `UsuarioResource` | `UsuarioDto` | auth |
| `VoluntarioResource` | `VoluntarioDto` | perfil |
| `FundacionResource` | `FundacionDto` | fundación |
| `PublicacionResource` | `PublicacionDto` | convocatorias |
| `PublicacionImagenResource` | `PublicacionImagenDto` | carrusel |
| `PostulacionResource` | `PostulacionDto` | postulaciones |
| `NotificacionResource` | `NotificacionDto` | notificaciones |
| `FavoritoResource` | `FavoritoDto` | favoritos |
| — | `DashboardVoluntarioDto` | dashboard (raw JSON) |
| — | `RankingDto` | ranking |
| — | `PuntosDto` | logros |
| — | `PaginatedResponse<T>` | generic wrapper |

## Anexo B — pubspec.yaml base recomendado

```yaml
name: voluntapp_mobile
description: VoluntApp — Plataforma de voluntariado Colombia
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  go_router: ^14.2.0
  dio: ^5.4.3
  flutter_secure_storage: ^9.2.2
  freezed_annotation: ^2.4.1
  json_annotation: ^4.9.0
  cached_network_image: ^3.3.1
  intl: ^0.19.0
  fpdart: ^1.1.0
  connectivity_plus: ^6.0.3
  hive_flutter: ^1.1.0
  image_picker: ^1.1.2
  firebase_core: ^3.1.0        # Sprint 8
  firebase_messaging: ^15.0.0  # Sprint 8

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  build_runner: ^2.4.9
  freezed: ^2.5.2
  json_serializable: ^6.8.0
  mocktail: ^1.0.3
  flutter_lints: ^4.0.0
```

## Anexo C — Punto de retoma para agentes

| Si el último trabajo fue… | Continuar en… |
|---------------------------|---------------|
| Nada iniciado | STEP-1.1 crear `mobile/` |
| Proyecto Flutter vacío | STEP-4.1 pubspec + core |
| Dio sin refresh | STEP-3.2 RefreshInterceptor |
| Auth screens sin registro | Screen 02 Sprint 2 |
| Voluntario sin dashboard | Screen 05A Sprint 4 |
| Convocatorias sin favoritos | Screen 07 favoritos toggle |
| Fundación sin imágenes | Screen 13 multipart |
| Sin push | Sprint 8 API-M03 |
| Listo para stores | Sprint 10 |

## Anexo D — Comandos útiles

```bash
# Backend
php artisan serve --host=0.0.0.0 --port=8000
php artisan migrate
php artisan test
php artisan route:list --path=api

# Mobile
cd mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run --dart-define=ENV=dev --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
flutter test
flutter build apk --release
```

---

## Historial de revisiones

| Versión | Fecha | Autor | Cambios |
|---------|-------|-------|---------|
| 1.0.0 | 2026-06-20 | Arquitectura | Versión inicial basada en backend 71 endpoints + frontend Vue 18 screens |

---

**Fin del documento — GUIA_MAESTRA_FLUTTER.md**

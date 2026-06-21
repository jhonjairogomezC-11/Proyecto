# Baseline Backend — VoluntApp Mobile

**Actualizado:** 2026-06-20  
**Fuente:** `routes/api.php`, auditoría Fase 0

## API

- Base: `/api/v1`
- Auth: JWT Bearer + refresh token (tabla `refresh_tokens`)
- Roles: `VOLUNTARIO`, `FUNDACION`, `ADMIN`
- Endpoints: 72 (incluye `POST /auth/revoke-refresh`)

## Cambios Sprint 1 (móvil)

| Cambio | Detalle |
|--------|---------|
| `POST /auth/logout` | Revoca refresh tokens del usuario |
| `POST /auth/revoke-refresh` | Revoca refresh tokens explícitamente |
| `?per_page=` | En publicaciones, mis-postulaciones, notificaciones (max 50) |

## Gaps pendientes

- Push FCM/APNs
- `POST /broadcasting/auth`
- Upload foto perfil / logo
- OpenAPI spec

Ver [`GUIA_MAESTRA_FLUTTER.md`](../GUIA_MAESTRA_FLUTTER.md) Fase 2.

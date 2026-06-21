# Mapeo DTO Dart ↔ Laravel Resource

| Resource PHP | DTO / Entity Dart | Feature | Sprint |
|--------------|-------------------|---------|--------|
| `UsuarioResource` | `Usuario` | auth | 1 ✅ |
| `VoluntarioResource` | `VoluntarioPerfil` | perfil | 3 ✅ |
| `FundacionResource` | `FundacionDto` | fundación | 7 |
| `PublicacionResource` | `PublicacionDto` | convocatorias | 5 |
| `PublicacionImagenResource` | `PublicacionImagenDto` | carrusel | 5 |
| `PostulacionResource` | `PostulacionDto` | postulaciones | 5 |
| `NotificacionResource` | `NotificacionDto` | notificaciones | 8 |
| `FavoritoResource` | `FavoritoDto` | favoritos | 6 |
| — (raw JSON) | `DashboardVoluntario` | dashboard | 4 ✅ |
| — | `RankingDto` | ranking | 6 |
| — | `PuntosDto` / `LogrosDto` | logros | 6 |
| — | `PaginatedResponse<T>` | core | 1 |

Ubicación planificada: `mobile/lib/features/{feature}/data/models/`

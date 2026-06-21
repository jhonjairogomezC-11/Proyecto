# Mapeo DTO Dart ↔ Laravel Resource

| Resource PHP | DTO / Entity Dart | Feature | Sprint |
|--------------|-------------------|---------|--------|
| `UsuarioResource` | `Usuario` | auth | 1 ✅ |
| `VoluntarioResource` | `VoluntarioPerfil` | perfil | 3 ✅ |
| `FundacionResource` | `FundacionPerfil` | fundación | 7 ✅ |
| `PublicacionResource` | `Publicacion` | convocatorias | 5 ✅ |
| `PublicacionImagenResource` | (nested in `Publicacion.imageUrls`) | carrusel | 5 ✅ |
| `PostulacionResource` | `Postulacion` | postulaciones | 5 ✅ |
| `NotificacionResource` | `Notificacion` | notificaciones | 8 ✅ |
| `FavoritoResource` | `Favorito` | favoritos | 6 ✅ |
| — (raw JSON) | `DashboardVoluntario` | dashboard | 4 ✅ |
| — | `RankingResponse` | ranking | 6 ✅ |
| — | `PuntosDetalle` / `LogrosDetalle` | logros | 6 ✅ |
| — | `PaginatedResponse<T>` | core | 5 ✅ |

Ubicación planificada: `mobile/lib/features/{feature}/data/models/`

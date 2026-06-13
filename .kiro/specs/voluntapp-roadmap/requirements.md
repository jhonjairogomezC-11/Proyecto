# Requirements Document — VoluntApp MVP Roadmap

## Introduction

VoluntApp es una plataforma de voluntariado que conecta voluntarios con fundaciones en el
departamento de Cundinamarca (Colombia). El sistema cuenta con una base funcional: autenticación
con Sanctum, CRUD de voluntarios, fundaciones, publicaciones (convocatorias), postulaciones y
notificaciones, y un panel de administración básico.

Este documento define los requisitos funcionales y de calidad para el **roadmap completo del MVP**,
organizado en 5 sprints. Cada sprint agrupa mejoras relacionadas que llevan el sistema desde su
estado inicial hasta un producto completamente operativo con gamificación y tiempo real.

---

## Glossary

- **Sistema**: la aplicación VoluntApp (backend Laravel 12 + frontend Vue 3).
- **Auth_Service**: componente responsable de autenticación y emisión/validación de tokens JWT.
- **JWT**: JSON Web Token; mecanismo de autenticación sin estado que reemplaza Sanctum tokens.
- **Refresh_Token**: token de larga duración utilizado para renovar el Access Token sin reautenticar.
- **Role_Middleware**: middleware de Laravel que verifica el rol del usuario (ADMIN, FUNDACION, VOLUNTARIO).
- **Postulacion_Service**: servicio de dominio que gestiona el ciclo de vida de las postulaciones.
- **Publicacion**: convocatoria de voluntariado creada por una fundación.
- **Timezone_Service**: componente que convierte marcas de tiempo UTC (base de datos) a America/Bogota.
- **Catalogo_Service**: componente que gestiona listas maestras de departamentos y municipios.
- **Fundacion**: organización registrada que publica convocatorias de voluntariado.
- **Voluntario**: usuario registrado que se postula a convocatorias.
- **Admin**: usuario con rol ADMIN que gestiona la plataforma.
- **Documento_Service**: componente que gestiona la carga y validación de documentos de fundaciones.
- **Aprobacion_Service**: componente que gestiona el flujo de aprobación de fundaciones.
- **Sancion_Service**: componente que gestiona advertencias y sanciones sobre usuarios.
- **Punto_Service**: componente que calcula y asigna puntos por participación en convocatorias.
- **Ranking_Service**: componente que calcula y expone rankings de voluntarios.
- **Logro_Service**: componente que evalúa y otorga logros a voluntarios.
- **Evento_Bus**: bus de eventos en tiempo real basado en WebSockets (Laravel Broadcasting + Pusher/Soketi/Reverb).
- **Notificacion_Service**: componente que envía y gestiona notificaciones en tiempo real.
- **Email_Service**: componente de envío de correo electrónico (pendiente integración con proveedor externo).
- **Estado_Postulacion**: enumeración con valores PENDIENTE, ACEPTADO, RECHAZADO, RETIRADO, ASISTIO, NO_ASISTIO.
- **Estado_Fundacion**: enumeración con valores PENDIENTE, APROBADA, RECHAZADA, SUSPENDIDA.
- **Estado_Voluntario**: enumeración con valores ACTIVO, SUSPENDIDO, BLOQUEADO.
- **Cundinamarca**: departamento colombiano que define la cobertura geográfica permitida.
- **Municipio_Permitido**: municipio perteneciente al departamento de Cundinamarca (incluye Bogotá D.C.).
- **Dificultad_Convocatoria**: enumeración con valores FACIL (10 pts), MEDIA (25 pts), DIFICIL (50 pts), MUY_DIFICIL (100 pts).

---

## Requirements

---

## SPRINT 1 — Seguridad y Correcciones Críticas

---

### Requirement 1: Migración a JWT

**User Story:** Como desarrollador, quiero reemplazar Sanctum tokens por JWT con refresh token,
para que la autenticación sea sin estado, escalable y con control de roles en cada petición.

#### Acceptance Criteria

1. WHEN el usuario envía credenciales válidas en `POST /api/v1/auth/login`, THE Auth_Service SHALL emitir un Access Token JWT firmado con expiración de 60 minutos y un Refresh Token con expiración de 7 días.
2. WHEN el usuario envía un Refresh Token válido en `POST /api/v1/auth/refresh`, THE Auth_Service SHALL emitir un nuevo Access Token JWT y un nuevo Refresh Token, invalidando el Refresh Token anterior.
3. IF el Access Token enviado en el header `Authorization: Bearer` está expirado o es inválido, THEN THE Auth_Service SHALL responder con HTTP 401 y un mensaje de error descriptivo.
4. IF el Refresh Token enviado está expirado, revocado o es inválido, THEN THE Auth_Service SHALL responder con HTTP 401 y un mensaje de error descriptivo.
5. WHEN el usuario realiza `POST /api/v1/auth/logout`, THE Auth_Service SHALL revocar el Refresh Token activo del usuario y responder con HTTP 200.
6. WHILE una petición protegida incluye un Access Token JWT válido, THE Role_Middleware SHALL leer el claim `rol` del token y verificar que el usuario tenga el rol requerido por la ruta.
7. IF el claim `rol` del token no coincide con el rol exigido por la ruta, THEN THE Role_Middleware SHALL responder con HTTP 403 y el mensaje "No tienes permisos para esta acción."
8. THE Auth_Service SHALL almacenar los Refresh Tokens activos en la tabla `refresh_tokens` con columnas: `id`, `usuario_id`, `token_hash`, `expires_at`, `revoked_at`, `created_at`.
9. THE Auth_Service SHALL exponer `GET /api/v1/auth/me` que, dado un Access Token JWT válido, retorne el perfil del usuario autenticado incluyendo su rol.
10. WHEN se registra un nuevo usuario en `POST /api/v1/auth/register`, THE Auth_Service SHALL emitir un par de tokens JWT (Access + Refresh) junto con la respuesta de registro.

---

### Requirement 2: Corrección del Flujo de Postulación y Cancelación

**User Story:** Como voluntario, quiero poder cancelar mi postulación, que el cupo quede libre
y poder postularme de nuevo, para que el sistema refleje siempre el estado real de mis
participaciones.

#### Acceptance Criteria

1. THE Postulacion_Service SHALL soportar los estados: POSTULADO, CANCELADO, ACEPTADO, RECHAZADO, ASISTIO, NO_ASISTIO para cada postulación.
2. WHEN un voluntario cancela una postulación en estado POSTULADO o ACEPTADO mediante `POST /api/v1/postulaciones/{id}/cancelar`, THE Postulacion_Service SHALL cambiar el estado a CANCELADO.
3. WHEN el estado de una postulación cambia a CANCELADO y la publicación estaba en estado CERRADA por cupo lleno, THE Postulacion_Service SHALL cambiar el estado de la publicación a PUBLICADA y decrementar el contador de cupos ocupados.
4. WHEN una postulación es CANCELADA, THE Postulacion_Service SHALL permitir al mismo voluntario crear una nueva postulación para la misma publicación.
5. WHEN la vista de postulaciones del voluntario solicita datos, THE Sistema SHALL retornar el estado actualizado de cada postulación sin requerir recarga de página (respuesta JSON sincrónica inmediata).
6. IF un voluntario intenta cancelar una postulación en estado ASISTIO o NO_ASISTIO, THEN THE Postulacion_Service SHALL responder con HTTP 422 y el mensaje "No puedes cancelar una postulación ya confirmada."
7. WHEN la fundación responde una postulación con estado ACEPTADO, THE Postulacion_Service SHALL registrar la fecha de respuesta y disminuir los cupos disponibles de la publicación en 1.
8. WHEN la fundación rechaza una postulación, THE Postulacion_Service SHALL requerir un campo `motivo_rechazo` no vacío y registrarlo en la postulación.

---

### Requirement 3: Hora Real del Sistema con Zona Horaria Colombia

**User Story:** Como usuario, quiero ver todas las fechas y horas en hora colombiana (UTC-5),
para interpretar correctamente los eventos de voluntariado.

#### Acceptance Criteria

1. THE Sistema SHALL almacenar todas las marcas de tiempo en la base de datos en formato UTC.
2. WHEN el Sistema retorna cualquier campo de tipo fecha-hora en una respuesta JSON, THE Timezone_Service SHALL convertir el valor UTC a la zona horaria `America/Bogota` antes de serializar.
3. THE Timezone_Service SHALL formatear las fechas en las respuestas JSON con el formato ISO 8601: `YYYY-MM-DDTHH:mm:ss-05:00`.
4. IF el código fuente contiene fechas o horas hardcodeadas que no usen las funciones de tiempo del framework, THEN THE Sistema SHALL reemplazarlas por llamadas a `now()` o `Carbon::now('America/Bogota')`.
5. WHEN se crea o actualiza un registro con campos de fecha-hora desde el frontend, THE Sistema SHALL aceptar valores en hora Colombia y convertirlos a UTC antes de persistir.
6. THE Sistema SHALL configurar `APP_TIMEZONE=UTC` en el entorno y aplicar la conversión de presentación exclusivamente en la capa de serialización (Resources/Transformers).

---

### Requirement 4: Cobertura Geográfica Limitada a Cundinamarca

**User Story:** Como administrador, quiero que el sistema solo ofrezca municipios de Cundinamarca,
para enfocar el MVP en el área de operación real del proyecto.

#### Acceptance Criteria

1. THE Catalogo_Service SHALL retornar únicamente municipios del departamento de Cundinamarca (incluyendo Bogotá D.C.) en el endpoint `GET /api/v1/catalogos/municipios`.
2. THE Catalogo_Service SHALL incluir los siguientes Municipios_Permitidos: Bogotá, Soacha, Chía, Cajicá, Zipaquirá, Facatativá, Funza, Mosquera, Madrid, Fusagasugá, Girardot y los demás municipios de Cundinamarca registrados en la tabla `municipios`.
3. IF una solicitud de creación o actualización de publicación incluye un `municipio_id` que no pertenece a Cundinamarca, THEN THE Sistema SHALL responder con HTTP 422 y el mensaje "El municipio seleccionado no está disponible en la cobertura actual."
4. IF una solicitud de creación o actualización de perfil de voluntario incluye un `municipio_id` que no pertenece a Cundinamarca, THEN THE Sistema SHALL responder con HTTP 422 y el mensaje "El municipio seleccionado no está disponible en la cobertura actual."
5. THE Catalogo_Service SHALL eliminar del seeder y de la base de datos los departamentos Antioquia, Valle del Cauca, Atlántico, Santander y sus municipios asociados que no sean de Cundinamarca.
6. WHEN el frontend solicita la lista de departamentos, THE Catalogo_Service SHALL retornar únicamente "Bogotá D.C." y "Cundinamarca" como opciones seleccionables.

---

## SPRINT 2 — Administración Completa

---

### Requirement 5: Flujo de Aprobación de Fundaciones

**User Story:** Como administrador, quiero revisar los documentos de una fundación y aprobar o
rechazar su registro, para garantizar que solo organizaciones legítimas operen en la plataforma.

#### Acceptance Criteria

1. WHEN una fundación se registra en el sistema, THE Aprobacion_Service SHALL asignarle el estado PENDIENTE y crear una tarea de revisión en la cola administrativa.
2. THE Documento_Service SHALL requerir los siguientes documentos obligatorios durante el registro: Cámara de Comercio, documento de identidad del representante legal y certificados de operación.
3. IF una fundación intenta publicar una convocatoria y su estado no es ACTIVA, THEN THE Sistema SHALL responder con HTTP 403 y el mensaje "Tu fundación debe estar aprobada para publicar convocatorias."
4. WHEN el administrador aprueba una fundación mediante `PUT /api/v1/admin/fundaciones/{id}/aprobar`, THE Aprobacion_Service SHALL cambiar el estado a ACTIVA y enviar una notificación al usuario representante.
5. WHEN el administrador rechaza una fundación mediante `PUT /api/v1/admin/fundaciones/{id}/rechazar`, THE Aprobacion_Service SHALL cambiar el estado a RECHAZADA, registrar el motivo del rechazo y enviar una notificación al usuario representante.
6. WHEN el administrador rechaza una fundación, THE Aprobacion_Service SHALL requerir un campo `motivo` no vacío con al menos 20 caracteres.
7. THE Documento_Service SHALL almacenar cada documento con: `id`, `fundacion_id`, `tipo_documento`, `ruta_archivo`, `nombre_original`, `fecha_subida`, `validado`.
8. WHEN el administrador consulta `GET /api/v1/admin/fundaciones/{id}/documentos`, THE Documento_Service SHALL retornar la lista de documentos de la fundación incluyendo URLs de descarga firmadas con vigencia de 60 minutos.

---

### Requirement 6: Gestión Administrativa de Fundaciones

**User Story:** Como administrador, quiero poder suspender, bloquear, reactivar fundaciones y
ver su historial completo, para mantener la calidad y seguridad de la plataforma.

#### Acceptance Criteria

1. THE Sistema SHALL soportar los siguientes estados para fundaciones: PENDIENTE, ACTIVA, SUSPENDIDA, BLOQUEADA, RECHAZADA.
2. WHEN el administrador suspende una fundación mediante `PUT /api/v1/admin/fundaciones/{id}/suspender`, THE Aprobacion_Service SHALL cambiar el estado a SUSPENDIDA, registrar el motivo y la fecha, y enviar una notificación al representante.
3. WHEN el administrador bloquea una fundación mediante `PUT /api/v1/admin/fundaciones/{id}/bloquear`, THE Aprobacion_Service SHALL cambiar el estado a BLOQUEADA, registrar el motivo y la fecha, y enviar una notificación al representante.
4. WHEN el administrador reactiva una fundación mediante `PUT /api/v1/admin/fundaciones/{id}/reactivar`, THE Aprobacion_Service SHALL cambiar el estado de SUSPENDIDA o BLOQUEADA a ACTIVA y enviar una notificación al representante.
5. WHILE una fundación está en estado SUSPENDIDA o BLOQUEADA, THE Sistema SHALL rechazar con HTTP 403 cualquier acción de publicación o gestión de postulaciones de esa fundación.
6. WHEN el administrador consulta `GET /api/v1/admin/fundaciones/{id}/historial`, THE Aprobacion_Service SHALL retornar el historial cronológico de cambios de estado con: estado anterior, estado nuevo, motivo, usuario administrador responsable y fecha.
7. THE Aprobacion_Service SHALL registrar cada cambio de estado de una fundación en la tabla `historial_estados_fundacion` con: `id`, `fundacion_id`, `estado_anterior`, `estado_nuevo`, `motivo`, `admin_id`, `fecha`.
8. WHEN el administrador consulta `GET /api/v1/admin/fundaciones`, THE Sistema SHALL retornar la lista de fundaciones con filtros por estado, nombre y fecha de registro, paginada en grupos de 20 registros.

---

### Requirement 7: Gestión Administrativa de Voluntarios

**User Story:** Como administrador, quiero poder ver el perfil completo de un voluntario,
suspenderlo, bloquearlo, reactivarlo y registrar advertencias, para garantizar una comunidad
segura de voluntarios.

#### Acceptance Criteria

1. THE Sistema SHALL soportar los siguientes estados para voluntarios: ACTIVO, SUSPENDIDO, BLOQUEADO.
2. WHEN el administrador consulta `GET /api/v1/admin/voluntarios/{id}`, THE Sistema SHALL retornar el perfil completo del voluntario incluyendo: datos personales, habilidades, intereses, historial de participaciones, sanciones activas y calificación promedio.
3. WHEN el administrador suspende un voluntario mediante `PUT /api/v1/admin/voluntarios/{id}/suspender`, THE Sancion_Service SHALL cambiar el estado a SUSPENDIDO, registrar el motivo y la duración en días, y enviar una notificación al voluntario.
4. WHEN el administrador bloquea un voluntario mediante `PUT /api/v1/admin/voluntarios/{id}/bloquear`, THE Sancion_Service SHALL cambiar el estado a BLOQUEADO, registrar el motivo y enviar una notificación al voluntario.
5. WHEN el administrador reactiva un voluntario mediante `PUT /api/v1/admin/voluntarios/{id}/reactivar`, THE Sancion_Service SHALL cambiar el estado de SUSPENDIDO o BLOQUEADO a ACTIVO y enviar una notificación al voluntario.
6. WHEN el administrador emite una advertencia mediante `POST /api/v1/admin/voluntarios/{id}/advertencias`, THE Sancion_Service SHALL registrar la advertencia con: motivo, fecha, admin responsable, y retornar el conteo total de advertencias activas del voluntario.
7. WHILE un voluntario está en estado SUSPENDIDO o BLOQUEADO, THE Sistema SHALL rechazar con HTTP 403 cualquier acción de postulación de ese voluntario.
8. WHEN el administrador consulta `GET /api/v1/admin/voluntarios/{id}/historial`, THE Sancion_Service SHALL retornar el historial cronológico de participaciones y sanciones del voluntario ordenado por fecha descendente.
9. WHEN el administrador consulta `GET /api/v1/admin/voluntarios`, THE Sistema SHALL retornar la lista de voluntarios con filtros por estado, nombre, municipio y rango de fechas, paginada en grupos de 20 registros.

---

## SPRINT 3 — Gamificación

---

### Requirement 8: Sistema de Puntos por Convocatoria

**User Story:** Como voluntario, quiero ganar puntos al participar en convocatorias según su
dificultad, urgencia y distancia, para ver reconocido mi esfuerzo de manera diferenciada.

#### Acceptance Criteria

1. THE Punto_Service SHALL asignar puntos base por participación según la dificultad de la convocatoria: FACIL = 10 puntos, MEDIA = 25 puntos, DIFICIL = 50 puntos, MUY_DIFICIL = 100 puntos.
2. WHEN una publicación tiene el campo `urgente = true`, THE Punto_Service SHALL aplicar un multiplicador de 1.5 sobre los puntos base al calcular los puntos de la convocatoria.
3. WHEN quedan 5 o menos cupos disponibles en una publicación activa, THE Punto_Service SHALL aplicar un multiplicador de 1.25 sobre los puntos base para esa convocatoria.
4. WHEN el administrador o la fundación asigna una distancia estimada de más de 30 km desde Bogotá a la ubicación de la convocatoria, THE Punto_Service SHALL aplicar un bono fijo de 15 puntos adicionales.
5. WHEN el estado de una postulación cambia a ASISTIO, THE Punto_Service SHALL calcular los puntos totales de esa participación aplicando todos los modificadores activos y acreditarlos al saldo de puntos del voluntario.
6. IF el estado de una postulación cambia a NO_ASISTIO después de haber sido ACEPTADO, THEN THE Punto_Service SHALL no acreditar puntos y registrar la inasistencia en el historial del voluntario.
7. THE Punto_Service SHALL mantener un registro histórico de cada transacción de puntos en la tabla `transacciones_puntos` con: `id`, `voluntario_id`, `postulacion_id`, `puntos_base`, `puntos_bonus`, `puntos_total`, `motivo`, `fecha`.
8. WHEN el voluntario consulta `GET /api/v1/voluntario/puntos`, THE Punto_Service SHALL retornar: saldo actual de puntos, total histórico acumulado y las últimas 10 transacciones.

---

### Requirement 9: Ranking de Voluntarios

**User Story:** Como voluntario, quiero ver un ranking de los mejores voluntarios por municipio
y por Cundinamarca en general, para motivarme a participar más.

#### Acceptance Criteria

1. THE Ranking_Service SHALL calcular y exponer rankings de voluntarios en `GET /api/v1/rankings` con los siguientes scopes: municipio específico (Bogotá, Soacha, Chía), y Cundinamarca general.
2. THE Ranking_Service SHALL ordenar cada ranking por puntos acumulados en orden descendente como criterio primario y por número de participaciones confirmadas como criterio de desempate.
3. THE Ranking_Service SHALL retornar para cada entrada del ranking: posición, nombre del voluntario, municipio, puntos acumulados, número de participaciones y horas de voluntariado.
4. THE Ranking_Service SHALL exponer las siguientes vistas de ranking: Top 10, Top 50 y General (todos los voluntarios con al menos 1 participación confirmada).
5. WHEN el Ranking_Service calcula los rankings, THE Sistema SHALL actualizar los datos del ranking al menos cada 30 minutos mediante un job programado o al registrarse una nueva transacción de puntos.
6. WHEN el voluntario consulta `GET /api/v1/rankings/mi-posicion`, THE Ranking_Service SHALL retornar la posición actual del voluntario en el ranking de su municipio y en el ranking general de Cundinamarca.
7. IF un voluntario no tiene ninguna participación confirmada, THEN THE Ranking_Service SHALL excluirlo de todos los rankings públicos.

---

### Requirement 10: Sistema de Logros

**User Story:** Como voluntario, quiero desbloquear logros a medida que acumulo participaciones
y puntos, para sentirme reconocido y motivado a continuar.

#### Acceptance Criteria

1. THE Logro_Service SHALL definir los siguientes logros por número de convocatorias completadas: "Primer Paso" (1 convocatoria), "Comprometido" (10 convocatorias), "Voluntario Activo" (25 convocatorias), "Impacto Social" (50 convocatorias), "Leyenda Solidaria" (100 convocatorias).
2. WHEN el estado de una postulación cambia a ASISTIO y el conteo de participaciones del voluntario alcanza el umbral de un logro, THE Logro_Service SHALL desbloquear automáticamente el logro correspondiente y registrar la fecha de obtención.
3. THE Logro_Service SHALL definir el logro "Mayor Puntaje Mensual" otorgado al voluntario con más puntos acumulados en el mes calendario en curso.
4. THE Logro_Service SHALL definir el logro "Mayor Puntaje Anual" otorgado al voluntario con más puntos acumulados en el año calendario en curso.
5. THE Logro_Service SHALL calcular y actualizar los logros "Mayor Puntaje Mensual" y "Mayor Puntaje Anual" diariamente mediante un job programado a las 00:05 AM hora Colombia.
6. WHEN el voluntario consulta `GET /api/v1/voluntario/logros`, THE Logro_Service SHALL retornar: lista de logros obtenidos con fecha de obtención, y lista de logros pendientes con el progreso actual (ej.: 7/10 participaciones para "Comprometido").
7. THE Logro_Service SHALL registrar cada logro obtenido en la tabla `voluntario_logros` con: `id`, `voluntario_id`, `logro_id`, `fecha_obtencion`.
8. IF un voluntario ya obtuvo un logro de conteo de participaciones y su estado cambia a BLOQUEADO, THEN THE Logro_Service SHALL conservar los logros ya obtenidos sin revocarlos.

---

## SPRINT 4 — Tiempo Real

---

### Requirement 11: WebSockets para Eventos en Tiempo Real

**User Story:** Como fundación, quiero ver instantáneamente cuando un voluntario se postula o
cancela, para gestionar cupos y responder sin necesidad de recargar la página.

#### Acceptance Criteria

1. THE Evento_Bus SHALL implementar comunicación en tiempo real mediante Laravel Broadcasting con un driver compatible (Pusher, Soketi o Laravel Reverb).
2. WHEN un voluntario crea una nueva postulación, THE Evento_Bus SHALL emitir el evento `PostulacionCreada` al canal privado `fundacion.{fundacion_id}` con los datos de la postulación y el voluntario.
3. WHEN un voluntario cancela una postulación, THE Evento_Bus SHALL emitir el evento `PostulacionCancelada` al canal privado `fundacion.{fundacion_id}` con el id de la postulación y el cupo actualizado de la publicación.
4. WHEN la fundación acepta o rechaza una postulación, THE Evento_Bus SHALL emitir el evento `PostulacionRespondida` al canal privado `voluntario.{voluntario_id}` con el nuevo estado y el motivo (si aplica).
5. WHEN se publica una nueva convocatoria, THE Evento_Bus SHALL emitir el evento `NuevaPublicacion` al canal público `convocatorias` con los datos básicos de la publicación.
6. THE frontend Vue 3 SHALL suscribirse a los canales privados del usuario autenticado al iniciar sesión y desuscribirse al cerrar sesión.
7. WHEN el Evento_Bus emite un evento, THE Sistema SHALL actualizar el estado local en el store de Pinia sin requerir una nueva llamada HTTP al backend.
8. IF la conexión WebSocket se interrumpe, THEN THE frontend SHALL intentar reconectarse automáticamente con backoff exponencial con intervalos de 1s, 2s, 4s, 8s hasta un máximo de 60s.

---

### Requirement 12: Notificaciones en Tiempo Real

**User Story:** Como voluntario y como fundación, quiero recibir notificaciones inmediatas
sobre los eventos que me afectan, para actuar rápidamente sin depender de la recarga manual.

#### Acceptance Criteria

1. THE Notificacion_Service SHALL enviar una notificación en tiempo real al voluntario cuando su postulación es aceptada, con el mensaje: "{nombre_fundacion} aceptó tu postulación para '{titulo_convocatoria}'."
2. THE Notificacion_Service SHALL enviar una notificación en tiempo real al voluntario cuando su postulación es rechazada, con el mensaje: "{nombre_fundacion} rechazó tu postulación para '{titulo_convocatoria}'."
3. THE Notificacion_Service SHALL enviar una notificación en tiempo real al voluntario cuando se publique una nueva convocatoria en su municipio de residencia.
4. THE Notificacion_Service SHALL enviar una notificación en tiempo real a la fundación cuando un voluntario se postule a una de sus convocatorias, con el mensaje: "{nombre_voluntario} se postuló a '{titulo_convocatoria}'."
5. THE Notificacion_Service SHALL enviar una notificación en tiempo real a la fundación cuando un voluntario cancele una postulación, con el mensaje: "{nombre_voluntario} canceló su postulación de '{titulo_convocatoria}'."
6. WHEN una convocatoria tiene 24 horas o menos para su fecha de inicio, THE Notificacion_Service SHALL enviar una notificación a la fundación propietaria con el mensaje: "La convocatoria '{titulo}' inicia en menos de 24 horas."
7. THE Notificacion_Service SHALL persistir cada notificación en la tabla `notificaciones` antes de emitirla por WebSocket, garantizando que las notificaciones sean recuperables aunque el usuario no esté conectado.
8. WHEN el usuario consulta `GET /api/v1/notificaciones/no-leidas`, THE Notificacion_Service SHALL retornar el conteo y la lista de notificaciones no leídas ordenadas por fecha descendente.
9. THE frontend SHALL mostrar un indicador visual (badge) con el conteo de notificaciones no leídas en la barra de navegación, actualizado en tiempo real mediante WebSocket.

---

## SPRINT 5 — Funcionalidades Futuras

---

### Requirement 13: Recuperación de Contraseña por Email

**User Story:** Como usuario, quiero recuperar mi contraseña mediante un enlace enviado a mi
correo electrónico, para acceder a mi cuenta en caso de olvidar mi contraseña.

#### Acceptance Criteria

1. WHEN el usuario envía su email en `POST /api/v1/auth/forgot-password`, THE Email_Service SHALL generar un token de recuperación de un solo uso con vigencia de 1 hora y enviarlo por correo al usuario si el email existe en el sistema.
2. IF el email proporcionado no existe en el sistema, THEN THE Auth_Service SHALL responder con HTTP 200 y el mensaje "Si tu email está registrado, recibirás instrucciones para recuperar tu contraseña." sin revelar si el email existe.
3. WHEN el usuario envía el token de recuperación y la nueva contraseña en `POST /api/v1/auth/reset-password`, THE Auth_Service SHALL validar el token, actualizar la contraseña con hash bcrypt y revocar el token.
4. IF el token de recuperación está expirado o ya fue usado, THEN THE Auth_Service SHALL responder con HTTP 422 y el mensaje "El enlace de recuperación es inválido o ha expirado."
5. THE Auth_Service SHALL almacenar los tokens de recuperación en la tabla `password_reset_tokens` con: `email`, `token_hash`, `created_at`, `used_at`.
6. THE Auth_Service SHALL invalidar todos los Refresh Tokens activos del usuario cuando se completa un restablecimiento de contraseña exitoso.
7. WHERE el servicio de correo externo (Resend, SendGrid o AWS SES) no está configurado, THE Email_Service SHALL registrar el email en el log del sistema con nivel INFO en lugar de fallar, para facilitar el desarrollo sin bloquear otras funcionalidades.
8. THE Email_Service SHALL soportar los proveedores Resend, SendGrid y AWS SES mediante la configuración de la variable de entorno `MAIL_MAILER` sin requerir cambios en el código de la aplicación.

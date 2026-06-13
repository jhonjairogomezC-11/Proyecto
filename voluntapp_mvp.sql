-- =============================================================
-- VOLUNTAPP / SIGCV — SCRIPT ÚNICO MVP
-- Versión: MVP 1.0
-- PostgreSQL 14+
--
-- CONTENIDO (lo esencial para el MVP):
--   1. Infraestructura base (extensiones, función auditoría)
--   2. Autenticación: usuarios, sesiones, verificación email
--   3. Recuperación de contraseña
--   4. Geografía: departamentos y municipios (Colombia)
--   5. Perfil del voluntario + catálogos
--   6. Fundaciones + áreas de impacto
--   7. Publicaciones (convocatorias)
--   8. Postulaciones (ciclo de vida completo)
--   9. Notificaciones (automáticas por trigger)
--  10. Panel admin (perfil, auditoría, reportes, funciones)
--  11. Configuración del sistema
--  12. Datos iniciales (catálogos, admin inicial)
--
-- EXCLUIDO DEL MVP (v2):
--   · Gamificación (puntos, niveles, logros)
--   · Ranking periódico
--   · Favoritos
--   · Historial de estados
--   · Búsqueda full-text (FTS / GIN)
--   · Mensajería interna en postulaciones
--   · Notas internas de fundación sobre voluntario
--   · Jobs de limpieza periódica
--
-- Ejecutar completo en una sola transacción:
--   psql -d tu_base -f voluntapp_mvp.sql
-- =============================================================

BEGIN;

-- =============================================================
-- SECCIÓN 1: INFRAESTRUCTURA BASE
-- =============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Función compartida de auditoría: actualiza fecha_actualizacion
-- en cualquier tabla que la tenga, en cada UPDATE.
CREATE OR REPLACE FUNCTION fn_actualizar_fecha_actualizacion()
RETURNS TRIGGER AS $$
BEGIN
    NEW.fecha_actualizacion = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- =============================================================
-- SECCIÓN 2: AUTENTICACIÓN
-- =============================================================

-- Rol del usuario en el sistema
DO $$ BEGIN
    CREATE TYPE rol_usuario AS ENUM ('VOLUNTARIO', 'FUNDACION', 'ADMIN');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- Estado operativo de la cuenta
DO $$ BEGIN
    CREATE TYPE estado_usuario AS ENUM ('ACTIVO', 'BLOQUEADO', 'SUSPENDIDO');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- Proveedor de autenticación
DO $$ BEGIN
    CREATE TYPE proveedor_auth AS ENUM ('LOCAL', 'GOOGLE');
EXCEPTION WHEN duplicate_object THEN null; END $$;


-- ── TABLA: USUARIOS ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS usuarios (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre              VARCHAR(120) NOT NULL,
    email               VARCHAR(150) NOT NULL,
    password_hash       TEXT,                       -- Solo LOCAL
    provider            proveedor_auth NOT NULL DEFAULT 'LOCAL',
    provider_id         VARCHAR(255),               -- Solo GOOGLE
    telefono            VARCHAR(20),
    rol                 rol_usuario NOT NULL,
    estado              estado_usuario NOT NULL DEFAULT 'ACTIVO',
    email_verificado    BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_registro      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE TRIGGER trg_usuarios_fecha_actualizacion
BEFORE UPDATE ON usuarios
FOR EACH ROW EXECUTE FUNCTION fn_actualizar_fecha_actualizacion();

-- LOCAL debe tener password_hash; GOOGLE debe tener provider_id
DO $$ BEGIN
    ALTER TABLE usuarios ADD CONSTRAINT chk_auth_valid
    CHECK (
        (provider = 'LOCAL'  AND password_hash IS NOT NULL) OR
        (provider = 'GOOGLE' AND provider_id   IS NOT NULL)
    );
EXCEPTION WHEN duplicate_object THEN null; END $$;

CREATE INDEX IF NOT EXISTS idx_usuario_email    ON usuarios(email);
CREATE INDEX IF NOT EXISTS idx_usuario_provider ON usuarios(provider);

-- El mismo email puede existir en LOCAL y GOOGLE como cuentas distintas
CREATE UNIQUE INDEX IF NOT EXISTS idx_email_provider_unique
    ON usuarios(email, provider);

CREATE UNIQUE INDEX IF NOT EXISTS idx_provider_id_unique
    ON usuarios(provider, provider_id)
    WHERE provider_id IS NOT NULL;


-- ── TABLA: VERIFICACIÓN DE EMAIL ──────────────────────────────
CREATE TABLE IF NOT EXISTS verificacion_email (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id     UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    token          TEXT NOT NULL,
    expiracion     TIMESTAMP NOT NULL DEFAULT (CURRENT_TIMESTAMP + INTERVAL '1 day'),
    usado          BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_token_verificacion_unique
    ON verificacion_email(token);
CREATE INDEX IF NOT EXISTS idx_verificacion_usuario
    ON verificacion_email(usuario_id);
CREATE INDEX IF NOT EXISTS idx_verificacion_expiracion
    ON verificacion_email(expiracion);


-- ── TABLA: SESIONES ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS sesiones (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id       UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    token            TEXT NOT NULL,
    fecha_creacion   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_expiracion TIMESTAMP,
    ip               VARCHAR(50),
    user_agent       TEXT
);

CREATE INDEX IF NOT EXISTS idx_sesion_usuario ON sesiones(usuario_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_sesion_token ON sesiones(token);
CREATE INDEX IF NOT EXISTS idx_sesion_expiracion
    ON sesiones(fecha_expiracion)
    WHERE fecha_expiracion IS NOT NULL;


-- =============================================================
-- SECCIÓN 3: RECUPERACIÓN DE CONTRASEÑA
-- =============================================================

CREATE TABLE IF NOT EXISTS recuperacion_password (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id      UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    token           TEXT NOT NULL,
    expiracion      TIMESTAMP NOT NULL DEFAULT (CURRENT_TIMESTAMP + INTERVAL '1 hour'),
    usado           BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_uso       TIMESTAMP,
    ip_solicitud    VARCHAR(50),
    user_agent      TEXT,
    fecha_creacion  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_reset_token_unique
    ON recuperacion_password(token);
CREATE INDEX IF NOT EXISTS idx_reset_usuario
    ON recuperacion_password(usuario_id);
CREATE INDEX IF NOT EXISTS idx_reset_expiracion
    ON recuperacion_password(expiracion)
    WHERE usado = FALSE;


-- Solicita un token de reset; invalida el anterior si existía.
-- Devuelve el token para que el backend lo envíe por email.
CREATE OR REPLACE FUNCTION fn_solicitar_reset_password(
    p_usuario_id UUID,
    p_ip         VARCHAR(50) DEFAULT NULL,
    p_user_agent TEXT        DEFAULT NULL
)
RETURNS TEXT AS $$
DECLARE
    v_provider  proveedor_auth;
    v_estado    estado_usuario;
    v_token     TEXT;
BEGIN
    SELECT provider, estado INTO v_provider, v_estado
    FROM usuarios WHERE id = p_usuario_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Usuario % no encontrado.', p_usuario_id;
    END IF;
    IF v_provider != 'LOCAL' THEN
        RAISE EXCEPTION 'El usuario usa %. La recuperación de contraseña no aplica.', v_provider;
    END IF;
    IF v_estado = 'BLOQUEADO' THEN
        RAISE EXCEPTION 'Cuenta bloqueada. Contacta al soporte.';
    END IF;

    -- Invalida tokens anteriores sin usar
    UPDATE recuperacion_password
    SET usado = TRUE, fecha_uso = CURRENT_TIMESTAMP
    WHERE usuario_id = p_usuario_id AND usado = FALSE;

    v_token := gen_random_uuid()::TEXT || '-' || gen_random_uuid()::TEXT;

    INSERT INTO recuperacion_password (usuario_id, token, ip_solicitud, user_agent)
    VALUES (p_usuario_id, v_token, p_ip, p_user_agent);

    RETURN v_token;
END;
$$ LANGUAGE plpgsql;


-- Aplica el nuevo hash de contraseña si el token es válido.
-- Devuelve TRUE si se aplicó, FALSE si el token es inválido o expirado.
CREATE OR REPLACE FUNCTION fn_aplicar_reset_password(
    p_token      TEXT,
    p_nuevo_hash TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    v_usuario_id UUID;
BEGIN
    IF p_nuevo_hash IS NULL OR TRIM(p_nuevo_hash) = '' THEN
        RAISE EXCEPTION 'El hash de la nueva contraseña no puede estar vacío.';
    END IF;

    SELECT usuario_id INTO v_usuario_id
    FROM recuperacion_password
    WHERE token = p_token AND usado = FALSE AND expiracion > CURRENT_TIMESTAMP
    FOR UPDATE;

    IF v_usuario_id IS NULL THEN RETURN FALSE; END IF;

    UPDATE usuarios SET password_hash = p_nuevo_hash WHERE id = v_usuario_id;

    UPDATE recuperacion_password
    SET usado = TRUE, fecha_uso = CURRENT_TIMESTAMP
    WHERE token = p_token;

    -- Cierra todas las sesiones del usuario por seguridad
    DELETE FROM sesiones WHERE usuario_id = v_usuario_id;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;


-- =============================================================
-- SECCIÓN 4: GEOGRAFÍA — DEPARTAMENTOS Y MUNICIPIOS
-- =============================================================

CREATE TABLE IF NOT EXISTS departamentos (
    id     SERIAL PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS municipios (
    id              SERIAL PRIMARY KEY,
    nombre          VARCHAR(100) NOT NULL,
    departamento_id INT NOT NULL REFERENCES departamentos(id) ON DELETE RESTRICT,
    UNIQUE (nombre, departamento_id)
);

CREATE INDEX IF NOT EXISTS idx_municipio_departamento
    ON municipios(departamento_id);


-- Departamentos incluidos en el MVP
INSERT INTO departamentos (nombre) VALUES
    ('Antioquia'), ('Bogotá D.C.'), ('Boyacá'), ('Caldas'),
    ('Cundinamarca'), ('Quindío'), ('Risaralda'), ('Tolima'),
    ('Valle del Cauca'), ('Atlántico'), ('Bolívar'), ('Santander'),
    ('Nariño'), ('Córdoba'), ('Meta'), ('Huila')
ON CONFLICT DO NOTHING;

-- Bogotá
INSERT INTO municipios (nombre, departamento_id)
SELECT 'Bogotá', id FROM departamentos WHERE nombre = 'Bogotá D.C.'
ON CONFLICT DO NOTHING;

-- Antioquia
INSERT INTO municipios (nombre, departamento_id)
SELECT m.nombre, d.id FROM (VALUES
    ('Medellín'),('Bello'),('Itagüí'),('Envigado'),('Rionegro'),
    ('Sabaneta'),('Apartadó'),('Turbo')
) AS m(nombre) CROSS JOIN departamentos d WHERE d.nombre = 'Antioquia'
ON CONFLICT DO NOTHING;

-- Valle del Cauca
INSERT INTO municipios (nombre, departamento_id)
SELECT m.nombre, d.id FROM (VALUES
    ('Cali'),('Buenaventura'),('Palmira'),('Tuluá'),('Buga')
) AS m(nombre) CROSS JOIN departamentos d WHERE d.nombre = 'Valle del Cauca'
ON CONFLICT DO NOTHING;

-- Atlántico
INSERT INTO municipios (nombre, departamento_id)
SELECT m.nombre, d.id FROM (VALUES
    ('Barranquilla'),('Soledad'),('Malambo'),('Sabanagrande')
) AS m(nombre) CROSS JOIN departamentos d WHERE d.nombre = 'Atlántico'
ON CONFLICT DO NOTHING;

-- Bolívar
INSERT INTO municipios (nombre, departamento_id)
SELECT m.nombre, d.id FROM (VALUES
    ('Cartagena'),('Magangué'),('Mompós')
) AS m(nombre) CROSS JOIN departamentos d WHERE d.nombre = 'Bolívar'
ON CONFLICT DO NOTHING;

-- Santander
INSERT INTO municipios (nombre, departamento_id)
SELECT m.nombre, d.id FROM (VALUES
    ('Bucaramanga'),('Floridablanca'),('Girón'),('Piedecuesta')
) AS m(nombre) CROSS JOIN departamentos d WHERE d.nombre = 'Santander'
ON CONFLICT DO NOTHING;

-- Boyacá
INSERT INTO municipios (nombre, departamento_id)
SELECT m.nombre, d.id FROM (VALUES
    ('Tunja'),('Duitama'),('Sogamoso'),('Chiquinquirá')
) AS m(nombre) CROSS JOIN departamentos d WHERE d.nombre = 'Boyacá'
ON CONFLICT DO NOTHING;

-- Caldas
INSERT INTO municipios (nombre, departamento_id)
SELECT m.nombre, d.id FROM (VALUES
    ('Manizales'),('La Dorada'),('Villamaría'),('Chinchiná')
) AS m(nombre) CROSS JOIN departamentos d WHERE d.nombre = 'Caldas'
ON CONFLICT DO NOTHING;

-- Cundinamarca
INSERT INTO municipios (nombre, departamento_id)
SELECT m.nombre, d.id FROM (VALUES
    ('Soacha'),('Facatativá'),('Zipaquirá'),('Chía'),('Fusagasugá'),
    ('Girardot'),('Mosquera'),('Madrid'),('Cajicá'),('Funza')
) AS m(nombre) CROSS JOIN departamentos d WHERE d.nombre = 'Cundinamarca'
ON CONFLICT DO NOTHING;

-- Quindío
INSERT INTO municipios (nombre, departamento_id)
SELECT m.nombre, d.id FROM (VALUES
    ('Armenia'),('Calarcá'),('Montenegro'),('La Tebaida')
) AS m(nombre) CROSS JOIN departamentos d WHERE d.nombre = 'Quindío'
ON CONFLICT DO NOTHING;

-- Risaralda
INSERT INTO municipios (nombre, departamento_id)
SELECT m.nombre, d.id FROM (VALUES
    ('Pereira'),('Dosquebradas'),('Santa Rosa de Cabal')
) AS m(nombre) CROSS JOIN departamentos d WHERE d.nombre = 'Risaralda'
ON CONFLICT DO NOTHING;

-- Tolima
INSERT INTO municipios (nombre, departamento_id)
SELECT m.nombre, d.id FROM (VALUES
    ('Ibagué'),('Espinal'),('Melgar'),('Honda')
) AS m(nombre) CROSS JOIN departamentos d WHERE d.nombre = 'Tolima'
ON CONFLICT DO NOTHING;

-- Meta
INSERT INTO municipios (nombre, departamento_id)
SELECT m.nombre, d.id FROM (VALUES
    ('Villavicencio'),('Acacías'),('Granada')
) AS m(nombre) CROSS JOIN departamentos d WHERE d.nombre = 'Meta'
ON CONFLICT DO NOTHING;

-- Huila
INSERT INTO municipios (nombre, departamento_id)
SELECT m.nombre, d.id FROM (VALUES
    ('Neiva'),('Pitalito'),('Garzón')
) AS m(nombre) CROSS JOIN departamentos d WHERE d.nombre = 'Huila'
ON CONFLICT DO NOTHING;

-- Nariño
INSERT INTO municipios (nombre, departamento_id)
SELECT m.nombre, d.id FROM (VALUES
    ('Pasto'),('Tumaco'),('Ipiales')
) AS m(nombre) CROSS JOIN departamentos d WHERE d.nombre = 'Nariño'
ON CONFLICT DO NOTHING;

-- Córdoba
INSERT INTO municipios (nombre, departamento_id)
SELECT m.nombre, d.id FROM (VALUES
    ('Montería'),('Lorica'),('Cereté')
) AS m(nombre) CROSS JOIN departamentos d WHERE d.nombre = 'Córdoba'
ON CONFLICT DO NOTHING;


-- =============================================================
-- SECCIÓN 5: PERFIL DEL VOLUNTARIO
-- =============================================================

DO $$ BEGIN
    CREATE TYPE tipo_documento AS ENUM ('CC', 'TI', 'CE', 'PASAPORTE');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE genero_tipo AS ENUM ('MASCULINO', 'FEMENINO', 'OTRO');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE disponibilidad_tipo AS ENUM ('ENTRE_SEMANA', 'FINES_DE_SEMANA', 'FLEXIBLE');
EXCEPTION WHEN duplicate_object THEN null; END $$;


-- ── TABLA: VOLUNTARIOS ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS voluntarios (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id       UUID UNIQUE NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    tipo_documento   tipo_documento NOT NULL,
    numero_documento VARCHAR(30) UNIQUE NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    genero           genero_tipo NOT NULL,
    municipio_id     INT NOT NULL REFERENCES municipios(id) ON DELETE RESTRICT,
    disponibilidad   disponibilidad_tipo NOT NULL,
    experiencia      TEXT,
    foto_perfil      VARCHAR(500),               -- Nullable: registro progresivo
    fecha_creacion      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE TRIGGER trg_voluntarios_fecha_actualizacion
BEFORE UPDATE ON voluntarios
FOR EACH ROW EXECUTE FUNCTION fn_actualizar_fecha_actualizacion();

-- Voluntario debe tener al menos 14 años
DO $$ BEGIN
    ALTER TABLE voluntarios ADD CONSTRAINT chk_edad_minima
    CHECK (fecha_nacimiento <= (CURRENT_DATE - INTERVAL '14 years'));
EXCEPTION WHEN duplicate_object THEN null; END $$;

CREATE INDEX IF NOT EXISTS idx_voluntario_usuario   ON voluntarios(usuario_id);
CREATE INDEX IF NOT EXISTS idx_voluntario_municipio ON voluntarios(municipio_id);


-- ── CATÁLOGOS: HABILIDADES E INTERESES ────────────────────────
CREATE TABLE IF NOT EXISTS habilidades (
    id     SERIAL PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS intereses (
    id     SERIAL PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL
);

-- Relaciones N:M voluntario ↔ habilidades/intereses
CREATE TABLE IF NOT EXISTS voluntario_habilidades (
    voluntario_id UUID REFERENCES voluntarios(id) ON DELETE CASCADE,
    habilidad_id  INT  REFERENCES habilidades(id) ON DELETE CASCADE,
    PRIMARY KEY (voluntario_id, habilidad_id)
);

CREATE TABLE IF NOT EXISTS voluntario_intereses (
    voluntario_id UUID REFERENCES voluntarios(id) ON DELETE CASCADE,
    interes_id    INT  REFERENCES intereses(id) ON DELETE CASCADE,
    PRIMARY KEY (voluntario_id, interes_id)
);

CREATE INDEX IF NOT EXISTS idx_vol_hab ON voluntario_habilidades(voluntario_id);
CREATE INDEX IF NOT EXISTS idx_vol_int ON voluntario_intereses(voluntario_id);

INSERT INTO habilidades (nombre) VALUES
    ('Educación'),('Tecnología'),('Salud'),('Medio Ambiente'),
    ('Arte'),('Deportes'),('Comunicación'),('Liderazgo'),
    ('Idiomas'),('Cocina')
ON CONFLICT DO NOTHING;

INSERT INTO intereses (nombre) VALUES
    ('Social'),('Ambiental'),('Educativo'),('Cultural'),
    ('Comunitario'),('Salud'),('Derechos Humanos'),('Infancia')
ON CONFLICT DO NOTHING;


-- =============================================================
-- SECCIÓN 6: FUNDACIONES
-- =============================================================

DO $$ BEGIN
    CREATE TYPE estado_verificacion AS ENUM ('PENDIENTE', 'APROBADA', 'RECHAZADA', 'SUSPENDIDA');
EXCEPTION WHEN duplicate_object THEN null; END $$;


-- ── CATÁLOGO: ÁREAS DE IMPACTO ────────────────────────────────
-- Compartido con publicaciones como categoría temática
CREATE TABLE IF NOT EXISTS areas_impacto (
    id     SERIAL PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL
);

INSERT INTO areas_impacto (nombre) VALUES
    ('Educacion'),('Salud'),('Medio Ambiente'),('Derechos Humanos'),
    ('Infancia'),('Adulto Mayor'),('Discapacidad'),('Cultura'),
    ('Deportes'),('Tecnologia'),('Inclusion Social')
ON CONFLICT DO NOTHING;


-- ── TABLA: FUNDACIONES ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS fundaciones (
    id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id            UUID UNIQUE NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    nombre                VARCHAR(150) NOT NULL,
    -- NIT colombiano: 7-10 dígitos + guion + 1 dígito verificador
    nit                   VARCHAR(20) UNIQUE NOT NULL,
    representante_legal   VARCHAR(150) NOT NULL,
    -- Correo institucional opcional al registrarse; requerido para ser APROBADA
    correo_institucional  VARCHAR(150),
    telefono              VARCHAR(20) NOT NULL,
    direccion             VARCHAR(200) NOT NULL,
    municipio_id          INT NOT NULL REFERENCES municipios(id) ON DELETE RESTRICT,
    pagina_web            VARCHAR(255),
    descripcion           TEXT NOT NULL,
    -- Ruta o URL al documento legal (personería jurídica, RUT, etc.)
    documento_legal       TEXT NOT NULL,
    logo                  VARCHAR(500),
    estado_verificacion   estado_verificacion NOT NULL DEFAULT 'PENDIENTE',
    fecha_verificacion    TIMESTAMP,
    motivo_rechazo        TEXT,
    fecha_creacion        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE TRIGGER trg_fundaciones_fecha_actualizacion
BEFORE UPDATE ON fundaciones
FOR EACH ROW EXECUTE FUNCTION fn_actualizar_fecha_actualizacion();

-- NIT con formato colombiano válido
DO $$ BEGIN
    ALTER TABLE fundaciones ADD CONSTRAINT chk_nit_formato
    CHECK (nit ~ '^\d{7,10}-\d$');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- Una fundación APROBADA debe tener correo institucional
DO $$ BEGIN
    ALTER TABLE fundaciones ADD CONSTRAINT chk_correo_si_aprobada
    CHECK (estado_verificacion != 'APROBADA' OR correo_institucional IS NOT NULL);
EXCEPTION WHEN duplicate_object THEN null; END $$;

CREATE INDEX IF NOT EXISTS idx_fundacion_usuario   ON fundaciones(usuario_id);
CREATE INDEX IF NOT EXISTS idx_fundacion_nit        ON fundaciones(nit);
CREATE INDEX IF NOT EXISTS idx_fundacion_municipio  ON fundaciones(municipio_id);
CREATE INDEX IF NOT EXISTS idx_fundacion_estado     ON fundaciones(estado_verificacion);
CREATE INDEX IF NOT EXISTS idx_fundacion_fecha_verificacion
    ON fundaciones(fecha_verificacion) WHERE fecha_verificacion IS NOT NULL;

-- Unicidad de correo institucional (solo cuando existe)
CREATE UNIQUE INDEX IF NOT EXISTS idx_fundacion_correo_unique
    ON fundaciones(correo_institucional)
    WHERE correo_institucional IS NOT NULL;


-- ── RELACIÓN N:M: FUNDACIÓN ↔ ÁREAS DE IMPACTO ───────────────
CREATE TABLE IF NOT EXISTS fundacion_areas (
    fundacion_id UUID REFERENCES fundaciones(id) ON DELETE CASCADE,
    area_id      INT  REFERENCES areas_impacto(id) ON DELETE CASCADE,
    PRIMARY KEY (fundacion_id, area_id)
);

CREATE INDEX IF NOT EXISTS idx_fundacion_areas ON fundacion_areas(fundacion_id);


-- =============================================================
-- SECCIÓN 7: PUBLICACIONES (CONVOCATORIAS)
-- =============================================================

DO $$ BEGIN
    CREATE TYPE modalidad_tipo AS ENUM ('PRESENCIAL', 'VIRTUAL', 'HIBRIDA');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- Ciclo de vida de una convocatoria:
--   BORRADOR → guardada pero invisible para voluntarios
--   PUBLICADA → visible y abierta a postulaciones
--   CERRADA → cupo lleno o fecha vencida
--   CANCELADA → cancelada por la fundación
--   COMPLETADA → la actividad se realizó exitosamente
--   FINALIZADA → cierre administrativo definitivo
DO $$ BEGIN
    CREATE TYPE estado_publicacion AS ENUM (
        'BORRADOR','PUBLICADA','CERRADA','CANCELADA','COMPLETADA','FINALIZADA'
    );
EXCEPTION WHEN duplicate_object THEN null; END $$;


-- ── TABLA: PUBLICACIONES ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS publicaciones (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    fundacion_id        UUID NOT NULL REFERENCES fundaciones(id) ON DELETE CASCADE,
    titulo              VARCHAR(200) NOT NULL,
    descripcion         TEXT NOT NULL,
    categoria_id        INT NOT NULL REFERENCES areas_impacto(id) ON DELETE RESTRICT,
    modalidad           modalidad_tipo NOT NULL,
    -- municipio_id obligatorio para PRESENCIAL e HIBRIDA
    municipio_id        INT REFERENCES municipios(id) ON DELETE RESTRICT,
    direccion_exacta    VARCHAR(200),
    -- TEXT para URLs largas de videollamada (Meet/Zoom con tokens)
    enlace_virtual      TEXT,
    fecha_inicio        DATE NOT NULL,
    fecha_fin           DATE NOT NULL,
    hora_inicio         TIME,
    hora_fin            TIME,
    cupo_maximo         INT NOT NULL DEFAULT 1,
    edad_minima         INT,
    edad_maxima         INT,
    requisitos_adicionales TEXT,
    imagen              VARCHAR(500),
    contacto_nombre     VARCHAR(150),
    contacto_email      VARCHAR(150),
    contacto_telefono   VARCHAR(20),
    estado              estado_publicacion NOT NULL DEFAULT 'BORRADOR',
    -- Campo para moderación: el admin puede ocultar sin eliminar
    oculta_por_admin    BOOLEAN NOT NULL DEFAULT FALSE,
    motivo_ocultamiento TEXT,
    fecha_ocultamiento  TIMESTAMP,
    fecha_publicacion   TIMESTAMP,   -- Se registra automáticamente al publicar
    fecha_creacion      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE TRIGGER trg_publicaciones_fecha_actualizacion
BEFORE UPDATE ON publicaciones
FOR EACH ROW EXECUTE FUNCTION fn_actualizar_fecha_actualizacion();

-- Registra el momento en que la publicación se hace visible por primera vez
CREATE OR REPLACE FUNCTION fn_registrar_fecha_publicacion()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.estado = 'PUBLICADA' AND OLD.estado != 'PUBLICADA' THEN
        NEW.fecha_publicacion = CURRENT_TIMESTAMP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_publicaciones_fecha_publicacion
BEFORE UPDATE ON publicaciones
FOR EACH ROW EXECUTE FUNCTION fn_registrar_fecha_publicacion();

-- Solo fundaciones APROBADAS pueden crear publicaciones
CREATE OR REPLACE FUNCTION fn_validar_fundacion_aprobada_publicacion()
RETURNS TRIGGER AS $$
DECLARE v_estado estado_verificacion;
BEGIN
    SELECT estado_verificacion INTO v_estado
    FROM fundaciones WHERE id = NEW.fundacion_id;
    IF v_estado != 'APROBADA' THEN
        RAISE EXCEPTION 'Solo fundaciones APROBADAS pueden crear publicaciones. Estado actual: %.', v_estado;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_validar_fundacion_aprobada
BEFORE INSERT ON publicaciones
FOR EACH ROW EXECUTE FUNCTION fn_validar_fundacion_aprobada_publicacion();

-- Constraints de validación
DO $$ BEGIN
    ALTER TABLE publicaciones ADD CONSTRAINT chk_fechas_validas
    CHECK (fecha_fin >= fecha_inicio);
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    ALTER TABLE publicaciones ADD CONSTRAINT chk_cupo_valido
    CHECK (cupo_maximo >= 1);
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    ALTER TABLE publicaciones ADD CONSTRAINT chk_edades_validas
    CHECK (edad_minima IS NULL OR edad_maxima IS NULL OR edad_maxima >= edad_minima);
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- Actividades presenciales e híbridas requieren municipio
DO $$ BEGIN
    ALTER TABLE publicaciones ADD CONSTRAINT chk_ubicacion_presencial
    CHECK (
        modalidad = 'VIRTUAL' OR
        (modalidad IN ('PRESENCIAL', 'HIBRIDA') AND municipio_id IS NOT NULL)
    );
EXCEPTION WHEN duplicate_object THEN null; END $$;

CREATE INDEX IF NOT EXISTS idx_pub_fundacion   ON publicaciones(fundacion_id);
CREATE INDEX IF NOT EXISTS idx_pub_estado       ON publicaciones(estado);
CREATE INDEX IF NOT EXISTS idx_pub_categoria    ON publicaciones(categoria_id);
CREATE INDEX IF NOT EXISTS idx_pub_municipio    ON publicaciones(municipio_id);
CREATE INDEX IF NOT EXISTS idx_pub_fecha_inicio ON publicaciones(fecha_inicio);
CREATE INDEX IF NOT EXISTS idx_pub_modalidad    ON publicaciones(modalidad);
-- Índice compuesto para el listado principal del frontend
CREATE INDEX IF NOT EXISTS idx_pub_estado_fecha ON publicaciones(estado, fecha_inicio);


-- ── RELACIÓN N:M: PUBLICACIÓN ↔ HABILIDADES REQUERIDAS ───────
CREATE TABLE IF NOT EXISTS publicacion_habilidades (
    publicacion_id UUID REFERENCES publicaciones(id) ON DELETE CASCADE,
    habilidad_id   INT  REFERENCES habilidades(id)   ON DELETE CASCADE,
    PRIMARY KEY (publicacion_id, habilidad_id)
);

CREATE INDEX IF NOT EXISTS idx_pub_habilidades ON publicacion_habilidades(publicacion_id);


-- =============================================================
-- SECCIÓN 8: POSTULACIONES
-- =============================================================

-- Flujo de estados:
--   PENDIENTE → ACEPTADO  → ASISTIO
--                         → NO_ASISTIO
--             → RECHAZADO
--   PENDIENTE → RETIRADO (voluntario cancela)
DO $$ BEGIN
    CREATE TYPE estado_postulacion AS ENUM (
        'PENDIENTE','ACEPTADO','RECHAZADO','RETIRADO','ASISTIO','NO_ASISTIO'
    );
EXCEPTION WHEN duplicate_object THEN null; END $$;


-- ── TABLA: POSTULACIONES ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS postulaciones (
    id                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    publicacion_id       UUID NOT NULL REFERENCES publicaciones(id) ON DELETE CASCADE,
    voluntario_id        UUID NOT NULL REFERENCES voluntarios(id)   ON DELETE CASCADE,
    estado               estado_postulacion NOT NULL DEFAULT 'PENDIENTE',
    mensaje_voluntario   TEXT,
    motivo_rechazo       TEXT,
    fecha_respuesta      TIMESTAMP,        -- Cuándo la fundación aceptó o rechazó
    fecha_confirmacion   TIMESTAMP,        -- Cuándo se marcó ASISTIO o NO_ASISTIO
    -- Calificación de la fundación al voluntario (solo si ASISTIO)
    calificacion         SMALLINT,         -- Escala 1-5
    comentario_fundacion TEXT,
    fecha_postulacion    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- Un voluntario no puede postularse dos veces a la misma convocatoria
    UNIQUE (publicacion_id, voluntario_id)
);

CREATE OR REPLACE TRIGGER trg_postulaciones_fecha_actualizacion
BEFORE UPDATE ON postulaciones
FOR EACH ROW EXECUTE FUNCTION fn_actualizar_fecha_actualizacion();

-- Registra cuándo la fundación tomó su decisión
CREATE OR REPLACE FUNCTION fn_registrar_fecha_respuesta()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.estado IN ('ACEPTADO', 'RECHAZADO') AND OLD.estado = 'PENDIENTE' THEN
        NEW.fecha_respuesta = CURRENT_TIMESTAMP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_postulaciones_fecha_respuesta
BEFORE UPDATE ON postulaciones
FOR EACH ROW EXECUTE FUNCTION fn_registrar_fecha_respuesta();

-- Registra cuándo se confirmó o negó la asistencia
CREATE OR REPLACE FUNCTION fn_registrar_fecha_confirmacion()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.estado IN ('ASISTIO', 'NO_ASISTIO') AND
       OLD.estado NOT IN ('ASISTIO', 'NO_ASISTIO') THEN
        NEW.fecha_confirmacion = CURRENT_TIMESTAMP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_postulaciones_fecha_confirmacion
BEFORE UPDATE ON postulaciones
FOR EACH ROW EXECUTE FUNCTION fn_registrar_fecha_confirmacion();

-- Cierra la publicación automáticamente cuando el cupo se llena.
-- FOR UPDATE serializa aceptaciones concurrentes para evitar condición de carrera.
CREATE OR REPLACE FUNCTION fn_verificar_cupo()
RETURNS TRIGGER AS $$
DECLARE
    v_cupo_maximo   INT;
    v_cupos_tomados INT;
BEGIN
    IF NEW.estado = 'ACEPTADO' AND OLD.estado != 'ACEPTADO' THEN
        SELECT cupo_maximo INTO v_cupo_maximo
        FROM publicaciones WHERE id = NEW.publicacion_id
        FOR UPDATE;

        SELECT COUNT(*) INTO v_cupos_tomados
        FROM postulaciones
        WHERE publicacion_id = NEW.publicacion_id AND estado = 'ACEPTADO';

        IF v_cupos_tomados >= v_cupo_maximo THEN
            UPDATE publicaciones SET estado = 'CERRADA' WHERE id = NEW.publicacion_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_cupo_publicacion
AFTER UPDATE ON postulaciones
FOR EACH ROW EXECUTE FUNCTION fn_verificar_cupo();

-- Un voluntario solo puede postularse a publicaciones PUBLICADAS o CERRADAS
CREATE OR REPLACE FUNCTION fn_validar_postulacion_publicacion()
RETURNS TRIGGER AS $$
DECLARE v_estado estado_publicacion;
BEGIN
    SELECT estado INTO v_estado FROM publicaciones WHERE id = NEW.publicacion_id;
    IF v_estado NOT IN ('PUBLICADA', 'CERRADA') THEN
        RAISE EXCEPTION
            'No se puede postular a una publicación en estado %. Solo PUBLICADAS son válidas.', v_estado;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_validar_postulacion_publicacion
BEFORE INSERT ON postulaciones
FOR EACH ROW EXECUTE FUNCTION fn_validar_postulacion_publicacion();

-- Constraints de validación
DO $$ BEGIN
    ALTER TABLE postulaciones ADD CONSTRAINT chk_calificacion_valida
    CHECK (calificacion IS NULL OR calificacion BETWEEN 1 AND 5);
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    ALTER TABLE postulaciones ADD CONSTRAINT chk_calificacion_solo_si_asistio
    CHECK (calificacion IS NULL OR estado = 'ASISTIO');
EXCEPTION WHEN duplicate_object THEN null; END $$;

CREATE INDEX IF NOT EXISTS idx_post_publicacion        ON postulaciones(publicacion_id);
CREATE INDEX IF NOT EXISTS idx_post_voluntario         ON postulaciones(voluntario_id);
CREATE INDEX IF NOT EXISTS idx_post_estado             ON postulaciones(estado);
CREATE INDEX IF NOT EXISTS idx_post_voluntario_estado  ON postulaciones(voluntario_id, estado);
CREATE INDEX IF NOT EXISTS idx_post_publicacion_estado ON postulaciones(publicacion_id, estado);


-- =============================================================
-- SECCIÓN 9: NOTIFICACIONES
-- =============================================================

-- Identifica qué evento generó la notificación.
-- El frontend usa este campo para elegir ícono y texto.
DO $$ BEGIN
    CREATE TYPE tipo_notificacion AS ENUM (
        -- Hacia la fundación
        'NUEVA_POSTULACION',
        'POSTULACION_RETIRADA',
        'VOLUNTARIO_ASISTIO',
        'VOLUNTARIO_NO_ASISTIO',
        -- Hacia el voluntario
        'POSTULACION_ACEPTADA',
        'POSTULACION_RECHAZADA',
        'ACTIVIDAD_CANCELADA',
        'ACTIVIDAD_MODIFICADA',
        -- Admin → fundación
        'FUNDACION_APROBADA',
        'FUNDACION_RECHAZADA',
        'FUNDACION_SUSPENDIDA',
        'FUNDACION_REACTIVADA',
        -- Sistema
        'RECORDATORIO_ACTIVIDAD'
    );
EXCEPTION WHEN duplicate_object THEN null; END $$;


-- ── TABLA: NOTIFICACIONES ─────────────────────────────────────
-- Una fila por notificación por destinatario.
-- objeto_tipo + objeto_id permiten que el frontend construya
-- el enlace de navegación sin hardcodear lógica de rutas.
CREATE TABLE IF NOT EXISTS notificaciones (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id      UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    tipo            tipo_notificacion NOT NULL,
    mensaje         TEXT NOT NULL,
    objeto_tipo     VARCHAR(30),    -- 'POSTULACION' | 'PUBLICACION' | 'FUNDACION'
    objeto_id       UUID,
    leida           BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_lectura   TIMESTAMP,
    fecha_creacion  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_notif_usuario
    ON notificaciones(usuario_id, leida, fecha_creacion DESC);

-- Marcar una notificación como leída (verifica que pertenece al usuario)
CREATE OR REPLACE FUNCTION fn_marcar_notificacion_leida(
    p_notificacion UUID,
    p_usuario      UUID
)
RETURNS BOOLEAN AS $$
DECLARE v_afectadas INT;
BEGIN
    UPDATE notificaciones
    SET leida = TRUE, fecha_lectura = CURRENT_TIMESTAMP
    WHERE id = p_notificacion AND usuario_id = p_usuario AND leida = FALSE;
    GET DIAGNOSTICS v_afectadas = ROW_COUNT;
    RETURN v_afectadas > 0;
END;
$$ LANGUAGE plpgsql;

-- Marcar todas las notificaciones de un usuario como leídas
CREATE OR REPLACE FUNCTION fn_marcar_todas_notificaciones_leidas(p_usuario UUID)
RETURNS INT AS $$
DECLARE v_afectadas INT;
BEGIN
    UPDATE notificaciones
    SET leida = TRUE, fecha_lectura = CURRENT_TIMESTAMP
    WHERE usuario_id = p_usuario AND leida = FALSE;
    GET DIAGNOSTICS v_afectadas = ROW_COUNT;
    RETURN v_afectadas;
END;
$$ LANGUAGE plpgsql;


-- ── TRIGGER: NOTIFICACIONES AUTOMÁTICAS POR CAMBIO DE POSTULACIÓN
-- Cubre las transiciones de estado más relevantes para ambas partes.
CREATE OR REPLACE FUNCTION fn_notificar_cambio_postulacion()
RETURNS TRIGGER AS $$
DECLARE
    v_nombre_voluntario  VARCHAR(120);
    v_nombre_fundacion   VARCHAR(150);
    v_titulo_actividad   VARCHAR(200);
    v_usuario_fundacion  UUID;
    v_usuario_voluntario UUID;
BEGIN
    -- Obtener datos necesarios para el mensaje
    SELECT u.nombre, u.id, vol.id
    INTO   v_nombre_voluntario, v_usuario_voluntario, v_usuario_voluntario
    FROM   voluntarios vol
    JOIN   usuarios u ON u.id = vol.usuario_id
    WHERE  vol.id = NEW.voluntario_id;

    -- Corregir: obtener usuario_voluntario correctamente
    SELECT u.id INTO v_usuario_voluntario
    FROM   voluntarios vol
    JOIN   usuarios u ON u.id = vol.usuario_id
    WHERE  vol.id = NEW.voluntario_id;

    SELECT u.nombre INTO v_nombre_voluntario
    FROM   voluntarios vol
    JOIN   usuarios u ON u.id = vol.usuario_id
    WHERE  vol.id = NEW.voluntario_id;

    SELECT f.nombre, f.usuario_id, pub.titulo
    INTO   v_nombre_fundacion, v_usuario_fundacion, v_titulo_actividad
    FROM   publicaciones pub
    JOIN   fundaciones f ON f.id = pub.fundacion_id
    WHERE  pub.id = NEW.publicacion_id;

    -- PENDIENTE → ACEPTADO: notificar al voluntario
    IF NEW.estado = 'ACEPTADO' AND OLD.estado = 'PENDIENTE' THEN
        INSERT INTO notificaciones (usuario_id, tipo, mensaje, objeto_tipo, objeto_id)
        VALUES (
            v_usuario_voluntario, 'POSTULACION_ACEPTADA',
            v_nombre_fundacion || ' aceptó tu postulación para "' || v_titulo_actividad || '".',
            'POSTULACION', NEW.id
        );

    -- PENDIENTE → RECHAZADO: notificar al voluntario
    ELSIF NEW.estado = 'RECHAZADO' AND OLD.estado = 'PENDIENTE' THEN
        INSERT INTO notificaciones (usuario_id, tipo, mensaje, objeto_tipo, objeto_id)
        VALUES (
            v_usuario_voluntario, 'POSTULACION_RECHAZADA',
            v_nombre_fundacion || ' rechazó tu postulación para "' || v_titulo_actividad || '".',
            'POSTULACION', NEW.id
        );

    -- * → RETIRADO: notificar a la fundación
    ELSIF NEW.estado = 'RETIRADO' AND OLD.estado != 'RETIRADO' THEN
        INSERT INTO notificaciones (usuario_id, tipo, mensaje, objeto_tipo, objeto_id)
        VALUES (
            v_usuario_fundacion, 'POSTULACION_RETIRADA',
            v_nombre_voluntario || ' retiró su postulación de "' || v_titulo_actividad || '".',
            'POSTULACION', NEW.id
        );

    -- ACEPTADO → ASISTIO: notificar a la fundación
    ELSIF NEW.estado = 'ASISTIO' AND OLD.estado = 'ACEPTADO' THEN
        INSERT INTO notificaciones (usuario_id, tipo, mensaje, objeto_tipo, objeto_id)
        VALUES (
            v_usuario_fundacion, 'VOLUNTARIO_ASISTIO',
            v_nombre_voluntario || ' confirmó asistencia a "' || v_titulo_actividad || '".',
            'POSTULACION', NEW.id
        );

    -- ACEPTADO → NO_ASISTIO: notificar a la fundación
    ELSIF NEW.estado = 'NO_ASISTIO' AND OLD.estado = 'ACEPTADO' THEN
        INSERT INTO notificaciones (usuario_id, tipo, mensaje, objeto_tipo, objeto_id)
        VALUES (
            v_usuario_fundacion, 'VOLUNTARIO_NO_ASISTIO',
            v_nombre_voluntario || ' no asistió a "' || v_titulo_actividad || '".',
            'POSTULACION', NEW.id
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_notificaciones_postulacion
AFTER UPDATE ON postulaciones
FOR EACH ROW EXECUTE FUNCTION fn_notificar_cambio_postulacion();


-- Notificación al insertar una nueva postulación (notifica a la fundación)
CREATE OR REPLACE FUNCTION fn_notificar_nueva_postulacion()
RETURNS TRIGGER AS $$
DECLARE
    v_nombre_voluntario VARCHAR(120);
    v_titulo_actividad  VARCHAR(200);
    v_usuario_fundacion UUID;
BEGIN
    SELECT u.nombre INTO v_nombre_voluntario
    FROM voluntarios vol JOIN usuarios u ON u.id = vol.usuario_id
    WHERE vol.id = NEW.voluntario_id;

    SELECT pub.titulo, f.usuario_id
    INTO   v_titulo_actividad, v_usuario_fundacion
    FROM   publicaciones pub JOIN fundaciones f ON f.id = pub.fundacion_id
    WHERE  pub.id = NEW.publicacion_id;

    INSERT INTO notificaciones (usuario_id, tipo, mensaje, objeto_tipo, objeto_id)
    VALUES (
        v_usuario_fundacion, 'NUEVA_POSTULACION',
        v_nombre_voluntario || ' se postuló a tu actividad "' || v_titulo_actividad || '".',
        'POSTULACION', NEW.id
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_notificacion_nueva_postulacion
AFTER INSERT ON postulaciones
FOR EACH ROW EXECUTE FUNCTION fn_notificar_nueva_postulacion();


-- =============================================================
-- SECCIÓN 10: PANEL ADMINISTRADOR
-- =============================================================

-- Nivel del administrador
DO $$ BEGIN
    CREATE TYPE nivel_admin AS ENUM ('SUPER', 'OPERATIVO');
EXCEPTION WHEN duplicate_object THEN null; END $$;


-- ── TABLA: ADMIN_PERFILES ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS admin_perfiles (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id          UUID UNIQUE NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    nivel               nivel_admin NOT NULL DEFAULT 'OPERATIVO',
    -- Permisos granulares por módulo (solo aplica para nivel OPERATIVO)
    permisos            JSONB,
    creado_por          UUID REFERENCES admin_perfiles(id) ON DELETE SET NULL,
    activo              BOOLEAN NOT NULL DEFAULT TRUE,
    cargo               VARCHAR(100),
    notas_internas      TEXT,
    fecha_creacion      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE TRIGGER trg_admin_perfiles_fecha_actualizacion
BEFORE UPDATE ON admin_perfiles
FOR EACH ROW EXECUTE FUNCTION fn_actualizar_fecha_actualizacion();

-- Solo usuarios con rol ADMIN pueden tener perfil de administrador
CREATE OR REPLACE FUNCTION fn_validar_rol_admin()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT rol FROM usuarios WHERE id = NEW.usuario_id) != 'ADMIN' THEN
        RAISE EXCEPTION 'El usuario % no tiene rol ADMIN.', NEW.usuario_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_validar_rol_admin
BEFORE INSERT OR UPDATE ON admin_perfiles
FOR EACH ROW EXECUTE FUNCTION fn_validar_rol_admin();

CREATE INDEX IF NOT EXISTS idx_admin_usuario ON admin_perfiles(usuario_id);
CREATE INDEX IF NOT EXISTS idx_admin_activo   ON admin_perfiles(activo) WHERE activo = TRUE;
CREATE INDEX IF NOT EXISTS idx_admin_nivel    ON admin_perfiles(nivel);


-- ── ENUM Y TABLA: LOG DE ACCIONES ADMIN ──────────────────────
DO $$ BEGIN
    CREATE TYPE tipo_accion_admin AS ENUM (
        'USUARIO_SUSPENDIDO', 'USUARIO_BLOQUEADO', 'USUARIO_REACTIVADO',
        'USUARIO_ELIMINADO',  'USUARIO_EDITADO',
        'FUNDACION_APROBADA', 'FUNDACION_RECHAZADA',
        'FUNDACION_SUSPENDIDA','FUNDACION_REACTIVADA',
        'PUBLICACION_OCULTADA','PUBLICACION_RESTAURADA',
        'PUBLICACION_ELIMINADA','PUBLICACION_ESTADO_CAMBIADO',
        'POSTULACION_INTERVENIDA',
        'REPORTE_RESUELTO',   'REPORTE_DESESTIMADO',
        'PUNTOS_AJUSTADOS',   'LOGRO_ASIGNADO',
        'ADMIN_CREADO',       'ADMIN_DESACTIVADO',
        'ADMIN_PERMISOS_ACTUALIZADOS'
    );
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- Log inmutable de acciones administrativas (sin UPDATE ni DELETE)
CREATE TABLE IF NOT EXISTS admin_acciones (
    id                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_id           UUID NOT NULL REFERENCES admin_perfiles(id) ON DELETE RESTRICT,
    tipo               tipo_accion_admin NOT NULL,
    objeto_tipo        VARCHAR(30),
    objeto_id          UUID,
    objeto_descripcion TEXT,
    detalle_anterior   JSONB,
    detalle_nuevo      JSONB,
    motivo             TEXT,
    fecha_accion       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_admin_acc_admin  ON admin_acciones(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_acc_tipo   ON admin_acciones(tipo);
CREATE INDEX IF NOT EXISTS idx_admin_acc_objeto ON admin_acciones(objeto_tipo, objeto_id);
CREATE INDEX IF NOT EXISTS idx_admin_acc_fecha  ON admin_acciones(fecha_accion DESC);


-- ── TABLA: REPORTES ───────────────────────────────────────────
DO $$ BEGIN
    CREATE TYPE estado_reporte AS ENUM ('PENDIENTE', 'EN_REVISION', 'RESUELTO', 'DESESTIMADO');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE motivo_reporte AS ENUM (
        'INFORMACION_FALSA', 'CONTENIDO_INAPROPIADO',
        'ACTIVIDAD_SOSPECHOSA', 'PERFIL_SOSPECHOSO', 'OTRO'
    );
EXCEPTION WHEN duplicate_object THEN null; END $$;

CREATE TABLE IF NOT EXISTS reportes (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reportante_id     UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    objeto_tipo       VARCHAR(30) NOT NULL,    -- 'PUBLICACION' | 'FUNDACION' | 'USUARIO'
    objeto_id         UUID NOT NULL,
    motivo            motivo_reporte NOT NULL,
    detalle           TEXT,
    estado            estado_reporte NOT NULL DEFAULT 'PENDIENTE',
    admin_asignado_id UUID REFERENCES admin_perfiles(id) ON DELETE SET NULL,
    fecha_asignacion  TIMESTAMP,
    resolucion        TEXT,
    fecha_resolucion  TIMESTAMP,
    fecha_creacion    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_reporte_estado  ON reportes(estado);
CREATE INDEX IF NOT EXISTS idx_reporte_objeto  ON reportes(objeto_tipo, objeto_id);
CREATE INDEX IF NOT EXISTS idx_reporte_admin   ON reportes(admin_asignado_id);


-- ── FUNCIÓN: fn_admin_gestionar_fundacion ─────────────────────
-- Aprueba, rechaza, suspende o reactiva una fundación.
-- Actualiza el estado del usuario asociado y genera notificación.
CREATE OR REPLACE FUNCTION fn_admin_gestionar_fundacion(
    p_admin_id      UUID,
    p_fundacion_id  UUID,
    p_nuevo_estado  estado_verificacion,
    p_motivo        TEXT DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_estado_anterior  estado_verificacion;
    v_usuario_fundacion UUID;
    v_nombre_fundacion  VARCHAR(150);
    v_tipo_accion       tipo_accion_admin;
    v_tipo_notif        tipo_notificacion;
BEGIN
    SELECT estado_verificacion, usuario_id, nombre
    INTO   v_estado_anterior, v_usuario_fundacion, v_nombre_fundacion
    FROM   fundaciones WHERE id = p_fundacion_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Fundación % no encontrada.', p_fundacion_id;
    END IF;

    IF p_nuevo_estado IN ('RECHAZADA', 'SUSPENDIDA') AND
       (p_motivo IS NULL OR TRIM(p_motivo) = '') THEN
        RAISE EXCEPTION 'El motivo es obligatorio para rechazar o suspender una fundación.';
    END IF;

    v_tipo_accion := CASE p_nuevo_estado
        WHEN 'APROBADA'   THEN 'FUNDACION_APROBADA'
        WHEN 'RECHAZADA'  THEN 'FUNDACION_RECHAZADA'
        WHEN 'SUSPENDIDA' THEN 'FUNDACION_SUSPENDIDA'
        ELSE 'FUNDACION_REACTIVADA'
    END::tipo_accion_admin;

    v_tipo_notif := CASE p_nuevo_estado
        WHEN 'APROBADA'   THEN 'FUNDACION_APROBADA'
        WHEN 'RECHAZADA'  THEN 'FUNDACION_RECHAZADA'
        WHEN 'SUSPENDIDA' THEN 'FUNDACION_SUSPENDIDA'
        ELSE 'FUNDACION_REACTIVADA'
    END::tipo_notificacion;

    UPDATE fundaciones
    SET estado_verificacion = p_nuevo_estado,
        fecha_verificacion  = CURRENT_TIMESTAMP,
        motivo_rechazo      = CASE
            WHEN p_nuevo_estado IN ('RECHAZADA', 'SUSPENDIDA') THEN p_motivo
            ELSE NULL
        END
    WHERE id = p_fundacion_id;

    IF p_nuevo_estado IN ('RECHAZADA', 'SUSPENDIDA') THEN
        UPDATE usuarios SET estado = 'SUSPENDIDO' WHERE id = v_usuario_fundacion;
    ELSIF p_nuevo_estado IN ('APROBADA', 'PENDIENTE') THEN
        UPDATE usuarios SET estado = 'ACTIVO'     WHERE id = v_usuario_fundacion;
    END IF;

    INSERT INTO notificaciones (usuario_id, tipo, mensaje, objeto_tipo, objeto_id)
    VALUES (
        v_usuario_fundacion,
        v_tipo_notif,
        CASE p_nuevo_estado
            WHEN 'APROBADA'   THEN 'Tu fundación "' || v_nombre_fundacion || '" fue aprobada. Ya puedes publicar actividades.'
            WHEN 'RECHAZADA'  THEN 'Tu fundación "' || v_nombre_fundacion || '" fue rechazada. Motivo: ' || COALESCE(p_motivo, '')
            WHEN 'SUSPENDIDA' THEN 'Tu fundación "' || v_nombre_fundacion || '" fue suspendida. Motivo: ' || COALESCE(p_motivo, '')
            ELSE 'El estado de tu fundación "' || v_nombre_fundacion || '" fue actualizado.'
        END,
        'FUNDACION', p_fundacion_id
    );

    INSERT INTO admin_acciones (
        admin_id, tipo, objeto_tipo, objeto_id,
        objeto_descripcion, detalle_anterior, detalle_nuevo, motivo
    ) VALUES (
        p_admin_id, v_tipo_accion, 'FUNDACION', p_fundacion_id,
        v_nombre_fundacion,
        jsonb_build_object('estado_verificacion', v_estado_anterior),
        jsonb_build_object('estado_verificacion', p_nuevo_estado),
        p_motivo
    );
END;
$$ LANGUAGE plpgsql;


-- ── FUNCIÓN: fn_admin_ocultar_publicacion ────────────────────
-- Oculta o restaura una publicación sin eliminarla.
CREATE OR REPLACE FUNCTION fn_admin_ocultar_publicacion(
    p_admin_id       UUID,
    p_publicacion_id UUID,
    p_ocultar        BOOLEAN,
    p_motivo         TEXT
)
RETURNS VOID AS $$
DECLARE v_titulo VARCHAR(200);
BEGIN
    SELECT titulo INTO v_titulo FROM publicaciones WHERE id = p_publicacion_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Publicación % no encontrada.', p_publicacion_id;
    END IF;
    IF p_ocultar AND (p_motivo IS NULL OR TRIM(p_motivo) = '') THEN
        RAISE EXCEPTION 'El motivo es obligatorio para ocultar una publicación.';
    END IF;

    UPDATE publicaciones
    SET oculta_por_admin    = p_ocultar,
        motivo_ocultamiento = CASE WHEN p_ocultar THEN p_motivo ELSE NULL END,
        fecha_ocultamiento  = CASE WHEN p_ocultar THEN CURRENT_TIMESTAMP ELSE NULL END
    WHERE id = p_publicacion_id;

    INSERT INTO admin_acciones (admin_id, tipo, objeto_tipo, objeto_id, objeto_descripcion, detalle_nuevo, motivo)
    VALUES (
        p_admin_id,
        CASE WHEN p_ocultar THEN 'PUBLICACION_OCULTADA' ELSE 'PUBLICACION_RESTAURADA' END::tipo_accion_admin,
        'PUBLICACION', p_publicacion_id, v_titulo,
        jsonb_build_object('oculta_por_admin', p_ocultar), p_motivo
    );
END;
$$ LANGUAGE plpgsql;


-- ── FUNCIÓN: fn_admin_resolver_reporte ───────────────────────
CREATE OR REPLACE FUNCTION fn_admin_resolver_reporte(
    p_admin_id   UUID,
    p_reporte_id UUID,
    p_estado     estado_reporte,
    p_resolucion TEXT
)
RETURNS VOID AS $$
BEGIN
    IF p_estado NOT IN ('RESUELTO', 'DESESTIMADO') THEN
        RAISE EXCEPTION 'Solo se puede resolver con RESUELTO o DESESTIMADO.';
    END IF;
    IF p_resolucion IS NULL OR TRIM(p_resolucion) = '' THEN
        RAISE EXCEPTION 'La descripción de la resolución es obligatoria.';
    END IF;

    UPDATE reportes
    SET estado           = p_estado,
        resolucion       = p_resolucion,
        fecha_resolucion = CURRENT_TIMESTAMP,
        admin_asignado_id = p_admin_id,
        fecha_asignacion  = COALESCE(fecha_asignacion, CURRENT_TIMESTAMP)
    WHERE id = p_reporte_id AND estado IN ('PENDIENTE', 'EN_REVISION');

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Reporte % no encontrado o ya fue resuelto.', p_reporte_id;
    END IF;

    INSERT INTO admin_acciones (admin_id, tipo, objeto_tipo, objeto_id, motivo)
    VALUES (
        p_admin_id,
        CASE p_estado WHEN 'RESUELTO' THEN 'REPORTE_RESUELTO' ELSE 'REPORTE_DESESTIMADO' END::tipo_accion_admin,
        'REPORTE', p_reporte_id, p_resolucion
    );
END;
$$ LANGUAGE plpgsql;


-- =============================================================
-- SECCIÓN 11: CONFIGURACIÓN DEL SISTEMA
-- =============================================================

-- Centraliza parámetros configurables que actualmente están
-- hardcodeados. Cambiar un valor es un UPDATE, no un redeploy.
CREATE TABLE IF NOT EXISTS configuracion_sistema (
    clave               VARCHAR(100) PRIMARY KEY,
    valor_texto         TEXT,
    valor_int           INT,
    valor_decimal       NUMERIC(10, 4),
    valor_bool          BOOLEAN,
    descripcion         TEXT NOT NULL,
    modulo              VARCHAR(50) NOT NULL,
    fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE TRIGGER trg_config_fecha_actualizacion
BEFORE UPDATE ON configuracion_sistema
FOR EACH ROW EXECUTE FUNCTION fn_actualizar_fecha_actualizacion();

CREATE INDEX IF NOT EXISTS idx_config_modulo ON configuracion_sistema(modulo);

INSERT INTO configuracion_sistema (clave, valor_int, descripcion, modulo) VALUES
    ('TOKEN_VERIFICACION_EMAIL_HORAS', 24,  'Horas de vigencia del token de verificación de email.',      'AUTH'),
    ('TOKEN_RESET_PASSWORD_HORAS',      1,  'Horas de vigencia del token de recuperación de contraseña.', 'AUTH'),
    ('SESSION_TTL_HORAS',              24,  'Duración en horas de una sesión normal.',                     'AUTH'),
    ('SESSION_ADMIN_TTL_HORAS',         2,  'Duración en horas de una sesión de administrador.',           'AUTH'),
    ('MAX_INTENTOS_LOGIN',              5,  'Intentos fallidos antes de bloquear temporalmente.',          'AUTH'),
    ('MAX_POSTULACIONES_ACTIVAS',      10,  'Postulaciones PENDIENTE o ACEPTADO simultáneas por voluntario.','POSTULACIONES'),
    ('DIAS_RESPUESTA_FUNDACION',        7,  'Días máximos para que una fundación responda una postulación.','POSTULACIONES'),
    ('DIAS_RETENER_NOTIFICACIONES',    90,  'Días de retención de notificaciones leídas.',                 'NOTIFICACIONES'),
    ('MAX_NOTIFICACIONES_NO_LEIDAS',   50,  'Máximo de notificaciones no leídas en el badge del frontend.','NOTIFICACIONES'),
    ('REPORTES_PARA_ALERTA_ADMIN',      3,  'Reportes sobre un mismo objeto que genera alerta de prioridad alta.','REPORTES'),
    ('MAX_TAMANO_IMAGEN_MB',            5,  'Tamaño máximo de imágenes subidas, en MB.',                  'ARCHIVOS')
ON CONFLICT (clave) DO NOTHING;

INSERT INTO configuracion_sistema (clave, valor_texto, descripcion, modulo) VALUES
    ('FORMATOS_IMAGEN_PERMITIDOS', 'jpg,jpeg,png,webp', 'Formatos de imagen aceptados.', 'ARCHIVOS')
ON CONFLICT (clave) DO NOTHING;

-- Helpers para leer configuración desde PL/pgSQL
CREATE OR REPLACE FUNCTION fn_config_int(p_clave VARCHAR)
RETURNS INT AS $$
    SELECT valor_int FROM configuracion_sistema WHERE clave = p_clave;
$$ LANGUAGE SQL STABLE;

CREATE OR REPLACE FUNCTION fn_config_texto(p_clave VARCHAR)
RETURNS TEXT AS $$
    SELECT valor_texto FROM configuracion_sistema WHERE clave = p_clave;
$$ LANGUAGE SQL STABLE;


-- =============================================================
-- SECCIÓN 12: VISTAS ÚTILES PARA EL BACKEND
-- =============================================================

-- Panel principal de la fundación: resumen de sus actividades
CREATE OR REPLACE VIEW vw_resumen_fundacion AS
SELECT
    f.id AS fundacion_id,
    f.nombre,
    f.estado_verificacion,
    COUNT(DISTINCT pub.id)                                                AS total_publicaciones,
    COUNT(DISTINCT pub.id) FILTER (WHERE pub.estado = 'PUBLICADA')       AS publicaciones_activas,
    COUNT(DISTINCT p.id)                                                  AS total_postulaciones,
    COUNT(DISTINCT p.voluntario_id) FILTER (WHERE p.estado = 'ASISTIO')  AS voluntarios_participantes,
    COUNT(p.id) FILTER (WHERE p.estado = 'PENDIENTE')                    AS postulaciones_pendientes
FROM fundaciones f
LEFT JOIN publicaciones pub ON pub.fundacion_id = f.id
LEFT JOIN postulaciones  p  ON p.publicacion_id = pub.id
GROUP BY f.id, f.nombre, f.estado_verificacion;


-- Detalle de actividades de una fundación con métricas de postulaciones
CREATE OR REPLACE VIEW vw_actividades_fundacion AS
SELECT
    pub.id AS publicacion_id,
    pub.fundacion_id,
    pub.titulo,
    pub.estado,
    pub.modalidad,
    pub.fecha_inicio,
    pub.fecha_fin,
    pub.cupo_maximo,
    m.nombre AS municipio,
    d.nombre AS departamento,
    COUNT(p.id)                                                       AS total_postulaciones,
    COUNT(p.id) FILTER (WHERE p.estado = 'PENDIENTE')                AS postulaciones_pendientes,
    COUNT(p.id) FILTER (WHERE p.estado = 'ACEPTADO')                 AS postulaciones_aceptadas,
    COUNT(p.id) FILTER (WHERE p.estado = 'ASISTIO')                  AS confirmaron_asistencia,
    pub.cupo_maximo - COUNT(p.id) FILTER (WHERE p.estado IN ('ACEPTADO', 'ASISTIO')) AS cupos_disponibles
FROM publicaciones pub
LEFT JOIN postulaciones p   ON p.publicacion_id = pub.id
LEFT JOIN municipios m      ON m.id = pub.municipio_id
LEFT JOIN departamentos d   ON d.id = m.departamento_id
GROUP BY pub.id, m.nombre, d.nombre;


-- Lista de postulantes de una actividad con datos del voluntario
CREATE OR REPLACE VIEW vw_postulantes_actividad AS
SELECT
    p.id AS postulacion_id,
    p.publicacion_id,
    p.estado AS estado_postulacion,
    p.mensaje_voluntario,
    p.motivo_rechazo,
    p.fecha_postulacion,
    p.calificacion,
    p.comentario_fundacion,
    vol.id AS voluntario_id,
    u.nombre AS nombre_voluntario,
    u.email  AS correo_voluntario,
    u.telefono AS telefono_voluntario,
    vol.genero,
    vol.tipo_documento,
    vol.numero_documento,
    m.nombre AS municipio_voluntario,
    dep.nombre AS departamento_voluntario,
    (SELECT COUNT(*) FROM postulaciones p2
     WHERE p2.voluntario_id = vol.id AND p2.estado = 'ASISTIO') AS actividades_completadas_total
FROM postulaciones p
JOIN voluntarios vol   ON vol.id = p.voluntario_id
JOIN usuarios u        ON u.id  = vol.usuario_id
JOIN municipios m      ON m.id  = vol.municipio_id
JOIN departamentos dep ON dep.id = m.departamento_id;


-- =============================================================
-- SECCIÓN 13: ADMIN INICIAL DEL SISTEMA
-- =============================================================

-- IMPORTANTE: Cambiar email y contraseña antes de usar en producción.
-- El backend debe hacer el hash con bcrypt/argon2 antes de insertar.
INSERT INTO usuarios (
    nombre, email, password_hash, provider, rol, estado, email_verificado
)
SELECT
    'Administrador del Sistema',
    'admin@voluntapp.co',
    '$HASH_PENDIENTE_CAMBIAR_EN_PRODUCCION$',
    'LOCAL', 'ADMIN', 'ACTIVO', TRUE
WHERE NOT EXISTS (
    SELECT 1 FROM usuarios WHERE email = 'admin@voluntapp.co' AND rol = 'ADMIN'
);

INSERT INTO admin_perfiles (usuario_id, nivel, creado_por, cargo)
SELECT
    u.id, 'SUPER', NULL, 'Super Administrador'
FROM usuarios u
WHERE u.email = 'admin@voluntapp.co' AND u.rol = 'ADMIN'
  AND NOT EXISTS (
      SELECT 1 FROM admin_perfiles ap WHERE ap.usuario_id = u.id
  );


-- =============================================================
-- VERIFICACIÓN FINAL
-- =============================================================

SELECT '=== VOLUNTAPP MVP — VERIFICACIÓN ===' AS info;

SELECT tabla, total FROM (
    SELECT 'departamentos'  AS tabla, COUNT(*)::INT AS total FROM departamentos  UNION ALL
    SELECT 'municipios',               COUNT(*)::INT          FROM municipios     UNION ALL
    SELECT 'habilidades',              COUNT(*)::INT          FROM habilidades    UNION ALL
    SELECT 'intereses',                COUNT(*)::INT          FROM intereses      UNION ALL
    SELECT 'areas_impacto',            COUNT(*)::INT          FROM areas_impacto  UNION ALL
    SELECT 'usuarios',                 COUNT(*)::INT          FROM usuarios       UNION ALL
    SELECT 'configuracion_sistema',    COUNT(*)::INT          FROM configuracion_sistema
) t ORDER BY tabla;

COMMIT;

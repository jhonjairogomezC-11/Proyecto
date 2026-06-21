# 🚀 Configuración de Datos Masivos para VoluntApp

Este documento explica cómo configurar la aplicación con datos masivos y realistas para simular un entorno de producción.

## 📊 ¿Qué incluye?

### 👥 **Usuarios (150+ registros)**
- **100 voluntarios activos** con fotos de perfil reales
- **25 voluntarios pendientes** de aprobación 
- **15 voluntarios suspendidos**
- **10 voluntarios bloqueados**
- Correos electrónicos realistas usando dominios populares
- Teléfonos, documentos y datos personales variados

### 🏢 **Fundaciones (40 registros)**
- **25 fundaciones aprobadas** con logos
- **8 fundaciones pendientes** de aprobación
- **4 fundaciones rechazadas** 
- **3 fundaciones suspendidas**
- Nombres realistas de organizaciones
- NITs, representantes legales y correos institucionales

### 📢 **Publicaciones (200+ registros)**
- Actividades variadas: limpieza, educación, salud, etc.
- Diferentes modalidades: presencial, virtual, híbrida
- Estados variados: publicadas, borradores, pausadas
- Fechas futuras realistas

### 📝 **Postulaciones (1000+ registros)**
- Entre 5-25 postulaciones por publicación
- Estados variados: pendiente, aceptado, rechazado, retirado
- Mensajes y calificaciones aleatorias

### 👨‍💼 **Administradores (6 perfiles)**
- **María Elena Rodríguez** - Directora General (SUPER)
- **Carlos Andrés Martínez** - Coordinador Operaciones (OPERATIVO) 
- **Ana Sofía Hernández** - Especialista Contenidos (MODERADOR)
- **Luis Fernando García** - Supervisor Calidad (OPERATIVO)
- **Patricia Morales Silva** - Coordinadora Regional (MODERADOR)
- **admin@voluntapp.co** - Super Administrador (Legacy)

## 🛠️ Instalación

### Opción 1: Instalación completa (Recomendada)

```bash
# Resetear base de datos y crear todos los datos
php artisan db:populate-massive --fresh

# Si estás en producción (NO recomendado), usar:
php artisan db:populate-massive --fresh --force
```

### Opción 2: Solo agregar datos masivos

```bash
# Solo ejecutar el seeder de datos masivos
php artisan db:seed --class=MassiveDataSeeder
```

### Opción 3: Paso a paso

```bash
# 1. Migrar base de datos
php artisan migrate:fresh

# 2. Seeders básicos
php artisan db:seed --class=CatalogosSeeder
php artisan db:seed --class=AdminSeeder  
php artisan db:seed --class=DemoSeeder

# 3. Datos masivos
php artisan db:seed --class=MassiveDataSeeder
```

## 🔑 Credenciales de Acceso

### Administradores
| Email | Password | Cargo | Nivel |
|-------|----------|--------|-------|
| maria.rodriguez@voluntapp.co | Admin1234! | Directora General | SUPER |
| carlos.martinez@voluntapp.co | Coord2024! | Coordinador Operaciones | OPERATIVO |
| ana.hernandez@voluntapp.co | Mod2024! | Especialista Contenidos | MODERADOR |
| luis.garcia@voluntapp.co | Super2024! | Supervisor Calidad | OPERATIVO |
| patricia.morales@voluntapp.co | Region2024! | Coordinadora Regional | MODERADOR |
| admin@voluntapp.co | Admin1234! | Super Administrador | SUPER |

### Voluntarios y Fundaciones
- **Password para todos**: `password123`
- **Emails**: Siguen el patrón `nombre.apellido123@dominio.com`
- **Ejemplos**:
  - `carlos.rodriguez1@gmail.com`
  - `fundacion.amigos.ambiente2@hotmail.com`

## 📱 Probando la Aplicación

### Panel de Administrador
1. Inicia sesión con cualquiera de los administradores
2. Ve a **Voluntarios** - verás una lista compacta con fotos
3. Ve a **Fundaciones** - lista compacta con logos
4. Prueba expandir/colapsar items haciendo clic
5. Prueba suspender/bloquear voluntarios
6. Prueba aprobar/rechazar fundaciones

### Aplicación Móvil (Voluntarios)
1. Inicia sesión como voluntario
2. Ve a **Actividades** - verás muchas publicaciones
3. Usa el botón de cambio de vista (compacta/completa)
4. Ve al **Ranking** - verás fotos de perfil reales
5. Prueba postularte a actividades

### Aplicación Móvil (Fundaciones)  
1. Inicia sesión como fundación aprobada
2. Crea nuevas publicaciones
3. Ve postulantes con fotos de perfil
4. Gestiona estados de postulaciones

## 🐛 Solución de Problemas

### Error al suspender usuarios
Si aparece el error `dependents.isEmpty is not true`:
- **Causa**: Problema de navegación en Flutter
- **Solución**: Los archivos ya fueron actualizados con verificaciones adicionales

### Faltan datos
```bash
# Verificar que todos los seeders corrieron
php artisan tinker
>>> App\Models\Usuario::count()
>>> App\Models\Voluntario::count()
>>> App\Models\Fundacion::count()
```

### Performance lenta
```bash
# Optimizar base de datos
php artisan optimize:clear
php artisan config:cache
php artisan route:cache
```

## 📈 Estadísticas Esperadas

Después de ejecutar los seeders deberías tener aproximadamente:

- **170+ usuarios** totales
- **150 voluntarios** (100 activos, 25 pendientes, 15 suspendidos, 10 bloqueados)
- **40 fundaciones** (25 aprobadas, 8 pendientes, 4 rechazadas, 3 suspendidas)
- **200+ publicaciones** variadas
- **1000+ postulaciones** distribuidas
- **6 administradores** con diferentes niveles

## 🔄 Actualizar Solo Algunos Datos

Si quieres agregar más datos sin borrar los existentes:

```bash
# Solo más voluntarios
php artisan db:seed --class=MassiveDataSeeder

# O crear un seeder específico
php artisan make:seeder ExtraVoluntariosSeeder
```

## 🌐 URLs de Avatares

Los avatares se generan usando servicios públicos:
- `ui-avatars.com` - Iniciales con colores
- `dicebear.com` - Avatares ilustrados
- `robohash.org` - Robots únicos

Si quieres usar fotos reales, puedes:
1. Subir imágenes a un CDN
2. Actualizar las URLs en el seeder
3. Re-ejecutar solo los datos de usuarios

## 🚀 ¡Listo para Producción!

Con estos datos masivos tienes un entorno completo que simula una aplicación real con:
- ✅ Múltiples tipos de usuarios
- ✅ Estados variados realistas  
- ✅ Relaciones complejas entre entidades
- ✅ Datos suficientes para pruebas de rendimiento
- ✅ Fotos y logos que mejoran la experiencia visual
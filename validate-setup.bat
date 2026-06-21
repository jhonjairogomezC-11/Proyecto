@echo off
echo 🔍 Verificando instalación de VoluntApp...
echo.

echo Verificando PHP...
php --version > nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ PHP no está instalado o no está en el PATH
    goto :error
) else (
    echo ✅ PHP encontrado: 
    php --version | findstr "PHP"
)

echo.
echo Verificando Composer...
composer --version > nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Composer no está instalado
    goto :error
) else (
    echo ✅ Composer encontrado:
    composer --version
)

echo.
echo Verificando Node.js...
node --version > nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Node.js no está instalado
    goto :error
) else (
    echo ✅ Node.js encontrado:
    node --version
    npm --version
)

echo.
echo Verificando PostgreSQL...
psql --version > nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️  PostgreSQL no encontrado en PATH (puede estar instalado pero no accesible)
) else (
    echo ✅ PostgreSQL encontrado:
    psql --version
)

echo.
echo Verificando Flutter (opcional)...
flutter --version > nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️  Flutter no encontrado (opcional para desarrollo móvil)
) else (
    echo ✅ Flutter encontrado:
    flutter --version | findstr "Flutter"
)

echo.
echo Verificando archivos del proyecto...
if exist "composer.json" (
    echo ✅ composer.json encontrado
) else (
    echo ❌ composer.json no encontrado
    goto :error
)

if exist "frontend\package.json" (
    echo ✅ frontend/package.json encontrado
) else (
    echo ❌ frontend/package.json no encontrado
    goto :error
)

if exist ".env" (
    echo ✅ .env encontrado
) else (
    echo ⚠️  .env no encontrado (copiar desde .env.example)
)

echo.
echo 🎉 Verificación completada. El entorno parece estar listo.
echo.
echo 📝 Próximos pasos:
echo 1. Configurar .env con credenciales de base de datos
echo 2. Ejecutar: php artisan db:populate-massive --fresh
echo 3. Ejecutar: start-dev.bat
echo.
goto :end

:error
echo.
echo ❌ Se encontraron problemas. Revisa los requisitos en README.md
echo.

:end
pause
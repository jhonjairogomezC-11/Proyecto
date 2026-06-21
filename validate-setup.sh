#!/bin/bash

echo "🔍 Verificando instalación de VoluntApp..."
echo

has_error=false

echo "Verificando PHP..."
if command -v php &> /dev/null; then
    echo "✅ PHP encontrado:"
    php --version | head -1
else
    echo "❌ PHP no está instalado o no está en el PATH"
    has_error=true
fi

echo
echo "Verificando Composer..."
if command -v composer &> /dev/null; then
    echo "✅ Composer encontrado:"
    composer --version | head -1
else
    echo "❌ Composer no está instalado"
    has_error=true
fi

echo
echo "Verificando Node.js..."
if command -v node &> /dev/null; then
    echo "✅ Node.js encontrado:"
    echo "Node: $(node --version)"
    echo "npm: $(npm --version)"
else
    echo "❌ Node.js no está instalado"
    has_error=true
fi

echo
echo "Verificando PostgreSQL..."
if command -v psql &> /dev/null; then
    echo "✅ PostgreSQL encontrado:"
    psql --version
else
    echo "⚠️  PostgreSQL no encontrado en PATH (puede estar instalado pero no accesible)"
fi

echo
echo "Verificando Flutter (opcional)..."
if command -v flutter &> /dev/null; then
    echo "✅ Flutter encontrado:"
    flutter --version | head -1
else
    echo "⚠️  Flutter no encontrado (opcional para desarrollo móvil)"
fi

echo
echo "Verificando archivos del proyecto..."
if [ -f "composer.json" ]; then
    echo "✅ composer.json encontrado"
else
    echo "❌ composer.json no encontrado"
    has_error=true
fi

if [ -f "frontend/package.json" ]; then
    echo "✅ frontend/package.json encontrado"
else
    echo "❌ frontend/package.json no encontrado"
    has_error=true
fi

if [ -f ".env" ]; then
    echo "✅ .env encontrado"
else
    echo "⚠️  .env no encontrado (copiar desde .env.example)"
fi

echo

if [ "$has_error" = true ]; then
    echo "❌ Se encontraron problemas. Revisa los requisitos en README.md"
    echo
    exit 1
else
    echo "🎉 Verificación completada. El entorno parece estar listo."
    echo
    echo "📝 Próximos pasos:"
    echo "1. Configurar .env con credenciales de base de datos"
    echo "2. Ejecutar: php artisan db:populate-massive --fresh"
    echo "3. Ejecutar: ./start-dev.sh"
    echo
fi
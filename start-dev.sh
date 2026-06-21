#!/bin/bash
echo "🚀 Iniciando VoluntApp en modo desarrollo..."

# Backend en background
echo "📡 Iniciando backend Laravel..."
php artisan serve --host=0.0.0.0 --port=8000 &
BACKEND_PID=$!

sleep 3

# Frontend en background  
echo "🌐 Iniciando frontend Vue..."
cd frontend && npm run dev &
FRONTEND_PID=$!

echo "✅ VoluntApp iniciado!"
echo "📱 Web: http://localhost:5173"
echo "🔧 API: http://localhost:8000"  
echo "📋 Admin: http://localhost:5173/admin"
echo ""
echo "Presiona Ctrl+C para detener todos los servicios..."

# Manejar interrupción
trap "echo 'Deteniendo servicios...'; kill $BACKEND_PID $FRONTEND_PID; exit" INT
wait
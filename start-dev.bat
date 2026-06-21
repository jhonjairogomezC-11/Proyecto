@echo off
echo 🚀 Iniciando VoluntApp en modo desarrollo...

echo 📡 Iniciando backend Laravel...
start "Backend" cmd /k "cd /d %~dp0 && php artisan serve --host=0.0.0.0 --port=8000"

timeout /t 3 > nul

echo 🌐 Iniciando frontend Vue...  
start "Frontend" cmd /k "cd /d %~dp0\frontend && npm run dev"

echo ✅ VoluntApp iniciado!
echo 📱 Web: http://localhost:5173
echo 🔧 API: http://localhost:8000
echo 📋 Admin: http://localhost:5173/admin
echo.
echo Presiona cualquier tecla para cerrar...

pause
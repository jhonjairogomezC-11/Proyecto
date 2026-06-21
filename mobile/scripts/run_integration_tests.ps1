# Ejecuta integration tests en Windows contra el backend local.
# Requisitos: Laravel en 127.0.0.1:8000 con datos demo (DemoSeeder + AdminSeeder).

$ErrorActionPreference = "Stop"

$mobileRoot = Split-Path -Parent $PSScriptRoot
Set-Location $mobileRoot

$env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "Flutter no esta en PATH." -ForegroundColor Red
    exit 1
}

$healthUrl = "http://127.0.0.1:8000"
Write-Host "Comprobando backend en $healthUrl ..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri $healthUrl -TimeoutSec 5 -UseBasicParsing | Out-Null
} catch {
    Write-Host ""
    Write-Host "Backend no disponible." -ForegroundColor Red
    Write-Host "Desde la raiz del monorepo ejecuta:" -ForegroundColor Yellow
    Write-Host "  php artisan serve --host=0.0.0.0 --port=8000" -ForegroundColor White
    Write-Host ""
    Write-Host "Si es la primera vez, también:" -ForegroundColor Yellow
    Write-Host "  php artisan migrate --seed" -ForegroundColor White
    exit 1
}

Write-Host "Ejecutando integration tests (Windows desktop)..." -ForegroundColor Green
Write-Host "Cierra flutter run si esta activo (evita bloqueo de Hive)." -ForegroundColor Yellow

flutter test integration_test/app_flow_test.dart `
    -d windows `
    --dart-define=ENV=dev `
    --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1 `
    --timeout=3m

if ($LASTEXITCODE -eq 0) {
    Write-Host "Integration tests OK." -ForegroundColor Cyan
}

exit $LASTEXITCODE

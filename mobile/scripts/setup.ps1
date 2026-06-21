# Genera carpetas android/ios si Flutter esta instalado
$ErrorActionPreference = "Stop"

Write-Host "VoluntApp Mobile - setup" -ForegroundColor Cyan

# Refrescar PATH de la sesion (Machine + User)
$env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")

# Fallback: Flutter en ubicacion tipica de este proyecto
$flutterCandidates = @(
    "C:\flutter\bin",
    "$env:LOCALAPPDATA\flutter\bin",
    "$env:USERPROFILE\flutter\bin"
)

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    foreach ($dir in $flutterCandidates) {
        if (Test-Path "$dir\flutter.bat") {
            $env:Path = "$dir;" + $env:Path
            break
        }
    }
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "Flutter no esta en PATH." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Solucion rapida (copia y pega en esta terminal):" -ForegroundColor Cyan
    Write-Host '  $env:Path = "C:\flutter\bin;" + $env:Path' -ForegroundColor White
    Write-Host "  .\scripts\setup.ps1" -ForegroundColor White
    Write-Host ""
    Write-Host "O cierra y abre de nuevo la terminal / Cursor despues de instalar Flutter."
    Write-Host "Instalacion: https://docs.flutter.dev/get-started/install/windows"
    exit 1
}

Write-Host ("Flutter: " + (flutter --version | Select-Object -First 1)) -ForegroundColor Gray

$mobileRoot = Split-Path -Parent $PSScriptRoot
Set-Location $mobileRoot

if (-not (Test-Path "android")) {
    Write-Host "Generando plataformas con flutter create..." -ForegroundColor Green
    flutter create . --org co.voluntapp --project-name voluntapp_mobile
} else {
    Write-Host "Carpeta android/ ya existe - omitiendo flutter create." -ForegroundColor Gray
}

Write-Host "Instalando dependencias..." -ForegroundColor Green
flutter pub get

Write-Host "Analizando proyecto..." -ForegroundColor Green
flutter analyze

Write-Host "Setup completado." -ForegroundColor Cyan

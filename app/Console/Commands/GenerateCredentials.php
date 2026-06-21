<?php

namespace App\Console\Commands;

use App\Models\Usuario;
use Illuminate\Console\Command;

class GenerateCredentials extends Command
{
    protected $signature = 'app:generate-credentials';
    protected $description = 'Generate a list of sample credentials';

    public function handle()
    {
        $this->info('🔑 Generando archivo de credenciales...');

        // Obtener usuarios sample
        $voluntarios = Usuario::where('rol', 'VOLUNTARIO')
            ->with('voluntario')
            ->limit(10)
            ->get();

        $fundaciones = Usuario::where('rol', 'FUNDACION')
            ->with('fundacion')
            ->limit(10)
            ->get();

        $admins = Usuario::where('rol', 'ADMIN')
            ->limit(6)
            ->get();

        // Crear contenido del archivo
        $content = $this->generateCredentialsFile($voluntarios, $fundaciones, $admins);

        // Escribir archivo
        file_put_contents(base_path('CREDENCIALES_ACCESO.md'), $content);

        $this->info('✅ Archivo CREDENCIALES_ACCESO.md creado en el directorio raíz del proyecto');
        
        return 0;
    }

    private function generateCredentialsFile($voluntarios, $fundaciones, $admins): string
    {
        $content = "# 🔑 Credenciales de Acceso - VoluntApp\n\n";
        $content .= "*Generado automáticamente el " . now()->format('d/m/Y H:i:s') . "*\n\n";
        $content .= "**⚠️ Todas las contraseñas son: `password123` (excepto admins que tienen contraseñas específicas)**\n\n";

        // Sección Administradores
        $content .= "## 👨‍💼 Administradores\n\n";
        $content .= "| Email | Contraseña | Nombre | Nivel |\n";
        $content .= "|-------|------------|--------|-------|\n";
        
        $adminCredentials = [
            ['maria.rodriguez@voluntapp.co', 'Admin1234!', 'María Elena Rodríguez', 'SUPER'],
            ['carlos.martinez@voluntapp.co', 'Coord2024!', 'Carlos Andrés Martínez', 'OPERATIVO'],
            ['ana.hernandez@voluntapp.co', 'Mod2024!', 'Ana Sofía Hernández', 'OPERATIVO'],
            ['luis.garcia@voluntapp.co', 'Super2024!', 'Luis Fernando García', 'OPERATIVO'],
            ['patricia.morales@voluntapp.co', 'Region2024!', 'Patricia Morales Silva', 'OPERATIVO'],
            ['admin@voluntapp.co', 'Admin1234!', 'Administrador del Sistema', 'SUPER (Legacy)']
        ];

        foreach ($adminCredentials as $admin) {
            $content .= "| {$admin[0]} | `{$admin[1]}` | {$admin[2]} | {$admin[3]} |\n";
        }

        // Sección Voluntarios
        $content .= "\n## 👥 Voluntarios\n\n";
        $content .= "*Contraseña para todos: `password123`*\n\n";
        $content .= "| Email | Nombre | Estado | Verificado |\n";
        $content .= "|-------|---------|--------|------------|\n";

        foreach ($voluntarios as $voluntario) {
            $verificado = $voluntario->voluntario && $voluntario->voluntario->esta_verificado ? '✅ Sí' : '❌ No';
            $estado = $voluntario->estado->value ?? $voluntario->estado;
            $content .= "| {$voluntario->email} | {$voluntario->nombre} | {$estado} | {$verificado} |\n";
        }

        // Sección Fundaciones
        $content .= "\n## 🏢 Fundaciones\n\n";
        $content .= "*Contraseña para todas: `password123`*\n\n";
        $content .= "| Email | Nombre | Estado Verificación | Usuario Estado |\n";
        $content .= "|-------|---------|---------------------|----------------|\n";

        foreach ($fundaciones as $fundacion) {
            $estadoVerif = $fundacion->fundacion ? $fundacion->fundacion->estado_verificacion->value : 'N/A';
            $estadoUsuario = $fundacion->estado->value ?? $fundacion->estado;
            $content .= "| {$fundacion->email} | {$fundacion->nombre} | {$estadoVerif} | {$estadoUsuario} |\n";
        }

        // Información adicional
        $content .= "\n---\n\n";
        $content .= "## 📱 Instrucciones de Uso\n\n";
        $content .= "### Para Voluntarios:\n";
        $content .= "1. Usar cualquier email de la tabla de voluntarios\n";
        $content .= "2. Contraseña: `password123`\n";
        $content .= "3. Acceder a la app móvil para ver publicaciones y postularse\n";
        $content .= "4. Probar el ranking para ver las fotos de perfil\n\n";

        $content .= "### Para Fundaciones:\n";
        $content .= "1. Usar cualquier email de fundaciones **APROBADAS**\n";
        $content .= "2. Contraseña: `password123`\n";
        $content .= "3. Crear publicaciones y gestionar postulantes\n";
        $content .= "4. Solo fundaciones aprobadas pueden crear publicaciones\n\n";

        $content .= "### Para Administradores:\n";
        $content .= "1. Usar cualquier email de la tabla de administradores\n";
        $content .= "2. Usar la contraseña específica de cada admin\n";
        $content .= "3. Acceder al panel web de administración\n";
        $content .= "4. Gestionar usuarios (aprobar, suspender, etc.)\n\n";

        $content .= "## 🎯 Casos de Uso Recomendados\n\n";
        $content .= "### Probar Interface Compacta:\n";
        $content .= "- **Admin**: Entrar como admin y ver listas compactas de voluntarios/fundaciones\n";
        $content .= "- **Voluntario**: Ver publicaciones y cambiar entre vista compacta/completa\n";
        $content .= "- **Ranking**: Ver fotos de perfil reales en el ranking\n\n";

        $content .= "### Probar Funcionalidades:\n";
        $content .= "- **Suspender usuarios**: Como admin, suspender voluntarios (error corregido)\n";
        $content .= "- **Aprobar fundaciones**: Como admin, aprobar fundaciones pendientes\n";
        $content .= "- **Crear publicaciones**: Como fundación aprobada\n";
        $content .= "- **Postularse**: Como voluntario activo\n\n";

        $content .= "## 📊 Estadísticas Actuales\n\n";
        
        // Obtener estadísticas reales
        $stats = [
            'Usuarios Totales' => Usuario::count(),
            'Voluntarios' => Usuario::where('rol', 'VOLUNTARIO')->count(),
            'Fundaciones' => Usuario::where('rol', 'FUNDACION')->count(),
            'Administradores' => Usuario::where('rol', 'ADMIN')->count(),
        ];

        foreach ($stats as $label => $count) {
            $content .= "- **{$label}**: {$count}\n";
        }

        $content .= "\n---\n";
        $content .= "*📝 Este archivo fue generado automáticamente. Para regenerarlo ejecuta: `php artisan app:generate-credentials`*\n";

        return $content;
    }
}
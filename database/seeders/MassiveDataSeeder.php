<?php

namespace Database\Seeders;

use App\Enums\DisponibilidadTipo;
use App\Enums\EstadoUsuario;
use App\Enums\EstadoVerificacion;
use App\Enums\GeneroTipo;
use App\Enums\ProveedorAuth;
use App\Enums\RolUsuario;
use App\Enums\TipoDocumento;
use App\Models\AreaImpacto;
use App\Models\Fundacion;
use App\Models\Habilidad;
use App\Models\Municipio;
use App\Models\Postulacion;
use App\Models\Publicacion;
use App\Models\Usuario;
use App\Models\Voluntario;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class MassiveDataSeeder extends Seeder
{
    private array $voluntariosReales = [
        'Carlos Rodríguez', 'Ana García', 'Luis López', 'María Fernández', 'José Martín',
        'Carmen Sánchez', 'Francisco Jiménez', 'Isabel Ruiz', 'Antonio Hernández', 'Dolores Díaz',
        'Manuel Morales', 'Pilar Muñoz', 'David Álvarez', 'Rosa Romero', 'Miguel Alonso',
        'Antonia Gutiérrez', 'Alejandro Navarro', 'Francisca Torres', 'Daniel Domínguez', 'Teresa Vázquez',
        'Rafael Ramos', 'Juana Gil', 'Gabriel Serrano', 'Manuela Blanco', 'Adrián Moreno',
        'Concepciones Suárez', 'Óscar Ortega', 'Amparo Delgado', 'Ricardo Castro', 'Remedios Ortiz',
        'Fernando Rubio', 'Josefa Molina', 'Eduardo Marín', 'Esperanza Sanz', 'Roberto Iglesias',
        'Inmaculada Medina', 'Sergio Garrido', 'Victoria Cortés', 'Pablo Campos', 'Ángeles Herrera',
        'Jorge Guerrero', 'Encarnación Aguilar', 'Alberto León', 'Milagros Méndez', 'Rubén Cruz',
        'Mercedes Prieto', 'Víctor Flores', 'Soledad Lozano', 'Raúl Peña', 'Purificación Cano',
        'Gonzalo Pascual', 'Rosario Vega', 'Iván Román', 'Consuelo Giménez', 'Jesús Herrero',
        'Cristina Silva', 'Marcos Vargas', 'Rocío Reyes', 'Nicolás Carmona', 'Paloma Santiago',
        'Emilio Benítez', 'Begoña Ramírez', 'Lorenzo Santana', 'Trinidad Montero', 'Ángel Cabrera',
        'Yolanda Carrasco', 'Hugo Fuentes', 'Natividad Nieto', 'Juan Carlos Aguilera', 'Marisol Pascual',
        'Esteban Cortés', 'Montserrat Herrera', 'Santiago López', 'Ascensión García', 'Tomás Rodríguez',
        'Celestino Martínez', 'Lucía González', 'Aurelio Pérez', 'Virtudes Gómez', 'Clemente Martín',
        'Perpetua Jiménez', 'Máximo Ruiz', 'Amparo Hernández', 'Aquilino Díaz', 'Consolación Morales',
        'Germán Muñoz', 'Purificación Álvarez', 'Félix Romero', 'Encarnación Alonso', 'Leandro Gutiérrez',
        'Remedios Navarro', 'Plácido Torres', 'Visitación Domínguez', 'Bautista Vázquez', 'Milagros Ramos'
    ];

    private array $fundacionesReales = [
        'Fundación Amigos del Ambiente', 'Cruz Verde Colombia', 'Fundación Niños Felices',
        'Organización Manos Solidarias', 'Fundación Esperanza y Vida', 'Alianza por la Educación',
        'Fundación Corazones Unidos', 'Red de Apoyo Comunitario', 'Fundación Futuro Brillante',
        'Organización Tierra Limpia', 'Fundación Sonrisas', 'Alianza Verde', 'Fundación Caminos de Paz',
        'Red Solidaria Nacional', 'Fundación Horizontes', 'Organización Manos Amigas',
        'Fundación Semillas de Esperanza', 'Alianza por los Niños', 'Fundación Puentes',
        'Red de Voluntarios Unidos', 'Fundación Nuevo Amanecer', 'Organización Raíces',
        'Fundación Árbol de Vida', 'Alianza Comunitaria', 'Fundación Águilas Doradas',
        'Red de Cambio Social', 'Fundación Luz y Esperanza', 'Organización Hermanos Unidos',
        'Fundación Caminos Verdes', 'Alianza por el Futuro', 'Fundación Corazón Latino',
        'Red de Apoyo Familiar', 'Fundación Estrella del Sur', 'Organización Manos Unidas',
        'Fundación Renacer', 'Alianza Solidaria', 'Fundación Mariposas', 'Red Comunitaria',
        'Fundación Senderos de Luz', 'Organización Vientos de Cambio'
    ];

    private array $emailDomains = [
        'gmail.com', 'hotmail.com', 'yahoo.com', 'outlook.com', 'live.com', 
        'protonmail.com', 'icloud.com', 'msn.com', 'terra.com'
    ];

    private array $nombresActividades = [
        'Limpieza de Parques', 'Educación Ambiental', 'Apoyo Escolar', 'Cocina Comunitaria',
        'Construcción de Huertas', 'Talleres de Reciclaje', 'Cuidado de Adultos Mayores',
        'Alfabetización Digital', 'Reforestación Urbana', 'Arte y Cultura', 'Deportes Inclusivos',
        'Atención Médica Básica', 'Capacitación Laboral', 'Biblioteca Móvil', 'Mercado Solidario',
        'Huerta Comunitaria', 'Centro de Acopio', 'Taller de Manualidades', 'Brigada de Salud',
        'Campaña de Donación', 'Festival Cultural', 'Maratón Benéfica', 'Feria Educativa',
        'Jornada de Vacunación', 'Taller de Música', 'Centro Recreativo', 'Brigada Veterinaria',
        'Campaña Nutricional', 'Taller de Emprendimiento', 'Jornada de Inclusión'
    ];

    public function run(): void
    {
        $this->command->info('🚀 Iniciando creación de datos masivos...');
        
        // Obtener datos base
        $municipios = Municipio::pluck('id')->toArray();
        $habilidadIds = Habilidad::pluck('id')->toArray();
        $areaIds = AreaImpacto::pluck('id')->toArray();

        // Crear 150 voluntarios en diferentes estados
        $this->command->info('📊 Creando 150 voluntarios...');
        $voluntarios = $this->crearVoluntarios($municipios, $habilidadIds);

        // Crear 40 fundaciones en diferentes estados
        $this->command->info('🏢 Creando 40 fundaciones...');
        $fundaciones = $this->crearFundaciones($municipios, $areaIds);

        // Crear 200 publicaciones variadas
        $this->command->info('📢 Creando 200 publicaciones...');
        $publicaciones = $this->crearPublicaciones($fundaciones, $municipios, $areaIds);

        // Crear postulaciones masivas
        $this->command->info('📝 Creando postulaciones masivas...');
        $this->crearPostulaciones($publicaciones, $voluntarios);

        $this->command->info('✅ ¡Datos masivos creados exitosamente!');
    }

    private function crearVoluntarios(array $municipios, array $habilidadIds): array
    {
        $voluntarios = [];
        $estados = [
            EstadoUsuario::ACTIVO->value => 125,      // 125 activos
            EstadoUsuario::SUSPENDIDO->value => 15,  // 15 suspendidos
            EstadoUsuario::BLOQUEADO->value => 10    // 10 bloqueados
        ];

        $contador = 0;
        foreach ($estados as $estadoValue => $cantidad) {
            for ($i = 0; $i < $cantidad; $i++) {
                $contador++;
                $nombre = $this->voluntariosReales[$contador % count($this->voluntariosReales)];
                $emailName = Str::slug($nombre, '.');
                $domain = $this->emailDomains[array_rand($this->emailDomains)];
                // Agregar timestamp para hacer único el email
                $timestamp = time() + $contador;
                $email = $emailName . $timestamp . '@' . $domain;

                // Convertir de nuevo a enum
                $estado = EstadoUsuario::from($estadoValue);

                $usuario = Usuario::create([
                    'email' => $email,
                    'nombre' => $nombre,
                    'password_hash' => Hash::make('password123'),
                    'rol' => RolUsuario::VOLUNTARIO,
                    'estado' => $estado,
                    'email_verificado' => $estado === EstadoUsuario::ACTIVO, // Solo activos están verificados
                    'provider' => ProveedorAuth::LOCAL,
                ]);

                $voluntario = Voluntario::create([
                    'usuario_id' => $usuario->id,
                    'tipo_documento' => fake()->randomElement([TipoDocumento::CC, TipoDocumento::CE, TipoDocumento::TI]),
                    'numero_documento' => fake()->unique()->numberBetween(10000000, 99999999),
                    'fecha_nacimiento' => fake()->dateTimeBetween('-60 years', '-18 years')->format('Y-m-d'),
                    'genero' => fake()->randomElement([GeneroTipo::MASCULINO, GeneroTipo::FEMENINO, GeneroTipo::OTRO]),
                    'municipio_id' => $municipios[array_rand($municipios)],
                    'disponibilidad' => fake()->randomElement([DisponibilidadTipo::FLEXIBLE, DisponibilidadTipo::FINES_DE_SEMANA, DisponibilidadTipo::ENTRE_SEMANA]),
                    'foto_perfil' => $this->generarAvatarReal($nombre),
                    'esta_verificado' => $estado === EstadoUsuario::ACTIVO ? fake()->boolean(80) : false,
                    // Removed telefono as it doesn't exist in the table
                ]);

                // Asignar habilidades aleatorias (2-5 por voluntario)
                $habilidadesSeleccionadas = fake()->randomElements($habilidadIds, fake()->numberBetween(2, 5));
                $voluntario->habilidades()->sync($habilidadesSeleccionadas);

                $voluntarios[] = $voluntario;
            }
        }

        return $voluntarios;
    }

    private function crearFundaciones(array $municipios, array $areaIds): array
    {
        $fundaciones = [];
        $estados = [
            EstadoVerificacion::APROBADA->value => 25,    // 25 aprobadas
            EstadoVerificacion::PENDIENTE->value => 8,   // 8 pendientes
            EstadoVerificacion::RECHAZADA->value => 4,   // 4 rechazadas
            EstadoVerificacion::SUSPENDIDA->value => 3   // 3 suspendidas
        ];

        $contador = 0;
        foreach ($estados as $estadoValue => $cantidad) {
            for ($i = 0; $i < $cantidad; $i++) {
                $contador++;
                $nombreFundacion = $this->fundacionesReales[$contador % count($this->fundacionesReales)];
                $emailName = Str::slug($nombreFundacion, '.');
                $domain = $this->emailDomains[array_rand($this->emailDomains)];
                // Agregar timestamp para hacer único el email
                $timestamp = time() + $contador + 1000; // +1000 para evitar colisión con voluntarios
                $email = $emailName . $timestamp . '@' . $domain;

                // Convertir de nuevo a enum
                $estado = EstadoVerificacion::from($estadoValue);

                $usuario = Usuario::create([
                    'email' => $email,
                    'nombre' => $nombreFundacion,
                    'password_hash' => Hash::make('password123'),
                    'rol' => RolUsuario::FUNDACION,
                    'estado' => $estado->value === EstadoVerificacion::APROBADA->value ? EstadoUsuario::ACTIVO : EstadoUsuario::SUSPENDIDO,
                    'email_verificado' => true,
                    'provider' => ProveedorAuth::LOCAL,
                ]);

                $fundacion = Fundacion::create([
                    'usuario_id' => $usuario->id,
                    'nombre' => $nombreFundacion,
                    'nit' => fake()->numerify('9########') . '-' . fake()->numberBetween(1, 9),
                    'representante_legal' => fake()->name(),
                    'correo_institucional' => 'info' . $timestamp . '@' . Str::slug($nombreFundacion, '') . '.org',
                    'telefono' => '+57' . fake()->randomElement([1, 2, 4, 5, 8]) . fake()->numberBetween(2000000, 9999999),
                    'direccion' => fake()->address(),
                    'municipio_id' => $municipios[array_rand($municipios)],
                    'descripcion' => fake()->paragraph(3),
                    'documento_legal' => 'documentos/legal-' . $contador . '.pdf',
                    'logo' => $this->generarLogoFundacion($nombreFundacion),
                    'estado_verificacion' => $estado,
                ]);

                // Asignar áreas de impacto (1-3 por fundación)
                $areasSeleccionadas = fake()->randomElements($areaIds, fake()->numberBetween(1, 3));
                $fundacion->areas()->sync($areasSeleccionadas);

                $fundaciones[] = $fundacion;
            }
        }

        return $fundaciones;
    }

    private function crearPublicaciones(array $fundaciones, array $municipios, array $areaIds): array
    {
        $publicaciones = [];
        $modalidades = ['PRESENCIAL', 'VIRTUAL', 'HIBRIDA'];
        $estados = ['PUBLICADA', 'BORRADOR', 'PENDIENTE_APROBACION'];

        // Solo fundaciones aprobadas pueden crear publicaciones
        $fundacionesAprobadas = array_filter($fundaciones, function($f) {
            return $f->estado_verificacion === EstadoVerificacion::APROBADA->value;
        });

        // Solo fundaciones aprobadas pueden crear publicaciones
        $fundacionesAprobadas = array_filter($fundaciones, function($f) {
            return $f->estado_verificacion === EstadoVerificacion::APROBADA;
        });
        
        // Si no hay suficientes fundaciones aprobadas, crear algunas más
        if (count($fundacionesAprobadas) < 5) {
            $this->command->warn("Pocas fundaciones aprobadas (" . count($fundacionesAprobadas) . "), creando más...");
            
            // Crear 10 fundaciones adicionales aprobadas
            for ($i = 0; $i < 10; $i++) {
                $contador = count($fundaciones) + $i + 1;
                $nombreFundacion = $this->fundacionesReales[$contador % count($this->fundacionesReales)];
                $emailName = Str::slug($nombreFundacion, '.');
                $domain = $this->emailDomains[array_rand($this->emailDomains)];
                $timestamp = time() + $contador + 2000;
                $email = $emailName . $timestamp . '@' . $domain;

                $usuario = Usuario::create([
                    'email' => $email,
                    'nombre' => $nombreFundacion,
                    'password_hash' => Hash::make('password123'),
                    'rol' => RolUsuario::FUNDACION,
                    'estado' => EstadoUsuario::ACTIVO,
                    'email_verificado' => true,
                    'provider' => ProveedorAuth::LOCAL,
                ]);

                $fundacion = Fundacion::create([
                    'usuario_id' => $usuario->id,
                    'nombre' => $nombreFundacion,
                    'nit' => fake()->numerify('9########') . '-' . fake()->numberBetween(1, 9),
                    'representante_legal' => fake()->name(),
                    'correo_institucional' => 'info' . $timestamp . '@' . Str::slug($nombreFundacion, '') . '.org',
                    'telefono' => '+57' . fake()->randomElement([1, 2, 4, 5, 8]) . fake()->numberBetween(2000000, 9999999),
                    'direccion' => fake()->address(),
                    'municipio_id' => $municipios[array_rand($municipios)],
                    'descripcion' => fake()->paragraph(3),
                    'documento_legal' => 'documentos/legal-' . $contador . '.pdf',
                    'logo' => $this->generarLogoFundacion($nombreFundacion),
                    'estado_verificacion' => EstadoVerificacion::APROBADA,
                ]);

                $areasSeleccionadas = fake()->randomElements($areaIds, fake()->numberBetween(1, 3));
                $fundacion->areas()->sync($areasSeleccionadas);

                $fundacionesAprobadas[] = $fundacion;
            }
        }

        for ($i = 1; $i <= 200; $i++) {
            $fundacion = $fundacionesAprobadas[array_rand($fundacionesAprobadas)];
            $nombreActividad = $this->nombresActividades[array_rand($this->nombresActividades)];
            
            $fechaInicio = fake()->dateTimeBetween('now', '+3 months');
            $fechaFin = fake()->dateTimeBetween($fechaInicio, $fechaInicio->format('Y-m-d') . ' +30 days');

            $publicacion = Publicacion::create([
                'fundacion_id' => $fundacion->id,
                'titulo' => $nombreActividad . ' - ' . $fundacion->nombre,
                'descripcion' => fake()->paragraphs(3, true),
                'categoria_id' => $areaIds[array_rand($areaIds)],
                'modalidad' => $modalidades[array_rand($modalidades)],
                'municipio_id' => $municipios[array_rand($municipios)],
                'fecha_inicio' => $fechaInicio->format('Y-m-d'),
                'fecha_fin' => $fechaFin->format('Y-m-d'),
                'cupo_maximo' => fake()->numberBetween(10, 100),
                'estado' => $estados[array_rand($estados)], // Selección aleatoria simple
                'dificultad' => fake()->randomElement(['FACIL', 'MEDIA', 'DIFICIL']),
                'direccion_exacta' => fake()->address(),
            ]);

            $publicaciones[] = $publicacion;
        }

        return $publicaciones;
    }

    private function crearPostulaciones(array $publicaciones, array $voluntarios): void
    {
        // Solo voluntarios activos pueden postularse
        $voluntariosActivos = array_filter($voluntarios, function($v) {
            return $v->usuario->estado === EstadoUsuario::ACTIVO;
        });

        $estadosPostulacion = ['PENDIENTE', 'ACEPTADO', 'RECHAZADO', 'RETIRADO', 'ASISTIO', 'NO_ASISTIO'];

        foreach ($publicaciones as $publicacion) {
            // Cada publicación tendrá entre 5 y 25 postulaciones
            $numPostulaciones = fake()->numberBetween(5, 25);
            $voluntariosSeleccionados = fake()->randomElements($voluntariosActivos, $numPostulaciones);

            foreach ($voluntariosSeleccionados as $voluntario) {
                $estado = fake()->randomElement($estadosPostulacion);
                
                Postulacion::create([
                    'publicacion_id' => $publicacion->id,
                    'voluntario_id' => $voluntario->id,
                    'estado' => $estado,
                    'mensaje_voluntario' => fake()->boolean(70) ? fake()->sentence() : null,
                    'motivo_rechazo' => $estado === 'RECHAZADO' && fake()->boolean(80) ? fake()->sentence() : null,
                    // Solo dar calificación si asistió
                    'calificacion' => $estado === 'ASISTIO' && fake()->boolean(70) ? fake()->numberBetween(1, 5) : null,
                    'comentario_fundacion' => in_array($estado, ['ACEPTADO', 'RECHAZADO', 'ASISTIO', 'NO_ASISTIO']) && fake()->boolean(40) ? fake()->sentence() : null,
                ]);
            }
        }
    }

    private function generarAvatarReal(string $nombre): string
    {
        // URLs de avatares realistas usando diferentes servicios
        $servicios = [
            'https://ui-avatars.com/api/?name=' . urlencode($nombre) . '&background=random&color=fff&size=200',
            'https://api.dicebear.com/7.x/avataaars/png?seed=' . urlencode($nombre),
            'https://api.dicebear.com/7.x/personas/png?seed=' . urlencode($nombre),
            'https://robohash.org/' . urlencode($nombre) . '?set=set4&size=200x200',
        ];
        
        return $servicios[array_rand($servicios)];
    }

    private function generarLogoFundacion(string $nombre): string
    {
        // URLs de logos para fundaciones
        $servicios = [
            'https://ui-avatars.com/api/?name=' . urlencode($nombre) . '&background=2563eb&color=fff&size=200&format=png',
            'https://api.dicebear.com/7.x/initials/png?seed=' . urlencode($nombre) . '&backgroundColor=2563eb',
            'https://api.dicebear.com/7.x/shapes/png?seed=' . urlencode($nombre),
        ];
        
        return $servicios[array_rand($servicios)];
    }
}
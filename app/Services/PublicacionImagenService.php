<?php

namespace App\Services;

use App\Models\Publicacion;
use App\Models\PublicacionImagen;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;

class PublicacionImagenService
{
    private const MAX_IMAGENES = 5;
    private const MAX_SIZE_KB  = 5120; // 5 MB
    private const MIME_TYPES   = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];

    public function subir(Publicacion $publicacion, array $archivos): array
    {
        $actuales = $publicacion->imagenes()->count();
        $nuevas   = count($archivos);

        if ($actuales + $nuevas > self::MAX_IMAGENES) {
            throw ValidationException::withMessages([
                'imagenes' => 'Máximo ' . self::MAX_IMAGENES . ' imágenes por convocatoria. Actualmente tienes ' . $actuales . '.',
            ]);
        }

        $creadas = [];
        $orden   = $actuales;

        foreach ($archivos as $archivo) {
            $this->validarArchivo($archivo);
            $ruta = $archivo->store("publicaciones/{$publicacion->id}", 'public');

            $creadas[] = PublicacionImagen::create([
                'publicacion_id' => $publicacion->id,
                'ruta'           => $ruta,
                'orden'          => $orden++,
            ]);
        }

        // Mantener compatibilidad: primera imagen como campo legacy
        if (!$publicacion->imagen && !empty($creadas)) {
            $publicacion->update(['imagen' => '/storage/' . ltrim($creadas[0]->ruta, '/')]);
        }

        return $creadas;
    }

    public function eliminar(Publicacion $publicacion, PublicacionImagen $imagen): void
    {
        if ($imagen->publicacion_id !== $publicacion->id) {
            throw ValidationException::withMessages(['imagen' => 'Imagen no pertenece a esta convocatoria.']);
        }

        Storage::disk('public')->delete($imagen->ruta);
        $imagen->delete();

        // Reordenar
        $publicacion->imagenes()->orderBy('orden')->get()->each(function ($img, $idx) {
            $img->update(['orden' => $idx]);
        });

        $primera = $publicacion->imagenes()->first();
        $publicacion->update(['imagen' => $primera ? '/storage/' . ltrim($primera->ruta, '/') : null]);
    }

    private function validarArchivo(UploadedFile $archivo): void
    {
        if (!in_array($archivo->getMimeType(), self::MIME_TYPES, true)) {
            throw ValidationException::withMessages(['imagenes' => 'Formato no permitido. Usa JPG, PNG, WEBP o GIF.']);
        }
        if ($archivo->getSize() > self::MAX_SIZE_KB * 1024) {
            throw ValidationException::withMessages(['imagenes' => 'Cada imagen debe pesar máximo 5 MB.']);
        }
    }
}

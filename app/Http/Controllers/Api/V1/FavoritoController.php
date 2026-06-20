<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\FavoritoResource;
use App\Models\VoluntarioFavorito;
use App\Services\FavoritoService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FavoritoController extends Controller
{
    public function __construct(private FavoritoService $favoritoService) {}

    /** GET /api/v1/voluntario/favoritos */
    public function index(Request $request): JsonResponse
    {
        $voluntario = $request->user()->voluntario()->firstOrFail();
        $tipo       = $request->get('tipo');

        $favoritos = $this->favoritoService->listar($voluntario, $tipo);

        return response()->json(FavoritoResource::collection($favoritos));
    }

    /** GET /api/v1/voluntario/favoritos/ids */
    public function ids(Request $request): JsonResponse
    {
        $voluntario = $request->user()->voluntario()->firstOrFail();
        return response()->json($this->favoritoService->idsPorTipo($voluntario));
    }

    /** POST /api/v1/voluntario/favoritos/publicacion/{publicacion} */
    public function togglePublicacion(Request $request, string $publicacionId): JsonResponse
    {
        $voluntario = $request->user()->voluntario()->firstOrFail();
        return response()->json($this->favoritoService->togglePublicacion($voluntario, $publicacionId));
    }

    /** POST /api/v1/voluntario/favoritos/fundacion/{fundacion} */
    public function toggleFundacion(Request $request, string $fundacionId): JsonResponse
    {
        $voluntario = $request->user()->voluntario()->firstOrFail();
        $favorito   = VoluntarioFavorito::where('voluntario_id', $voluntario->id)
            ->where('fundacion_id', $fundacionId)
            ->first();

        if ($favorito) {
            $this->favoritoService->quitar($voluntario, $favorito);
            return response()->json(['favorito' => false]);
        }

        $this->favoritoService->agregarFundacion($voluntario, $fundacionId);
        return response()->json(['favorito' => true]);
    }

    /** DELETE /api/v1/voluntario/favoritos/{favorito} */
    public function destroy(Request $request, VoluntarioFavorito $favorito): JsonResponse
    {
        $voluntario = $request->user()->voluntario()->firstOrFail();
        $this->favoritoService->quitar($voluntario, $favorito);
        return response()->json(['message' => 'Eliminado de favoritos.']);
    }
}

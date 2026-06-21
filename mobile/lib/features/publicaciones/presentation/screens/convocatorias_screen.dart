import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voluntapp_mobile/app/router/app_router.dart';
import 'package:voluntapp_mobile/app/theme/app_colors.dart';
import 'package:voluntapp_mobile/core/models/paginated_response.dart';
import 'package:voluntapp_mobile/core/network/api_exception.dart';
import 'package:voluntapp_mobile/features/auth/presentation/providers/auth_notifier.dart';
import 'package:voluntapp_mobile/features/catalog/data/models/catalog_models.dart';
import 'package:voluntapp_mobile/features/catalog/data/repositories/catalog_repository.dart';
import 'package:voluntapp_mobile/features/favoritos/presentation/providers/favoritos_provider.dart';
import 'package:voluntapp_mobile/features/postulaciones/data/models/postulacion.dart';
import 'package:voluntapp_mobile/features/postulaciones/data/repositories/postulacion_repository.dart';
import 'package:voluntapp_mobile/features/publicaciones/data/models/publicacion.dart';
import 'package:voluntapp_mobile/features/publicaciones/data/repositories/publicacion_repository.dart';
import 'package:voluntapp_mobile/features/publicaciones/presentation/widgets/image_carousel.dart';
import 'package:voluntapp_mobile/features/publicaciones/presentation/widgets/publicacion_card.dart';
import 'package:voluntapp_mobile/features/voluntario/presentation/utils/dashboard_formatters.dart';

/// Screen 07 — Actividades disponibles (Convocatorias)
class ConvocatoriasScreen extends ConsumerStatefulWidget {
  const ConvocatoriasScreen({super.key});

  @override
  ConsumerState<ConvocatoriasScreen> createState() => _ConvocatoriasScreenState();
}

class _ConvocatoriasScreenState extends ConsumerState<ConvocatoriasScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  PublicacionFilters _filters = const PublicacionFilters();
  List<Publicacion> _items = [];
  PaginationMeta? _meta;
  List<Postulacion> _misPostulaciones = [];

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  Timer? _debounce;

  int? _filtroDepartamentoId;
  List<Municipio> _municipiosFiltro = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _init();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await Future.wait([
      ref.read(catalogRepositoryProvider).getAreasImpacto(),
      ref.read(catalogRepositoryProvider).getDepartamentos(),
      ref.read(favoritosNotifierProvider.notifier).loadIds(),
    ]);
    await _loadPostulaciones();
    await _load(page: 1, replace: true);
  }

  Future<void> _loadPostulaciones() async {
    try {
      _misPostulaciones =
          await ref.read(postulacionRepositoryProvider).fetchMisPostulacionesActivas();
    } catch (_) {}
  }

  void _onScroll() {
    if (_loadingMore || _loading || _meta == null || !_meta!.hasMore) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _load(page: _meta!.currentPage + 1);
    }
  }

  Future<void> _load({required int page, bool replace = false}) async {
    if (replace) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final result = await ref.read(publicacionRepositoryProvider).fetchPublicaciones(
            filters: _filters,
            page: page,
          );
      if (!mounted) return;
      setState(() {
        if (replace) {
          _items = result.data;
        } else {
          _items = [..._items, ...result.data];
        }
        _meta = result.meta;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e is ApiException ? e.message : 'Error al cargar convocatorias.');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _filters = _filters.copyWith(buscar: value);
      _load(page: 1, replace: true);
    });
  }

  bool _yaPostulado(String publicacionId) {
    return _misPostulaciones.any((p) {
      final pubId = p.publicacionId ?? p.publicacion?.id;
      return pubId == publicacionId && p.activa;
    });
  }

  Future<void> _openFilters() async {
    final areas = await ref.read(areasImpactoProvider.future);
    final departamentos = await ref.read(departamentosProvider.future);

    if (!mounted) return;

    var localFilters = _filters;
    var deptId = _filtroDepartamentoId;
    var municipios = _municipiosFiltro;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Filtros', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int?>(
                    initialValue: localFilters.categoriaId,
                    decoration: const InputDecoration(labelText: 'Área de impacto'),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Todas')),
                      ...areas.map((a) => DropdownMenuItem(value: a.id, child: Text(a.nombre))),
                    ],
                    onChanged: (v) => setModalState(() {
                      localFilters = localFilters.copyWith(categoriaId: v, clearCategoria: v == null);
                    }),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: localFilters.modalidad,
                    decoration: const InputDecoration(labelText: 'Modalidad'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Todas')),
                      DropdownMenuItem(value: 'PRESENCIAL', child: Text('Presencial')),
                      DropdownMenuItem(value: 'VIRTUAL', child: Text('Virtual')),
                      DropdownMenuItem(value: 'HIBRIDA', child: Text('Híbrida')),
                    ],
                    onChanged: (v) => setModalState(() {
                      localFilters = localFilters.copyWith(
                        modalidad: v,
                        clearModalidad: v == null,
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    initialValue: deptId,
                    decoration: const InputDecoration(labelText: 'Departamento'),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Todos')),
                      ...departamentos.map((d) => DropdownMenuItem(value: d.id, child: Text(d.nombre))),
                    ],
                    onChanged: (v) async {
                      deptId = v;
                      localFilters = localFilters.copyWith(clearMunicipio: true);
                      municipios = v == null
                          ? []
                          : await ref.read(catalogRepositoryProvider).getMunicipios(v);
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    initialValue: localFilters.municipioId,
                    decoration: const InputDecoration(labelText: 'Municipio'),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Todos')),
                      ...municipios.map((m) => DropdownMenuItem(value: m.id, child: Text(m.nombre))),
                    ],
                    onChanged: deptId == null
                        ? null
                        : (v) => setModalState(() {
                              localFilters = localFilters.copyWith(
                                municipioId: v,
                                clearMunicipio: v == null,
                              );
                            }),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            localFilters = const PublicacionFilters();
                            deptId = null;
                            municipios = [];
                            setModalState(() {});
                          },
                          child: const Text('Limpiar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            setState(() {
                              _filters = localFilters;
                              _filtroDepartamentoId = deptId;
                              _municipiosFiltro = municipios;
                            });
                            _load(page: 1, replace: true);
                          },
                          child: const Text('Aplicar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showDetalle(Publicacion pub, {bool postularDirecto = false}) async {
    final mensajeController = TextEditingController();
    var postulando = false;
    var error = '';
    var success = '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final yaPostulado = _yaPostulado(pub.id);

            Future<void> confirmar() async {
              setSheetState(() {
                postulando = true;
                error = '';
              });
              try {
                await ref.read(postulacionRepositoryProvider).postular(
                      publicacionId: pub.id,
                      mensajeVoluntario: mensajeController.text.trim().isEmpty
                          ? null
                          : mensajeController.text.trim(),
                    );
                await _loadPostulaciones();
                setSheetState(() => success = '¡Te has postulado exitosamente!');
              } on ValidationException catch (e) {
                setSheetState(() => error = e.errors.values.firstOrNull ?? e.message);
              } on ApiException catch (e) {
                setSheetState(() => error = e.message);
              } catch (_) {
                setSheetState(() => error = 'Error al postularse.');
              } finally {
                setSheetState(() => postulando = false);
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(pub.titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    ImageCarousel(urls: pub.imageUrls),
                    const SizedBox(height: 12),
                    if (pub.fundacionNombre != null) Text('Fundación: ${pub.fundacionNombre}'),
                    Text('Modalidad: ${pub.modalidad}'),
                    Text('Inicio: ${formatShortDate(pub.fechaInicio)}'),
                    Text('Fin: ${formatShortDate(pub.fechaFin)}'),
                    if (pub.cupoMaximo != null) Text('Cupos: ${pub.cupoMaximo}'),
                    if (pub.municipio != null)
                      Text('Lugar: ${pub.municipio!.nombre}, ${pub.municipio!.departamento?.nombre ?? ''}'),
                    const SizedBox(height: 12),
                    Text(pub.descripcion),
                    if (error.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(error, style: const TextStyle(color: AppColors.danger)),
                      ),
                    if (success.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(success, style: const TextStyle(color: AppColors.success)),
                      ),
                    if (!yaPostulado && success.isEmpty) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: mensajeController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Mensaje (opcional)',
                          hintText: '¿Por qué quieres participar?',
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: postulando ? null : confirmar,
                        child: postulando
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Confirmar postulación'),
                      ),
                    ] else if (yaPostulado)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text('✓ Ya estás postulado', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    mensajeController.dispose();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final favoritos = ref.watch(favoritosNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Actividades'),
        actions: [
          IconButton(icon: const Icon(Icons.tune), onPressed: _openFilters, tooltip: 'Filtros'),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar convocatorias…',
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          if (_meta != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_meta!.total} convocatoria${_meta!.total == 1 ? '' : 's'}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
            ),
          Expanded(
            child: _loading && _items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _items.isEmpty
                    ? Center(child: Text(_error!))
                    : _items.isEmpty
                        ? const Center(child: Text('Sin resultados. Prueba otros filtros.'))
                        : RefreshIndicator(
                            onRefresh: () async {
                              await _loadPostulaciones();
                              await _load(page: 1, replace: true);
                            },
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: _items.length + (_loadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index >= _items.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }
                                final pub = _items[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: PublicacionCard(
                                    publicacion: pub,
                                    esFavorito: favoritos.esFavoritoPublicacion(pub.id),
                                    yaPostulado: _yaPostulado(pub.id),
                                    onTap: () => _showDetalle(pub),
                                    onToggleFavorito: () =>
                                        ref.read(favoritosNotifierProvider.notifier).togglePublicacion(pub.id),
                                    onPostular: () => _showDetalle(pub, postularDirecto: true),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

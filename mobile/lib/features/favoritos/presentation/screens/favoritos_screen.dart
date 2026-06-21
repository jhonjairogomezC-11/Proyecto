import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voluntapp_mobile/app/router/app_router.dart';
import 'package:voluntapp_mobile/app/theme/app_colors.dart';
import 'package:voluntapp_mobile/core/network/api_exception.dart';
import 'package:voluntapp_mobile/features/favoritos/data/models/favorito.dart';
import 'package:voluntapp_mobile/features/favoritos/data/repositories/favorito_repository.dart';
import 'package:voluntapp_mobile/features/favoritos/presentation/providers/favoritos_provider.dart';
import 'package:voluntapp_mobile/features/notificaciones/presentation/widgets/notificacion_app_bar_action.dart';
import 'package:voluntapp_mobile/features/publicaciones/presentation/widgets/publicacion_card.dart';

/// Screen 09 — Favoritos
class FavoritosScreen extends ConsumerStatefulWidget {
  const FavoritosScreen({super.key});

  @override
  ConsumerState<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends ConsumerState<FavoritosScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<Favorito> _items = [];
  bool _loading = true;
  String? _error;
  String? _removingId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Favorito> get _actividades =>
      _items.where((f) => f.esPublicacion).toList();
  List<Favorito> get _fundaciones =>
      _items.where((f) => f.esFundacion).toList();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ref.read(favoritoRepositoryProvider).fetchAll();
      await ref.read(favoritosNotifierProvider.notifier).loadIds();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error =
          e is ApiException ? e.message : 'Error al cargar favoritos.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _quitar(Favorito fav) async {
    setState(() => _removingId = fav.id);
    try {
      await ref.read(favoritoRepositoryProvider).remove(fav.id);
      final notifier = ref.read(favoritosNotifierProvider.notifier);
      if (fav.esPublicacion && fav.publicacion != null) {
        notifier.removePublicacionLocal(fav.publicacion!.id);
      } else if (fav.esFundacion && fav.fundacion != null) {
        notifier.removeFundacionLocal(fav.fundacion!.id);
      }
      if (!mounted) return;
      setState(() => _items = _items.where((i) => i.id != fav.id).toList());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e is ApiException
                ? e.message
                : 'No se pudo quitar el favorito.')),
      );
    } finally {
      if (mounted) setState(() => _removingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoritos'),
        actions: const [NotificacionAppBarAction()],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Actividades (${_actividades.length})'),
            Tab(text: 'Fundaciones (${_fundaciones.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      FilledButton(
                          onPressed: _load, child: const Text('Reintentar')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _ActividadesTab(
                        items: _actividades,
                        removingId: _removingId,
                        onQuitar: _quitar,
                        onExplorar: () =>
                            context.go(AppRoutes.voluntarioActividades),
                      ),
                      _FundacionesTab(
                        items: _fundaciones,
                        removingId: _removingId,
                        onQuitar: _quitar,
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _ActividadesTab extends StatelessWidget {
  const _ActividadesTab({
    required this.items,
    required this.removingId,
    required this.onQuitar,
    required this.onExplorar,
  });

  final List<Favorito> items;
  final String? removingId;
  final ValueChanged<Favorito> onQuitar;
  final VoidCallback onExplorar;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.favorite_border,
              size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          const Text(
            'Sin actividades favoritas',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Marca con el corazón las convocatorias que te interesen.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          FilledButton(
              onPressed: onExplorar,
              child: const Text('Explorar convocatorias')),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final fav = items[index];
        final pub = fav.publicacion;
        if (pub == null) return const SizedBox.shrink();

        return PublicacionCard(
          publicacion: pub,
          esFavorito: true,
          yaPostulado: false,
          onTap: onExplorar,
          onToggleFavorito: removingId == fav.id ? () {} : () => onQuitar(fav),
          onPostular: onExplorar,
        );
      },
    );
  }
}

class _FundacionesTab extends StatelessWidget {
  const _FundacionesTab({
    required this.items,
    required this.removingId,
    required this.onQuitar,
  });

  final List<Favorito> items;
  final String? removingId;
  final ValueChanged<Favorito> onQuitar;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [
          Icon(Icons.business_outlined,
              size: 48, color: AppColors.textSecondary),
          SizedBox(height: 16),
          Text(
            'Sin fundaciones favoritas',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Text(
            'Guarda fundaciones desde las convocatorias para seguirlas.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final fav = items[index];
        final fund = fav.fundacion;
        if (fund == null) return const SizedBox.shrink();

        final initial =
            fund.nombre.isNotEmpty ? fund.nombre[0].toUpperCase() : '?';

        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text(initial)),
            title: Text(fund.nombre,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(fund.municipio?.nombre ?? 'Colombia'),
            trailing: IconButton(
              onPressed: removingId == fav.id ? null : () => onQuitar(fav),
              icon: removingId == fav.id
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.favorite, color: AppColors.danger),
            ),
          ),
        );
      },
    );
  }
}

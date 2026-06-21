import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voluntapp_mobile/features/favoritos/data/repositories/favorito_repository.dart';

class FavoritosState {
  const FavoritosState({
    this.publicacionIds = const {},
    this.fundacionIds = const {},
    this.loaded = false,
  });

  final Set<String> publicacionIds;
  final Set<String> fundacionIds;
  final bool loaded;

  FavoritosState copyWith({
    Set<String>? publicacionIds,
    Set<String>? fundacionIds,
    bool? loaded,
  }) {
    return FavoritosState(
      publicacionIds: publicacionIds ?? this.publicacionIds,
      fundacionIds: fundacionIds ?? this.fundacionIds,
      loaded: loaded ?? this.loaded,
    );
  }

  bool esFavoritoPublicacion(String id) => publicacionIds.contains(id);
  bool esFavoritoFundacion(String id) => fundacionIds.contains(id);
}

class FavoritosNotifier extends StateNotifier<FavoritosState> {
  FavoritosNotifier(this._ref) : super(const FavoritosState());

  final Ref _ref;

  Future<void> loadIds() async {
    final repo = _ref.read(favoritoRepositoryProvider);
    final ids = await repo.fetchIds();
    state = FavoritosState(
      publicacionIds: ids.publicaciones.toSet(),
      fundacionIds: ids.fundaciones.toSet(),
      loaded: true,
    );
  }

  Future<bool> togglePublicacion(String id) async {
    final repo = _ref.read(favoritoRepositoryProvider);
    final favorito = await repo.togglePublicacion(id);
    final next = Set<String>.from(state.publicacionIds);
    if (favorito) {
      next.add(id);
    } else {
      next.remove(id);
    }
    state = state.copyWith(publicacionIds: next);
    return favorito;
  }

  Future<bool> toggleFundacion(String id) async {
    final repo = _ref.read(favoritoRepositoryProvider);
    final favorito = await repo.toggleFundacion(id);
    final next = Set<String>.from(state.fundacionIds);
    if (favorito) {
      next.add(id);
    } else {
      next.remove(id);
    }
    state = state.copyWith(fundacionIds: next);
    return favorito;
  }

  void removePublicacionLocal(String id) {
    final next = Set<String>.from(state.publicacionIds)..remove(id);
    state = state.copyWith(publicacionIds: next);
  }

  void removeFundacionLocal(String id) {
    final next = Set<String>.from(state.fundacionIds)..remove(id);
    state = state.copyWith(fundacionIds: next);
  }
}

final favoritosNotifierProvider =
    StateNotifierProvider<FavoritosNotifier, FavoritosState>((ref) {
  return FavoritosNotifier(ref);
});

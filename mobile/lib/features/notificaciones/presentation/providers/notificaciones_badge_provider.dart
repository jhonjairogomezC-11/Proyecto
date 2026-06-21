import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voluntapp_mobile/features/auth/presentation/providers/auth_notifier.dart';
import 'package:voluntapp_mobile/features/notificaciones/data/repositories/notificacion_repository.dart';

class NotificacionesBadgeNotifier extends StateNotifier<int> {
  NotificacionesBadgeNotifier(this._ref) : super(0);

  final Ref _ref;
  Timer? _timer;

  Future<void> refresh() async {
    if (_ref.read(authNotifierProvider).status != AuthStatus.authenticated) {
      state = 0;
      return;
    }
    try {
      final total =
          await _ref.read(notificacionRepositoryProvider).fetchNoLeidas();
      state = total;
    } catch (_) {
      // Silencioso: el badge no debe bloquear la app.
    }
  }

  void startPolling() {
    _timer?.cancel();
    unawaited(refresh());
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => refresh());
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  void decrement([int n = 1]) {
    state = (state - n).clamp(0, 999);
  }

  void reset() => state = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final notificacionesBadgeProvider =
    StateNotifierProvider<NotificacionesBadgeNotifier, int>((ref) {
  final notifier = NotificacionesBadgeNotifier(ref);

  ref.listen(authNotifierProvider, (previous, next) {
    if (next.status == AuthStatus.authenticated) {
      notifier.startPolling();
    } else {
      notifier.stopPolling();
      notifier.reset();
    }
  }, fireImmediately: true);

  return notifier;
});

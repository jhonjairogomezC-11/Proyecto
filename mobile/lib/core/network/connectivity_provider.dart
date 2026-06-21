import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectivityNotifier extends Notifier<bool> {
  @override
  bool build() {
    _listen();
    _checkInitial();
    return true;
  }

  Future<void> _checkInitial() async {
    final results = await Connectivity().checkConnectivity();
    state = _isOnline(results);
  }

  void _listen() {
    Connectivity().onConnectivityChanged.listen((results) {
      state = _isOnline(results);
    });
  }

  bool _isOnline(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) => r != ConnectivityResult.none);
  }
}

final connectivityProvider =
    NotifierProvider<ConnectivityNotifier, bool>(ConnectivityNotifier.new);

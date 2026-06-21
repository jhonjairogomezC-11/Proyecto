import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:voluntapp_mobile/features/auth/domain/entities/usuario.dart';

/// Datos de sesión no sensibles (usuario serializado).
class SessionStorage {
  SessionStorage(this._prefs);

  final SharedPreferences _prefs;

  static const _userKey = 'auth_user';

  Future<Usuario?> getUser() async {
    final raw = _prefs.getString(_userKey);
    if (raw == null) return null;
    try {
      return Usuario.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUser(Usuario user) async {
    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> clearUser() async {
    await _prefs.remove(_userKey);
  }

  Future<void> clearAll() async {
    await clearUser();
  }
}

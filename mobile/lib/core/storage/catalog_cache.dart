import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

/// Cache local de catálogos (Sprint 3).
class CatalogCache {
  CatalogCache._();

  static const _boxName = 'catalog_cache';
  static const departamentosKey = 'departamentos';
  static const habilidadesKey = 'habilidades';
  static const interesesKey = 'intereses';

  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<String>(_boxName);
    }
  }

  static Box<String> get _box => Hive.box<String>(_boxName);

  static List<Map<String, dynamic>>? readList(String key) {
    final raw = _box.get(key);
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! List) return null;
    return decoded.cast<Map<String, dynamic>>();
  }

  static Future<void> writeList(String key, List<Map<String, dynamic>> data) {
    return _box.put(key, jsonEncode(data));
  }

  static String municipiosKey(int departamentoId) => 'municipios_$departamentoId';

  static List<Map<String, dynamic>>? readMunicipios(int departamentoId) {
    return readList(municipiosKey(departamentoId));
  }

  static Future<void> writeMunicipios(
    int departamentoId,
    List<Map<String, dynamic>> data,
  ) {
    return writeList(municipiosKey(departamentoId), data);
  }
}

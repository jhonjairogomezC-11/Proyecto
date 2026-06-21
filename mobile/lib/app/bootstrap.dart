import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voluntapp_mobile/app/app.dart';
import 'package:voluntapp_mobile/core/storage/catalog_cache.dart';

/// Arranque compartido entre `main.dart` e integration tests.
Future<void> bootstrapVoluntApp({String? hivePath}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await CatalogCache.init(hivePath: hivePath);
  runApp(const ProviderScope(child: VoluntApp()));
}

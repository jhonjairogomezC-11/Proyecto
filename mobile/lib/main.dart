import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voluntapp_mobile/app/app.dart';
import 'package:voluntapp_mobile/core/storage/catalog_cache.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CatalogCache.init();
  runApp(const ProviderScope(child: VoluntApp()));
}

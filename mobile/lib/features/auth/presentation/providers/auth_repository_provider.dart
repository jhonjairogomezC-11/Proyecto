import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voluntapp_mobile/features/auth/data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref);
});

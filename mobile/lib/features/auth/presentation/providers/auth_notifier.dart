import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voluntapp_mobile/core/constants/api_constants.dart';
import 'package:voluntapp_mobile/core/network/api_exception.dart';
import 'package:voluntapp_mobile/core/providers/core_providers.dart';
import 'package:voluntapp_mobile/core/storage/secure_token_storage.dart';
import 'package:voluntapp_mobile/core/storage/session_storage.dart';
import 'package:voluntapp_mobile/features/auth/data/models/auth_session.dart';
import 'package:voluntapp_mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:voluntapp_mobile/features/auth/domain/entities/usuario.dart';
import 'package:voluntapp_mobile/features/auth/presentation/providers/auth_repository_provider.dart';

enum AuthStatus { initial, authenticated, unauthenticated, blocked }

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.usuario,
    this.blockedMessage,
  });

  final AuthStatus status;
  final Usuario? usuario;
  final String? blockedMessage;

  AuthState copyWith({
    AuthStatus? status,
    Usuario? usuario,
    String? blockedMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      usuario: usuario ?? this.usuario,
      blockedMessage: blockedMessage ?? this.blockedMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(
    this._tokenStorage,
    this._sessionStorageFuture,
    this._ref,
    this._authRepository,
  ) : super(const AuthState());

  final SecureTokenStorage _tokenStorage;
  final Future<SessionStorage> _sessionStorageFuture;
  final Ref _ref;
  final AuthRepository _authRepository;

  Future<void> bootstrap() async {
    final token = await _tokenStorage.getAccessToken();
    final sessionStorage = await _sessionStorageFuture;
    final user = await sessionStorage.getUser();

    if (token == null || user == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    if (user.isSuspendido) {
      await clearSession();
      state = const AuthState(
        status: AuthStatus.blocked,
        blockedMessage:
            'Tu cuenta ha sido suspendida. Contacta al administrador.',
      );
      return;
    }

    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.get<Map<String, dynamic>>(ApiConstants.authMe);
      final freshUser = Usuario.fromJson(response.data!);

      if (freshUser.isSuspendido) {
        await clearSession();
        state = const AuthState(
          status: AuthStatus.blocked,
          blockedMessage:
              'Tu cuenta ha sido suspendida. Contacta al administrador.',
        );
        return;
      }

      await sessionStorage.saveUser(freshUser);
      state = AuthState(status: AuthStatus.authenticated, usuario: freshUser);
    } catch (e) {
      if (e is ForbiddenException) {
        await clearSession();
        state = AuthState(
          status: AuthStatus.blocked,
          blockedMessage: e.message,
        );
        return;
      }
      state = AuthState(status: AuthStatus.authenticated, usuario: user);
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      final session = await _authRepository.login(
        email: email,
        password: password,
      );
      await setSession(session);
    } on ValidationException catch (e) {
      final suspended =
          e.errors['email']?.toLowerCase().contains('suspendida') ?? false;
      if (suspended) {
        state = AuthState(
          status: AuthStatus.blocked,
          blockedMessage: e.errors['email'],
        );
        return;
      }
      rethrow;
    } on ForbiddenException catch (e) {
      state = AuthState(
        status: AuthStatus.blocked,
        blockedMessage: e.message,
      );
    }
  }

  Future<void> register({
    required String nombre,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String rol,
    String? telefono,
  }) async {
    final session = await _authRepository.register(
      nombre: nombre,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
      rol: rol,
      telefono: telefono,
    );
    await setSession(session);
  }

  Future<void> logout() async {
    try {
      await _authRepository.logout();
    } catch (_) {
      // Token expirado: igual limpiamos sesión local.
    } finally {
      await clearSession();
    }
  }

  Future<String> forgotPassword({required String email}) {
    return _authRepository.forgotPassword(email: email);
  }

  Future<String> resetPassword({
    required String token,
    required String password,
    required String passwordConfirmation,
    String? email,
  }) {
    return _authRepository.resetPassword(
      token: token,
      password: password,
      passwordConfirmation: passwordConfirmation,
      email: email,
    );
  }

  Future<void> setSession(AuthSession session) async {
    await _tokenStorage.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    final sessionStorage = await _sessionStorageFuture;
    await sessionStorage.saveUser(session.usuario);
    state = AuthState(
      status: AuthStatus.authenticated,
      usuario: session.usuario,
    );
  }

  Future<void> clearSession() async {
    await _tokenStorage.clearTokens();
    final sessionStorage = await _sessionStorageFuture;
    await sessionStorage.clearAll();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearBlocked() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(secureTokenStorageProvider),
    ref.watch(sessionStorageProvider.future),
    ref,
    ref.watch(authRepositoryProvider),
  );
});

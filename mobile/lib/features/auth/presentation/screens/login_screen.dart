import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voluntapp_mobile/app/router/app_router.dart';
import 'package:voluntapp_mobile/app/theme/app_colors.dart';
import 'package:voluntapp_mobile/core/network/api_exception.dart';
import 'package:voluntapp_mobile/features/auth/presentation/providers/auth_notifier.dart';
import 'package:voluntapp_mobile/features/auth/presentation/utils/auth_validators.dart';
import 'package:voluntapp_mobile/features/auth/presentation/widgets/auth_alert_banner.dart';
import 'package:voluntapp_mobile/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:voluntapp_mobile/features/auth/presentation/widgets/loading_button.dart';

/// Screen 01 — Login
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  String _error = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      await ref.read(authNotifierProvider.notifier).login(
            email: _emailController.text,
            password: _passwordController.text,
          );

      if (!mounted) return;

      final status = ref.read(authNotifierProvider).status;
      if (status == AuthStatus.blocked) {
        context.go(AppRoutes.blocked);
      } else if (status == AuthStatus.authenticated) {
        context.go(AppRoutes.homeForUser(ref.read(authNotifierProvider).usuario));
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Error al iniciar sesión.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Iniciar sesión',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthErrorBanner(message: _error),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'correo@ejemplo.com',
              ),
              validator: AuthValidators.email,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Contraseña',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) => AuthValidators.requiredField(v, 'La contraseña'),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _loading ? null : () => context.push(AppRoutes.forgotPassword),
                child: const Text('¿Olvidaste tu contraseña?'),
              ),
            ),
            const SizedBox(height: 8),
            LoadingButton(
              label: 'Ingresar',
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('¿No tienes cuenta?', style: TextStyle(color: AppColors.textSecondary)),
                TextButton(
                  onPressed: _loading ? null : () => context.push(AppRoutes.register),
                  child: const Text('Regístrate aquí'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

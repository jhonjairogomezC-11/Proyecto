import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voluntapp_mobile/app/router/app_router.dart';
import 'package:voluntapp_mobile/core/network/api_exception.dart';
import 'package:voluntapp_mobile/features/auth/presentation/providers/auth_notifier.dart';
import 'package:voluntapp_mobile/features/auth/presentation/utils/auth_validators.dart';
import 'package:voluntapp_mobile/features/auth/presentation/widgets/auth_alert_banner.dart';
import 'package:voluntapp_mobile/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:voluntapp_mobile/features/auth/presentation/widgets/loading_button.dart';

/// Screen 04 — Reset Password
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({
    super.key,
    this.token,
    this.email,
  });

  final String? token;
  final String? email;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _error = '';
  String _success = '';

  bool get _hasValidLink =>
      widget.token != null && widget.token!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (!_hasValidLink) {
      _error = 'El enlace de restablecimiento no es válido. Solicita uno nuevo.';
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_hasValidLink || !_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = '';
      _success = '';
    });

    try {
      final message = await ref.read(authNotifierProvider.notifier).resetPassword(
            token: widget.token!,
            password: _passwordController.text,
            passwordConfirmation: _confirmController.text,
            email: widget.email,
          );
      if (mounted) setState(() => _success = message);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Error al restablecer la contraseña.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Restablecer contraseña',
      subtitle: 'Ingresa tu nueva contraseña.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthErrorBanner(message: _error),
            AuthSuccessBanner(message: _success),
            if (_success.isEmpty) ...[
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: 'Nueva contraseña',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: AuthValidators.password,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Confirmar contraseña',
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) =>
                    AuthValidators.passwordConfirmation(v, _passwordController.text),
              ),
              const SizedBox(height: 24),
              LoadingButton(
                label: 'Restablecer contraseña',
                loading: _loading,
                onPressed: _hasValidLink ? _submit : null,
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loading ? null : () => context.go(AppRoutes.login),
              child: const Text('Volver al inicio de sesión'),
            ),
          ],
        ),
      ),
    );
  }
}

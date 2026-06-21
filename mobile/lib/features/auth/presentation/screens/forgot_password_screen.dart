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

/// Screen 03 — Forgot Password
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _loading = false;
  String _error = '';
  String _success = '';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = '';
      _success = '';
    });

    try {
      final message = await ref.read(authNotifierProvider.notifier).forgotPassword(
            email: _emailController.text,
          );
      if (mounted) setState(() => _success = message);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Error al enviar la solicitud.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Recuperar contraseña',
      subtitle: 'Te enviaremos un enlace si el email está registrado.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthErrorBanner(message: _error),
            AuthSuccessBanner(message: _success),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'correo@ejemplo.com',
              ),
              validator: AuthValidators.email,
            ),
            const SizedBox(height: 24),
            LoadingButton(
              label: 'Enviar enlace',
              loading: _loading,
              onPressed: _submit,
            ),
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

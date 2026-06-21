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
import 'package:voluntapp_mobile/features/auth/presentation/widgets/role_selector.dart';

/// Screen 02 — Register
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String _rol = 'VOLUNTARIO';
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _error = '';

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      await ref.read(authNotifierProvider.notifier).register(
            nombre: _nombreController.text,
            email: _emailController.text,
            password: _passwordController.text,
            passwordConfirmation: _confirmController.text,
            rol: _rol,
            telefono: _telefonoController.text,
          );

      if (!mounted) return;
      context.go(AppRoutes.homeForUser(ref.read(authNotifierProvider).usuario));
    } on ValidationException catch (e) {
      if (mounted) {
        setState(() => _error = e.errors.values.firstOrNull ?? e.message);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Error al registrar la cuenta.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Crear cuenta',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthErrorBanner(message: _error),
            const Text('Tipo de cuenta',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            RoleSelector(
                value: _rol, onChanged: (rol) => setState(() => _rol = rol)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nombreController,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                hintText: 'Tu nombre completo',
              ),
              validator: (v) => AuthValidators.requiredField(v, 'El nombre'),
            ),
            const SizedBox(height: 16),
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
              controller: _telefonoController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.telephoneNumber],
              decoration: const InputDecoration(
                labelText: 'Teléfono (opcional)',
                hintText: '+57 300 000 0000',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'Contraseña',
                hintText: 'Mínimo 8 caracteres',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
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
                  icon: Icon(_obscureConfirm
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (v) => AuthValidators.passwordConfirmation(
                  v, _passwordController.text),
            ),
            const SizedBox(height: 24),
            LoadingButton(
              label: 'Crear cuenta',
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('¿Ya tienes cuenta?',
                    style: TextStyle(color: AppColors.textSecondary)),
                TextButton(
                  onPressed: _loading ? null : () => context.pop(),
                  child: const Text('Inicia sesión'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

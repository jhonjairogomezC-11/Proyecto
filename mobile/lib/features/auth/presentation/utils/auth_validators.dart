/// Validaciones client-side alineadas al frontend Vue.
abstract final class AuthValidators {
  static final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El email es obligatorio.';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Ingresa un email válido.';
    }
    return null;
  }

  static String? requiredField(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label es obligatorio.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria.';
    }
    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres.';
    }
    return null;
  }

  static String? passwordConfirmation(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña.';
    }
    if (value != password) {
      return 'Las contraseñas no coinciden.';
    }
    return null;
  }
}

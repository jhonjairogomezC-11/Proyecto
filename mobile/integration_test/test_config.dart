/// Credenciales del DemoSeeder (requiere `php artisan db:seed --class=DemoSeeder`).
abstract final class TestCredentials {
  static const voluntarioEmail = 'voluntario1@demo.com';
  static const fundacionEmail = 'fundacion1@demo.com';
  static const adminEmail = 'admin@voluntapp.co';

  static const demoPassword = 'password';
  static const adminPassword = 'Admin1234!';
}

abstract final class TestTimeouts {
  static const bootstrap = Duration(seconds: 30);
  static const apiAction = Duration(seconds: 20);
  static const pumpStep = Duration(milliseconds: 200);
}

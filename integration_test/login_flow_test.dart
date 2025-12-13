import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pideqr/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Flujo de Login (Integration Test)', () {

    testWidgets('Muestra SnackBar de error al iniciar sesión con contraseña incorrecta',
        (WidgetTester tester) async {
      
      // --- CREDENCIALES ---
      const userEmail = 'q@q.com';
      const wrongPassword = 'contraseña-incorrecta';
      // --------------------

      // 1. Inicia la aplicación
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 2. Encuentra los widgets de la pantalla de login
      print('Verificando la pantalla de login...');
      final emailField = find.byKey(const Key('loginEmailField'));
      final passwordField = find.byKey(const Key('loginPasswordField'));
      final loginButton = find.widgetWithText(ElevatedButton, 'Iniciar Sesión');

      expect(emailField, findsOneWidget);
      expect(passwordField, findsOneWidget);
      expect(loginButton, findsOneWidget);

      // 3. Simula la entrada de datos y el tap
      print('Iniciando sesión con contraseña incorrecta...');
      await tester.enterText(emailField, userEmail);
      await tester.enterText(passwordField, wrongPassword);
      await tester.tap(loginButton);
      
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 4. Verificación del resultado
      print('Verificando que aparece el SnackBar de error...');
      
      expect(find.byType(SnackBar), findsOneWidget);
      // --- CORRECCIÓN: Se usa el mensaje de error exacto del ErrorTranslator ---
      expect(find.text('Correo o contraseña incorrectos. Por favor, inténtalo de nuevo.'), findsOneWidget);

      print('Verificando que seguimos en la pantalla de login...');
      expect(loginButton, findsOneWidget);

      print('¡Test de login fallido completado con éxito!');
    });
  });
}

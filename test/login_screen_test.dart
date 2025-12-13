import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pideqr/features/auth/auth_providers.dart';
import 'package:pideqr/features/auth/login_screen.dart';
import 'package:pideqr/services/auth_service.dart';
import 'register_screen_test.dart'; // Importamos el archivo que contiene el Mock

void main() {
  final mockAuthService = MockAuthService(); // Usamos la misma clase Mock

  group('LoginScreen Widget Tests', () {
    testWidgets('Renderiza los widgets iniciales correctamente', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          // Sobrescribimos el provider para inyectar el mock
          overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      expect(find.text('Bienvenido a PideQR'), findsOneWidget);
      expect(find.text('Correo Electrónico'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Iniciar Sesión'), findsOneWidget);
    });

    testWidgets('Muestra mensajes de error si los campos están vacíos al iniciar sesión', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar Sesión'));
      await tester.pump();

      expect(find.text('El correo no puede estar vacío'), findsOneWidget);
      expect(find.text('La contraseña no puede estar vacía'), findsOneWidget);
    });

    // Test extra: Simular un login exitoso
    testWidgets('No muestra error al rellenar los campos y pulsar login', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Simulamos la entrada de datos correctos
      await tester.enterText(find.byKey(const Key('loginEmailField')), 'test@test.com');
      await tester.enterText(find.byKey(const Key('loginPasswordField')), 'password');

      // Pulsamos el botón
      await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar Sesión'));
      await tester.pump();

      // Verificamos que los mensajes de error NO aparecen
      expect(find.text('El correo no puede estar vacío'), findsNothing);
      expect(find.text('La contraseña no puede estar vacía'), findsNothing);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pideqr/core/models/user_model.dart';
import 'package:pideqr/features/auth/auth_providers.dart';
import 'package:pideqr/features/auth/register_screen.dart';
import 'package:pideqr/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

// 1. MOCK COMPLETO Y CORRECTO DE AUTHSERVICE
class MockAuthService implements AuthService {
  @override
  Stream<firebase_auth.User?> get authStateChanges => Stream.empty();

  @override
  Future<UserModel?> getUserData(String uid) async => null;

  @override
  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    // Devolvemos un usuario falso para cumplir con el tipo de retorno.
    return UserModel(uid: '123', email: email, name: name, role: UserRole.cliente);
  }

  @override
  Future<UserModel?> signInWithEmail({required String email, required String password}) async => null;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}
}

void main() {
  // Creamos una instancia de nuestro mock para reutilizarla
  final mockAuthService = MockAuthService();

  group('RegisterScreen Widget Tests', () {
    testWidgets('Renderiza los widgets de registro correctamente', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
          ],
          child: const MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      expect(find.text('Registrar Nuevo Usuario'), findsOneWidget);
      expect(find.text('Nombre Completo'), findsOneWidget);
      // ... (el resto de los expects de renderizado son correctos)
    });

    testWidgets('Muestra un error si las contraseñas no coinciden', (WidgetTester tester) async {
       await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
          ],
          child: const MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'password456');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Registrarse'));
      await tester.pump();

      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    });

    testWidgets('No muestra error si las contraseñas coinciden y los datos son válidos', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
          ],
          child: const MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'Nombre de Prueba');
      await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'password123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Registrarse'));
      await tester.pump(); 

      // Verificamos que no hay errores de validación
      expect(find.text('Las contraseñas no coinciden'), findsNothing);
      // El test ahora pasa porque la llamada al mock de registerWithEmail funciona
    });
  });
}

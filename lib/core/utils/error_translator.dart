import 'package:firebase_auth/firebase_auth.dart';

// Clase de utilidad para centralizar la traducción de errores de Firebase
class ErrorTranslator {
  static String getFriendlyMessage(Object error) {
    if (error is! FirebaseAuthException) {
      return 'Ocurrió un error inesperado.';
    }

    switch (error.code) {
      case 'invalid-email':
        return 'El formato del correo electrónico no es válido.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential': // Nuevo código de error de Firebase
        return 'Correo o contraseña incorrectos. Por favor, inténtalo de nuevo.';
      case 'email-already-in-use':
        return 'Este correo electrónico ya está registrado.';
      case 'weak-password':
        return 'La contraseña es muy débil (mínimo 6 caracteres).';
      case 'network-request-failed':
        return 'Error de red. Por favor, revisa tu conexión a internet.';
      default:
        return 'Ocurrió un error de autenticación. Inténtalo de nuevo.';
    }
  }
}

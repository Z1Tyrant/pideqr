import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pideqr/features/auth/auth_providers.dart';
import 'package:pideqr/features/menu/menu_providers.dart';

// Provider para nuestro nuevo servicio
final notificationServiceProvider = Provider((ref) => NotificationService(ref));

class NotificationService {
  final Ref _ref;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  NotificationService(this._ref);

  Future<void> initNotifications() async {
    // Pedir permiso al usuario (necesario en iOS)
    await _fcm.requestPermission();

    // Obtener el token del dispositivo
    final fcmToken = await _fcm.getToken();

    if (fcmToken != null) {
      print('FCM Token: $fcmToken'); // Útil para depuración
      await saveTokenToDatabase(fcmToken);
    }

    // Escuchar cambios en el token (si se refresca)
    _fcm.onTokenRefresh.listen((newToken) async {
      await saveTokenToDatabase(newToken);
    });
  }

  Future<void> saveTokenToDatabase(String token) async {
    final userId = _ref.read(userModelProvider).value?.uid;
    if (userId == null) return;

    try {
      await _ref.read(firestoreServiceProvider).addFcmToken(userId: userId, token: token);
    } catch (e) {
      print('Error al guardar el token FCM: $e');
    }
  }

  Future<void> removeTokenFromDatabase() async {
    final userId = _ref.read(userModelProvider).value?.uid;
    final currentToken = await _fcm.getToken();

    if (userId == null || currentToken == null) return;

    try {
      await _ref.read(firestoreServiceProvider).removeFcmToken(userId: userId, token: currentToken);
    } catch (e) {
      print('Error al eliminar el token FCM: $e');
    }
  }
}

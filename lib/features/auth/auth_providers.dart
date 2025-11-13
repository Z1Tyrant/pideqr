import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../core/models/user_model.dart';

// 1. Provider para exponer la instancia del AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// 2. StreamProvider para escuchar el estado de autenticación de Firebase
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// 3. FutureProvider para obtener los datos COMPLETO del UserModel (incluido el Rol)
final userModelProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateChangesProvider);

  if (authState.asData?.value != null) {
    final uid = authState.asData!.value!.uid;
    return ref.watch(authServiceProvider).getUserData(uid);
  }

  return null;
});
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pideqr/features/menu/menu_providers.dart';
import '../../services/auth_service.dart';
import '../../core/models/user_model.dart';
import '../../services/firestore_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final userModelProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateChangesProvider);

  if (authState.asData?.value != null) {
    final uid = authState.asData!.value!.uid;
    return ref.watch(authServiceProvider).getUserData(uid);
  }

  return null;
});

final userDataProvider = FutureProvider.autoDispose.family<UserModel?, String>((ref, userId) {
  if (userId.isEmpty) {
    return Future.value(null);
  }
  return ref.watch(authServiceProvider).getUserData(userId);
});

final sellerForStoreProvider = StreamProvider.autoDispose.family<UserModel?, String>((ref, tiendaId) {
  if (tiendaId.isEmpty) {
    return Stream.value(null);
  }
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getSellerForStore(tiendaId);
});

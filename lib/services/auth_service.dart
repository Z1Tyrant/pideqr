import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference _userCollection = 
      FirebaseFirestore.instance.collection('users');

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> getUserData(String uid) async {
    final doc = await _userCollection.doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // --- FUNCIÓN DE REGISTRO SIMPLIFICADA ---
  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = userCredential.user!.uid;

      // El rol se asigna como 'cliente' por defecto
      final newUser = UserModel(
        uid: uid,
        email: email,
        name: name,
        role: UserRole.cliente, 
      );

      await _userCollection.doc(uid).set(newUser.toMap());
      return newUser;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Ha ocurrido un error inesperado al registrar.');
    }
  }

  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = userCredential.user!.uid;
      return await getUserData(uid);
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Ha ocurrido un error inesperado al iniciar sesión.');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference _userCollection = 
      FirebaseFirestore.instance.collection('users');

  // --- Mapeo de Usuario y Streams ---

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> getUserData(String uid) async {
    final doc = await _userCollection.doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // --- 1. REGISTRO ---
  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    try {
      // 1. Crear el usuario en Firebase Authentication
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // 2. Crear el objeto UserModel
      final newUser = UserModel(
        uid: uid,
        email: email,
        name: name,
        role: role,
      );

      // 3. Guardar los datos del usuario (incluido el rol) en Firestore
      await _userCollection.doc(uid).set(newUser.toMap());

      return newUser;

    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Error desconocido al registrar.');
    } catch (e) {
      throw Exception('Ha ocurrido un error inesperado al registrar.');
    }
  }

  // --- 2. INICIO DE SESIÓN ---
  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Iniciar sesión en Firebase Authentication
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final uid = userCredential.user!.uid;

      // 2. Obtener los datos del usuario (rol, nombre) desde Firestore
      return await getUserData(uid);

    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Error desconocido al iniciar sesión.');
    } catch (e) {
      throw Exception('Ha ocurrido un error inesperado al iniciar sesión.');
    }
  }

  // --- 3. CERRAR SESIÓN ---
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
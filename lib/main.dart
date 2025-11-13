import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // NECESARIO para usar Riverpod
import 'package:firebase_core/firebase_core.dart'; // NECESARIO para Firebase
import 'firebase_options.dart'; // NECESARIO: Archivo generado por flutterfire
import 'features/auth/auth_checker.dart'; // La clase que verifica la sesión

// --- FUNCIÓN MAIN CORREGIDA ---
Future<void> main() async {
  // Asegura que Flutter esté inicializado antes de llamar a servicios nativos
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase (usa el archivo generado)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Envuelve la aplicación en ProviderScope (Requisito de Riverpod)
  runApp(const ProviderScope(
    child: PideQRApp(), 
  ));
}

// --- CLASE RAÍZ (PideQRApp) ---
class PideQRApp extends StatelessWidget {
  const PideQRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PideQR',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      // Punto de entrada que verifica si el usuario está logueado o no
      home: const AuthChecker(), 
    );
  }
}
// --- FIN DEL ARCHIVO ---
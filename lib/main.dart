// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // NECESARIO para usar Riverpod
import 'package:firebase_core/firebase_core.dart'; // NECESARIO para Firebase
import 'firebase_options.dart'; // NECESARIO: Archivo generado por flutterfire
import 'features/auth/auth_checker.dart'; // La clase que verifica la sesión

// 🚨 DEFINICIÓN DE COLORES CLAVE
const Color pideQRPrimaryColor = Color(0xFF3F51B5); // Índigo Profundo (Seguridad)
const Color pideQRAccentColor = Color(0xFF00BCD4); // Cian Brillante (Acción)

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
        // Tema base y colores principales
        primarySwatch: Colors.indigo,
        primaryColor: pideQRPrimaryColor,

        // 🚨 CONFIGURACIÓN DEL COLOR SCHEME Y ACENTO
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.indigo,
          accentColor: pideQRAccentColor,
          // Fondo oscuro (el negro que usarás en el Stack)
          backgroundColor: Colors.black, 
        ),
        
        // 🚨 CONFIGURACIÓN DEL TEMA DE TEXTO (para fondo oscuro)
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white70),
          bodyMedium: TextStyle(color: Colors.white70),
          headlineLarge: TextStyle(color: Colors.white),
        ),
        
        useMaterial3: true,
      ),
      // Punto de entrada que verifica si el usuario está logueado o no
      home: const AuthChecker(), 
    );
  }
}
// --- FIN DEL ARCHIVO ---
// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dynamic_color/dynamic_color.dart'; // <-- IMPORTACIÓN
import 'firebase_options.dart';
import 'features/auth/auth_checker.dart';

<<<<<<< HEAD
void main() async {
=======
// 🚨 DEFINICIÓN DE COLORES CLAVE
const Color pideQRPrimaryColor = Color(0xFF3F51B5); // Índigo Profundo (Seguridad)
const Color pideQRAccentColor = Color(0xFF00BCD4); // Cian Brillante (Acción)

// --- FUNCIÓN MAIN CORREGIDA ---
Future<void> main() async {
  // Asegura que Flutter esté inicializado antes de llamar a servicios nativos
>>>>>>> e67c6a4c2d11608daba6986e610b080e0246f443
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const ProviderScope(
    child: PideQRApp(), 
  ));
}

// Paleta de colores de respaldo si el color dinámico no está disponible
final _defaultLightColorScheme = ColorScheme.fromSeed(seedColor: Colors.blueAccent);
final _defaultDarkColorScheme = ColorScheme.fromSeed(seedColor: Colors.blueAccent, brightness: Brightness.dark);

class PideQRApp extends StatelessWidget {
  const PideQRApp({super.key});

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {

        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          lightColorScheme = lightDynamic.harmonized();
          darkColorScheme = darkDynamic.harmonized();
        } else {
          lightColorScheme = _defaultLightColorScheme;
          darkColorScheme = _defaultDarkColorScheme;
        }

        return MaterialApp(
          title: 'PideQR',
          theme: ThemeData(
            colorScheme: lightColorScheme,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: darkColorScheme,
            useMaterial3: true,
          ),
          themeMode: ThemeMode.system,
          home: const AuthChecker(), 
        );
      },
=======
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
>>>>>>> e67c6a4c2d11608daba6986e610b080e0246f443
    );
  }
}

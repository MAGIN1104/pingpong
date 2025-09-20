import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'features/setup/presentation/setup_screen.dart';
import 'features/splash/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Permitir todas las orientaciones al inicio
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Establecer la barra de estado
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top],
  );

  runApp(const PingPongApp());
}

class PingPongApp extends StatelessWidget {
  const PingPongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ping Pong',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D1333), // Azul oscuro campeonato
          primary: const Color(0xFF0D1333), // Azul oscuro
          secondary: const Color(0xFFFFD700), // Dorado
          tertiary: const Color(0xFFC0C0C0), // Plateado
          surface: const Color(0xFFFFFFFF), // Blanco
          error: const Color(0xFFD32F2F),
          onPrimary: const Color(0xFFFFFFFF),
          onSecondary: const Color(0xFF0D1333),
          onTertiary: const Color(0xFF0D1333),
          onSurface: const Color(0xFF0D1333),
          onError: const Color(0xFFFFFFFF),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA), // Fondo muy claro
      ),
      home: const SplashScreen(child: SetupScreen()),
    );
  }
}

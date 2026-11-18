import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.surface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Explora Bucaramanga',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      // Detectar sesión activa con StreamBuilder
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Cargando estado de sesión
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _SplashScreen();
          }
          // Si hay sesión activa → ir directo al mapa
          if (snapshot.hasData && snapshot.data != null) {
            return const MainScreen();
          }
          // Si no hay sesión → ir al login
          return const LoginScreen();
        },
      ),
      routes: {
        '/login':    (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home':     (_) => const MainScreen(),
      },
    );
  }
}

// Pantalla de splash mientras carga la sesión
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
              ),
              child: const Text('📍', style: TextStyle(fontSize: 48)),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: AppTheme.accent),
          ],
        ),
      ),
    );
  }
}
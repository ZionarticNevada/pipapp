import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const PipApp());
}

class PipApp extends StatelessWidget {
  const PipApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'PipApp',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorSchemeSeed: const Color(0xFF1E6FD9),
      useMaterial3: true,
    ),
    home: const AuthGate(),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) {
        return const Scaffold(
            body: Center(child: CircularProgressIndicator()));
      }
      if (snap.hasData) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('PipApp'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Cerrar sesión',
                onPressed: () => AuthService().cerrarSesion(),
              ),
            ],
          ),
          body: Center(child: Text('Sesión iniciada como ${snap.data!.email}')),
        );
      }
      return const LoginScreen();
    },
  );
}
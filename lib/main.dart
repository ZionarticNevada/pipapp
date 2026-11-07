import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'auth_gate.dart';
import 'firebase_options.dart';

export 'auth_gate.dart';

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

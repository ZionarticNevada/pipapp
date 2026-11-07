import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth_gate.dart';
import '../services/auth_service.dart';
import '../utils/validadores.dart';
import 'registro_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _correo = TextEditingController();
  final _pass = TextEditingController();
  final _auth = AuthService();
  bool _verPass = false;
  bool _cargando = false;

  Future<void> _entrar() async {
    final correo = _correo.text.trim();
    if (!Validadores.correoValido(correo)) {
      _mensaje('Escribe un correo válido');
      return;
    }
    if (_pass.text.isEmpty) {
      _mensaje('Escribe tu contraseña');
      return;
    }
    setState(() => _cargando = true);
    try {
      await _auth.iniciarSesion(_correo.text.trim(), _pass.text);
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      _mensaje(_traducir(e.code));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _recuperar() async {
    if (!Validadores.correoValido(_correo.text)) {
      _mensaje('Escribe un correo válido');
      return;
    }
    try {
      await _auth.recuperarPassword(_correo.text.trim());
      _mensaje(
          'Si el correo está registrado, recibirás un mensaje para restablecer tu contraseña');
    } on FirebaseAuthException catch (e) {
      _mensaje(_traducir(e.code));
    }
  }

  String _traducir(String code) {
    switch (code) {
      case 'invalid-email':
        return 'El correo no es válido';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos';
      case 'too-many-requests':
        return 'Demasiados intentos, intenta más tarde';
      default:
        return 'Ocurrió un error ($code)';
    }
  }

  void _mensaje(String texto) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(texto)));

  @override
  void dispose() {
    _correo.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                children: [
                  Image.asset('assets/images/logoEmpresa.png', height: 96),
                  const SizedBox(height: 8),
                  Text('Monitorea tu cisterna,\ncuida el agua',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _correo,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pass,
                    obscureText: !_verPass,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_verPass
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => _verPass = !_verPass),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _recuperar,
                      child: const Text('¿Olvidaste tu contraseña?'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _cargando ? null : _entrar,
                      child: _cargando
                          ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Iniciar sesión'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegistroScreen())),
                      child: const Text('Crear una cuenta'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tus datos están protegidos y solo tú puedes verlos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ignore: camel_case_types
typedef loginPage = LoginScreen;
typedef LoginPage = LoginScreen;

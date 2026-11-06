import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/validadores.dart';
import 'aviso_privacidad_screen.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});
  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  final _auth = AuthService();
  bool _acepto = false;
  bool _cargando = false;

  Future<void> _registrar() async {
    final correo = _correo.text.trim();
    if (!Validadores.correoValido(correo)) {
      _mensaje('Escribe un correo válido');
      return;
    }
    if (_pass.text.length < 6) {
      _mensaje('La contraseña debe tener al menos 6 caracteres');
      return;
    }
    if (_pass.text != _pass2.text) {
      _mensaje('Las contraseñas no coinciden');
      return;
    }
    setState(() => _cargando = true);
    try {
      await _auth.registrar(
        _correo.text.trim(),
        _pass.text,
        nombre: _nombre.text.trim(),
      );
      if (mounted) Navigator.pop(context); // AuthGate mostrará la app
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          _mensaje('Ese correo ya está registrado');
          break;
        case 'invalid-email':
          _mensaje('El correo no es válido');
          break;
        case 'weak-password':
          _mensaje('La contraseña es muy débil (mínimo 6 caracteres)');
          break;
        default:
          _mensaje('No se pudo crear la cuenta (${e.code})');
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mensaje(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                children: [
                  TextField(
                    controller: _nombre,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _correo,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pass,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pass2,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Confirmar contraseña',
                        border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                          value: _acepto,
                          onChanged: (v) =>
                              setState(() => _acepto = v ?? false)),
                      Expanded(
                        child: Wrap(
                          children: [
                            const Text('He leído y acepto el '),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                      const AvisoPrivacidadScreen())),
                              child: const Text('aviso de privacidad',
                                  style: TextStyle(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: (_acepto && !_cargando) ? _registrar : null,
                      child: _cargando
                          ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Crear cuenta'),
                    ),
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
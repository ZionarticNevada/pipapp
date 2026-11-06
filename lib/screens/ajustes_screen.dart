import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth_gate.dart';
import '../services/auth_service.dart';

class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  final _auth = AuthService();

  // Controladores de perfil
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();

  // Controladores de contraseña
  final _passActualController = TextEditingController();
  final _passNuevaController = TextEditingController();
  final _passConfirmarController = TextEditingController();

  bool _verPassActual = false;
  bool _verPassNueva = false;
  bool _verPassConfirmar = false;

  bool _notificaciones = true;
  bool _cargandoDatos = true;
  bool _guardandoNombre = false;
  bool _cambiandoPass = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _correoController.text = user.email ?? '';
    _nombreController.text = user.displayName ?? '';

    try {
      final datos = await _auth.obtenerDatosUsuario();
      if (datos != null && mounted) {
        setState(() {
          if ((user.displayName == null || user.displayName!.isEmpty) &&
              datos['nombre'] != null) {
            _nombreController.text = datos['nombre'];
          }
          if (datos['notificaciones'] != null) {
            _notificaciones = datos['notificaciones'] as bool;
          }
        });
      }
    } catch (_) {
      // Si falla Firestore, mantenemos los valores de FirebaseAuth
    } finally {
      if (mounted) {
        setState(() => _cargandoDatos = false);
      }
    }
  }

  Future<void> _guardarNombre() async {
    final nuevoNombre = _nombreController.text.trim();
    if (nuevoNombre.isEmpty) {
      _mostrarMensaje('El nombre no puede estar vacío');
      return;
    }

    setState(() => _guardandoNombre = true);
    try {
      await _auth.actualizarNombre(nuevoNombre);
      _mostrarMensaje('Nombre actualizado con éxito');
    } catch (e) {
      _mostrarMensaje('Error al actualizar el nombre: $e');
    } finally {
      if (mounted) setState(() => _guardandoNombre = false);
    }
  }

  Future<void> _cambiarPassword() async {
    final actual = _passActualController.text;
    final nueva = _passNuevaController.text;
    final confirmar = _passConfirmarController.text;

    if (actual.isEmpty || nueva.isEmpty || confirmar.isEmpty) {
      _mostrarMensaje('Completa todos los campos de contraseña');
      return;
    }

    if (nueva.length < 6) {
      _mostrarMensaje('La nueva contraseña debe tener al menos 6 caracteres');
      return;
    }

    if (nueva != confirmar) {
      _mostrarMensaje('Las nuevas contraseñas no coinciden');
      return;
    }

    if (actual == nueva) {
      _mostrarMensaje('La nueva contraseña debe ser diferente a la actual');
      return;
    }

    setState(() => _cambiandoPass = true);
    try {
      await _auth.cambiarPassword(actual, nueva);
      _passActualController.clear();
      _passNuevaController.clear();
      _passConfirmarController.clear();
      _mostrarMensaje('Contraseña actualizada correctamente');
    } on FirebaseAuthException catch (e) {
      _mostrarMensaje(_traducirErrorAuth(e.code));
    } catch (e) {
      _mostrarMensaje('Ocurrió un error al cambiar la contraseña');
    } finally {
      if (mounted) setState(() => _cambiandoPass = false);
    }
  }

  Future<void> _alternarNotificaciones(bool valor) async {
    setState(() => _notificaciones = valor);
    try {
      await _auth.actualizarNotificaciones(valor);
      _mostrarMensaje(valor
          ? 'Notificaciones activadas'
          : 'Notificaciones desactivadas');
    } catch (e) {
      if (mounted) setState(() => _notificaciones = !valor);
      _mostrarMensaje('No se pudo actualizar la preferencia de notificaciones');
    }
  }

  Future<void> _enviarCorreoRestablecimiento() async {
    final email = _correoController.text.trim();
    if (email.isEmpty) return;
    try {
      await _auth.recuperarPassword(email);
      _mostrarMensaje('Se envió un correo de restablecimiento a $email');
    } on FirebaseAuthException catch (e) {
      _mostrarMensaje(_traducirErrorAuth(e.code));
    }
  }

  Future<void> _confirmarCerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text(
            '¿Estás seguro de que deseas cerrar tu sesión en PipApp?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      await _auth.cerrarSesion();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    }
  }

  String _traducirErrorAuth(String code) {
    switch (code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'La contraseña actual es incorrecta';
      case 'weak-password':
        return 'La contraseña es muy débil (mínimo 6 caracteres)';
      case 'requires-recent-login':
        return 'Por seguridad, vuelve a iniciar sesión antes de cambiar la contraseña';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      default:
        return 'Error de autenticación ($code)';
    }
  }

  void _mostrarMensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _passActualController.dispose();
    _passNuevaController.dispose();
    _passConfirmarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes de cuenta'),
        centerTitle: true,
      ),
      body: _cargandoDatos
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Encabezado de Avatar y Bienvenida
                        Center(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 42,
                                backgroundColor: colorScheme.primaryContainer,
                                child: Icon(
                                  Icons.person,
                                  size: 48,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _nombreController.text.isNotEmpty
                                    ? _nombreController.text
                                    : 'Usuario PipApp',
                                style: Theme.of(context).textTheme.titleLarge,
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                _correoController.text,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Sección: Datos de registro / Usuario
                        _buildSectionCard(
                          context,
                          title: 'Datos de registro',
                          icon: Icons.badge_outlined,
                          children: [
                            TextField(
                              controller: _nombreController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Nombre de usuario',
                                helperText:
                                    'Nombre con el que te identificas en la app',
                                prefixIcon: Icon(Icons.person_outline),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _correoController,
                              enabled: false,
                              decoration: const InputDecoration(
                                labelText: 'Correo electrónico',
                                helperText:
                                    'El correo está asociado a tu cuenta de acceso',
                                prefixIcon: Icon(Icons.email_outlined),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 46,
                              child: FilledButton.tonalIcon(
                                onPressed:
                                    _guardandoNombre ? null : _guardarNombre,
                                icon: _guardandoNombre
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Icon(Icons.save_outlined),
                                label: const Text('Actualizar nombre'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Sección: Contraseña
                        _buildSectionCard(
                          context,
                          title: 'Seguridad y contraseña',
                          icon: Icons.lock_outline,
                          children: [
                            TextField(
                              controller: _passActualController,
                              obscureText: !_verPassActual,
                              decoration: InputDecoration(
                                labelText: 'Contraseña actual',
                                prefixIcon: const Icon(Icons.password_outlined),
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(_verPassActual
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                  onPressed: () => setState(() =>
                                      _verPassActual = !_verPassActual),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _passNuevaController,
                              obscureText: !_verPassNueva,
                              decoration: InputDecoration(
                                labelText: 'Nueva contraseña',
                                helperText: 'Mínimo 6 caracteres',
                                prefixIcon:
                                    const Icon(Icons.lock_reset_outlined),
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(_verPassNueva
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                  onPressed: () => setState(
                                      () => _verPassNueva = !_verPassNueva),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _passConfirmarController,
                              obscureText: !_verPassConfirmar,
                              decoration: InputDecoration(
                                labelText: 'Confirmar nueva contraseña',
                                prefixIcon:
                                    const Icon(Icons.check_circle_outline),
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(_verPassConfirmar
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                  onPressed: () => setState(() =>
                                      _verPassConfirmar = !_verPassConfirmar),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 46,
                              child: FilledButton.tonalIcon(
                                onPressed: _cambiandoPass
                                    ? null
                                    : _cambiarPassword,
                                icon: _cambiandoPass
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Icon(Icons.vpn_key_outlined),
                                label: const Text('Actualizar contraseña'),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _enviarCorreoRestablecimiento,
                                child: const Text(
                                    '¿Olvidaste tu contraseña actual?'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Sección: Notificaciones
                        _buildSectionCard(
                          context,
                          title: 'Notificaciones',
                          icon: Icons.notifications_outlined,
                          children: [
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              value: _notificaciones,
                              title: const Text('Alertas y avisos'),
                              subtitle: const Text(
                                  'Recibe alertas cuando el nivel de agua de la cisterna esté bajo.'),
                              onChanged: _alternarNotificaciones,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Sección: Cierre de sesión
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.error,
                            side: BorderSide(color: colorScheme.error),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _confirmarCerrarSesion,
                          icon: const Icon(Icons.logout),
                          label: const Text(
                            'Cerrar sesión',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 22, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

// ignore: camel_case_types
typedef ajustes = AjustesScreen;
typedef AjustesPage = AjustesScreen;

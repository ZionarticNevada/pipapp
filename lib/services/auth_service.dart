import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<void> registrar(String correo, String pass, {String? nombre}) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: correo,
      password: pass,
    );

    if (nombre != null && nombre.trim().isNotEmpty) {
      await cred.user!.updateDisplayName(nombre.trim());
    }

    await _db.collection('usuarios').doc(cred.user!.uid).set({
      'correo': correo,
      'nombre': nombre?.trim() ?? '',
      'umbralAlerta': 25,
      'notificaciones': true,
      'avisoPrivacidadAceptado': true,
      'fechaAceptacion': FieldValue.serverTimestamp(),
    });
  }

  Future<void> iniciarSesion(String correo, String pass) =>
      _auth.signInWithEmailAndPassword(email: correo, password: pass);

  Future<void> recuperarPassword(String correo) =>
      _auth.sendPasswordResetEmail(email: correo);

  Future<void> cerrarSesion() => _auth.signOut();

  Future<Map<String, dynamic>?> obtenerDatosUsuario() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('usuarios').doc(user.uid).get();
    return doc.data();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>? obtenerDatosUsuarioStream() {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _db.collection('usuarios').doc(user.uid).snapshots();
  }

  Future<void> actualizarNombre(String nuevoNombre) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No hay un usuario autenticado');
    final nombreLimpio = nuevoNombre.trim();
    await user.updateDisplayName(nombreLimpio);
    await _db.collection('usuarios').doc(user.uid).set({
      'nombre': nombreLimpio,
    }, SetOptions(merge: true));
  }

  Future<void> actualizarNotificaciones(bool activas) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No hay un usuario autenticado');
    await _db.collection('usuarios').doc(user.uid).set({
      'notificaciones': activas,
    }, SetOptions(merge: true));
  }

  Future<void> cambiarPassword(String actual, String nueva) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('No hay un usuario autenticado');
    }
    final cred =
        EmailAuthProvider.credential(email: user.email!, password: actual);
    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(nueva);
  }
}

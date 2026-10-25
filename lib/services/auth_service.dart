import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<void> registrar(String correo, String pass) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: correo, password: pass);
    await _db.collection('usuarios').doc(cred.user!.uid).set({
      'correo': correo,
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

  Future<void> cambiarPassword(String actual, String nueva) async {
    final user = _auth.currentUser!;
    final cred =
    EmailAuthProvider.credential(email: user.email!, password: actual);
    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(nueva);
  }
}
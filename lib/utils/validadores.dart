class Validadores {
  static bool correoValido(String correo) =>
      RegExp(r'^[\w.+\-]+@[\w\-]+(\.[\w\-]+)+$').hasMatch(correo.trim());
}

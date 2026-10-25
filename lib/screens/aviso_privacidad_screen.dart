import 'package:flutter/material.dart';

class AvisoPrivacidadScreen extends StatelessWidget {
  const AvisoPrivacidadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aviso de privacidad')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Text(
          'Responsable: ZumpaSoft (contacto: zumpasoft@gmail.com).\n\n'
              'Datos que recabamos: correo electrónico, contraseña, niveles de '
              'agua de tu cisterna, historial y tus preferencias de alertas. '
              'Tu contraseña se almacena cifrada mediante Firebase Authentication '
              'y el equipo no puede verla.\n\n'
              'Finalidad: mostrarte el nivel de agua, guardar tu historial y '
              'enviarte notificaciones cuando el nivel sea bajo. No vendemos ni '
              'usamos tus datos con fines comerciales.\n\n'
              'Con quién se comparten: únicamente con Google Firebase, nuestro '
              'proveedor de infraestructura.\n\n'
              'Tus derechos: puedes acceder a tus datos, corregirlos, cancelarlos '
              'u oponerte a su uso (derechos ARCO) escribiendo a nuestro correo '
              'de contacto. También puedes solicitar que eliminemos tu cuenta.\n\n'
              'Cambios: si modificamos este aviso, te lo notificaremos dentro de '
              'la aplicación.',
          style: TextStyle(height: 1.4),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '../config.dart';
import '../models/medicion.dart';
import '../services/esp32_service.dart';
import 'historial_screen.dart';

class DetalleNivelScreen extends StatefulWidget {
  const DetalleNivelScreen({super.key});

  @override
  State<DetalleNivelScreen> createState() => _DetalleNivelScreenState();
}

class _DetalleNivelScreenState extends State<DetalleNivelScreen> {
  final Esp32Service _servicio = Esp32Service.instancia;

  @override
  void initState() {
    super.initState();
    _servicio.iniciar();
  }

  @override
  void dispose() {
    _servicio.detener();
    super.dispose();
  }

  Color _colorEstado(Medicion m) {
    if (!m.ok) return Colors.grey;
    switch (m.estado) {
      case 'BAJO':
        return Colors.red;
      case 'MEDIO':
        return Colors.amber.shade700;
      default:
        return Colors.green;
    }
  }

  IconData _iconoEstado(Medicion m) {
    if (!m.ok) return Icons.sensors_off;
    if (m.estado == 'BAJO') return Icons.warning;
    return Icons.check_circle;
  }

  void _mostrarConfiguracion() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Configuración'),
        content: Text(
          'ESP32: ${AppConfig.urlNivel}\n'
          'Actualización: cada ${AppConfig.intervaloActualizacion.inSeconds} s\n'
          'Capacidad: ${AppConfig.capacidadLitros} L\n\n'
          'Para cambiar estos valores edita lib/config.dart.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          "Nivel de agua",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _servicio.actualizar,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black87),
            onPressed: _mostrarConfiguracion,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _servicio,
        builder: (context, _) {
          final actual = _servicio.actual;

          if (actual == null) {
            return _buildSinDatos();
          }
          return _buildContenido(actual);
        },
      ),
    );
  }

  Widget _buildSinDatos() {
    final error = _servicio.error;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (error == null) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Conectando con ${AppConfig.esp32Ip}...'),
            ] else ...[
              const Icon(Icons.wifi_off, size: 56, color: Colors.grey),
              const SizedBox(height: 12),
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              const Text(
                'Revisa que el teléfono esté en la misma red WiFi que el ESP32.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _servicio.actualizar,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContenido(Medicion actual) {
    final colorEstado = _colorEstado(actual);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          if (_servicio.error != null)
            _buildAviso(Icons.wifi_off,
                '${_servicio.error}. Mostrando la última lectura.', Colors.red),
          if (_servicio.error == null && !actual.ok)
            _buildAviso(Icons.sensors_off,
                'El sensor no responde. Mostrando el último valor válido.', Colors.orange),
          if (_servicio.error == null && actual.ok && actual.datosViejos)
            _buildAviso(Icons.schedule,
                'La última lectura tiene ${actual.antiguedadS} s.', Colors.orange),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Container(
                    width: 45,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    width: 110,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.blue.shade200, width: 3),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          width: double.infinity,
                          height: 154 * (actual.porcentaje / 100),
                          color: (actual.esBajo
                                  ? Colors.red.shade400
                                  : const Color(0xFF2196F3))
                              .withOpacity(0.85),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${actual.porcentajeEntero}%",
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    "${actual.litros} L",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                  Text(
                    "de ${actual.capacidadTotal} L",
                    style: const TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorEstado.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_iconoEstado(actual), size: 16, color: colorEstado),
                        const SizedBox(width: 6),
                        Text(
                          actual.estadoTexto,
                          style: TextStyle(
                            color: colorEstado,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.7,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildInfoCard(Icons.water_drop, "Nivel de agua",
                  "${actual.nivelCm.toStringAsFixed(1)} cm"),
              _buildInfoCard(Icons.straighten, "Distancia sensor",
                  "${actual.distanciaCm.toStringAsFixed(1)} cm"),
              _buildInfoCard(Icons.access_time, "Última medición",
                  "${actual.fecha}\n${actual.hora}"),
              _buildInfoCard(Icons.wifi, "Señal WiFi", actual.senalTexto),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HistorialScreen()),
                );
              },
              icon: const Icon(Icons.bar_chart, color: Colors.white),
              label: const Text(
                "Ver historial",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  Widget _buildAviso(IconData icono, String texto, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icono, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(texto, style: TextStyle(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String titulo, String valor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1976D2), size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(titulo, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

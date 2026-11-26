import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../config.dart';
import '../models/medicion.dart';
import '../services/esp32_service.dart';

/// Historial guardado en SQLite en el teléfono
/// (un registro cada AppConfig.intervaloHistorial).
class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final Esp32Service _servicio = Esp32Service.instancia;

  static const Map<String, Duration> _ventanas = {
    '1 hora': Duration(hours: 1),
    '24 h': Duration(hours: 24),
    '7 días': Duration(days: 7),
    '30 días': Duration(days: 30),
  };

  String _ventanaSeleccionada = '24 h';
  List<Medicion> _datos = [];
  int _totalRegistros = 0;
  bool _cargando = true;
  int _versionCargada = -1;

  @override
  void initState() {
    super.initState();
    _servicio.addListener(_alCambiarServicio);
    _cargar();
  }

  @override
  void dispose() {
    _servicio.removeListener(_alCambiarServicio);
    super.dispose();
  }

  void _alCambiarServicio() {
    // Solo recargar cuando se guardó (o borró) algo en la base de datos
    if (_servicio.versionHistorial != _versionCargada) _cargar();
  }

  Future<void> _cargar() async {
    final version = _servicio.versionHistorial;
    try {
      final datos =
          await _servicio.historialDesde(_ventanas[_ventanaSeleccionada]!);
      final total = await _servicio.totalRegistros();
      if (!mounted) return;
      setState(() {
        _datos = datos;
        _totalRegistros = total;
        _versionCargada = version;
        _cargando = false;
      });
    } catch (e) {
      debugPrint('Error leyendo historial: $e');
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _confirmarBorrado() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Borrar historial'),
        content: Text(
            'Se borrarán los $_totalRegistros registros guardados. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmar == true) await _servicio.borrarHistorial();
  }

  Color _obtenerColorEstado(double porcentaje) {
    if (porcentaje <= AppConfig.umbralBajo) return Colors.red;
    if (porcentaje <= AppConfig.umbralMedio) return Colors.amber;
    return Colors.green;
  }

  /// Reduce los puntos de la gráfica a AppConfig.maxPuntosGrafica.
  List<Medicion> _muestrear(List<Medicion> datos) {
    const max = AppConfig.maxPuntosGrafica;
    if (datos.length <= max) return datos;
    final paso = datos.length / max;
    final r = <Medicion>[];
    for (var i = 0; i < max; i++) {
      r.add(datos[(i * paso).floor()]);
    }
    r[r.length - 1] = datos.last;  // conservar siempre el más reciente
    return r;
  }

  /// Formato de la etiqueta del eje X según la ventana elegida.
  String _etiquetaX(Medicion m) {
    final ventana = _ventanas[_ventanaSeleccionada]!;
    if (ventana <= const Duration(hours: 24)) return m.horaCorta;
    return '${m.recibida.day}/${m.recibida.month}';
  }

  @override
  Widget build(BuildContext context) {
    final datosGrafica = _muestrear(_datos);
    final lista = _datos.reversed.toList();  // más reciente arriba

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Historial de mediciones",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Borrar historial',
            icon: const Icon(Icons.delete_outline, color: Colors.black87),
            onPressed: _totalRegistros == 0 ? null : _confirmarBorrado,
          ),
        ],
      ),
      // Todo en un solo scroll: filtros, gráfica y lista se desplazan juntos,
      // así no se desborda en pantallas bajas o en horizontal.
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: _ventanas.keys.map((nombre) {
                final activo = _ventanaSeleccionada == nombre;
                return ChoiceChip(
                  label: Text(nombre),
                  selected: activo,
                  selectedColor: const Color(0xFF1976D2),
                  labelStyle: TextStyle(
                    color: activo ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _ventanaSeleccionada = nombre;
                      _cargando = true;
                    });
                    _cargar();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 6),
            Text(
              '${_datos.length} registros en el periodo · $_totalRegistros guardados en total',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Container(
              height: 200,
              padding: const EdgeInsets.only(top: 16, right: 16, left: 8, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: _cargando
                  ? const Center(child: CircularProgressIndicator())
                  : datosGrafica.length < 2
                      ? const Center(
                          child: Text(
                            'Aún no hay suficientes registros.\nSe guarda uno por minuto.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : _buildGrafica(datosGrafica),
            ),
            const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (lista.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(_cargando ? '' : 'Sin registros en este periodo',
                      style: const TextStyle(color: Colors.grey)),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildFila(lista[index]),
                  childCount: lista.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGrafica(List<Medicion> datos) {
    // Mostrar como máximo ~5 etiquetas en el eje X
    final paso = (datos.length / 5).ceil().clamp(1, datos.length);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        gridData: const FlGridData(show: true, horizontalInterval: 25),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 25,
              reservedSize: 38,
              getTitlesWidget: (val, _) =>
                  Text("${val.toInt()}%", style: const TextStyle(fontSize: 11)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (val, _) {
                final idx = val.toInt();
                if (idx >= 0 && idx < datos.length && idx % paso == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(_etiquetaX(datos[idx]),
                        style: const TextStyle(fontSize: 10)),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              datos.length,
              (i) => FlSpot(i.toDouble(), datos[i].porcentaje),
            ),
            isCurved: false,
            color: const Color(0xFF1976D2),
            barWidth: 3,
            dotData: FlDotData(show: datos.length <= 30),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF1976D2).withOpacity(0.15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFila(Medicion item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0.5,
      child: ListTile(
        leading: const Icon(Icons.access_time, color: Color(0xFF1976D2)),
        title: Row(
          children: [
            Text(item.fecha,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(width: 8),
            Text(item.hora,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        subtitle: Text('${item.litros} L · ${item.nivelCm.toStringAsFixed(1)} cm'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${item.porcentajeEntero}%",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 5,
              backgroundColor: _obtenerColorEstado(item.porcentaje),
            ),
          ],
        ),
      ),
    );
  }
}

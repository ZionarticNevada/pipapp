
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'medicion.dart';

class HistorialDB {
  static final HistorialDB instance = HistorialDB._init();

  static Database? _database;

  HistorialDB._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('Tinaco.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final pathDB = join(dbPath, fileName);

    return await openDatabase(
      pathDB,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE historial (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nivel REAL,
            distancia REAL,
            fecha TEXT
          )
        ''');
      },
    );
  }

  // Guardar medicion
  Future<int> guardar(double nivel, double distancia) async {
    final db = await database;

    final valores = {
      'nivel': nivel,
      'distancia': distancia,
      'fecha': DateTime.now().toIso8601String(),
    };

    return await db.insert('historial', valores);
  }

  // Consultar historial
  Future<List<Medicion>> consultar() async {
    final db = await database;

    final resultado = await db.query(
      'historial',
      orderBy: 'id DESC',
    );

    return resultado.map((fila) {
      return Medicion.fromMap(fila);
    }).toList();
  }
}
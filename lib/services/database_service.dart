import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {

  static Database? _database;

  /* ================= GET DATABASE ================= */

  static Future<Database> get database async {

    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  /* ================= INIT DATABASE ================= */

  static Future<Database> _initDatabase() async {

    String path = join(
      await getDatabasesPath(),
      'vitals_pro.db',
    );

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {

        await db.execute('''
          CREATE TABLE vitals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT,
            heartRate REAL,
            respiratoryRate REAL,
            temperature REAL,
            bloodPressure TEXT,
            hydration TEXT,
            motion TEXT
          )
        ''');
      },
    );
  }

  /* ================= INSERT VITALS ================= */

  static Future<void> insertVitals({
    required double heartRate,
    required double respRate,
    required double temperature,
    required String bloodPressure,
    required String hydration,
    required String motion,
  }) async {

    final db = await database;

    await db.insert(
      'vitals',
      {
        'timestamp': DateTime.now().toIso8601String(),
        'heartRate': heartRate,
        'respiratoryRate': respRate,
        'temperature': temperature,
        'bloodPressure': bloodPressure,
        'hydration': hydration,
        'motion': motion,
      },
    );
  }

  /* ================= GET VITALS BY DATE ================= */

  static Future<List<Map<String, dynamic>>> getVitalsByDate(
      DateTime date) async {

    final db = await database;

    String start =
        DateTime(date.year, date.month, date.day)
            .toIso8601String();

    String end =
        DateTime(date.year, date.month, date.day, 23, 59, 59)
            .toIso8601String();

    return await db.query(
      'vitals',
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [start, end],
    );
  }

  /* ================= GET ALL ================= */

  static Future<List<Map<String, dynamic>>> getAllVitals() async {
    final db = await database;
    return await db.query('vitals');
  }
}
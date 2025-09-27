// lib/services/db_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/alert.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'silent_guardian.db');
    _db = await openDatabase(
      path,
      version: 2, // bumped version to handle migrations
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE alerts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT,
            timestamp INTEGER,
            latitude REAL,
            longitude REAL,
            synced INTEGER DEFAULT 0,
            meta TEXT
          );
        ''');

        await db.execute('''
          CREATE TABLE logs(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp INTEGER,
            level TEXT,
            message TEXT
          );
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Safe adds — will only run once if upgrading from v1 → v2
          await db.execute("ALTER TABLE alerts ADD COLUMN latitude REAL;");
          await db.execute("ALTER TABLE alerts ADD COLUMN longitude REAL;");
          await db.execute(
            "ALTER TABLE alerts ADD COLUMN synced INTEGER DEFAULT 0;",
          );
          await db.execute("ALTER TABLE alerts ADD COLUMN meta TEXT;");
        }
      },
    );
    return _db!;
  }

  Future<int> insertAlert(AlertModel alert) async {
    final db = await database;
    return await db.insert('alerts', alert.toMap());
  }

  Future<List<AlertModel>> getAllAlerts() async {
    final db = await database;
    final rows = await db.query('alerts', orderBy: 'timestamp DESC');
    return rows.map((r) => AlertModel.fromMap(r)).toList();
  }

  Future<List<AlertModel>> getUnsyncedAlerts() async {
    final db = await database;
    final rows = await db.query('alerts', where: 'synced = 0');
    return rows.map((r) => AlertModel.fromMap(r)).toList();
  }

  Future<int> markAlertSynced(int id) async {
    final db = await database;
    return db.update('alerts', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertLog(int timestamp, String level, String message) async {
    final db = await database;
    return db.insert('logs', {
      'timestamp': timestamp,
      'level': level,
      'message': message,
    });
  }
}

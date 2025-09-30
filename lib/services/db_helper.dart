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
      version: 5, // new stable baseline
      onCreate: (db, version) async {
        // Alerts table
        await db.execute('''
          CREATE TABLE alerts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,                -- panic, countdown, decoy, low_battery
            timestamp INTEGER NOT NULL,        -- epoch millis
            latitude REAL,
            longitude REAL,
            synced INTEGER DEFAULT 0,          -- 0 = not synced, 1 = synced
            meta TEXT,                         -- optional JSON
            escalation_policy TEXT,            -- e.g. immediate, tiered
            target_contacts TEXT               -- comma-separated UUIDs
          );
        ''');

        // Logs table
        await db.execute('''
          CREATE TABLE logs(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp INTEGER NOT NULL,
            level TEXT,
            message TEXT
          );
        ''');

        // Emergency contacts table
        await db.execute('''
          CREATE TABLE emergency_contacts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            uuid TEXT UNIQUE,
            name TEXT NOT NULL,
            phone TEXT NOT NULL,
            channels TEXT,                     -- e.g. sms,call,app
            priority INTEGER DEFAULT 0,
            notify_all_on_red INTEGER DEFAULT 0,
            notes TEXT,
            created_at INTEGER,
            updated_at INTEGER
          );
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // From v1 → v5, align all schemas
        if (oldVersion < 5) {
          // Alerts fixes
          await db.execute(
            "ALTER TABLE alerts ADD COLUMN escalation_policy TEXT;",
          );
          await db.execute(
            "ALTER TABLE alerts ADD COLUMN target_contacts TEXT;",
          );

          // Contacts fixes
          await db.execute(
            "ALTER TABLE emergency_contacts ADD COLUMN channels TEXT;",
          );
          await db.execute(
            "ALTER TABLE emergency_contacts ADD COLUMN notify_all_on_red INTEGER DEFAULT 0;",
          );
          await db.execute(
            "ALTER TABLE emergency_contacts ADD COLUMN notes TEXT;",
          );
          await db.execute(
            "ALTER TABLE emergency_contacts ADD COLUMN created_at INTEGER;",
          );
          await db.execute(
            "ALTER TABLE emergency_contacts ADD COLUMN updated_at INTEGER;",
          );
        }
      },
    );
    return _db!;
  }

  // ---------------- ALERTS ----------------
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

  // ---------------- LOGS ----------------
  Future<int> insertLog(int timestamp, String level, String message) async {
    final db = await database;
    return db.insert('logs', {
      'timestamp': timestamp,
      'level': level,
      'message': message,
    });
  }

  // ---------------- CONTACTS ----------------
  Future<int> insertContact(Map<String, dynamic> contact) async {
    final db = await database;
    return await db.insert(
      'emergency_contacts',
      contact,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllContacts() async {
    final db = await database;
    return await db.query(
      'emergency_contacts',
      orderBy: 'priority DESC, name ASC',
    );
  }

  Future<int> deleteContact(int id) async {
    final db = await database;
    return await db.delete(
      'emergency_contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateContact(int id, Map<String, dynamic> contact) async {
    final db = await database;
    return await db.update(
      'emergency_contacts',
      contact,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/alert.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._internal();
  factory DBHelper() => instance;
  DBHelper._internal();

  static Database? _db;
  static const int _dbVersion = 8;
  static const String _dbName = 'silent_guardian.db';

  Future<Database> get database async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), _dbName);

    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE alerts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            timestamp INTEGER NOT NULL,
            latitude REAL,
            longitude REAL,
            synced INTEGER DEFAULT 0,
            meta TEXT,
            escalation_policy TEXT,
            target_contacts TEXT,
            is_decoy INTEGER DEFAULT 0,
            escalation_state TEXT
          );
        ''');

        await db.execute('''
          CREATE TABLE logs(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp INTEGER NOT NULL,
            level TEXT,
            message TEXT
          );
        ''');

        await db.execute('''
          CREATE TABLE emergency_contacts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            uuid TEXT UNIQUE,
            name TEXT NOT NULL,
            phone TEXT NOT NULL,
            channels TEXT,
            priority INTEGER DEFAULT 0,
            notify_all_on_red INTEGER DEFAULT 0,
            notes TEXT,
            created_at INTEGER,
            updated_at INTEGER
          );
        ''');

        await db.execute('''
          CREATE TABLE alert_tasks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            alert_id INTEGER NOT NULL,
            contact_uuid TEXT,
            channel TEXT,
            status TEXT DEFAULT 'pending',
            retries INTEGER DEFAULT 0,
            last_error TEXT,
            created_at INTEGER,
            updated_at INTEGER,
            FOREIGN KEY (alert_id) REFERENCES alerts(id) ON DELETE CASCADE
          );
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 8) {
          try {
            await db.execute(
              "ALTER TABLE alerts ADD COLUMN is_decoy INTEGER DEFAULT 0;",
            );
          } catch (_) {}
          try {
            await db.execute(
              "ALTER TABLE alerts ADD COLUMN escalation_state TEXT;",
            );
          } catch (_) {}
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

  /// ✅ Updates meta field for an existing alert.
  Future<void> updateAlertMeta(int id, String newMeta) async {
    final db = await database;
    await db.update(
      'alerts',
      {'meta': newMeta},
      where: 'id = ?',
      whereArgs: [id],
    );
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

  // ---------------- ALERT TASKS ----------------
  Future<int> insertAlertTask(Map<String, dynamic> task) async {
    final db = await database;
    return await db.insert('alert_tasks', task);
  }

  Future<List<Map<String, dynamic>>> getTasksForAlert(int alertId) async {
    final db = await database;
    return await db.query(
      'alert_tasks',
      where: 'alert_id = ?',
      whereArgs: [alertId],
      orderBy: 'id ASC',
    );
  }

  Future<int> updateTaskStatus(
    int taskId,
    String status, {
    String? error,
    int? retries,
  }) async {
    final db = await database;
    return await db.update(
      'alert_tasks',
      {
        'status': status,
        'last_error': error,
        'retries': retries,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }
}

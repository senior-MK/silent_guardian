// lib/services/contact_service.dart
import 'package:uuid/uuid.dart';
import '../services/db_helper.dart';
import '../models/emergency_contact.dart';

class ContactService {
  final DBHelper _dbHelper = DBHelper();
  final Uuid _u = Uuid();

  /// Create a new contact and return the created EmergencyContact model
  Future<EmergencyContact> createContact({
    required String name,
    required String phone,
    required List<String> channels,
    bool priority = false,
    bool notifyAllOnRed = false,
    String? notes,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final uuid = _u.v4();

    final contact = {
      'uuid': uuid,
      'name': name,
      'phone': phone,
      'channels': channels.join(','), // stored as CSV in DB
      'priority': priority ? 1 : 0,
      'notify_all_on_red': notifyAllOnRed ? 1 : 0,
      'notes': notes,
      'created_at': now,
      'updated_at': now,
    };

    final id = await _dbHelper.insertContact(contact);

    final rows = await _dbHelper.getAllContacts();
    final row = rows.firstWhere((r) => r['id'] == id);

    return EmergencyContact.fromMap(row);
  }

  /// Get all contacts ordered by priority and name
  Future<List<EmergencyContact>> getAllContacts() async {
    final rows = await _dbHelper.getAllContacts();
    return rows.map((r) => EmergencyContact.fromMap(r)).toList();
  }

  /// Get only high-priority contacts
  Future<List<EmergencyContact>> getPriorityContacts() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'emergency_contacts',
      where: 'priority = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return rows.map((r) => EmergencyContact.fromMap(r)).toList();
  }

  /// Update an existing contact
  Future<void> updateContact(EmergencyContact contact) async {
    final updatedData = contact.toMap()
      ..['updated_at'] = DateTime.now().millisecondsSinceEpoch;

    await _dbHelper.updateContact(contact.id!, updatedData);
  }

  /// Delete a contact by its ID
  Future<void> deleteContact(int id) async {
    await _dbHelper.deleteContact(id);
  }

  /// Get contacts by a CSV of UUIDs (for escalation policies, etc.)
  Future<List<EmergencyContact>> getContactsByCsvUuids(String csvUuids) async {
    if (csvUuids.trim().isEmpty) return [];
    final uuids = csvUuids.split(',').where((s) => s.isNotEmpty).toList();

    final db = await _dbHelper.database;
    final where =
        'uuid IN (${List.generate(uuids.length, (_) => '?').join(',')})';
    final rows = await db.query(
      'emergency_contacts',
      where: where,
      whereArgs: uuids,
    );
    return rows.map((r) => EmergencyContact.fromMap(r)).toList();
  }
}

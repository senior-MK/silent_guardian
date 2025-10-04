// lib/services/alert_escalation_service.dart
import 'dart:async';
import 'db_helper.dart';
import 'contact_service.dart';
import 'sms_service.dart';
import 'call_service.dart';
import 'whatsapp_service.dart';

// ✅ Make sure your file name matches this exactly

class AlertEscalationService {
  final ContactService _cs = ContactService();
  final SmsService _sms = SmsService();
  final CallService _call = CallService();
  final WhatsappService _wa = WhatsappService();
  final _dbHelper = DBHelper.instance;

  /// Retry wrapper with backoff
  Future<bool> _withRetry(
    Future<bool> Function() action, {
    int retries = 3,
    Duration delay = const Duration(seconds: 2),
  }) async {
    for (int attempt = 1; attempt <= retries; attempt++) {
      try {
        final result = await action();
        if (result) return true;
      } catch (_) {
        // swallow and retry
      }
      if (attempt < retries) {
        await Future.delayed(delay);
      }
    }
    return false;
  }

  /// Insert a new task row for escalation
  Future<int> _insertTask(
    int alertId,
    String contactUuid,
    String channel,
  ) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    return await db.insert('alert_tasks', {
      'alert_id': alertId,
      'contact_uuid': contactUuid,
      'channel': channel,
      'status': 'sending',
      'retries': 0,
      'created_at': now,
      'updated_at': now,
    });
  }

  /// Update task status after attempt
  Future<void> _updateTask(int taskId, String status, {String? error}) async {
    final db = await _dbHelper.database;
    await db.update(
      'alert_tasks',
      {
        'status': status,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'last_error': error,
      },
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<void> _sendSms(Map<String, dynamic> alert, dynamic contact) async {
    final taskId = await _insertTask(alert['id'], contact.uuid, 'sms');
    try {
      final success = await _withRetry(
        () async => await _sms.sendAlertSms(contact.phone, alert),
      );
      await _updateTask(
        taskId,
        success ? 'sent' : 'failed',
        error: success ? null : 'Failed to send SMS',
      );
    } catch (e) {
      await _updateTask(taskId, 'failed', error: e.toString());
    }
  }

  Future<void> _makeCall(Map<String, dynamic> alert, dynamic contact) async {
    final taskId = await _insertTask(alert['id'], contact.uuid, 'call');
    try {
      final success = await _withRetry(
        () async => await _call.makeAlertCall(contact.phone, alert),
      );
      await _updateTask(
        taskId,
        success ? 'sent' : 'failed',
        error: success ? null : 'Failed to make call',
      );
    } catch (e) {
      await _updateTask(taskId, 'failed', error: e.toString());
    }
  }

  Future<void> _sendWhatsapp(
    Map<String, dynamic> alert,
    dynamic contact,
  ) async {
    final taskId = await _insertTask(alert['id'], contact.uuid, 'whatsapp');
    try {
      final success = await _withRetry(
        () async => await _wa.sendWhatsAppMessage(contact.phone, alert),
      );
      await _updateTask(
        taskId,
        success ? 'sent' : 'failed',
        error: success ? null : 'Failed to send WhatsApp',
      );
    } catch (e) {
      await _updateTask(taskId, 'failed', error: e.toString());
    }
  }

  Future<void> escalateAlertById(int alertId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'alerts',
      where: 'id = ?',
      whereArgs: [alertId],
    );
    if (rows.isEmpty) return;
    final alert = rows.first;

    final isDecoy = (alert['is_decoy'] ?? 0) == 1;
    final csv = alert['target_contacts'] as String? ?? '';
    final contacts = await _cs.getContactsByCsvUuids(csv);

    // Decide which contacts to notify
    List contactsToNotify;
    if (isDecoy) {
      final all = await _cs.getAllContacts();
      contactsToNotify = all
          .where((c) => c.notifyAllOnRed || c.priority)
          .toList();
    } else {
      contactsToNotify = contacts.isNotEmpty
          ? contacts
          : (await _cs.getPriorityContacts());
    }

    for (final c in contactsToNotify) {
      final channels = (c.channels is List)
          ? c.channels
          : (c.channels?.split(',') ?? []);
      for (final ch in channels) {
        if (ch == 'sms') {
          await _sendSms(alert, c);
        } else if (ch == 'call') {
          await _makeCall(alert, c);
        } else if (ch == 'whatsapp' || ch == 'wa') {
          await _sendWhatsapp(alert, c);
        }
      }
    }

    // Mark alert escalated
    await db.update(
      'alerts',
      {
        'escalation_state': 'escalated',
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [alertId],
    );
  }
}

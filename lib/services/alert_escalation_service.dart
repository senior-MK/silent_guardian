// lib/services/alert_escalation_service.dart
import 'dart:convert';
import '../db/database.dart';
import 'contact_service.dart';
import 'sms_service.dart';
import 'call_service.dart';
import 'whatsapp_service.dart';

class AlertEscalationService {
  final ContactService _cs = ContactService();
  final SmsService _sms = SmsService();
  final CallService _call = CallService();
  final WhatsappService _wa = WhatsappService();
  final _dbProvider = AppDatabase();

  Future<void> escalateAlertById(int alertId) async {
    final db = await _dbProvider.database;
    final rows = await db.query('alerts', where: 'id=?', whereArgs: [alertId]);
    if (rows.isEmpty) return;
    final alert = rows.first;
    final isDecoy = (alert['is_decoy'] ?? 0) == 1;
    final csv = alert['target_contacts'] as String? ?? '';
    final contacts = await _cs.getContactsByCsvUuids(csv);

    // If decoy -> escalate to all contacts that have notifyAllOnRed true, else use priority set
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
      // for each channel in contact preference or escalation policy
      for (final ch in c.channels) {
        try {
          if (ch == 'sms') {
            await _sms.sendAlertSms(c.phone, alert); // returns success/failure
          } else if (ch == 'call') {
            await _call.makeAlertCall(c.phone, alert);
          } else if (ch == 'whatsapp') {
            await _wa.sendWhatsAppMessage(c.phone, alert);
          }
        } catch (e) {
          // log and let AlertService retry as necessary
        }
      }
    }

    // mark as escalated
    await db.update(
      'alerts',
      {
        'escalation_state': 'escalated',
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id=?',
      whereArgs: [alertId],
    );
  }
}

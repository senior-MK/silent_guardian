// test/contact_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:your_app/services/contact_service.dart';

void main() {
  final cs = ContactService();

  test('create & fetch contact', () async {
    final c = await cs.createContact(
      name: 'Test',
      phone: '+2547...',
      channels: ['sms', 'call'],
      priority: true,
    );
    expect(c.id, isNotNull);
    final all = await cs.getAllContacts();
    expect(all.any((e) => e.uuid == c.uuid), isTrue);
    await cs.deleteContact(c.id!);
    final all2 = await cs.getAllContacts();
    expect(all2.any((e) => e.uuid == c.uuid), isFalse);
  });
}

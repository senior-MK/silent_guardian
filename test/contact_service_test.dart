import 'package:flutter_test/flutter_test.dart';
import 'package:silent_guardian/models/contact_model.dart';
import 'package:silent_guardian/services/contact_service.dart';

void main() {
  late ContactService service;

  setUp(() async {
    service = ContactService();
    await service.init();
  });

  tearDown(() async {
    final contacts = await service.getContacts();
    for (final c in contacts) {
      await service.deleteContact(c.id!);
    }
  });

  test('Add contact', () async {
    final contact = ContactModel(
      uuid: 'test-uuid-1',
      name: 'Alice',
      phone: '1234567890',
      email: 'alice@example.com',
      channels: 'sms',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final id = await service.addOrUpdateContact(contact);
    expect(id, isNonZero);
  });

  test('Retrieve contact', () async {
    final contact = ContactModel(
      uuid: 'test-uuid-2',
      name: 'Bob',
      phone: '0987654321',
      email: 'bob@example.com',
      channels: 'sms,email',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await service.addOrUpdateContact(contact);
    final contacts = await service.getContacts();

    expect(contacts.any((c) => c.name == 'Bob'), true);
  });

  test('Delete contact', () async {
    final contact = ContactModel(
      uuid: 'test-uuid-3',
      name: 'Charlie',
      phone: '111222333',
      email: 'charlie@example.com',
      channels: 'sms',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final id = await service.addOrUpdateContact(contact);
    await service.deleteContact(id);

    final contacts = await service.getContacts();
    expect(contacts.any((c) => c.name == 'Charlie'), false);
  });
}

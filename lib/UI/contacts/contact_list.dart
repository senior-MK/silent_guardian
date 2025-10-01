// lib/ui/contacts/contacts_list.dart
import 'package:flutter/material.dart';
import '../../services/contact_service.dart';
import '../../models/emergency_contact.dart';
import 'contact_form.dart';

class ContactsListScreen extends StatefulWidget {
  const ContactsListScreen({super.key});

  @override
  _ContactsListScreenState createState() => _ContactsListScreenState();
}

class _ContactsListScreenState extends State<ContactsListScreen> {
  final ContactService _cs = ContactService();
  List<EmergencyContact> contacts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await _cs.getAllContacts();
    setState(() => contacts = all);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Emergency Contacts')),
      body: ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (_, i) {
          final c = contacts[i];
          return ListTile(
            title: Text(c.name),
            subtitle: Text('${c.phone} • ${c.channels.join(', ')}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (c.priority) Icon(Icons.flag, color: Colors.orange),
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ContactForm(contact: c)),
                  ).then((_) => _load()),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () async {
                    await _cs.deleteContact(c.id!);
                    _load();
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ContactForm()),
        ).then((_) => _load()),
        child: Icon(Icons.add),
      ),
    );
  }
}

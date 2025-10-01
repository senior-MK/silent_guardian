// lib/ui/contacts/contact_form.dart
import 'package:flutter/material.dart';
import '../../services/contact_service.dart';
import '../../models/emergency_contact.dart';

class ContactForm extends StatefulWidget {
  final EmergencyContact? contact;
  const ContactForm({super.key, this.contact});

  @override
  _ContactFormState createState() => _ContactFormState();
}

class _ContactFormState extends State<ContactForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _phoneC = TextEditingController();
  bool _priority = false;
  bool _notifyAllOnRed = false;
  List<String> _channels = ['sms'];

  final ContactService _cs = ContactService();

  @override
  void initState() {
    super.initState();
    if (widget.contact != null) {
      _nameC.text = widget.contact!.name;
      _phoneC.text = widget.contact!.phone;
      _priority = widget.contact!.priority;
      _notifyAllOnRed = widget.contact!.notifyAllOnRed;
      _channels = widget.contact!.channels;
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.contact == null) {
      await _cs.createContact(
        name: _nameC.text,
        phone: _phoneC.text,
        channels: _channels,
        priority: _priority,
        notifyAllOnRed: _notifyAllOnRed,
        notes: null,
      );
    } else {
      final updated = widget.contact!.copyWith(
        name: _nameC.text,
        phone: _phoneC.text,
        channels: _channels,
        priority: _priority,
        notifyAllOnRed: _notifyAllOnRed,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await _cs.updateContact(updated);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // simple form: name, phone, channels checkboxes (sms/call/whatsapp), priority toggle
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contact == null ? 'Add Contact' : 'Edit Contact'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameC,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _phoneC,
                decoration: InputDecoration(labelText: 'Phone (E.164)'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              CheckboxListTile(
                value: _channels.contains('sms'),
                onChanged: (v) {
                  setState(
                    () => v! ? _channels.add('sms') : _channels.remove('sms'),
                  );
                },
                title: Text('SMS'),
              ),
              CheckboxListTile(
                value: _channels.contains('call'),
                onChanged: (v) {
                  setState(
                    () => v! ? _channels.add('call') : _channels.remove('call'),
                  );
                },
                title: Text('Call'),
              ),
              CheckboxListTile(
                value: _channels.contains('whatsapp'),
                onChanged: (v) {
                  setState(
                    () => v!
                        ? _channels.add('whatsapp')
                        : _channels.remove('whatsapp'),
                  );
                },
                title: Text('WhatsApp'),
              ),
              SwitchListTile(
                value: _priority,
                onChanged: (v) => setState(() => _priority = v),
                title: Text('Priority contact'),
              ),
              SwitchListTile(
                value: _notifyAllOnRed,
                onChanged: (v) => setState(() => _notifyAllOnRed = v),
                title: Text('Include in red alert'),
              ),
              SizedBox(height: 12),
              ElevatedButton(onPressed: _save, child: Text('Save')),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../services/alert_service.dart';
import '../utils/permissions.dart';

class DecoyPinPage extends StatefulWidget {
  const DecoyPinPage({super.key});

  @override
  _DecoyPinPageState createState() => _DecoyPinPageState();
}

class _DecoyPinPageState extends State<DecoyPinPage> {
  final TextEditingController _pinController = TextEditingController();
  bool _isProcessing = false;

  Future<void> _submitDecoyPin() async {
    setState(() => _isProcessing = true);

    bool micGranted = await Permissions.requestMicrophonePermission(context);
    if (!mounted) return;

    bool locGranted = await Permissions.requestLocationPermission(context);
    if (!mounted) return;

    if (!micGranted || !locGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All permissions are required to send alert.'),
        ),
      );
      setState(() => _isProcessing = false);
      return;
    }

    await AlertService.createDecoyAlert();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Decoy alert triggered!')));

    setState(() => _isProcessing = false);
    _pinController.clear();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Decoy PIN')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _pinController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Enter PIN'),
            ),
            const SizedBox(height: 20),
            _isProcessing
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _submitDecoyPin,
                    child: const Text('Submit PIN'),
                  ),
          ],
        ),
      ),
    );
  }
}

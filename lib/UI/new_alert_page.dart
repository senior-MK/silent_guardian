import 'package:flutter/material.dart';
import '../services/alert_service.dart';
import '../utils/permissions.dart';

class NewAlertPage extends StatefulWidget {
  const NewAlertPage({super.key});

  @override
  _NewAlertPageState createState() => _NewAlertPageState();
}

class _NewAlertPageState extends State<NewAlertPage> {
  bool _isCreatingAlert = false;

  Future<void> _createPanicAlert() async {
    setState(() => _isCreatingAlert = true);

    // Request necessary permissions
    bool camGranted = await Permissions.requestCameraPermission(context);
    if (!mounted) return;

    bool micGranted = await Permissions.requestMicrophonePermission(context);
    if (!mounted) return;

    bool locGranted = await Permissions.requestLocationPermission(context);
    if (!mounted) return;

    if (!camGranted || !micGranted || !locGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All permissions are required to send alert.'),
        ),
      );
      setState(() => _isCreatingAlert = false);
      return;
    }

    // Create alert with current location (if available)
    final alert = await AlertService.createPanicAlert();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Panic alert created successfully!')),
    );

    setState(() => _isCreatingAlert = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Alert')),
      body: Center(
        child: _isCreatingAlert
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _createPanicAlert,
                child: const Text('Create Panic Alert'),
              ),
      ),
    );
  }
}

// lib/ui/countdown_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:silent_guardian/services/audio_service.dart';
import 'package:silent_guardian/services/location_service.dart';
import 'package:silent_guardian/services/alert_service.dart';

class CountdownPage extends StatefulWidget {
  final int seconds;
  const CountdownPage({super.key, this.seconds = 10});

  @override
  CountdownPageState createState() => CountdownPageState();
}

class CountdownPageState extends State<CountdownPage> {
  late int _remaining;
  Timer? _timer;
  String? _recPath;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    _start();
  }

  Future<void> _start() async {
    // Start audio recording (static call)
    try {
      _recPath = await AudioService.startRecording();
    } catch (_) {
      // ignore errors for now
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remaining--;
      });
      if (_remaining <= 0) {
        _finish();
      }
    });
  }

  Future<void> _cancel() async {
    _timer?.cancel();
    await AudioService.stopRecording();

    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _finish() async {
    _timer?.cancel();

    // fetch last known location
    final latLng = await LocationService.getLastKnownPosition();

    // stop recording
    await AudioService.stopRecording();

    // create a panic alert with audio evidence
    await AlertService.createAlertWithEvidence(
      type: AlertType.panic, // use an appropriate AlertType
      evidencePaths: _recPath != null ? [_recPath!] : [],
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    AudioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Countdown')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$_remaining', style: const TextStyle(fontSize: 72)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _cancel, child: const Text('Cancel')),
          ],
        ),
      ),
    );
  }
}

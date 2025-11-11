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
  bool _isRecording = false;

  // Use the static AudioService API (no instance needed)

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    _startCountdown();
  }

  Future<void> _startCountdown() async {
    try {
      _recPath = await AudioService.startRecording();
      _isRecording = true;
      debugPrint('Recording started: $_recPath');
    } catch (e) {
      debugPrint('Audio start error: $e');
      _isRecording = false;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _remaining--;
      });

      if (_remaining <= 0) {
        _finishCountdown();
      }
    });
  }

  Future<void> _cancelCountdown() async {
    _timer?.cancel();

    if (_isRecording) {
      try {
        await AudioService.stopRecording();
        debugPrint('Recording cancelled and stopped.');
      } catch (e) {
        debugPrint('Stop recording error: $e');
      }
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _finishCountdown() async {
    _timer?.cancel();

    if (_isRecording) {
      try {
        await AudioService.stopRecording();
        debugPrint('Recording stopped successfully.');
      } catch (e) {
        debugPrint('Stop recording error: $e');
      }
    }

    // Get last known location for the alert (not used yet)
    await LocationService.getLastKnownPosition();

    try {
      // ✅ Remove 'location' param for now — we’ll handle location differently soon
      await AlertService.createAlertWithEvidence(
        type: AlertType.panic,
        evidencePaths: _recPath != null ? [_recPath!] : [],
      );
      debugPrint('Alert created with evidence: $_recPath');
    } catch (e) {
      debugPrint('Alert creation failed: $e');
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_isRecording) {
      AudioService.stopRecording();
    }
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
            ElevatedButton(
              onPressed: _cancelCountdown,
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

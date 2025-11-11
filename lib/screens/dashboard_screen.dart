// lib/screens/dashboard_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/alert_service.dart';
import '../services/location_service.dart';
import '../services/battery_service.dart';
import '../services/audio_service.dart';
import '../models/alert.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  List<AlertModel> _alerts = [];
  bool _loading = false;
  String _locationText = "Location not loaded";

  // --- Guardian Lock variables ---
  final String _decoyPin = '1234';

  // --- Developer test audio state ---
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    _tryLoadLastKnown();
    BatteryService.startMonitoring();
  }

  @override
  void dispose() {
    BatteryService.stopMonitoring();
    AudioService.dispose();
    super.dispose();
  }

  Future<void> _tryLoadLastKnown() async {
    try {
      final last = await LocationService.getLastKnownPosition();
      if (last != null && mounted) {
        setState(() {
          _locationText =
              "Lat: ${last.latitude.toStringAsFixed(5)}, Lon: ${last.longitude.toStringAsFixed(5)} (last known)";
        });
      }
    } catch (_) {}
  }

  // ------------------------------------------------------------
  // 🔹 AUDIO TEST (Developer)
  // ------------------------------------------------------------
  Future<void> _startRecording() async {
    try {
      _audioPath = await AudioService.startRecording();
      setState(() => _isRecording = true);
    } catch (e) {
      debugPrint('Recording failed: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      await AudioService.stopRecording();
      setState(() => _isRecording = false);
    } catch (e) {
      debugPrint('Stop recording failed: $e');
    }
  }

  Future<void> _playAudio() async {
    if (_audioPath == null) return;
    try {
      await AudioService.playFile(_audioPath!);
      setState(() => _isPlaying = true);
      AudioService.positionStream?.listen((event) {
        if (event.position >= event.duration) {
          setState(() => _isPlaying = false);
        }
      });
    } catch (e) {
      debugPrint('Playback failed: $e');
      setState(() => _isPlaying = false);
    }
  }

  Future<void> _stopAudio() async {
    await AudioService.stopPlayback();
    setState(() => _isPlaying = false);
  }

  // ------------------------------------------------------------
  // 🔹 ALERT CREATION
  // ------------------------------------------------------------
  Future<void> _showAlerts() async {
    setState(() => _loading = true);
    try {
      final alerts = await AlertService.getAllAlerts();
      if (!mounted) return;
      setState(() => _alerts = alerts);
    } catch (e, st) {
      debugPrint('showAlerts error: $e\n$st');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onPanicPressed() async {
    setState(() => _loading = true);
    try {
      await AlertService.createPanicAlert(extraMeta: 'user_triggered_panic');
      await _showAlerts();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('🚨 Panic alert created')));
    } catch (e) {
      debugPrint('panic create error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onRedAlertPressed() async {
    setState(() => _loading = true);
    try {
      await AlertService.createRedAlert(extraMeta: 'manual_test_red_alert');
      await _showAlerts();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🟥 Red alert (decoy) created')),
      );
    } catch (e) {
      debugPrint('red alert error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ------------------------------------------------------------
  // 🔹 GUARDIAN LOCK
  // ------------------------------------------------------------
  Future<void> _startGuardianLockCountdown(int seconds) async {
    final guardianId = await AlertService.createGuardianLock(
      durationSeconds: seconds,
      extraMeta: 'started_by_user',
    );

    debugPrint('Guardian lock id=$guardianId started for $seconds sec');
    int remaining = seconds;
    Timer? timer;

    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setStateDialog) {
            timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
              remaining--;
              if (remaining <= 0) {
                timer?.cancel();
                if (Navigator.of(ctx2).canPop()) {
                  Navigator.of(ctx2).pop('expired');
                }
              } else {
                setStateDialog(() {});
              }
            });

            return AlertDialog(
              title: Text('Guardian Lock: $remaining s remaining'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'You can cancel or enter decoy PIN to trigger a Red Alert.',
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: 'Enter decoy PIN to silently trigger red alert',
                    ),
                    onSubmitted: (val) async {
                      if (val == _decoyPin) {
                        timer?.cancel();
                        Navigator.of(ctx2).pop('decoy');
                      } else {
                        ScaffoldMessenger.of(ctx2).showSnackBar(
                          const SnackBar(content: Text('Wrong PIN')),
                        );
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    timer?.cancel();
                    Navigator.of(ctx2).pop('cancelled');
                  },
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    ).then((result) async {
      timer?.cancel();

      if (result == 'decoy') {
        await AlertService.createRedAlert(
          extraMeta: jsonEncode({'from_guardian_id': guardianId}),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Red alert triggered (decoy PIN)')),
        );
      } else if (result == 'expired') {
        final escalationId = await AlertService.createEscalationAlert(
          guardianId: guardianId,
          extraMeta: 'auto_escalation',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Escalation alert created')),
        );

        // 🎬 Automatically stop recordings after 30 seconds
        Future.delayed(const Duration(seconds: 30), () async {
          await AlertService.stopAllRecordings(escalationId.toString());
          debugPrint('🎥 Recordings stopped for escalation $escalationId');
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guardian Lock cancelled')),
        );
      }
    });
  }

  // ------------------------------------------------------------
  // 🔹 LOCATION
  // ------------------------------------------------------------
  Future<void> _loadLocation() async {
    setState(() => _loading = true);
    try {
      final pos = await LocationService.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _locationText =
            "Lat: ${pos.latitude.toStringAsFixed(5)}, Lon: ${pos.longitude.toStringAsFixed(5)}";
      });
    } catch (e) {
      debugPrint('getCurrentLocation failed: $e');
      try {
        final last = await LocationService.getLastKnownPosition();
        if (last != null && mounted) {
          setState(() {
            _locationText =
                "Lat: ${last.latitude.toStringAsFixed(5)}, Lon: ${last.longitude.toStringAsFixed(5)} (last known)";
          });
        } else if (mounted) {
          setState(() => _locationText = "Location unavailable: $e");
        }
      } catch (e2) {
        debugPrint('last known failed: $e2');
        if (mounted) setState(() => _locationText = "Location error: $e");
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _iconForType(String t) {
    switch (t) {
      case 'guardian_lock':
        return const Icon(Icons.lock_clock, color: Colors.orange);
      case 'escalation':
        return const Icon(Icons.warning, color: Colors.deepOrange);
      case 'panic':
        return const Icon(Icons.pan_tool, color: Colors.red);
      case 'red_alert':
        return const Icon(Icons.dangerous, color: Colors.redAccent);
      case 'low_battery':
        return const Icon(Icons.battery_alert, color: Colors.grey);
      default:
        return const Icon(Icons.notification_important);
    }
  }

  // ------------------------------------------------------------
  // 🔹 BUILD UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Silent Guardian Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- Guardian & Panic controls ---
            ElevatedButton(
              onPressed: () => _startGuardianLockCountdown(30),
              child: const Text('🕒 Guardian Lock (30s)'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _onPanicPressed,
              child: const Text('🚨 Panic Alert'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _onRedAlertPressed,
              child: const Text('🟥 Trigger Red Alert (Decoy)'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _showAlerts,
              child: const Text('📜 Show Alerts'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loadLocation,
              child: const Text('📍 Show My Location'),
            ),
            const SizedBox(height: 20),

            // --- Audio Test (developer only) ---
            if (kDebugMode) ...[
              const Divider(),
              const Text(
                '🎧 Audio Test (Dev Only)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _isRecording ? _stopRecording : _startRecording,
                    child: Text(
                      _isRecording ? '⏹ Stop Recording' : '🎙 Start Recording',
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isPlaying ? _stopAudio : _playAudio,
                    child: Text(
                      _isPlaying ? '⏹ Stop Playback' : '▶️ Play Audio',
                    ),
                  ),
                ],
              ),
              const Divider(),
            ],

            const SizedBox(height: 12),
            Text(
              _locationText,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // --- Alerts list ---
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _alerts.isEmpty
                  ? const Center(child: Text('No alerts yet'))
                  : ListView.builder(
                      itemCount: _alerts.length,
                      itemBuilder: (context, index) {
                        final alert = _alerts[index];
                        final ts = DateTime.fromMillisecondsSinceEpoch(
                          alert.timestamp,
                        ).toLocal();
                        final lat = alert.latitude != null
                            ? alert.latitude!.toStringAsFixed(5)
                            : 'N/A';
                        final lon = alert.longitude != null
                            ? alert.longitude!.toStringAsFixed(5)
                            : 'N/A';
                        return ListTile(
                          leading: _iconForType(alert.type),
                          title: Text(alert.type.toUpperCase()),
                          subtitle: Text(
                            '${ts.toString()} | Lat: $lat, Lon: $lon\nmeta: ${alert.meta ?? ''}',
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

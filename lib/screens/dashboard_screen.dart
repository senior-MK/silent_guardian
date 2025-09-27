// lib/screens/dashboard_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/alert_service.dart';
import '../services/location_service.dart';
import '../services/battery_service.dart';
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

  // Decoy PIN for testing. Later connect to secure storage/user settings
  final String _decoyPin = '1234';

  @override
  void initState() {
    super.initState();
    _tryLoadLastKnown();
    BatteryService.startMonitoring(); // start real low battery monitoring
  }

  @override
  void dispose() {
    BatteryService.stopMonitoring(); // cleanup timer
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

  // Dev-only test alert
  Future<void> _createTestAlert([String label = 'dev_test']) async {
    setState(() => _loading = true);
    try {
      final id = await AlertService.createPanicAlert(extraMeta: 'test:$label');
      debugPrint('Panic created id=$id');
      final alerts = await AlertService.getAllAlerts();
      if (!mounted) return;
      setState(() => _alerts = alerts);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Dev Test Alert inserted')),
      );
    } catch (e, st) {
      debugPrint('createTestAlert error: $e\n$st');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
      final alerts = await AlertService.getAllAlerts();
      if (!mounted) return;
      setState(() => _alerts = alerts);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Panic alert created')));
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
      final alerts = await AlertService.getAllAlerts();
      if (!mounted) return;
      setState(() => _alerts = alerts);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Red alert (decoy) created')),
      );
    } catch (e) {
      debugPrint('red alert error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startGuardianLockCountdown(int seconds) async {
    final guardianId = await AlertService.createGuardianLock(
      durationSeconds: seconds,
      extraMeta: 'started_by_user',
    );
    debugPrint('guardian lock id=$guardianId started for $seconds sec');

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
        await AlertService.createEscalationAlert(
          guardianId: guardianId,
          extraMeta: 'auto_escalation',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Escalation alert created')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guardian Lock cancelled')),
        );
      }
    });
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => _startGuardianLockCountdown(30),
              child: const Text('Guardian Lock (30s)'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _onPanicPressed,
              child: const Text('Panic Alert'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _onRedAlertPressed,
              child: const Text('Trigger Red Alert (decoy)'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _showAlerts,
              child: const Text('Show Alerts'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loadLocation,
              child: const Text('Show My Location'),
            ),
            // Dev-only button
            if (kDebugMode) ...[
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _createTestAlert("Dev"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                ),
                child: const Text('⚡ Insert Test Alert (Dev Only)'),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              _locationText,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
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

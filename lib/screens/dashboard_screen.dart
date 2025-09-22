import 'package:flutter/material.dart';
import '../services/alert_service.dart';
import '../models/alert.dart';
import '../services/location_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  List<AlertModel> _alerts = [];
  bool _loading = false;
  String _locationText = "Location not loaded";

  Future<void> _createTestAlert() async {
    setState(() => _loading = true);
    try {
      await AlertService.createTestAlert(
        meta: 'created from dashboard test button',
      );
      final alerts = await AlertService.getAllAlerts();
      if (!mounted) return; // Ensure widget is still mounted
      setState(() {
        _alerts = alerts;
      });
      if (!mounted) return; // Ensure widget is still mounted
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Test Alert Created!")));
    } catch (e, st) {
      debugPrint('createTestAlert error: $e\n$st');
      if (!mounted) return; // Ensure widget is still mounted
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error creating alert: $e")));
    } finally {
      if (!mounted) return; // Ensure widget is still mounted
      setState(() => _loading = false);
    }
  }

  Future<void> _showAlerts() async {
    setState(() => _loading = true);
    try {
      final alerts = await AlertService.getAllAlerts();
      if (!mounted) return; // Ensure widget is still mounted
      setState(() => _alerts = alerts);
    } catch (e, st) {
      debugPrint('showAlerts error: $e\n$st');
      if (!mounted) return; // Ensure widget is still mounted
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading alerts: $e")));
    } finally {
      if (!mounted) return; // Ensure widget is still mounted
      setState(() => _loading = false);
    }
  }

  Future<void> _loadLocation() async {
    setState(() => _loading = true);
    try {
      debugPrint('Requesting current location...');
      final pos = await LocationService.getCurrentLocation();
      debugPrint('Got current location: ${pos.latitude}, ${pos.longitude}');
      if (!mounted) return; // Ensure widget is still mounted
      setState(() {
        _locationText =
            "Lat: ${pos.latitude.toStringAsFixed(5)}, Lon: ${pos.longitude.toStringAsFixed(5)}";
      });
    } catch (e, st) {
      debugPrint('getCurrentLocation failed: $e\n$st');
      try {
        debugPrint('Trying last known position...');
        final last = await LocationService.getLastKnownPosition();
        if (!mounted) return; // Ensure widget is still mounted
        if (last != null) {
          debugPrint('Last known: ${last.latitude}, ${last.longitude}');
          setState(() {
            _locationText =
                "Lat: ${last.latitude.toStringAsFixed(5)}, Lon: ${last.longitude.toStringAsFixed(5)} (last known)";
          });
        } else {
          debugPrint('No last known position available.');
          setState(() => _locationText = "Location unavailable: $e");
        }
      } catch (e2, st2) {
        debugPrint('getLastKnownPosition failed: $e2\n$st2');
        if (!mounted) return; // Ensure widget is still mounted
        setState(() => _locationText = "Location error: $e");
      }
    } finally {
      if (!mounted) return; // Ensure widget is still mounted
      setState(() => _loading = false);
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
              onPressed: _createTestAlert,
              child: const Text('Create Test Alert'),
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
            const SizedBox(height: 16),
            Text(
              _locationText,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Wrap the Expanded widget in a Flexible parent
            Flexible(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _alerts.isEmpty
                  ? const Center(child: Text("No alerts yet"))
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
                          leading: const Icon(Icons.notification_important),
                          title: Text(alert.type),
                          subtitle: Text(
                            "${ts.toString()} | Lat: $lat, Lon: $lon | synced: ${alert.synced}",
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

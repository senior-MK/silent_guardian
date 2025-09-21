import 'package:flutter/material.dart';
import '../services/alert_service.dart';
import '../models/alert.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  List<AlertModel> _alerts = [];
  bool _loading = false;

  Future<void> _createTestAlert() async {
    setState(() {
      _loading = true;
    });

    await AlertService.createTestAlert(
      meta: 'created from dashboard test button',
    );

    final alerts = await AlertService.getAllAlerts();
    setState(() {
      _alerts = alerts;
      _loading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Test Alert Created!")));
    }
  }

  Future<void> _showAlerts() async {
    setState(() {
      _loading = true;
    });

    final alerts = await AlertService.getAllAlerts();
    setState(() {
      _alerts = alerts;
      _loading = false;
    });
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
            const SizedBox(height: 20),
            Expanded(
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
                        return ListTile(
                          leading: const Icon(Icons.notification_important),
                          title: Text(alert.type),
                          subtitle: Text(
                            "${ts.toString()} | synced: ${alert.synced}",
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

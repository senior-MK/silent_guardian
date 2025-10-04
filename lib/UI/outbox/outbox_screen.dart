// lib/ui/outbox/outbox_screen.dart
import 'package:flutter/material.dart';
import '../../services/db_helper.dart';
import '../../models/alert.dart';
import 'alert_detail.dart';

class OutboxScreen extends StatefulWidget {
  const OutboxScreen({super.key});

  @override
  State<OutboxScreen> createState() => _OutboxScreenState();
}

class _OutboxScreenState extends State<OutboxScreen> {
  final db = DBHelper.instance;
  List<AlertModel> alerts = [];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    final dbClient = await db.database;
    final rows = await dbClient.query('alerts', orderBy: 'timestamp DESC');
    if (!mounted) return; // ✅ prevents setState after dispose
    setState(() {
      alerts = rows.map((e) => AlertModel.fromMap(e)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Outbox")),
      body: alerts.isEmpty
          ? const Center(child: Text("📭 No alerts found"))
          : RefreshIndicator(
              onRefresh: _loadAlerts, // ✅ Pull to refresh
              child: ListView.builder(
                itemCount: alerts.length,
                itemBuilder: (context, i) {
                  final a = alerts[i];
                  return ListTile(
                    title: Text(a.type),
                    subtitle: Text("State: ${a.escalationState ?? 'pending'}"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AlertDetailScreen(alert: a),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}

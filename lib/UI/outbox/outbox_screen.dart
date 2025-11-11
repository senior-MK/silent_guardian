import 'package:flutter/material.dart';
import '../../services/db_helper.dart';
import '../../models/alert.dart';
import 'alert_detail.dart';
import '../../widgets/simple_audio_player.dart'; // ✅ Added

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
    if (!mounted) return;
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
              onRefresh: _loadAlerts,
              child: ListView.builder(
                itemCount: alerts.length,
                itemBuilder: (context, i) {
                  final a = alerts[i];
                  return ListTile(
                    title: Text(a.type),
                    subtitle: Text("State: ${a.escalationState ?? 'pending'}"),
                    trailing: SimpleAudioPlayer(
                      filePath:
                          '/storage/emulated/0/SilentGuardian/Evidence/${a.id}/audio.m4a',
                    ),
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

import 'package:flutter/material.dart';
import '../../services/db_helper.dart';
import '../../models/alert.dart';
import '../../widgets/simple_audio_player.dart'; // ✅ Added

class AlertDetailScreen extends StatefulWidget {
  final AlertModel alert;
  const AlertDetailScreen({super.key, required this.alert});

  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  final db = DBHelper.instance;
  List<Map<String, dynamic>> tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final dbClient = await db.database;
    final rows = await dbClient.query(
      'alert_tasks',
      where: 'alert_id=?',
      whereArgs: [widget.alert.id],
    );
    setState(() => tasks = rows);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Alert ${widget.alert.id}")),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, i) {
          final t = tasks[i];
          return Card(
            child: ListTile(
              title: Text("${t['channel']} → ${t['contact_uuid']}"),
              subtitle: Text(
                "Status: ${t['status']} (retries: ${t['retries']})",
              ),
              trailing: SimpleAudioPlayer(
                filePath:
                    '/storage/emulated/0/SilentGuardian/Evidence/${widget.alert.id}/audio.m4a',
              ),
            ),
          );
        },
      ),
    );
  }
}

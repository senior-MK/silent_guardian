import 'dart:developer' as developer;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'db_helper.dart';
import '../models/alert.dart';

/// Handles syncing of unsynced alerts to backend (later in roadmap).
/// For now it only marks as synced locally to simulate flow.
class SyncService {
  final DBHelper _db = DBHelper();

  /// Check connectivity and sync unsynced alerts
  Future<void> syncAlerts() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        developer.log("No network, skipping sync", name: "sync_service");
        return;
      }

      final unsynced = await _db.getUnsyncedAlerts();
      developer.log(
        "Found ${unsynced.length} unsynced alerts",
        name: "sync_service",
      );

      for (AlertModel alert in unsynced) {
        // 🔹 Placeholder: here is where real backend API call will go (A9/A10).
        developer.log(
          "Uploading alert ${alert.id} type=${alert.type}",
          name: "sync_service",
        );

        // Simulate success: mark as synced locally
        await _db.markAlertSynced(alert.id!);
      }
    } catch (e) {
      developer.log("Sync failed: $e", name: "sync_service");
    }
  }
}

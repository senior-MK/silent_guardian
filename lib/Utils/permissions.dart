// lib/utils/permissions.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';

class Permissions {
  /// Request location permission
  static Future<bool> requestLocationPermission(BuildContext context) async {
    final status = await Permission.location.request();

    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      _showOpenSettingsDialog(
        context,
        title: 'Location Permission',
        message:
            'Location access is permanently denied. Please enable it in app settings.',
      );
    }

    return false;
  }

  /// Request camera permission
  static Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.request();

    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      _showOpenSettingsDialog(
        context,
        title: 'Camera Permission',
        message:
            'Camera access is permanently denied. Please enable it in app settings.',
      );
    }

    return false;
  }

  /// Request microphone permission
  static Future<bool> requestMicrophonePermission(BuildContext context) async {
    final status = await Permission.microphone.request();

    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      _showOpenSettingsDialog(
        context,
        title: 'Microphone Permission',
        message:
            'Microphone access is permanently denied. Please enable it in app settings.',
      );
    }

    return false;
  }

  /// Request storage permission (read/write)
  static Future<bool> requestStoragePermission(BuildContext context) async {
    final status = await Permission.storage.request();

    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      _showOpenSettingsDialog(
        context,
        title: 'Storage Permission',
        message:
            'Storage access is permanently denied. Please enable it in app settings.',
      );
    }

    return false;
  }

  /// Helper to show a dialog and open app settings
  static void _showOpenSettingsDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                AppSettings.openAppSettings(); // ✅ correct for 6.1.1
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }
}

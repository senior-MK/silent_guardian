import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Ensures that a 'recordings' directory exists inside the app's documents directory.
Future<Directory> getRecordingsDirectory() async {
  final baseDir = await getApplicationDocumentsDirectory();
  final dir = Directory('${baseDir.path}/recordings');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}

/// Generates a new unique path for an upcoming audio file.
Future<String> newRecordingPath(String nameBase) async {
  final dir = await getRecordingsDirectory();
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  return '${dir.path}/${nameBase}_$timestamp.m4a';
}

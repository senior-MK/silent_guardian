// lib/ui/attachments_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/audio_service.dart';
import '../services/alert_service.dart';

class AttachmentsPage extends StatefulWidget {
  const AttachmentsPage({super.key});

  @override
  AttachmentsPageState createState() => AttachmentsPageState();
}

class AttachmentsPageState extends State<AttachmentsPage> {
  final ImagePicker _picker = ImagePicker();
  final List<String> _photos = [];
  String? _audioPath;
  bool _recording = false;

  @override
  void initState() {
    super.initState();
    // prepare recorder using the static AudioService API
    AudioService.initRecorder();
  }

  Future<void> _takePhoto() async {
    final x = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
    );
    if (x != null && mounted) {
      setState(() => _photos.add(x.path));
    }
  }

  Future<void> _toggleRecord() async {
    if (!_recording) {
      try {
        // start recording via static API
        _audioPath = await AudioService.startRecording();
        if (mounted) setState(() => _recording = true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mic permission denied or error')),
          );
        }
      }
    } else {
      // stop recording via static API
      await AudioService.stopRecording();
      if (mounted) setState(() => _recording = false);
    }
  }

  Future<void> _saveAlert() async {
    final List<String> evidence = [
      if (_audioPath != null) _audioPath!,
      ..._photos,
    ];

    await AlertService.createAlertWithEvidence(
      type: AlertType.panic,
      evidencePaths: evidence.isNotEmpty ? evidence : null,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Alert saved successfully')));
    Navigator.pop(context);
  }

  @override
  void dispose() {
    // dispose audio service resources
    AudioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attachments')),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            if (_photos.isNotEmpty)
              Wrap(
                spacing: 8,
                children: _photos
                    .map(
                      (p) => Image.file(
                        File(p),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _takePhoto,
              child: const Text('Take Photo'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _toggleRecord,
              child: Text(_recording ? 'Stop Recording' : 'Start Recording'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveAlert,
              child: const Text('Save Alert with Attachments'),
            ),
          ],
        ),
      ),
    );
  }
}

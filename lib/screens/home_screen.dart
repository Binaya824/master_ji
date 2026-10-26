import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import 'answer_key_screen.dart';
import 'omr_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Uint8List? _answerKeyImage;

  @override
  void initState() {
    super.initState();
    _loadAnswerKeyPreview();
  }

  Future<void> _loadAnswerKeyPreview() async {
    final image = await StorageService.loadAnswerKeyImage();
    if (mounted) setState(() => _answerKeyImage = image);
  }

  Future<void> _openAnswerKeyScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AnswerKeyScreen()),
    );
    _loadAnswerKeyPreview(); // pick up a freshly-saved answer key, if any
  }

  void _showAnswerKeyPreview() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Image.memory(_answerKeyImage!),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OMR Scanner')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: _openAnswerKeyScreen,
                icon: const Icon(Icons.vpn_key),
                label: const Text('Scan Answer Key'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
              if (_answerKeyImage != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _showAnswerKeyPreview,
                  icon: const Icon(Icons.image),
                  label: const Text('View saved answer key'),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OmrScreen()),
                ),
                icon: const Icon(Icons.document_scanner),
                label: const Text('Scan OMR'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

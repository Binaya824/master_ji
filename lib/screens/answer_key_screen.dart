import 'package:flutter/material.dart';

import '../models/omr_result.dart';
import '../services/storage_service.dart';
import '../widgets/scan_flow_screen.dart';

class AnswerKeyScreen extends StatelessWidget {
  const AnswerKeyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScanFlowScreen(
      title: 'Scan Answer Key',
      pickButtonLabel: 'Scan Answer Key',
      onResult: (result) => StorageService.saveAnswerKey(result),
      extraContentBuilder: (context, OmrResult result) => Card(
        color: Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Answer key saved (${result.filledCount} answers marked). '
            'It will be used for every OMR scan until you scan a new one.',
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/omr_result.dart';
import '../services/storage_service.dart';
import '../widgets/scan_flow_screen.dart';

class OmrScreen extends StatefulWidget {
  const OmrScreen({super.key});

  @override
  State<OmrScreen> createState() => _OmrScreenState();
}

class _OmrScreenState extends State<OmrScreen> {
  Map<String, int>? _answerKey;
  bool _answerKeyLoaded = false;

  @override
  void initState() {
    super.initState();
    StorageService.loadAnswerKeyResults().then((key) {
      setState(() {
        _answerKey = key;
        _answerKeyLoaded = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScanFlowScreen(
      title: 'Scan OMR',
      pickButtonLabel: 'Scan OMR',
      extraContentBuilder: (context, OmrResult result) {
        final answered =
            result.results.values.where((v) => v != 0).length;

        if (!_answerKeyLoaded) {
          return const SizedBox.shrink();
        }
        if (_answerKey == null) {
          return const Card(
            color: Color(0xFFFFF3CD),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'No answer key saved yet, so correct answers can\'t be '
                'computed. Scan an answer key first.',
              ),
            ),
          );
        }

        final correct = result.results.entries
            .where((e) =>
                e.value != 0 && _answerKey![e.key] == e.value)
            .length;

        return Row(
          children: [
            Expanded(child: _StatCard(label: 'Answer found', value: answered)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: 'Correct answer', value: correct)),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text('$value', style: Theme.of(context).textTheme.headlineMedium),
            Text(label),
          ],
        ),
      ),
    );
  }
}

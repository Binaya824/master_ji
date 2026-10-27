import 'package:flutter/material.dart';

import '../models/omr_result.dart';
import '../services/omr_service.dart';
import 'image_source_sheet.dart';

/// Shared pick -> upload -> preview flow used by both the answer-key and
/// OMR scan screens. [onResult] runs side effects after a successful scan
/// (e.g. saving to disk); [extraContentBuilder] renders screen-specific
/// content below the returned image (e.g. the answer comparison counts).
class ScanFlowScreen extends StatefulWidget {
  final String title;
  final String pickButtonLabel;
  final Future<void> Function(OmrResult result)? onResult;
  final Widget Function(BuildContext context, OmrResult result)?
      extraContentBuilder;

  const ScanFlowScreen({
    super.key,
    required this.title,
    required this.pickButtonLabel,
    this.onResult,
    this.extraContentBuilder,
  });

  @override
  State<ScanFlowScreen> createState() => _ScanFlowScreenState();
}

class _ScanFlowScreenState extends State<ScanFlowScreen> {
  OmrResult? _result;
  bool _loading = false;
  String? _error;

  Future<void> _pickAndProcess() async {
    final file = await pickImageFromSource(context);
    if (file == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await OmrService.process(file);
      await widget.onResult?.call(result);
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to process image: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: _loading ? null : _pickAndProcess,
                icon: const Icon(Icons.camera_alt),
                label: Text(widget.pickButtonLabel),
              ),
              const SizedBox(height: 16),
              if (_loading) const Center(child: CircularProgressIndicator()),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              if (_result != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(_result!.imageBytes),
                ),
                const SizedBox(height: 16),
                if (widget.extraContentBuilder != null)
                  widget.extraContentBuilder!(context, _result!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

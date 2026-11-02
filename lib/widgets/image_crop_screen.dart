import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'primary_button.dart';

const double _handleRadius = 14;
// Finger movement is amplified before moving a corner/edge — a 1:1 mapping
// felt sluggish since real screen drags are short relative to the crop box.
const double _dragSensitivity = 2.2;

/// Lets the user drag the 4 corners of a quadrilateral over the picked
/// image (for perspective-correcting a photographed sheet) and rotate it
/// in 90° steps, then warps/crops to that quad on [done].
///
/// Pops with the cropped [XFile], or null if the user cancelled.
class ImageCropScreen extends StatefulWidget {
  final Uint8List bytes;

  const ImageCropScreen({super.key, required this.bytes});

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  late cv.Mat _mat;
  late Uint8List _previewBytes;
  late List<Offset> _corners; // image-pixel space: TL, TR, BR, BL
  bool _busy = false;

  int get _imgW => _mat.cols;
  int get _imgH => _mat.rows;

  @override
  void initState() {
    super.initState();
    _mat = cv.imdecode(widget.bytes, cv.IMREAD_COLOR);
    _previewBytes = widget.bytes;
    _resetCorners();
  }

  @override
  void dispose() {
    _mat.dispose();
    super.dispose();
  }

  void _resetCorners() {
    _corners = [
      Offset.zero,
      Offset(_imgW.toDouble(), 0),
      Offset(_imgW.toDouble(), _imgH.toDouble()),
      Offset(0, _imgH.toDouble()),
    ];
  }

  void _rotate() {
    setState(() => _busy = true);
    final rotated = cv.rotate(_mat, cv.ROTATE_90_CLOCKWISE);
    _mat.dispose();
    _mat = rotated;
    final encoded = cv.imencode('.jpg', _mat);
    setState(() {
      _previewBytes = encoded.$2;
      _resetCorners();
      _busy = false;
    });
  }

  Future<void> _confirm() async {
    setState(() => _busy = true);
    final src = cv.VecPoint2f.fromList([
      for (final c in _corners) cv.Point2f(c.dx, c.dy),
    ]);
    final widthTop = (_corners[1] - _corners[0]).distance;
    final widthBottom = (_corners[2] - _corners[3]).distance;
    final heightLeft = (_corners[3] - _corners[0]).distance;
    final heightRight = (_corners[2] - _corners[1]).distance;
    final outW = math.max(widthTop, widthBottom).round().clamp(1, 1 << 16);
    final outH = math.max(heightLeft, heightRight).round().clamp(1, 1 << 16);
    final dst = cv.VecPoint2f.fromList([
      cv.Point2f(0, 0),
      cv.Point2f(outW.toDouble(), 0),
      cv.Point2f(outW.toDouble(), outH.toDouble()),
      cv.Point2f(0, outH.toDouble()),
    ]);
    final transform = cv.getPerspectiveTransform2f(src, dst);
    final warped = cv.warpPerspective(_mat, transform, (outW, outH));
    final encoded = cv.imencode('.jpg', warped);
    if (!mounted) return;
    Navigator.pop(
      context,
      XFile.fromData(
        encoded.$2,
        mimeType: 'image/jpeg',
        name: 'cropped.jpg',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Crop & Straighten'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.rotate_90_degrees_cw_rounded),
            tooltip: 'Rotate 90°',
            onPressed: _busy ? null : _rotate,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.sp16),
                child: _busy
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : _CropCanvas(
                        previewBytes: _previewBytes,
                        imageSize: Size(_imgW.toDouble(), _imgH.toDouble()),
                        corners: _corners,
                        onCornersChanged: (c) => setState(() => _corners = c),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.sp16),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _busy ? null : () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.sp16),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Done',
                      loading: _busy,
                      onPressed: _confirm,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fits [previewBytes] inside the available box (BoxFit.contain) and
/// overlays 4 draggable corner handles + the quad they form, all in the
/// same screen-space as the image, converting to/from image-pixel space
/// at the box's own scale.
class _CropCanvas extends StatelessWidget {
  final Uint8List previewBytes;
  final Size imageSize;
  final List<Offset> corners;
  final ValueChanged<List<Offset>> onCornersChanged;

  const _CropCanvas({
    required this.previewBytes,
    required this.imageSize,
    required this.corners,
    required this.onCornersChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        final imgAspect = imageSize.width / imageSize.height;

        double dispW, dispH;
        if (maxW / maxH > imgAspect) {
          dispH = maxH;
          dispW = dispH * imgAspect;
        } else {
          dispW = maxW;
          dispH = dispW / imgAspect;
        }
        final scale = dispW / imageSize.width;
        final left = (maxW - dispW) / 2;
        final top = (maxH - dispH) / 2;

        Offset toScreen(Offset p) =>
            Offset(left + p.dx * scale, top + p.dy * scale);

        final screenCorners = corners.map(toScreen).toList();

        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              width: dispW,
              height: dispH,
              child: Image.memory(previewBytes, fit: BoxFit.fill),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _QuadPainter(screenCorners),
              ),
            ),
            // Edge bars: dragging the middle of a side moves both its
            // corners together. Drawn under the corner handles so a corner
            // always wins a tap where the two overlap.
            for (var i = 0; i < corners.length; i++)
              _EdgeHandle(
                start: screenCorners[i],
                end: screenCorners[(i + 1) % corners.length],
                onDragUpdate: (delta) {
                  final a = i;
                  final b = (i + 1) % corners.length;
                  final d = delta / scale;
                  final next = [...corners];
                  next[a] = Offset(
                    (next[a].dx + d.dx).clamp(0, imageSize.width),
                    (next[a].dy + d.dy).clamp(0, imageSize.height),
                  );
                  next[b] = Offset(
                    (next[b].dx + d.dx).clamp(0, imageSize.width),
                    (next[b].dy + d.dy).clamp(0, imageSize.height),
                  );
                  onCornersChanged(next);
                },
              ),
            for (var i = 0; i < corners.length; i++)
              _CornerHandle(
                center: screenCorners[i],
                onDragUpdate: (delta) {
                  // ponytail: corners aren't reordered if dragged past a
                  // neighbor — fine for the straighten-a-photo use case,
                  // revisit with convex-hull reordering if that bites.
                  final next = [...corners];
                  final moved = next[i] + delta / scale;
                  next[i] = Offset(
                    moved.dx.clamp(0, imageSize.width),
                    moved.dy.clamp(0, imageSize.height),
                  );
                  onCornersChanged(next);
                },
              ),
          ],
        );
      },
    );
  }
}

class _CornerHandle extends StatelessWidget {
  final Offset center;
  final ValueChanged<Offset> onDragUpdate;

  const _CornerHandle({required this.center, required this.onDragUpdate});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: center.dx - _handleRadius,
      top: center.dy - _handleRadius,
      width: _handleRadius * 2,
      height: _handleRadius * 2,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) =>
            onDragUpdate(details.delta * _dragSensitivity),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(color: Colors.black38, blurRadius: 4),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small bar centered on an edge's midpoint, rotated to align with that
/// edge; dragging it moves both of the edge's corners by the same delta.
class _EdgeHandle extends StatelessWidget {
  static const double _length = 32;

  final Offset start;
  final Offset end;
  final ValueChanged<Offset> onDragUpdate;

  const _EdgeHandle({
    required this.start,
    required this.end,
    required this.onDragUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final mid = Offset.lerp(start, end, 0.5)!;
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);

    return Positioned(
      left: mid.dx - _length / 2,
      top: mid.dy - _length / 2,
      width: _length,
      height: _length,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) =>
            onDragUpdate(details.delta * _dragSensitivity),
        child: Center(
          child: Transform.rotate(
            angle: angle,
            child: Container(
              width: _length,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuadPainter extends CustomPainter {
  final List<Offset> corners;

  _QuadPainter(this.corners);

  @override
  void paint(Canvas canvas, Size size) {
    if (corners.length != 4) return;
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path()..addPolygon(corners, true);
    canvas.drawPath(path, paint);

    final fillPaint = Paint()..color = AppColors.primary.withValues(alpha: 0.12);
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(_QuadPainter oldDelegate) => oldDelegate.corners != corners;
}

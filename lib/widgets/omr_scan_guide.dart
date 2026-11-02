import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

const double _sheetAspect = 210 / 297; // A4 portrait, width/height
const double _headerRatio = 0.58;
const int _totalQuestions = 50;
const int _gridCount = 3;

List<int> _splitQuestions(int total, int grids) {
  final base = total ~/ grids;
  final extra = total % grids;
  return [for (var g = 0; g < grids; g++) base + (g < extra ? 1 : 0)];
}

/// The answer-bubble block's bounds within a sheet of [size] — shared by the
/// static sheet painter and the animated highlight so they line up exactly.
Rect _answerBlockRect(Size size) {
  final top = size.height * _headerRatio;
  final sideMargin = size.width * 0.04;
  final bottomMargin = size.height * 0.03;
  return Rect.fromLTRB(
    sideMargin,
    top,
    size.width - sideMargin,
    size.height - bottomMargin,
  );
}

/// Animated preview of how to frame an OMR sheet: a schematic A4 sheet with
/// a header block and a 50-question, 3-grid answer block, with that answer
/// block pulsing + scan-lined to show "frame only this part" while scanning.
class ScanGuidePreview extends StatefulWidget {
  final double height;

  const ScanGuidePreview({super.key, this.height = 220});

  @override
  State<ScanGuidePreview> createState() => _ScanGuidePreviewState();
}

class _ScanGuidePreviewState extends State<ScanGuidePreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Fit within whatever space is given (e.g. half a row), capped at
        // [widget.height] when the parent imposes no height limit.
        final maxH = constraints.hasBoundedHeight
            ? math.min(constraints.maxHeight, widget.height)
            : widget.height;
        final maxW =
            constraints.hasBoundedWidth ? constraints.maxWidth : maxH * _sheetAspect;

        double w, h;
        if (maxW / maxH > _sheetAspect) {
          h = maxH;
          w = h * _sheetAspect;
        } else {
          w = maxW;
          h = w / _sheetAspect;
        }
        final size = Size(w, h);

        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            children: [
              CustomPaint(size: size, painter: _OmrSheetPainter()),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => CustomPaint(
                  size: size,
                  painter: _ScanHighlightPainter(_controller.value),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Static schematic of the sheet: border, corner alignment marks, header
/// placeholder lines, and the 3-grid, 50-question bubble block.
class _OmrSheetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sheetPaint = Paint()..color = Colors.white;
    final borderPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height).deflate(0.6),
      const Radius.circular(6),
    );
    canvas.drawRRect(rrect, sheetPaint);
    canvas.drawRRect(rrect, borderPaint);

    // Corner alignment marks, like a real OMR sheet.
    final markPaint = Paint()..color = Colors.grey.shade700;
    const markSize = 6.0;
    canvas.drawRect(const Rect.fromLTWH(6, 6, markSize, markSize), markPaint);
    canvas.drawRect(
      Rect.fromLTWH(size.width - 6 - markSize, 6, markSize, markSize),
      markPaint,
    );

    final headerHeight = size.height * _headerRatio;
    final boxBorder = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    final linePaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Title bar.
    canvas.drawLine(
      Offset(size.width * 0.3, headerHeight * 0.03),
      Offset(size.width * 0.7, headerHeight * 0.03),
      Paint()
        ..color = Colors.grey.shade500
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Instructions box: a bordered paragraph of thin lines, like the
    // "read the instructions" block on a real sheet.
    final instructionsBox = Rect.fromLTWH(
      size.width * 0.06,
      headerHeight * 0.07,
      size.width * 0.88,
      headerHeight * 0.22,
    );
    canvas.drawRect(instructionsBox, boxBorder);
    for (var i = 0; i < 5; i++) {
      final y = instructionsBox.top +
          instructionsBox.height * (0.14 + i * 0.16);
      canvas.drawLine(
        Offset(instructionsBox.left + 4, y),
        Offset(
          instructionsBox.right - 4 - (i.isEven ? 0 : instructionsBox.width * 0.2),
          y,
        ),
        linePaint,
      );
    }

    // Name / Class / Roll No lines (left) + Date of Examination digit
    // cells (right).
    final infoTop = instructionsBox.bottom + headerHeight * 0.04;
    for (var i = 0; i < 3; i++) {
      final y = infoTop + headerHeight * 0.05 * i;
      canvas.drawLine(
        Offset(size.width * 0.06, y),
        Offset(size.width * 0.56, y),
        linePaint,
      );
    }
    final dateCellSize = headerHeight * 0.045;
    for (var i = 0; i < 6; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * 0.62 + i * (dateCellSize + 1.5),
          infoTop - dateCellSize * 0.6,
          dateCellSize,
          dateCellSize,
        ),
        boxBorder,
      );
    }

    // Centre code / Subject code lines.
    final codeTop = infoTop + headerHeight * 0.18;
    for (var i = 0; i < 2; i++) {
      canvas.drawLine(
        Offset(size.width * 0.06, codeTop + headerHeight * 0.045 * i),
        Offset(size.width * 0.7, codeTop + headerHeight * 0.045 * i),
        linePaint,
      );
    }

    // Candidate + invigilator signature boxes, side by side.
    final sigTop = codeTop + headerHeight * 0.12;
    final sigHeight = headerHeight * 0.1;
    final sigWidth = size.width * 0.4;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.06, sigTop, sigWidth, sigHeight),
      boxBorder,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.52, sigTop, sigWidth, sigHeight),
      boxBorder,
    );

    // Tick-mark strip spanning the sheet width.
    final tickY = sigTop + sigHeight + headerHeight * 0.05;
    final tickPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;
    const tickCount = 22;
    for (var i = 0; i < tickCount; i++) {
      final x = size.width * 0.06 +
          i * (size.width * 0.88) / (tickCount - 1);
      canvas.drawLine(
        Offset(x, tickY),
        Offset(x, tickY + headerHeight * 0.025),
        tickPaint,
      );
    }

    // Answer block: 3 grids, 50 questions total (e.g. 17/17/16).
    final block = _answerBlockRect(size);
    final perGrid = _splitQuestions(_totalQuestions, _gridCount);
    final gridWidth = block.width / _gridCount;

    final circlePaint = Paint()
      ..color = Colors.grey.shade500
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final numberPainter = TextPainter(textDirection: TextDirection.ltr);

    var q = 1;
    for (var g = 0; g < _gridCount; g++) {
      final rows = perGrid[g];
      final gridLeft = block.left + g * gridWidth;
      final rowHeight = block.height / rows;
      final circleRadius = math.min(rowHeight * 0.32, gridWidth * 0.07);

      for (var r = 0; r < rows; r++) {
        final rowCenterY = block.top + r * rowHeight + rowHeight / 2;

        numberPainter.text = TextSpan(
          text: '$q',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: math.min(rowHeight * 0.55, 7.0),
          ),
        );
        numberPainter.layout();
        numberPainter.paint(
          canvas,
          Offset(gridLeft + 2, rowCenterY - numberPainter.height / 2),
        );

        final optionsStartX = gridLeft + gridWidth * 0.34;
        final optionsSpacing = gridWidth * 0.16;
        for (var o = 0; o < 4; o++) {
          canvas.drawCircle(
            Offset(optionsStartX + o * optionsSpacing, rowCenterY),
            circleRadius,
            circlePaint,
          );
        }
        q++;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OmrSheetPainter oldDelegate) => false;
}

/// Pulsing border + a sweeping scan-line over the answer block only, to
/// signal "frame just this region" while scanning.
class _ScanHighlightPainter extends CustomPainter {
  final double t; // 0..1, ping-ponging via the controller's repeat(reverse: true)

  _ScanHighlightPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final block = _answerBlockRect(size);

    final borderPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.5 + 0.5 * t)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 + t;
    canvas.drawRRect(
      RRect.fromRectAndRadius(block, const Radius.circular(4)),
      borderPaint,
    );

    final scanY = block.top + block.height * t;
    final scanRect = Rect.fromLTWH(block.left, scanY - 6, block.width, 12);
    final scanPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0),
          AppColors.primary.withValues(alpha: 0.8),
          AppColors.primary.withValues(alpha: 0),
        ],
      ).createShader(scanRect);
    canvas.drawRect(scanRect, scanPaint);
  }

  @override
  bool shouldRepaint(covariant _ScanHighlightPainter oldDelegate) =>
      oldDelegate.t != t;
}

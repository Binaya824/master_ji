import 'dart:math' as math;

import 'package:image_picker/image_picker.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

import '../models/omr_result.dart';

typedef _Bubble = (double, double, double);

class _SheetBox {
  final int x;
  final int y;
  final int width;
  final int height;

  const _SheetBox(this.x, this.y, this.width, this.height);
}

/// Dart translation of the Python OMR pipeline.
class OmrService {
  static const int optionsPerQuestion = 4;

  static Future<OmrResult> process(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final img = cv.imdecode(bytes, cv.IMREAD_COLOR);

    if (img.isEmpty) {
      throw Exception('Could not decode image.');
    }

    final box = _findLargestRectangle(img);

    final contourCircles = _normalizeRadius(
      _filterSimilarSize(_findCircles(img, box)),
    );

    final contourColumns = _buildGrid(contourCircles);
    final contourScore = _gridScore(contourColumns);

    final houghCircles = _normalizeRadius(
      _filterSimilarSize(_findCirclesHough(img, box)),
    );

    final houghColumns = _buildGrid(houghCircles);
    final houghScore = _gridScore(houghColumns);

    // Match Python: choose the contour grid when scores are equal.
    final selectedColumns =
        contourScore >= houghScore ? contourColumns : houghColumns;

    if (selectedColumns.isEmpty) {
      throw Exception(
        'Could not reconstruct the answer grid. '
        'The detected bubble layout did not form four-option groups.',
      );
    }

    // Sort columns from left to right.
    selectedColumns.sort((a, b) {
      final ax = _mean([
        for (final row in a)
          for (final bubble in row) bubble.$1,
      ]);

      final bx = _mean([
        for (final row in b)
          for (final bubble in row) bubble.$1,
      ]);

      return ax.compareTo(bx);
    });

    final gray = cv.cvtColor(img, cv.COLOR_BGR2GRAY);

    final allBubbles = <_Bubble>[
      for (final column in selectedColumns)
        for (final row in column)
          ...row,
    ];

    final fillRatios = allBubbles
        .map((bubble) => _fillRatio(gray, bubble))
        .toList();

    final threshold = _fillThreshold(fillRatios);

    final results = <String, int>{};
    var rowNumber = 1;
    var filledCount = 0;

    for (final column in selectedColumns) {
      for (final row in column) {
        var filledIndex = 0;

        for (var optionIndex = 0;
            optionIndex < row.length;
            optionIndex++) {
          final bubble = row[optionIndex];
          final filled = _fillRatio(gray, bubble) >= threshold;

          if (filled) {
            filledCount++;

            // Match Python: the first filled bubble wins if multiple are marked.
            if (filledIndex == 0) {
              filledIndex = optionIndex + 1;
            }

            cv.circle(
              img,
              cv.Point(bubble.$1.round(), bubble.$2.round()),
              bubble.$3.round(),
              cv.Scalar.fromRgb(0, 255, 0),
              thickness: 2,
            );
          }
        }

        results['$rowNumber'] = filledIndex;
        rowNumber++;
      }
    }

    final encoded = cv.imencode('.png', img);

    return OmrResult(
      circleCount: _gridScore(selectedColumns),
      columnCount: selectedColumns.length,
      filledCount: filledCount,
      results: results,
      imageBytes: encoded.$2,
    );
  }

  // ---------------------------------------------------------------------------
  // Python: find_largest_rectangle()
  // ---------------------------------------------------------------------------

  static _SheetBox _findLargestRectangle(
    cv.Mat img, {
    double areaRatio = 0.3,
    int targetSize = 1000,
  }) {
    final h = img.rows;
    final w = img.cols;

    final scale = math.min(1.0, targetSize / math.max(h, w));

    final small = scale < 1.0
        ? cv.resize(
            img,
            (0, 0),
            fx: scale,
            fy: scale,
            interpolation: cv.INTER_AREA,
          )
        : img;

    final gray = cv.cvtColor(small, cv.COLOR_BGR2GRAY);
    final blurred = cv.gaussianBlur(gray, (5, 5), 0);
    final edges = cv.canny(blurred, 50, 150);

    final kernel = cv.getStructuringElement(cv.MORPH_RECT, (3, 3));
    final dilated = cv.dilate(edges, kernel, iterations: 1);

    final contourResult = cv.findContours(
      dilated,
      cv.RETR_EXTERNAL,
      cv.CHAIN_APPROX_SIMPLE,
    );

    final contours = contourResult.$1;

    if (contours.isEmpty) {
      throw Exception('No sheet contours found.');
    }

    final areas = <double>[
      for (final contour in contours) cv.contourArea(contour),
    ];

    final maxArea = areas.reduce(math.max);

    if (maxArea <= 0) {
      throw Exception('Could not identify the answer sheet boundary.');
    }

    final boxes = <cv.Rect>[];

    for (var i = 0; i < contours.length; i++) {
      if (areas[i] >= areaRatio * maxArea) {
        boxes.add(cv.boundingRect(contours.elementAt(i)));
      }
    }

    if (boxes.isEmpty) {
      throw Exception('Could not identify the answer sheet boundary.');
    }

    final x0 = boxes.map((b) => b.x).reduce(math.min);
    final y0 = boxes.map((b) => b.y).reduce(math.min);
    final x1 = boxes.map((b) => b.x + b.width).reduce(math.max);
    final y1 = boxes.map((b) => b.y + b.height).reduce(math.max);

    return _SheetBox(
      (x0 / scale).round(),
      (y0 / scale).round(),
      ((x1 - x0) / scale).round(),
      ((y1 - y0) / scale).round(),
    );
  }

  // ---------------------------------------------------------------------------
  // Python: _normalized_roi()
  // ---------------------------------------------------------------------------

  static ({
    cv.Mat image,
    double scale,
    int offsetX,
    int offsetY,
  }) _normalizedRoi(
    cv.Mat img,
    _SheetBox box, {
    int targetSize = 1000,
  }) {
    final x = box.x.clamp(0, img.cols - 1);
    final y = box.y.clamp(0, img.rows - 1);
    final width = box.width.clamp(1, img.cols - x);
    final height = box.height.clamp(1, img.rows - y);

    final crop = cv.Mat.fromMat(
      img,
      roi: cv.Rect(x, y, width, height),
    );

    final scale =
        math.min(1.0, targetSize / math.max(height, width));

    final small = scale < 1.0
        ? cv.resize(
            crop,
            (0, 0),
            fx: scale,
            fy: scale,
            interpolation: cv.INTER_AREA,
          )
        : crop;

    return (
      image: small,
      scale: scale,
      offsetX: x,
      offsetY: y,
    );
  }

  // ---------------------------------------------------------------------------
  // Python: find_circles()
  // ---------------------------------------------------------------------------

  static List<_Bubble> _findCircles(
    cv.Mat img,
    _SheetBox box, {
    int minArea = 15,
    int maxArea = 400,
    double minCircularity = 0.7,
    double dedupDist = 4,
  }) {
    final normalized = _normalizedRoi(img, box);
    final roi = normalized.image;
    final roiScale = normalized.scale;
    final x = normalized.offsetX;
    final y = normalized.offsetY;

    final gray = cv.cvtColor(roi, cv.COLOR_BGR2GRAY);

    final threshold = cv.adaptiveThreshold(
      gray,
      255,
      cv.ADAPTIVE_THRESH_MEAN_C,
      cv.THRESH_BINARY_INV,
      15,
      5,
    );

    final found = cv.findContours(
      threshold,
      cv.RETR_LIST,
      cv.CHAIN_APPROX_SIMPLE,
    );

    final contours = found.$1;
    final circles = <_Bubble>[];

    for (final contour in contours) {
      final area = cv.contourArea(contour);

      if (area < minArea || area > maxArea) continue;

      final perimeter = cv.arcLength(contour, true);
      if (perimeter == 0) continue;

      final circularity =
          4 * math.pi * area / (perimeter * perimeter);

      if (circularity < minCircularity) continue;

      final enclosing = cv.minEnclosingCircle(contour);
      final center = enclosing.$1;
      final radius = enclosing.$2;

      if (radius <= 2) continue;

      circles.add((
        x + center.x / roiScale,
        y + center.y / roiScale,
        radius / roiScale,
      ));
    }

    // Larger circles first; suppress nearby duplicates.
    circles.sort((a, b) => b.$3.compareTo(a.$3));

    final kept = <_Bubble>[];
    final dedupDistanceOriginal = dedupDist / roiScale;
    final dedupDistanceSquared =
        dedupDistanceOriginal * dedupDistanceOriginal;

    for (final candidate in circles) {
      final duplicate = kept.any((existing) {
        final dx = candidate.$1 - existing.$1;
        final dy = candidate.$2 - existing.$2;

        return dx * dx + dy * dy < dedupDistanceSquared;
      });

      if (!duplicate) kept.add(candidate);
    }

    return kept;
  }

  // ---------------------------------------------------------------------------
  // Python: find_circles_hough()
  // ---------------------------------------------------------------------------

  static List<_Bubble> _findCirclesHough(
    cv.Mat img,
    _SheetBox box,
  ) {
    final normalized = _normalizedRoi(img, box);
    final roi = normalized.image;
    final roiScale = normalized.scale;
    final x = normalized.offsetX;
    final y = normalized.offsetY;

    final h = roi.rows;
    final gray = cv.cvtColor(roi, cv.COLOR_BGR2GRAY);
    final medianBlurred = cv.medianBlur(gray, 5);
    final blurred = cv.gaussianBlur(medianBlurred, (5, 5), 0);

    var bestCircles = <_Bubble>[];
    var bestScore = 0;

    for (var minRadius = 3;
        minRadius < math.max(5, h ~/ 12);
        minRadius += 2) {
      final maxRadius = (minRadius * 1.8).round() + 2;

      for (final param2 in [12, 14, 16, 20]) {
        final found = cv.HoughCircles(
          blurred,
          cv.HOUGH_GRADIENT,
          1,
          minRadius * 1.3,
          param1: 40,
          param2: param2.toDouble(),
          minRadius: minRadius,
          maxRadius: maxRadius,
        );

        if (found.isEmpty) continue;

        final candidates = <_Bubble>[];

        for (final circleRow in found.toList3D()) {
          for (final circle in circleRow) {
            candidates.add((
              x + circle[0] / roiScale,
              y + circle[1] / roiScale,
              circle[2] / roiScale,
            ));
          }
        }

        final normalizedCandidates = _normalizeRadius(
          _filterSimilarSize(candidates),
        );

        final grid = _buildGrid(normalizedCandidates);
        final score = _gridScore(grid);

        if (score > bestScore) {
          bestScore = score;
          bestCircles = candidates;
        }
      }
    }

    return bestCircles;
  }

  // ---------------------------------------------------------------------------
  // Python: filter_similar_size()
  // ---------------------------------------------------------------------------

  static List<_Bubble> _filterSimilarSize(
    List<_Bubble> circles, {
    double tolerance = 0.2,
  }) {
    if (circles.isEmpty) return circles;

    final medianRadius = _median(circles.map((c) => c.$3).toList());

    return circles
        .where(
          (circle) =>
              (circle.$3 - medianRadius).abs() <=
              tolerance * medianRadius,
        )
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Python: normalize_radius()
  // ---------------------------------------------------------------------------

  static List<_Bubble> _normalizeRadius(List<_Bubble> circles) {
    if (circles.isEmpty) return circles;

    final counts = <int, int>{};

    for (final circle in circles) {
      final radius = circle.$3.round();
      counts[radius] = (counts[radius] ?? 0) + 1;
    }

    var modeRadius = counts.keys.first;
    var modeCount = counts[modeRadius]!;

    for (final entry in counts.entries) {
      if (entry.value > modeCount) {
        modeRadius = entry.key;
        modeCount = entry.value;
      }
    }

    return [
      for (final circle in circles)
        (circle.$1, circle.$2, modeRadius.toDouble()),
    ];
  }

  // ---------------------------------------------------------------------------
  // Python: cluster_1d()
  // ---------------------------------------------------------------------------

  static List<double> _cluster1D(
    List<double> values,
    double tolerance,
  ) {
    if (values.isEmpty) return [];

    final sorted = [...values]..sort();
    final clusters = <List<double>>[];
    var current = <double>[sorted.first];

    for (final value in sorted.skip(1)) {
      if (value - current.last <= tolerance) {
        current.add(value);
      } else {
        clusters.add(current);
        current = <double>[value];
      }
    }

    clusters.add(current);

    return clusters.map(_mean).toList();
  }

  // ---------------------------------------------------------------------------
  // Python: build_grid()
  // ---------------------------------------------------------------------------

  static List<List<List<_Bubble>>> _buildGrid(
    List<_Bubble> circles, {
    int optionsPerRow = optionsPerQuestion,
  }) {
    if (circles.length < optionsPerRow) return [];

    final radius = circles.first.$3;

    final rowCenters = _cluster1D(
      circles.map((c) => c.$2).toList(),
      radius * 0.8,
    );

    final columnCenters = _cluster1D(
      circles.map((c) => c.$1).toList(),
      radius * 0.8,
    );

    if (columnCenters.length < optionsPerRow || rowCenters.length < 2) {
      return [];
    }

    double spacingOf(List<double> centers) {
      final sorted = [...centers]..sort();
      final diffs = <int>[];

      for (var i = 1; i < sorted.length; i++) {
        diffs.add((sorted[i] - sorted[i - 1]).round());
      }

      if (diffs.isEmpty) return 0;

      final counts = <int, int>{};

      for (final diff in diffs) {
        counts[diff] = (counts[diff] ?? 0) + 1;
      }

      var mode = diffs.first;
      var modeCount = counts[mode]!;

      for (final entry in counts.entries) {
        if (entry.value > modeCount) {
          mode = entry.key;
          modeCount = entry.value;
        }
      }

      return mode.toDouble();
    }

    List<double> uniformPositions(
      List<double> centers,
      double spacing,
    ) {
      final sorted = [...centers]..sort();
      final edge = sorted.reduce(math.min) - radius;

      return [
        for (var k = 0; k < sorted.length; k++)
          edge + radius + k * spacing,
      ];
    }

    final sortedColumns = [...columnCenters]..sort();
    final columnSpacing = spacingOf(sortedColumns);

    if (columnSpacing <= 0) return [];

    final blocks = <List<double>>[
      [sortedColumns.first],
    ];

    for (var i = 1; i < sortedColumns.length; i++) {
      final previous = sortedColumns[i - 1];
      final current = sortedColumns[i];

      if (current - previous > 1.5 * columnSpacing) {
        blocks.add([]);
      }

      blocks.last.add(current);
    }

    final sortedRows = [...rowCenters]..sort();
    final rowSpacing = spacingOf(sortedRows);

    if (rowSpacing <= 0) return [];

    final ys = uniformPositions(sortedRows, rowSpacing);
    final columns = <List<List<_Bubble>>>[];

    for (final block in blocks) {
      if (block.length != optionsPerRow) continue;

      final xs = uniformPositions(block, columnSpacing);

      columns.add([
        for (final y in ys)
          [
            for (final x in xs)
              (x, y, radius),
          ],
      ]);
    }

    return columns;
  }

  static int _gridScore(List<List<List<_Bubble>>> columns) {
    return columns.fold<int>(
      0,
      (sum, column) => sum + column.length * optionsPerQuestion,
    );
  }

  // ---------------------------------------------------------------------------
  // Python: fill_ratio()
  // ---------------------------------------------------------------------------

  static double _fillRatio(
    cv.Mat gray,
    _Bubble bubble, {
    double sampleScale = 0.85,
    int darkThreshold = 127,
  }) {
    final cx = bubble.$1;
    final cy = bubble.$2;
    final radius = bubble.$3;
    final r2 = radius * sampleScale;

    final y0 = (cy - r2).floor();
    final y1 = (cy + r2).ceil() + 1;
    final x0 = (cx - r2).floor();
    final x1 = (cx + r2).ceil() + 1;

    final clippedX0 = x0.clamp(0, gray.cols);
    final clippedY0 = y0.clamp(0, gray.rows);
    final clippedX1 = x1.clamp(0, gray.cols);
    final clippedY1 = y1.clamp(0, gray.rows);

    if (clippedX1 <= clippedX0 || clippedY1 <= clippedY0) {
      return 0;
    }

    final patchWidth = clippedX1 - clippedX0;
    final patchHeight = clippedY1 - clippedY0;

    final patch = cv.Mat.fromMat(
      gray,
      roi: cv.Rect(
        clippedX0,
        clippedY0,
        patchWidth,
        patchHeight,
      ),
    );

    final inkMask = cv.threshold(
      patch,
      darkThreshold.toDouble(),
      255,
      cv.THRESH_BINARY_INV,
    ).$2;

    final circularMask = cv.Mat.zeros(
      patchHeight,
      patchWidth,
      cv.MatType.CV_8UC1,
    );

    cv.circle(
      circularMask,
      cv.Point(
        (cx - clippedX0).round(),
        (cy - clippedY0).round(),
      ),
      r2.round(),
      cv.Scalar.all(255),
      thickness: -1,
    );

    final sampledInk = cv.bitwiseAND(inkMask, circularMask);
    final sampledPixels = cv.countNonZero(circularMask);

    if (sampledPixels == 0) return 0;

    return cv.countNonZero(sampledInk) / sampledPixels;
  }

  // ---------------------------------------------------------------------------
  // Python: fill_threshold()
  // ---------------------------------------------------------------------------

  static double _fillThreshold(
    List<double> ratios, {
    double defaultThreshold = 0.9,
    double minGap = 0.06,
  }) {
    if (ratios.isEmpty) {
      return defaultThreshold;
    }

    final sorted = [...ratios]..sort();

    var largestGap = 0.0;
    var lower = 0.0;
    var upper = 0.0;

    for (var i = 0; i < sorted.length - 1; i++) {
      final a = sorted[i];
      final b = sorted[i + 1];
      final gap = b - a;

      if (gap > largestGap) {
        largestGap = gap;
        lower = a;
        upper = b;
      }
    }

    return largestGap >= minGap
        ? (lower + upper) / 2
        : defaultThreshold;
  }

  static double _mean(List<double> values) {
    if (values.isEmpty) return 0;

    return values.reduce((a, b) => a + b) / values.length;
  }

  static double _median(List<double> values) {
    if (values.isEmpty) return 0;

    final sorted = [...values]..sort();
    final middle = sorted.length ~/ 2;

    if (sorted.length.isOdd) return sorted[middle];

    return (sorted[middle - 1] + sorted[middle]) / 2;
  }
}

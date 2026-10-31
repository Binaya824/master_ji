import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

import '../models/omr_result.dart';

typedef _Bubble = (int x, int y, int r);

/// Bubbles straight from Hough, before circles.py rounds them (it keeps
/// float centers through _reject_isolated/_reject_text_columns and only
/// rounds (int(round(x))) afterwards; rounding earlier shifts the pitch
/// and chain grouping and changes which glyph columns get dropped).
typedef _RawBubble = (double x, double y, double r);

/// Dart port of the OMR pipeline in script/circles.py: detect bubbles with
/// Hough circles, then group them into grids/rows/columns purely from their
/// own layout (gap clustering along the sheet's real tilt, not an assumed
/// axis-aligned grid), and score each bubble's fill via an Otsu dark-ratio.
class OmrService {
  /// Working resolution the Hough/clustering constants below were tuned
  /// against (script/circles.py, run on a 1280x960 sample). Uploaded images
  /// — which can be much higher resolution — are scaled to this first so
  /// those fixed-pixel thresholds behave consistently regardless of upload
  /// size.
  static const int workingLongSide = 1280;

  static const double fillThreshold = 0.80;

  /// Grid-to-grid gaps (the Q.No. lane) and row/column gaps are both
  /// multiples of bubble pitch (nearest-neighbor spacing) — grid gaps are
  /// always much wider than row/column gaps, which is what separates them.
  static const double gridGapFactor = 2.2;

  /// Rows and columns inside a grid are clustered at a tight 0.35 * pitch
  /// (also used by _rejectSparseClusters). This must match, else the
  /// population filter sees a different chain than the numbering pass:
  /// with perspective shearing, two adjacent real option columns can sit
  /// less than 0.6 * pitch apart, and merging them in one pass but not the
  /// other deletes a real column. Bubbles in one row share y to within a
  /// couple of pixels while real adjacent rows are a full pitch apart, so
  /// the tight threshold never merges real rows.
  static const double localGapFactor = 0.35;

  static Future<OmrResult> process(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    // Decode straight to grayscale, exactly like circles.py
    // (cv2.imread(path, IMREAD_GRAYSCALE)): the,Otsu ink mask and fill
    // ratios are computed on these values, so routing a color decode
    // through cvtColor (which rounds differently) shifts borderline
    // bubbles and changes answers vs the Python reference.
    final decoded = cv.imdecode(bytes, cv.IMREAD_GRAYSCALE);

    if (decoded.isEmpty) {
      throw Exception('Could not decode image.');
    }

    // High-resolution uploads are scaled down (tiny ones capped-upscaled) so
    // the fixed pixel thresholds below behave consistently.
    final img = _normalizeResolution(decoded, targetSize: workingLongSide);
    // Already grayscale; cvtColor(COLOR_BGR2GRAY) on a gray Mat is the
    // identity keeping channel layout, so just alias it.
    final gray = img;

    var detected = _detectBubbles(gray);
    assert(() {
      debugPrint('OMR stage detect=${detected.length}');
      return true;
    }());
    detected = _filterByRawRadius(detected);
    assert(() {
      debugPrint('OMR stage rawRadius=${detected.length}');
      return true;
    }());
    detected = _rejectIsolated(detected);
    assert(() {
      debugPrint('OMR stage iso=${detected.length}');
      return true;
    }());
    detected = _rejectTextColumns(detected);
    assert(() {
      debugPrint('OMR stage textcol=${detected.length}');
      return true;
    }());
    // circles.py rounds (int(round(x))) only here, after the float-precision
    // iso/text-column filters.
    final roundedDetected = [
      for (final b in detected) (b.$1.round(), b.$2.round(), b.$3.round()),
    ];
    // Sparse-filter per grid, not globally: a short final grid (e.g. 5
    // questions while other grids have 15) has much sparser columns/rows
    // than the tall ones, so a global population-ratio filter would delete
    // the entire short grid. Split grids first (using this sheet's own tilt
    // and bubble pitch), then filter each grid relative to itself.
    var bubbles = _perGridSparseFilter(roundedDetected);
    assert(() {
      debugPrint('OMR stage pergrid=${bubbles.length}');
      return true;
    }());

    // Python converts the gray image to BGR so filled-bubble annotations render correctly.
    final output = cv.cvtColor(img, cv.COLOR_GRAY2BGR);

    if (bubbles.isEmpty) {
      final encoded = cv.imencode('.png', output);
      return OmrResult(
        circleCount: 0,
        columnCount: 0,
        filledCount: 0,
        results: const {},
        imageBytes: encoded.$2,
      );
    }

    final mostCommonRadius = _mode([for (final b in bubbles) b.$3]);

    // circles.py outlines EVERY detected bubble in green (thickness 2),
    // then redraws the filled ones thicker below.
    // for (final b in bubbles) {
    //   cv.circle(
    //     output,
    //     cv.Point(b.$1, b.$2),
    //     mostCommonRadius,
    //     cv.Scalar.fromRgb(0, 255, 0),
    //     thickness: 2,
    //   );
    // }

    // How "filled" each bubble is: % of its own area that is dark ink.
    // First normalize out uneven illumination: shaded bands and glare
    // pools make parts of the sheet grey, and a plain global Otsu on the
    // raw image reads that grey as ink - empty bubbles under the shading
    // then look "filled" (everything marked in those grids). Dividing by
    // the local background (a heavy closing that removes dark ink and
    // leaves paper brightness) flattens the illumination, after which Otsu
    // cleanly separates ink from paper everywhere.
    final bgKernel = cv.getStructuringElement(cv.MORPH_ELLIPSE, (
      4 * mostCommonRadius + 1,
      4 * mostCommonRadius + 1,
    ));
    final bg = cv.morphologyEx(gray, cv.MORPH_CLOSE, bgKernel);
    final normed = cv.divide(gray, bg, scale: 255);
    final darkMask =
        cv.threshold(normed, 0, 255, cv.THRESH_BINARY_INV | cv.THRESH_OTSU).$2;

    final filled = <_Bubble, bool>{};
    var filledCount = 0;

    for (final b in bubbles) {
      final ratio = _fillRatio(darkMask, b.$1, b.$2, mostCommonRadius);
      final isFilled = ratio >= fillThreshold;
      filled[b] = isFilled;

      if (isFilled) {
        filledCount++;
        cv.circle(
          output,
          cv.Point(b.$1, b.$2),
          mostCommonRadius,
          cv.Scalar.fromRgb(0, 255, 0),
          thickness: 3,
        );
      }
    }

    // Group circles into answer grids (3, 4, 5... whatever the sheet has),
    // following the sheet's real tilt instead of forcing straight lines.
    final questionOf = <_Bubble, int>{};
    final optionOf = <_Bubble, int>{};
    final layout =
        _layoutGrids(bubbles, questionOf, optionOf, output, mostCommonRadius);

    // Answer key: question_no -> filled option, 0 if none (or more than
    // one) bubble was marked filled for that row.
    final results = <String, int>{};
    for (var q = 1; q <= layout.totalQuestions; q++) {
      final filledOptions = [
        for (final b in bubbles)
          if (questionOf[b] == q && filled[b] == true) optionOf[b]!,
      ];
      results['$q'] = filledOptions.length == 1 ? filledOptions.first : 0;
    }

    if (kDebugMode) {
      debugPrint(
        'OMR debug: grids=${layout.numGrids} questions=${layout.totalQuestions} '
        'bubbles=${bubbles.length} filled=$filledCount',
      );
    }

    final encoded = cv.imencode('.png', output);

    return OmrResult(
      circleCount: bubbles.length,
      columnCount: layout.numGrids,
      filledCount: filledCount,
      results: results,
      imageBytes: encoded.$2,
    );
  }

  // ---------------------------------------------------------------------------
  // Working-resolution normalization — small images are upscaled (capped) and
  // large images downscaled so every stage runs at a consistent scale.
  // ---------------------------------------------------------------------------

  static cv.Mat _normalizeResolution(
    cv.Mat img, {
    int targetSize = 1000,
    double maxUpscale = 4.0,
  }) {
    final h = img.rows;
    final w = img.cols;
    final longest = math.max(h, w).toDouble();
    if (longest <= 0) return img;

    var scale = targetSize / longest;

    // Cap upscaling so tiny images don't blow up memory / runtime.
    if (scale > maxUpscale) scale = maxUpscale;

    if ((scale - 1.0).abs() < 0.01) return img;

    return cv.resize(
      img,
      (0, 0),
      fx: scale,
      fy: scale,
      interpolation: scale > 1.0 ? cv.INTER_CUBIC : cv.INTER_AREA,
    );
  }

  // ---------------------------------------------------------------------------
  // Bubble detection — mirrors script/circles.py: a 2-pass adaptive Hough
  // sweep (first pass estimates this sheet's real bubble radius, second
  // pass re-detects in that tight window), then two cleanup passes that
  // drop Hough false-positives instead of a fixed pixel header-cutoff.
  // ---------------------------------------------------------------------------

  static List<_RawBubble> _detectBubbles(cv.Mat gray) {
    final blurred = cv.gaussianBlur(gray, (7, 7), 1.5);

    // Pass 1: wide radius net, just to estimate this sheet's real bubble size.
    final wide = cv.HoughCircles(
      blurred,
      cv.HOUGH_GRADIENT,
      1.2,
      12,
      param1: 60,
      param2: 28,
      minRadius: 6,
      maxRadius: (workingLongSide * 0.03).floor(),
    );
    if (wide.isEmpty) return [];

    final wideRadii = [
      for (final row in wide.toList3D())
        for (final c in row) c[2].toDouble(),
    ];
    final medianR = _median(wideRadii);
    final lo = math.max(4, (medianR * 0.7).floor());
    final hi = (medianR * 1.3).floor() + 1;

    // Pass 2: tight radius window sized to the real bubbles -> far better recall.
    final found = cv.HoughCircles(
      blurred,
      cv.HOUGH_GRADIENT,
      1.2,
      medianR * 1.6,
      param1: 60,
      param2: 30,
      minRadius: lo,
      maxRadius: hi,
    );
    if (found.isEmpty) return [];

    final circles = [
      for (final row in found.toList3D())
        for (final c in row)
          (c[0].toDouble(), c[1].toDouble(), c[2].toDouble()),
    ];

    // Completion pass for the last row of each option column. On photos
    // (screen shots, scans of printouts) the bottom bubbles of a grid sit
    // near the sheet edge where glare/shadow flattens their gradient, so
    // Hough at the strict threshold above skips exactly that row. Rather
    // than lower the threshold globally (which floods the page with false
    // positives), search aggressively (local-contrast-normalized, low
    // param2) and keep only candidates that land on a position predicted
    // from the already-detected layout: on an existing row level and an
    // existing column center, with a plausible bubble radius. Strays
    // (glare blobs, sheet-edge phantoms, logos, text) align with neither.
    if (circles.length >= 8) {
      final medR = _median([for (final c in circles) c.$3.toDouble()]);
      final pitch = _median(_nearestNeighborDistances(circles));
      final clahe = cv.CLAHE(3.0, (8, 8));
      // circles.py CLAHE-boosts the raw working-res gray (clahe.apply(work))
      // BEFORE blurring - CLAHE response through a prior blur differs.
      final boosted = cv.gaussianBlur(clahe.apply(gray), (7, 7), 1.5);
      // Wide radius net on the boosted image so both normal and
      // perspective-shrunken bottom bubbles fall inside the window.
      final extra = cv.HoughCircles(
        boosted,
        cv.HOUGH_GRADIENT,
        1.2,
        12,
        param1: 60,
        param2: 18,
        minRadius: math.max(4, (0.5 * medR).floor()),
        maxRadius: (medR * 1.5).floor() + 2,
      );

      List<double> levels(List<double> vals, double tol, int minCount) {
        final order = List.generate(vals.length, (i) => i)
          ..sort((a, b) => vals[a].compareTo(vals[b]));
        final ids = <int, int>{order.first: 0};
        var cur = 0;
        for (var k = 1; k < order.length; k++) {
          if (vals[order[k]] - vals[order[k - 1]] > tol) cur++;
          ids[order[k]] = cur;
        }
        final out = <double>[];
        for (var cid = 0; cid <= cur; cid++) {
          final members = [
            for (final k2 in order)
              if (ids[k2] == cid) vals[k2],
          ];
          if (members.length >= minCount) out.add(_mean(members));
        }
        return out;
      }

      // All grids on a sheet share roughly aligned rows (and a sheet's own
      // columns), so a real, missed bubble lands on an existing row level +
      // column combination - gaps are measured in rows' own scale, the
      // median nearest-neighbor pitch (NOT the bubble radius).
      final rowLevels = levels(
        [for (final c in circles) c.$2.toDouble()],
        0.35 * pitch,
        4,
      );
      final colCenters = levels(
        [for (final c in circles) c.$1.toDouble()],
        0.5 * pitch,
        4,
      );

      if (rowLevels.isNotEmpty && colCenters.isNotEmpty) {
        for (final row in extra.toList3D()) {
          for (final c in row) {
            final ex = c[0].toDouble();
            final ey = c[1].toDouble();
            final er = c[2].toDouble();
            // Skip duplicates of already-detected bubbles.
            var duplicate = false;
            for (final (x, y, _) in circles) {
              if ((ex - x) * (ex - x) + (ey - y) * (ey - y) <
                  (1.8 * medR) * (1.8 * medR)) {
                duplicate = true;
                break;
              }
            }
            if (duplicate) continue;
            // Plausible bubble geometry?
            if (!(0.5 * medR < er && er < 1.5 * medR)) continue;
            var onRow = false;
            var onCol = false;
            for (final lv in rowLevels) {
              if ((lv - ey).abs() < 0.3 * pitch) {
                onRow = true;
                break;
              }
            }
            if (!onRow) continue;
            for (final cc in colCenters) {
              if ((cc - ex).abs() < 0.4 * pitch) {
                onCol = true;
                break;
              }
            }
            if (onRow && onCol) {
              circles.add((ex, ey, er));
            }
          }
        }
      }
    }

    return circles;
  }

  /// Match circles.py's raw-radius filter before common-radius drawing/fill.
  static List<_RawBubble> _filterByRawRadius(List<_RawBubble> bubbles) {
    if (bubbles.isEmpty) return [];

    final medianRadius = _median([for (final b in bubbles) b.$3]);
    final minRadius = medianRadius * 0.20;
    final filtered = [
      for (final b in bubbles)
        if (b.$3 >= minRadius) b,
    ];

    assert(() {
      debugPrint(
        'OMR raw-radius median=${medianRadius.toStringAsFixed(2)} '
        'min=${minRadius.toStringAsFixed(2)} '
        'before=${bubbles.length} after=${filtered.length}',
      );
      return true;
    }());

    return filtered;
  }

  /// Drop Hough false-positives (logos, header text, decorations) that sit
  /// far from any dense bubble cluster. Real bubbles always have close
  /// row/column neighbors; stray detections don't - this replaces a fixed
  /// pixel header-cutoff, which only works for one specific sheet size.
  static List<_RawBubble> _rejectIsolated(List<_RawBubble> bubbles) {
    final n = bubbles.length;
    if (n < 3) return bubbles;

    final nn = _nearestNeighborDistances(bubbles);
    final pitch = _median(nn);
    return [
      for (var i = 0; i < n; i++)
        if (nn[i] <= 3 * pitch) bubbles[i],
    ];
  }

  /// Drop round-glyph false positives from printed question labels like
  /// "036" / "091". The digits sit on the same row grid as the bubbles, so
  /// the isolated/sparse-cluster filters cannot catch them - they look like
  /// short columns of small circles. But they never form a clean vertical
  /// column: chain bubbles along the tilt-corrected x axis and drop any
  /// column-like chain that is either too few bubbles or too smeared in x
  /// to be a row of real bubbles (glyph jitter smears such chains over most
  /// of a pitch, real bubble columns are only a few px wide).
  static List<_RawBubble> _rejectTextColumns(List<_RawBubble> bubbles) {
    final n = bubbles.length;
    if (n < 6) return bubbles;

    final pitch = _median(_nearestNeighborDistances(bubbles));

    // Python passes float32 points to cv2.minAreaRect - rounding to int
    // points shifts the angle by hundredths of a degree, which is just
    // enough to flip the smearing test on a borderline glyph chain.
    final pointsVec = cv.VecPoint2f.fromList([
      for (final b in bubbles) cv.Point2f(b.$1, b.$2),
    ]);
    final rect = cv.minAreaRect2f(pointsVec);
    var angle = rect.angle;
    if (angle < -45) angle += 90;
    assert(() {
      debugPrint('OMR textcol angle=${rect.angle} adj=$angle pitch=$pitch');
      return true;
    }());
    final theta = angle * math.pi / 180;
    final cosA = math.cos(theta);
    final sinA = math.sin(theta);
    final cx = _mean([for (final b in bubbles) b.$1.toDouble()]);
    final cy = _mean([for (final b in bubbles) b.$2.toDouble()]);

    final rxs = [
      for (final b in bubbles) (b.$1 - cx) * cosA + (b.$2 - cy) * sinA,
    ];

    final order = List.generate(n, (i) => i)
      ..sort((a, b) => rxs[a].compareTo(rxs[b]));
    final chainIds = List<int>.filled(n, 0);
    var current = 0;
    for (var k = 1; k < n; k++) {
      if (rxs[order[k]] - rxs[order[k - 1]] > 0.5 * pitch) current++;
      chainIds[order[k]] = current;
    }

    final counts = List<int>.filled(current + 1, 0);
    for (final id in chainIds) {
      counts[id]++;
    }
    final strong = counts.reduce(math.max);

    // Real columns may be smeared by perspective even after tilt removal
    // (recorded sheets), so the smearing limit must be relative to the
    // span of the dense columns on THIS sheet, not an absolute pitch
    // fraction.
    final spans = <int, double>{};
    for (var cid = 0; cid < counts.length; cid++) {
      var lo = double.infinity;
      var hi = -double.infinity;
      for (var i = 0; i < n; i++) {
        if (chainIds[i] == cid) {
          lo = math.min(lo, rxs[i]);
          hi = math.max(hi, rxs[i]);
        }
      }
      spans[cid] = hi - lo;
    }
    final denseSpans = [
      for (final entry in spans.entries)
        if (counts[entry.key] >= 0.5 * strong) entry.value,
    ];
    final spanThr = denseSpans.isNotEmpty
        ? math.max(2.5 * _median(denseSpans), 0.35 * pitch)
        : 0.35 * pitch;

    final keep = <int>[];
    for (var cid = 0; cid < counts.length; cid++) {
      final members = [
        for (var i = 0; i < n; i++)
          if (chainIds[i] == cid) i,
      ];
      if (members.length < 4) continue; // too sparse to be a real bubble column
      // Preserve dense real columns even when perspective/distortion makes
      // their horizontal spread wider than the typical column.
      if (spans[cid]! > spanThr && members.length < 0.8 * strong) continue;
      keep.addAll(members);
    }
    assert(() {
      debugPrint(
        'OMR textcol angle=${rect.angle} pitch=$pitch dropped=${n - keep.length}',
      );
      return true;
    }());
    return [for (final i in keep) bubbles[i]];
  }

  /// Sparse-filter bubbles per grid, not globally. A short final grid (e.g.
  /// 5 questions while other grids have 15) has much sparser columns/rows
  /// than the tall ones, so a global population-ratio filter
  /// (_rejectSparseClusters) would delete the entire short grid. Split
  /// grids first (using this sheet's own tilt and bubble pitch), then
  /// filter each grid relative to itself.
  static List<_Bubble> _perGridSparseFilter(List<_Bubble> bubbles) {
    final n = bubbles.length;
    if (n < 3) return bubbles;

    // Bubble pitch sets the scale for grid-to-grid gaps (the Q.No. lane).
    final bubblePitch = _median(_nearestNeighborDistances(bubbles));
    final gridGapThreshold = gridGapFactor * bubblePitch;

    // Sheet tilt from the circles' own layout, not an assumed axis.
    final pointsVec = cv.VecPoint.fromList([
      for (final b in bubbles) cv.Point(b.$1, b.$2),
    ]);
    var angle = cv.minAreaRect(pointsVec).angle;
    if (angle < -45) angle += 90;
    final theta = angle * math.pi / 180;
    final cosA = math.cos(theta);
    final sinA = math.sin(theta);
    final cx = _mean([for (final b in bubbles) b.$1.toDouble()]);
    final cy = _mean([for (final b in bubbles) b.$2.toDouble()]);

    final rotatedX = [
      for (final b in bubbles) (b.$1 - cx) * cosA + (b.$2 - cy) * sinA,
    ];

    final order = List.generate(n, (i) => i)
      ..sort((a, b) => rotatedX[a].compareTo(rotatedX[b]));
    final gridIds = List<int>.filled(n, 0);
    var currentGrid = 0;
    for (var k = 1; k < n; k++) {
      if (rotatedX[order[k]] - rotatedX[order[k - 1]] > gridGapThreshold)
        currentGrid++;
      gridIds[order[k]] = currentGrid;
    }

    final kept = <_Bubble>[];
    for (var gridId = 0; gridId <= currentGrid; gridId++) {
      var sub = [
        for (var i = 0; i < n; i++)
          if (gridIds[i] == gridId) bubbles[i],
      ];
      sub = _rejectSparseClusters(sub, false); // sparse columns
      sub = _rejectSparseClusters(sub, true); // sparse rows
      kept.addAll(sub);
    }
    return kept;
  }

  /// Drop Hough false-positives on printed text (a round digit like "0" in
  /// a question number, or a round letter in label text) that sit right
  /// next to real bubbles, so _rejectIsolated's distance check can't catch
  /// them. A real answer column/row gets hit by nearly every row/grid; a
  /// glyph that happens to look circular only coincidentally lines up with
  /// a handful - cluster bubbles along one tilt-corrected axis and drop
  /// anything in a cluster far sparser than the best-supported one.
  static List<_Bubble> _rejectSparseClusters(
    List<_Bubble> bubbles,
    bool useY, {
    double minPopRatio = 0.5,
  }) {
    final n = bubbles.length;
    if (n < 3) return bubbles;

    final xs = [for (final b in bubbles) b.$1.toDouble()];
    final ys = [for (final b in bubbles) b.$2.toDouble()];

    final pointsVec = cv.VecPoint.fromList([
      for (final b in bubbles) cv.Point(b.$1, b.$2),
    ]);
    var angle = cv.minAreaRect(pointsVec).angle;
    if (angle < -45) angle += 90;
    final theta = angle * math.pi / 180;
    final cosA = math.cos(theta);
    final sinA = math.sin(theta);
    final cx = _mean(xs);
    final cy = _mean(ys);

    final values = [
      for (var i = 0; i < n; i++)
        useY
            ? -(xs[i] - cx) * sinA + (ys[i] - cy) * cosA
            : (xs[i] - cx) * cosA + (ys[i] - cy) * sinA,
    ];

    // 0.35 * pitch, not 0.6: this must match the cluster division used for
    // question numbering (_layoutGrids re-clusters rows/columns at
    // 0.35 * pitch). With perspective-sheared sheets adjacent real columns
    // can sit less than 0.6 * pitch apart - merging them here and then
    // splitting them again for numbering makes the population filter see a
    // phantom "sparse" column and delete a real option column (and its
    // trailing question rows shrink to 3 bubbles each).
    final localGapThreshold =
        0.35 * _median(_nearestNeighborDistances(bubbles));

    final order = List.generate(n, (i) => i)
      ..sort((a, b) => values[a].compareTo(values[b]));
    final clusterIds = List<int>.filled(n, 0);
    var current = 0;
    for (var k = 1; k < n; k++) {
      if (values[order[k]] - values[order[k - 1]] > localGapThreshold)
        current++;
      clusterIds[order[k]] = current;
    }

    final counts = List<int>.filled(current + 1, 0);
    for (final id in clusterIds) {
      counts[id]++;
    }
    final minCount = counts.reduce(math.max) * minPopRatio;

    return [
      for (var i = 0; i < n; i++)
        if (counts[clusterIds[i]] >= minCount) bubbles[i],
    ];
  }

  // Helpers accepting either bubble record type.
  static double _bx(Object b) =>
      b is _RawBubble ? b.$1 : (b as _Bubble).$1.toDouble();
  static double _by(Object b) =>
      b is _RawBubble ? b.$2 : (b as _Bubble).$2.toDouble();

  static List<double> _nearestNeighborDistances(List<Object> bubbles) {
    final n = bubbles.length;
    final xs = [for (final b in bubbles) _bx(b)];
    final ys = [for (final b in bubbles) _by(b)];

    return [
      for (var i = 0; i < n; i++)
        [
          for (var j = 0; j < n; j++)
            if (j != i)
              math
                  .sqrt(math.pow(xs[i] - xs[j], 2) + math.pow(ys[i] - ys[j], 2))
                  .toDouble(),
        ].reduce(math.min),
    ];
  }

  // ---------------------------------------------------------------------------
  // Grid / row / column layout — mirrors script/circles.py's grouping: the
  // sheet's tilt comes from the detected circles themselves (via
  // minAreaRect), and grid/row/column boundaries are wherever the gap
  // between neighboring circles (along that tilted axis) is wide relative
  // to the typical bubble-to-bubble spacing.
  // ---------------------------------------------------------------------------

  static ({int numGrids, int totalQuestions}) _layoutGrids(
    List<_Bubble> detected,
    Map<_Bubble, int> questionOf,
    Map<_Bubble, int> optionOf,
    cv.Mat output,
    int mostCommonRadius,
  ) {
    final n = detected.length;
    if (n < 2) return (numGrids: 0, totalQuestions: 0);

    final xs = [for (final b in detected) b.$1.toDouble()];
    final ys = [for (final b in detected) b.$2.toDouble()];

    // Tilt comes from the circles' own layout, not an assumed horizontal axis.
    final pointsVec = cv.VecPoint.fromList([
      for (final b in detected) cv.Point(b.$1, b.$2),
    ]);
    var angle = cv.minAreaRect(pointsVec).angle;
    if (angle < -45) angle += 90;
    final theta = angle * math.pi / 180;
    final cosA = math.cos(theta);
    final sinA = math.sin(theta);

    final cx = _mean(xs);
    final cy = _mean(ys);

    final rotatedX = [
      for (var i = 0; i < n; i++) (xs[i] - cx) * cosA + (ys[i] - cy) * sinA,
    ];
    final rotatedY = [
      for (var i = 0; i < n; i++) -(xs[i] - cx) * sinA + (ys[i] - cy) * cosA,
    ];

    // Bubble pitch (nearest-neighbor spacing) sets the scale for "normal" vs
    // "grid/row/column boundary" gaps, which are always noticeably wider.
    final bubblePitch = _median(_nearestNeighborDistances(detected));
    final gridGapThreshold = gridGapFactor * bubblePitch;
    final localGapThreshold = localGapFactor * bubblePitch;

    final order = List.generate(n, (i) => i)
      ..sort((a, b) => rotatedX[a].compareTo(rotatedX[b]));
    final gridIds = List<int>.filled(n, 0);
    var currentGrid = 0;
    for (var k = 1; k < n; k++) {
      if (rotatedX[order[k]] - rotatedX[order[k - 1]] > gridGapThreshold)
        currentGrid++;
      gridIds[order[k]] = currentGrid;
    }
    final numGrids = currentGrid + 1;

    var questionOffset = 0;

    // Per-grid outline colors. circles.py uses BGR tuples; Scalar.fromRgb
    // maps (r,g,b) -> (b,g,r) channels, so each is the exact Python color.
    final gridColors = [
      cv.Scalar.fromRgb(0, 0, 255), // python (255,0,0)   - blue
      cv.Scalar.fromRgb(255, 165, 0), // python (0,165,255) - orange
      cv.Scalar.fromRgb(255, 0, 255), // python (255,0,255) - magenta
      cv.Scalar.fromRgb(255, 255, 0), // python (0,255,255) - yellow
      cv.Scalar.fromRgb(0, 255, 255), // python (255,255,0) - cyan
      cv.Scalar.fromRgb(255, 0, 128), // python (128,0,255) - purple
    ];

    for (var gridId = 0; gridId < numGrids; gridId++) {
      final indices = [
        for (var i = 0; i < n; i++)
          if (gridIds[i] == gridId) i,
      ];
      // Rows (questions, top to bottom) and columns (A, B, C, D...):
      // cluster by gaps along the tilt-corrected y/x axes - no assumption
      // that rows are horizontal in the original image. A tight threshold
      // (0.35 * pitch) is safe because bubbles in one row share y to
      // within a couple of pixels, while real adjacent rows are always a
      // full pitch apart. That way a single stray bubble sitting between
      // two real rows cannot chain the rows together (which would merge
      // two questions and shift every following question number).
      // Clusters holding < 2 bubbles are strays (round glyphs / Hough
      // noise) - drop them from question numbering instead of counting
      // them as a question.
      ({List<int> newIds, int numKept}) clusterAxis(List<double> axisValues) {
        final axisOrder = [...indices]
          ..sort((a, b) => axisValues[a].compareTo(axisValues[b]));
        final ids = <int, int>{axisOrder.first: 0};
        var cur = 0;
        for (var k = 1; k < axisOrder.length; k++) {
          if (axisValues[axisOrder[k]] - axisValues[axisOrder[k - 1]] >
              localGapThreshold) cur++;
          ids[axisOrder[k]] = cur;
        }
        final counts = List<int>.filled(cur + 1, 0);
        for (final i in indices) {
          counts[ids[i]!]++;
        }
        // Strays (round glyphs / Hough noise) form tiny clusters, e.g. the
        // two "O"-glyph dots of a page watermark under a real grid. Real
        // rows/columns hold most of a grid's per-cluster occupancy, so
        // keep clusters holding >= 60% of the biggest - small partial rows
        // (3 of 4 options) still survive, but 2-bubble watermark dots do
        // not.
        final minCluster = math.max(2, (0.6 * counts.reduce(math.max)).ceil());
        final keepIds = <int>[
          for (var cid = 0; cid < counts.length; cid++)
            if (counts[cid] >= minCluster) cid,
        ];
        final remap = {for (var k = 0; k < keepIds.length; k++) keepIds[k]: k};
        return (
          newIds: [for (final i in indices) remap[ids[i]] ?? -1],
          numKept: keepIds.length,
        );
      }

      final rowResult = clusterAxis(rotatedY);
      final rowIds = {
        for (var k = 0; k < indices.length; k++)
          indices[k]: rowResult.newIds[k],
      };
      final numRows = rowResult.numKept;

      final colResult = clusterAxis(rotatedX);
      final colIds = {
        for (var k = 0; k < indices.length; k++)
          indices[k]: colResult.newIds[k],
      };

      // Grid outline: the min-area rect of the grid's bubbles, expanded by
      // 1.5 * bubble radius on every side, drawn closed (drawContours with
      // thickness 3 in circles.py).
      final gridColor = gridColors[gridId % gridColors.length];
      {
        final gridVec = cv.VecPoint.fromList([
          for (final i in indices) cv.Point(detected[i].$1, detected[i].$2),
        ]);
        final rect = cv.minAreaRect(gridVec);
        final margin = mostCommonRadius * 1.5;
        final bw = rect.size.width + 2 * margin;
        final bh = rect.size.height + 2 * margin;
        final ra = rect.angle * math.pi / 180;
        final bcx = rect.center.x;
        final bcy = rect.center.y;
        final dxx = 0.5 * bw * math.cos(ra);
        final dxy = 0.5 * bw * math.sin(ra);
        final dyx = -0.5 * bh * math.sin(ra);
        final dyy = 0.5 * bh * math.cos(ra);
        // boxPoints order; circles.py's boxPoints().astype(int) truncates.
        int t(double v) => v.truncate();
        final boxPts = [
          cv.Point(t(bcx - dxx - dyx), t(bcy - dxy - dyy)),
          cv.Point(t(bcx + dxx - dyx), t(bcy + dxy - dyy)),
          cv.Point(t(bcx + dxx + dyx), t(bcy + dxy + dyy)),
          cv.Point(t(bcx - dxx + dyx), t(bcy - dxy + dyy)),
        ];
        // cv.drawContours(
        //   output,
        //   cv.VecVecPoint.fromList([boxPts]),
        //   0,
        //   gridColor,
        //   thickness: 3,
        // );
      }

      // Draw a line through each row, following the sheet's own tilt, and
      // label the question number (continuing from the previous grid).
      for (var rowId = 0; rowId < numRows; rowId++) {
        final rowXs = <double>[];
        final rowYs = <double>[];
        for (var k = 0; k < indices.length; k++) {
          if (rowResult.newIds[k] == rowId) {
            rowXs.add(rotatedX[indices[k]]);
            rowYs.add(rotatedY[indices[k]]);
          }
        }
        if (rowXs.isEmpty) continue;
        // final leftRx = rowXs.reduce(math.min);
        // final rightRx = rowXs.reduce(math.max);
        // final rowRy = rowYs.reduce((a, b) => a + b) / rowYs.length;

        // final p1x = cx + leftRx * cosA - rowRy * sinA;
        // final p1y = cy + leftRx * sinA + rowRy * cosA;
        // final p2x = cx + rightRx * cosA - rowRy * sinA;
        // final p2y = cy + rightRx * sinA + rowRy * cosA;

        // cv.line(
        //   output,
        //   cv.Point(p1x.toInt(), p1y.toInt()),
        //   cv.Point(p2x.toInt(), p2y.toInt()),
        //   gridColor,
        //   thickness: 1,
        // );
        // cv.putText(
        //   output,
        //   '${questionOffset + rowId + 1}',
        //   cv.Point(p1x.toInt() - 25, p1y.toInt() + 5),
        //   cv.FONT_HERSHEY_SIMPLEX,
        //   0.5,
        //   gridColor,
        //   thickness: 2,
        //   lineType: cv.LINE_AA,
        // );
      }

      for (final i in indices) {
        // Dropped rows/columns (stray glyph bubbles): excluded from
        // question numbering.
        if (rowIds[i]! >= 0 && colIds[i]! >= 0) {
          final bubble = detected[i];
          questionOf[bubble] = questionOffset + rowIds[i]! + 1;
          optionOf[bubble] = colIds[i]! + 1; // 1=A, 2=B, 3=C, 4=D...
        }
      }

      questionOffset += numRows;
    }

    return (numGrids: numGrids, totalQuestions: questionOffset);
  }

  // ---------------------------------------------------------------------------
  // Fill ratio — % of a bubble's own circular area that is dark ink in a
  // pre-thresholded (Otsu) mask.
  // ---------------------------------------------------------------------------

  static double _fillRatio(cv.Mat darkMask, int cx, int cy, int r) {
    final y0 = math.max(cy - r, 0);
    final y1 = math.min(cy + r + 1, darkMask.rows);
    final x0 = math.max(cx - r, 0);
    final x1 = math.min(cx + r + 1, darkMask.cols);

    if (x1 <= x0 || y1 <= y0) return 0;

    final roi = cv.Mat.fromMat(
      darkMask,
      roi: cv.Rect(x0, y0, x1 - x0, y1 - y0),
    );

    final bubbleMask = cv.Mat.zeros(y1 - y0, x1 - x0, cv.MatType.CV_8UC1);
    cv.circle(
      bubbleMask,
      cv.Point(cx - x0, cy - y0),
      r,
      cv.Scalar.all(255),
      thickness: -1,
    );

    final bubbleArea = cv.countNonZero(bubbleMask);
    if (bubbleArea == 0) return 0;

    final darkArea = cv.countNonZero(cv.bitwiseAND(roi, bubbleMask));
    return darkArea / bubbleArea;
  }

  static int _mode(List<int> values) {
    final counts = <int, int>{};
    for (final v in values) {
      counts[v] = (counts[v] ?? 0) + 1;
    }
    var best = values.first;
    var bestCount = 0;
    for (final entry in counts.entries) {
      if (entry.value > bestCount) {
        best = entry.key;
        bestCount = entry.value;
      }
    }
    return best;
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

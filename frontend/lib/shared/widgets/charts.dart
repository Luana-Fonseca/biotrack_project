import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Simple line chart (no external charting library) used for the dashboard's
/// monthly CO2/savings trend.
class BioLineChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final Color color;
  final double height;
  final bool filled;

  /// Index of the first value that's a projection rather than measured data (see
  /// `DashboardService.trend` on the backend, which fits a linear regression on the historical
  /// months and extends it forward). Points from this index on are drawn as a dashed line with no
  /// area fill beneath them, so a forecast never reads as if it were real accumulated data.
  final int? projectedFromIndex;

  const BioLineChart({
    super.key,
    required this.values,
    required this.labels,
    this.color = AppColors.azul,
    this.height = 160,
    this.filled = false,
    this.projectedFromIndex,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _LineChartPainter(
          values: values,
          color: color,
          gridColor: p.border,
          filled: filled,
          projectedFromIndex: projectedFromIndex,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: labels
                  .map((l) => Text(l, style: AppText.mono(size: 9, color: p.gray2)))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final Color gridColor;
  final bool filled;
  final int? projectedFromIndex;

  _LineChartPainter({
    required this.values,
    required this.color,
    required this.gridColor,
    required this.filled,
    this.projectedFromIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final chartHeight = size.height - 20;
    if (values.isEmpty) return;

    if (!filled) {
      final gridPaint = Paint()
        ..color = gridColor
        ..strokeWidth = 1;
      canvas.drawLine(Offset(0, chartHeight), Offset(size.width, chartHeight), gridPaint);
    }

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;

    // Single point: nothing to draw a line between — avoids a divide-by-zero
    // in the step calculation below.
    if (values.length == 1) {
      final y = chartHeight - (values[0] / safeMax) * (chartHeight - 10);
      final dotPaint = Paint()..color = color;
      canvas.drawCircle(Offset(size.width / 2, y), 4, dotPaint);
      return;
    }

    final step = size.width / (values.length - 1);
    final points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final x = i * step;
      final y = chartHeight - (values[i] / safeMax) * (chartHeight - 10);
      points.add(Offset(x, y));
    }

    // Split into a solid "real" segment and a dashed "projected" segment that starts one point
    // earlier so the two visually connect instead of leaving a gap.
    final splitAt = (projectedFromIndex != null && projectedFromIndex! > 0 && projectedFromIndex! < points.length)
        ? projectedFromIndex!
        : points.length;
    final realPoints = points.sublist(0, splitAt);
    final projectedPoints = splitAt < points.length ? points.sublist(splitAt - 1) : const <Offset>[];

    final linePath = Path()..moveTo(realPoints.first.dx, realPoints.first.dy);
    for (final pt in realPoints.skip(1)) {
      linePath.lineTo(pt.dx, pt.dy);
    }

    if (filled) {
      final areaPath = Path.from(linePath)
        ..lineTo(realPoints.last.dx, chartHeight)
        ..lineTo(realPoints.first.dx, chartHeight)
        ..close();
      final areaPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.28), color.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight));
      canvas.drawPath(areaPath, areaPaint);
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    if (projectedPoints.length > 1) {
      final dashedPaint = Paint()
        ..color = color.withOpacity(0.55)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < projectedPoints.length - 1; i++) {
        _drawDashedLine(canvas, projectedPoints[i], projectedPoints[i + 1], dashedPaint);
      }
    }

    if (filled) {
      // Filled/area mode (the dashboard's "Projeção" card) reads as a smooth
      // trend line with just the current point marked, not a dot per sample.
      final lastPoint = points.last;
      final dotPaint = Paint()..color = color.withOpacity(projectedPoints.isNotEmpty ? 0.55 : 1);
      canvas.drawCircle(lastPoint, 4, dotPaint);
      canvas.drawCircle(lastPoint, 4, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);
    } else {
      final dotPaint = Paint()..color = color;
      for (final pt in realPoints) {
        canvas.drawCircle(pt, 3, dotPaint);
      }
      final projectedDotPaint = Paint()..color = color.withOpacity(0.55);
      for (final pt in projectedPoints.skip(1)) {
        canvas.drawCircle(pt, 3, projectedDotPaint);
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint, {double dashWidth = 5, double dashGap = 4}) {
    final totalLength = (end - start).distance;
    if (totalLength == 0) return;
    final dx = (end.dx - start.dx) / totalLength;
    final dy = (end.dy - start.dy) / totalLength;
    double distance = 0;
    while (distance < totalLength) {
      final from = Offset(start.dx + dx * distance, start.dy + dy * distance);
      final segmentEnd = (distance + dashWidth).clamp(0, totalLength);
      final to = Offset(start.dx + dx * segmentEnd, start.dy + dy * segmentEnd);
      canvas.drawLine(from, to, paint);
      distance += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.color != color ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.filled != filled ||
      oldDelegate.projectedFromIndex != projectedFromIndex;
}

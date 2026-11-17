import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';

/// Side-by-side two-bar comparison (fossil fuel vs biometano CO2) used on the
/// calculator result screen and the operational dashboard.
class BarComparison extends StatelessWidget {
  final String leftLabel;
  final double leftValue;
  final String rightLabel;
  final double rightValue;
  final Color leftColor;
  final Color rightColor;

  const BarComparison({
    super.key,
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
    this.leftColor = AppColors.red,
    this.rightColor = AppColors.verde,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = [leftValue, rightValue].reduce((a, b) => a > b ? a : b);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _bar(context, leftLabel, leftValue, leftColor, leftValue / safeMax)),
        const SizedBox(width: 16),
        Expanded(child: _bar(context, rightLabel, rightValue, rightColor, rightValue / safeMax)),
      ],
    );
  }

  Widget _bar(BuildContext context, String label, double value, Color color, double ratio) {
    final p = context.palette;
    return Column(
      children: [
        Text(fmtNumber(value), style: AppText.mono(size: 12.5, weight: FontWeight.w700, color: p.ink)),
        const SizedBox(height: 6),
        Container(
          height: 8 + ratio.clamp(0, 1) * 70,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
        ),
        const SizedBox(height: 8),
        Text(label, style: AppText.inter(size: 11.5, color: p.gray), textAlign: TextAlign.center),
      ],
    );
  }
}

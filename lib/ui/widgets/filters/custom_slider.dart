import 'package:flutter/material.dart';
import 'package:take_home_assignment/styles/colors.dart';
import 'square_range_thumb.dart';

class MiniRangeSlider extends StatelessWidget {
  const MiniRangeSlider({
    super.key,
    required this.start,
    required this.end,
    required this.min,
    required this.max,
    required this.onChanged,
    this.hPadding = 3,
    this.minWidth = 14,
    this.maxWidth = 36,
    this.divisions = 100,
    this.thumbSize = 14,
    this.thumbRadius = 2,
    this.textStyle = const TextStyle(
      fontSize: 10,
      color: Colors.white,
      height: 1.0,
    ),
  });

  final double start;
  final double end;
  final double min;
  final double max;
  final void Function(double start, double end) onChanged;

  // optional
  final int divisions;
  final double thumbSize;
  final double thumbRadius;
  final TextStyle textStyle;

  final double minWidth;
  final double maxWidth;
  final double hPadding;

  String _fmt(num v) =>
      v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final safeMax = (max > min) ? max : (min + 1); // guard

    final startLabel = _fmt(start);
    final endLabel = _fmt(end);

    return SliderTheme(
      data: theme.sliderTheme.copyWith(
        trackHeight: 2,
        activeTrackColor: cs.primary,
        inactiveTrackColor: cs.outline.withValues(alpha: .25),
        rangeThumbShape: SquareRangeThumbAdaptiveShape(
          fillColor: AppColors.bg,
          borderRadius: thumbRadius,
          startLabel: startLabel,
          endLabel: endLabel,
          textStyle: textStyle,
          borderColor: Colors.white.withValues(alpha: .2),
        ),

        // minimal chrome
        overlayShape: SliderComponentShape.noOverlay,
        valueIndicatorShape: SliderComponentShape.noOverlay,
        showValueIndicator: ShowValueIndicator.never,
        tickMarkShape: SliderTickMarkShape.noTickMark,
      ),
      child: RangeSlider(
        values: RangeValues(start, end),
        min: min,
        max: safeMax,
        divisions: divisions,
        // We draw labels in the thumb; RangeSlider.labels are optional
        onChanged: (v) => onChanged(v.start, v.end),
      ),
    );
  }
}

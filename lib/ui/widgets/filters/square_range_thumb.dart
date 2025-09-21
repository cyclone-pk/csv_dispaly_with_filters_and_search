import 'package:flutter/material.dart';

/// RangeSlider thumb that grows horizontally to fit the value text.
/// Compatible with older Flutter RangeSliderThumbShape.paint signature.
class SquareRangeThumbAdaptiveShape extends RangeSliderThumbShape {
  const SquareRangeThumbAdaptiveShape({
    this.height = 20,
    this.minWidth = 14,
    this.maxWidth = 36,
    this.hPadding = 3,
    this.borderRadius = 2,
    required this.startLabel,
    required this.endLabel,
    this.textStyle = const TextStyle(
      fontSize: 11,
      color: Colors.white,
      height: 1.0,
    ),
    this.fillColor,
    this.borderColor,
  });

  /// Vertical size of the knob.
  final double height;

  /// Minimum/maximum knob width; actual width = textWidth + 2*hPadding and clamped.
  final double minWidth;
  final double maxWidth;
  final double hPadding;

  final double borderRadius;
  final String startLabel;
  final String endLabel;
  final TextStyle textStyle;

  /// If null, falls back to sliderTheme.thumbColor.
  final Color? fillColor;

  /// If null, uses overlayColor ~25% for a subtle outline.
  final Color? borderColor;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    // Return the worst-case width so layout never clips the thumb.
    return Size(maxWidth, height);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = true,
    bool isOnTop = false,
    bool isPressed = false,
    required SliderThemeData sliderTheme,
    TextDirection textDirection = TextDirection.ltr,
    Thumb thumb = Thumb.start,
  }) {
    final Canvas canvas = context.canvas;

    // Choose label based on thumb side
    final String text = (thumb == Thumb.start) ? startLabel : endLabel;

    // Measure text
    final tp = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: textDirection,
      maxLines: 1,
      ellipsis: '…',
    )..layout();

    final double desiredWidth = (tp.width + 4 * hPadding).clamp(
      minWidth,
      maxWidth,
    );

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: desiredWidth, height: height),
      Radius.circular(borderRadius),
    );

    final Color fill = fillColor ?? (sliderTheme.thumbColor ?? Colors.white);
    final Color stroke =
        borderColor ??
        (sliderTheme.overlayColor ?? Colors.black).withValues(alpha: .25);

    // Fill + border
    final paintFill = Paint()
      ..color = fill
      ..style = PaintingStyle.fill;
    final paintStroke = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRRect(rrect, paintFill);
    canvas.drawRRect(rrect, paintStroke);

    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }
}

import 'package:flutter/material.dart';
import 'colors.dart';

class AppTextStyle {
  static const TextStyle navLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  static const TextStyle h16 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  static const TextStyle h14 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  static const TextStyle body = TextStyle(fontSize: 13, color: AppColors.text);

  static const TextStyle bodyDim = TextStyle(
    fontSize: 12,
    color: AppColors.textDim,
  );

  static TextTheme get textTheme =>
      const TextTheme(titleMedium: h16, bodyMedium: body);
}

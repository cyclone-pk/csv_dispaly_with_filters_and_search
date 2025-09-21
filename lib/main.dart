import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'provider/data_provider.dart';
import 'ui/pages/home_page.dart';
import 'styles/colors.dart';
import 'styles/text_style.dart';

void main() => runApp(const XPawnApp());

class XPawnApp extends StatelessWidget {
  const XPawnApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.dark,
      // background: AppColors.bg,
      surface: AppColors.bg,
    );

    final theme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
      canvasColor: AppColors.surface,
      textTheme: AppTextStyle.textTheme,

      // Inputs like the search bar
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: AppColors.surface2,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        hintStyle: const TextStyle(color: AppColors.textDim),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppColors.outline.withValues(alpha: .35),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppColors.outline.withValues(alpha: .35),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.seed.withValues(alpha: .8)),
        ),
      ),

      // Compact chips like the screenshot
      chipTheme: ChipThemeData(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        labelStyle: const TextStyle(fontSize: 11, color: AppColors.text),
        backgroundColor: AppColors.surface2,
        selectedColor: AppColors.seed.withValues(alpha: .18),
        side: BorderSide(
          color: AppColors.outline.withValues(alpha: .3),
          width: .6,
        ),
        shape: const StadiumBorder(),
      ),

      // Slim sliders
      sliderTheme: SliderThemeData(
        trackHeight: 2,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayShape: SliderComponentShape.noOverlay,
        valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
        // showValueIndicator: ShowValueIndicator.always,
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: AppColors.outline.withValues(alpha: .25),
            width: .7,
          ),
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
        side: BorderSide(
          color: AppColors.outline.withValues(alpha: .5),
          width: 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      dividerTheme: DividerThemeData(
        color: AppColors.outline.withValues(alpha: .3),
        space: 20,
        thickness: .7,
      ),

      dataTableTheme: const DataTableThemeData(
        headingTextStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        dataTextStyle: TextStyle(fontSize: 12),
      ),
    );

    return ChangeNotifierProvider(
      create: (_) => DataProvider()..loadFromAssets(), // ← your CSV loader
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'XPawn Multi-Table Search',
        theme: theme,
        home: const HomePage(),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// PraiseTeam visual tokens.
///
/// The sheet music is the hero, so chrome stays neutral and color carries
/// meaning only:
///  * [teamInk]  shared things (team annotations, primary actions)
///  * [myPencil] private things (my annotations, "only me")
///  * [stageAmber] live-mode cues that must read from across a dark stage
/// Dividers are thin "staff lines" instead of boxing everything in cards.
abstract final class AppColors {
  static const teamInk = Color(0xFF2541B2); // fountain-pen royal blue
  static const myPencil = Color(0xFF666B73); // graphite
  static const stageAmber = Color(0xFFF2A007); // stage wash / cue
  static const staffLine = Color(0xFFD5D9DE);
  static const canvas = Color(0xFFF4F5F2); // manuscript-paper grey, not cream
  static const ink = Color(0xFF1D1F23); // body text
  static const danger = Color(0xFFB3261E);

  /// Stage mode is pure black so a tablet doesn't glow on a dark stage.
  static const stageBlack = Color(0xFF000000);
}

/// The setlist (콘티) reads like a printed church bulletin: song names in a
/// Korean serif. It is the app's single display face; everything else
/// uses the platform sans.
abstract final class AppType {
  static const setlistFamily = 'GowunBatang';
}

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.teamInk,
      brightness: brightness,
      // tonalSpot keeps containers light (readable behind dark text) while
      // `primary` below stays exactly the team ink.
      dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
      primary: isDark ? const Color(0xFFB7C4FF) : AppColors.teamInk,
      secondary: isDark ? const Color(0xFFC4C7CE) : AppColors.myPencil,
      tertiary: AppColors.stageAmber,
      error: isDark ? const Color(0xFFF2B8B5) : AppColors.danger,
      surface: isDark ? const Color(0xFF16181C) : Colors.white,
      outlineVariant: isDark ? const Color(0xFF3A3E45) : AppColors.staffLine,
    );

    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: isDark ? const Color(0xFF101215) : AppColors.canvas,
      visualDensity: VisualDensity.standard,
    );

    final text = base.textTheme.apply(
      bodyColor: isDark ? const Color(0xFFE4E6EA) : AppColors.ink,
      displayColor: isDark ? const Color(0xFFE4E6EA) : AppColors.ink,
    );

    return base.copyWith(
      textTheme: text.copyWith(
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: base.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        // No titleTextStyle: the default (textTheme.titleLarge, w700 above)
        // gets its size from the locale's type geometry at runtime.
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
      listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 20)),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1E2126) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: base.scaffoldBackgroundColor,
        indicatorColor: scheme.primaryContainer,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF16181C) : Colors.white,
        indicatorColor: scheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}

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

  /// Dark mode is an evening sanctuary: deep navy instead of black, with
  /// surfaces that step up in visible layers.
  static const night = Color(0xFF0F1424);
  static const nightSurface = Color(0xFF171D31);
  static const nightRaised = Color(0xFF1F2740);
  static const nightLine = Color(0xFF2B3452);
}

/// Colors that carry meaning across screens: where a serving request
/// stands, who someone is at a glance, and the one bold card per screen.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.accepted,
    required this.pending,
    required this.declined,
    required this.draft,
    required this.hero,
    required this.onHero,
    required this.people,
  });

  final Color accepted;
  final Color pending;
  final Color declined;
  final Color draft;

  /// The highlighted card (the next service): team ink, white text.
  final Color hero;
  final Color onHero;

  /// Avatar backgrounds; white initials read on every one.
  final List<Color> people;

  static const light = AppPalette(
    accepted: Color(0xFF2E7D57),
    pending: Color(0xFFB36A00),
    declined: Color(0xFFB3412E),
    draft: AppColors.myPencil,
    hero: AppColors.teamInk,
    onHero: Colors.white,
    people: [
      Color(0xFF2541B2),
      Color(0xFF6A4BC0),
      Color(0xFF0F7A73),
      Color(0xFFB0521E),
      Color(0xFF8E7110),
      Color(0xFF3D7A3A),
      Color(0xFFA83A68),
    ],
  );

  static const dark = AppPalette(
    accepted: Color(0xFF7DD3A4),
    pending: Color(0xFFF5B942),
    declined: Color(0xFFFF9B87),
    draft: Color(0xFFA3ABC2),
    hero: Color(0xFF2F47BE),
    onHero: Colors.white,
    people: [
      Color(0xFF4A63D6),
      Color(0xFF8566DA),
      Color(0xFF1E968D),
      Color(0xFFC96A34),
      Color(0xFFA88A22),
      Color(0xFF55934F),
      Color(0xFFC25285),
    ],
  );

  static AppPalette of(BuildContext context) => Theme.of(context).extension<AppPalette>()!;

  /// The same person gets the same color everywhere (stable across runs).
  Color person(String key) {
    var hash = 0;
    for (final unit in key.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return people[hash % people.length];
  }

  @override
  AppPalette copyWith({Color? accepted, Color? pending, Color? declined, Color? draft, Color? hero, Color? onHero}) =>
      AppPalette(
        accepted: accepted ?? this.accepted,
        pending: pending ?? this.pending,
        declined: declined ?? this.declined,
        draft: draft ?? this.draft,
        hero: hero ?? this.hero,
        onHero: onHero ?? this.onHero,
        people: people,
      );

  @override
  AppPalette lerp(AppPalette? other, double t) => other == null || t < 0.5 ? this : other;
}

/// The setlist (콘티) reads like a printed church bulletin: song and service
/// names in a Korean serif. It is the app's single display face; everything
/// else uses the platform sans.
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
      primary: isDark ? const Color(0xFFA9B8FF) : AppColors.teamInk,
      primaryContainer: isDark ? const Color(0xFF26326B) : const Color(0xFFDFE5FF),
      onPrimaryContainer: isDark ? const Color(0xFFDDE3FF) : const Color(0xFF14246B),
      secondary: isDark ? const Color(0xFFC4C7CE) : AppColors.myPencil,
      tertiary: AppColors.stageAmber,
      error: isDark ? const Color(0xFFFF9B87) : AppColors.danger,
      surface: isDark ? AppColors.nightSurface : Colors.white,
      onSurface: isDark ? const Color(0xFFE7EAF3) : AppColors.ink,
      onSurfaceVariant: isDark ? const Color(0xFFA3ABC2) : const Color(0xFF5B6068),
      surfaceContainerLow: isDark ? AppColors.nightSurface : const Color(0xFFF9FAF8),
      surfaceContainer: isDark ? AppColors.nightRaised : const Color(0xFFF0F1EE),
      surfaceContainerHigh: isDark ? const Color(0xFF253051) : const Color(0xFFEAECE8),
      surfaceContainerHighest: isDark ? const Color(0xFF2C3759) : const Color(0xFFE4E7E2),
      outlineVariant: isDark ? AppColors.nightLine : AppColors.staffLine,
    );
    final palette = isDark ? AppPalette.dark : AppPalette.light;

    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: isDark ? AppColors.night : AppColors.canvas,
      visualDensity: VisualDensity.standard,
    );

    final text = base.textTheme.apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    return base.copyWith(
      extensions: [palette],
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
      // Cards are flat paper: a hairline in light, a raised layer in dark.
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isDark ? BorderSide.none : BorderSide(color: scheme.outlineVariant),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.hero,
        foregroundColor: palette.onHero,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
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
        fillColor: isDark ? AppColors.nightRaised : Colors.white,
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
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium?.copyWith(
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? scheme.primary : scheme.onSurfaceVariant,
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}

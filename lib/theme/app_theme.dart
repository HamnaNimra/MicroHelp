import 'package:flutter/material.dart';

/// Semantic colors for post types, statuses, and badges.
/// Adapt to light/dark mode via context.
class AppColors {
  AppColors._();

  // Post type colors
  static const Color requestLight = Color(0xFFE65100);
  static const Color requestDark = Color(0xFFFFAB40);
  static const Color offerLight = Color(0xFF2E7D32);
  static const Color offerDark = Color(0xFF69F0AE);

  // Status colors
  static const Color activeLight = Color(0xFF1565C0);
  static const Color activeDark = Color(0xFF82B1FF);
  static const Color pendingLight = Color(0xFFE65100);
  static const Color pendingDark = Color(0xFFFFAB40);
  static const Color completedLight = Color(0xFF757575);
  static const Color completedDark = Color(0xFF9E9E9E);

  // Badge colors
  static const Color badgeEarnedLight = Color(0xFFFFA000);
  static const Color badgeEarnedDark = Color(0xFFFFD54F);
  static const Color badgeUnearnedLight = Color(0xFF9E9E9E);
  static const Color badgeUnearnedDark = Color(0xFF616161);

  // Password strength (universal — semantic meaning is clear)
  static const Color strengthWeak = Color(0xFFD32F2F);
  static const Color strengthMedium = Color(0xFFF57C00);
  static const Color strengthStrong = Color(0xFF388E3C);

  static Color request(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? requestDark
          : requestLight;

  static Color offer(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? offerDark
          : offerLight;

  static Color active(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? activeDark
          : activeLight;

  static Color pending(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? pendingDark
          : pendingLight;

  static Color completed(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? completedDark
          : completedLight;

  static Color badgeEarned(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? badgeEarnedDark
          : badgeEarnedLight;

  static Color badgeUnearned(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? badgeUnearnedDark
          : badgeUnearnedLight;
}

/// Centralized theme configuration for MicroHelp.
class AppTheme {
  AppTheme._();

  static const _seedColor = Color(0xFF00897B); // teal 600

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );
    return _buildTheme(colorScheme);
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );
    return _buildTheme(colorScheme);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,

      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),

      cardTheme: CardThemeData(
        elevation: isDark ? 1 : 2,
        shadowColor: colorScheme.shadow.withAlpha(38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: colorScheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 72,
        elevation: 2,
        backgroundColor:
            isDark ? colorScheme.surfaceContainerHigh : colorScheme.surface,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(color: colorScheme.outline.withAlpha(128)),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withAlpha(102)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withAlpha(77)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide.none,
        backgroundColor: colorScheme.surfaceContainerHigh,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        backgroundColor: colorScheme.surface,
        showDragHandle: true,
      ),

      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withAlpha(128),
        thickness: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// Convenience SnackBar helpers to replace hardcoded Colors.green/red/orange.
extension SnackBarHelpers on BuildContext {
  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(this).colorScheme.primary,
      ),
    );
  }

  void showErrorSnackBar(String message, {VoidCallback? onRetry}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(this).colorScheme.error,
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Theme.of(this).colorScheme.onError,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  void showWarningSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(this).colorScheme.tertiary,
      ),
    );
  }
}

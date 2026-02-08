import 'package:flutter/material.dart';

/// Semantic colors for post types, statuses, and badges.
/// Adapt to light/dark mode via context.
class AppColors {
  AppColors._();

  // Post type colors — vibrant and distinct
  static const Color requestLight = Color.fromARGB(255, 118, 18, 141); // violet
  static const Color requestDark = Color.fromARGB(255, 146, 6, 90); // magenta
  static const Color offerLight = Color.fromARGB(255, 3, 85, 123); // cyan
  static const Color offerDark = Color.fromARGB(255, 37, 156, 180); // teal

  // Status colors
  static const Color activeLight = Color(0xFF3B82F6); // bright blue
  static const Color activeDark = Color(0xFF93C5FD); // light blue
  static const Color pendingLight = Color(0xFFDB7706); // amber
  static const Color pendingDark = Color(0xFFFBBF24);
  static const Color completedLight = Color(0xFF6B7280); // cool gray
  static const Color completedDark = Color(0xFF9CA3AF);

  // Badge colors — golden & warm
  static const Color badgeEarnedLight = Color(0xFFD97706); // warm amber
  static const Color badgeEarnedDark = Color(0xFFFBBF24);
  static const Color badgeUnearnedLight = Color(0xFF9CA3AF);
  static const Color badgeUnearnedDark = Color(0xFF4B5563);

  // Password strength (universal)
  static const Color strengthWeak = Color(0xFFEF4444);
  static const Color strengthMedium = Color(0xFFF59E0B);
  static const Color strengthStrong = Color(0xFF10B981);

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

  // Vibrant violet-blue seed — fun and modern
  static const _seedColor = Color(0xFF7C3AED); // violet 600

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
      // Override key roles for extra personality
      primary: const Color(0xFF7C3AED),
      secondary: const Color(0xFFEC4899), // pink accent
      tertiary: const Color(0xFFF59E0B), // warm amber accent
      primaryContainer: const Color(0xFFEDE9FE), // soft violet wash
      secondaryContainer: const Color(0xFFFCE7F3), // soft pink wash
      tertiaryContainer: const Color(0xFFFEF3C7), // soft amber wash
    );
    return _buildTheme(colorScheme);
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
      primary: const Color(0xFFA78BFA), // lighter violet
      secondary: const Color(0xFFF472B6), // lighter pink
      tertiary: const Color(0xFFFBBF24), // bright amber
      primaryContainer: const Color(0xFF3B1E8E), // deep violet
      secondaryContainer: const Color(0xFF831843), // deep pink
      tertiaryContainer: const Color(0xFF78350F), // deep amber
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

import 'package:flutter/material.dart';

// Color scheme constants
class AppColors {
  // Primary palette - BRIGHTER GREEN COLORS
  static const Color primary = Color(0xFF55613b); // Brightened from 1A632D
  static const Color primaryLight = Color(0xFF4CAF50); // Brightened from 378D4C
  static const Color primaryDark = Color(0xFF1B7340); // Brightened from 0B4A1C

  // Accent colors
  static const Color accent = Color(0xFFD4AF37); // Gold accent
  static const Color accentLight = Color(0xFFEACD6D);

  // Neutral colors
  static const Color background = Color(0xFFF9F9F9);
  static const Color surface = Colors.white;
  static const Color cardBackground = Colors.white;

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFF9E9E9E);

  // Feedback colors
  static const Color success = Color(0xFF4CAF50);
  static const Color info = Color(0xFF2196F3);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
}

// Typography styles
class AppTypography {
  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
      letterSpacing: -0.5,
    ),
    displayMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
      letterSpacing: -0.25,
    ),
    displaySmall: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    headlineMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    titleLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      color: AppColors.textPrimary,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: AppColors.textPrimary,
      height: 1.4,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      color: AppColors.textSecondary,
      height: 1.3,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.primary,
    ),
  );
}

// Border radius constants
class AppBorderRadius {
  static const double small = 4.0;
  static const double medium = 8.0;
  static const double large = 16.0;

  static BorderRadius get smallAll => BorderRadius.circular(small);
  static BorderRadius get mediumAll => BorderRadius.circular(medium);
  static BorderRadius get largeAll => BorderRadius.circular(large);
}

// Shadows for elevation
class AppShadows {
  static List<BoxShadow> get small => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get medium => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get large => [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];
}

// Application spacing
class AppSpacing {
  static const double xs = 4.0;
  static const double small = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

// Main application theme
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryLight,
        onPrimaryContainer: Colors.white,
        secondary: AppColors.accent,
        onSecondary: Colors.black,
        secondaryContainer: AppColors.accentLight,
        onSecondaryContainer: Colors.black,
        error: AppColors.error,
        onError: Colors.white,
        background: AppColors.background,
        onBackground: AppColors.textPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),

      // Text styling
      textTheme: AppTypography.textTheme,

      // App bar styling
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Scaffold background
      scaffoldBackgroundColor: AppColors.background,

      // Card styling
      cardTheme: CardTheme(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.mediumAll,
        ),
        color: AppColors.cardBackground,
        margin: EdgeInsets.all(AppSpacing.small),
      ),

      // Input fields styling
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.medium, vertical: AppSpacing.small),
        border: OutlineInputBorder(
          borderRadius: AppBorderRadius.mediumAll,
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.mediumAll,
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.mediumAll,
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.mediumAll,
          borderSide: BorderSide(color: AppColors.error),
        ),
        labelStyle: TextStyle(color: AppColors.textSecondary),
        hintStyle: TextStyle(color: AppColors.textLight),
      ),

      // Elevated button styling
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.medium, vertical: AppSpacing.small),
          textStyle: AppTypography.textTheme.labelLarge?.copyWith(
            color: Colors.white,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.mediumAll,
          ),
        ),
      ),

      // Text button styling
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.small,
            vertical: AppSpacing.xs,
          ),
          textStyle: AppTypography.textTheme.labelLarge,
        ),
      ),

      // Outlined button styling
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary),
          padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.medium, vertical: AppSpacing.small),
          textStyle: AppTypography.textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.mediumAll,
          ),
        ),
      ),

      // Floating action button styling
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.largeAll,
        ),
      ),

      // Chip styling
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade100,
        selectedColor: AppColors.primaryLight,
        disabledColor: Colors.grey.shade200,
        labelStyle: TextStyle(color: AppColors.textPrimary),
        secondaryLabelStyle: TextStyle(color: Colors.white),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.small,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.smallAll,
        ),
      ),

      // Icon theme
      iconTheme: IconThemeData(
        color: AppColors.textSecondary,
        size: 24,
      ),
      primaryIconTheme: IconThemeData(
        color: Colors.white,
        size: 24,
      ),

      // List tile theme
      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small,
        ),
        tileColor: Colors.transparent,
        selectedTileColor: AppColors.primaryLight.withOpacity(0.1),
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
        space: AppSpacing.medium,
      ),

      // Tab bar theme
      tabBarTheme: TabBarTheme(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTypography.textTheme.labelLarge,
        unselectedLabelStyle: AppTypography.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.normal,
        ),
        indicatorColor: AppColors.primary,
        dividerColor: Colors.transparent,
      ),

      // Dialog theme
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.mediumAll,
        ),
      ),

      // Bottom sheet theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppBorderRadius.large),
          ),
        ),
      ),

      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return Colors.grey.shade400;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected))
            return AppColors.primaryLight.withOpacity(0.5);
          return Colors.grey.shade300;
        }),
      ),
    );
  }

  // Optionally add a dark theme
  static ThemeData get darkTheme {
    // Implement dark theme here if needed
    return lightTheme;
  }
}

// Export the main theme to use in your app
final ThemeData appTheme = AppTheme.lightTheme;

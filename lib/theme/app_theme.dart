import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// NiyatiMart brand palette.
///
/// Roles come straight from the brand sheet:
///   Primary Blue   - navigation, header, primary buttons
///   Teal           - icons, highlights, category chips
///   Orange         - offers, badges, CTA highlights
///   Green          - success, secure, savings
///   Light          - page background and cards
///   Dark / Grey    - primary and secondary text
class AppColors {
  static const primary = Color(0xFF0D47A1);
  static const primaryDark = Color(0xFF093670);
  static const primaryLight = Color(0xFF1565C0);
  static const primarySoft = Color(0xFFE8EEF9);

  static const teal = Color(0xFF00897B);
  static const tealSoft = Color(0xFFE0F2F0);

  static const orange = Color(0xFFFF9800);
  static const orangeSoft = Color(0xFFFFF3E0);

  static const success = Color(0xFF43A047);
  static const successSoft = Color(0xFFE8F5E9);
  static const danger = Color(0xFFE53935);

  static const background = Color(0xFFF5F7FA);
  static const card = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE3E8EF);

  static const textDark = Color(0xFF212121);
  static const textGrey = Color(0xFF757575);
  static const textLight = Color(0xFF9E9E9E);
  static const onPrimary = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------
  // Legacy aliases. The app was originally built dark-with-gold; these keep
  // older call sites compiling and pointing at the right new role.
  // ---------------------------------------------------------------------
  static const gold = primary;
  static const goldLight = primaryLight;
  static const grey = textGrey;
  static const white = Color(0xFFFFFFFF);
  static const gradientStart = primary;
  static const gradientEnd = primaryDark;
}

class AppTheme {
  static ThemeData get lightTheme => _build();

  /// Kept so existing references (and tests) resolve. The app ships a single
  /// light theme now; this is the same [ThemeData].
  static ThemeData get darkTheme => _build();

  static ThemeData _build() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.teal,
        onSecondary: AppColors.onPrimary,
        tertiary: AppColors.orange,
        surface: AppColors.card,
        onSurface: AppColors.textDark,
        error: AppColors.danger,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textDark,
        displayColor: AppColors.textDark,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.onPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.onPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        hintStyle: const TextStyle(color: AppColors.textLight),
        labelStyle: const TextStyle(color: AppColors.textGrey),
        prefixIconColor: AppColors.textGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,

          // Height only. An infinite minimum WIDTH here forces a tight
          // infinite width on every ElevatedButton, which throws
          // "BoxConstraints forces an infinite width" the moment one is placed
          // in a Row or any other horizontally unbounded parent. Buttons that
          // should span the screen wrap themselves in
          // SizedBox(width: double.infinity) or Expanded at the call site.
          minimumSize: const Size(0, 52),

          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border),
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.card,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.primarySoft,
        labelStyle: const TextStyle(color: AppColors.primary),
        side: BorderSide.none,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        titleTextStyle: const TextStyle(
          color: AppColors.textDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: const TextStyle(color: AppColors.textDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.textDark,
        contentTextStyle: TextStyle(color: AppColors.onPrimary),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),

      dividerColor: AppColors.border,
      iconTheme: const IconThemeData(color: AppColors.textGrey),
    );
  }

  /// Soft elevation for cards on the light background.
  static BoxDecoration premiumCardDecoration = BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.border),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.06),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

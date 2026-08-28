import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The admin console reuses the NiyatiMart brand palette from the customer
/// app so the two products look like one company, but leans on a slightly
/// cooler, denser surface treatment — this is a work tool, not a storefront.
class AdminColors {
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
  static const dangerSoft = Color(0xFFFFEBEE);

  static const purple = Color(0xFF6A1B9A);
  static const purpleSoft = Color(0xFFF3E5F5);

  static const background = Color(0xFFF4F6FA);
  static const card = Color(0xFFFFFFFF);
  static const sidebar = Color(0xFF0B1F3F);
  static const sidebarHover = Color(0xFF16305A);
  static const border = Color(0xFFE3E8EF);

  static const textDark = Color(0xFF1A1D23);
  static const textGrey = Color(0xFF6B7280);
  static const textLight = Color(0xFF9CA3AF);
  static const onPrimary = Color(0xFFFFFFFF);
}

class AdminTheme {
  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AdminColors.background,
      colorScheme: const ColorScheme.light(
        primary: AdminColors.primary,
        onPrimary: AdminColors.onPrimary,
        secondary: AdminColors.teal,
        onSecondary: AdminColors.onPrimary,
        tertiary: AdminColors.orange,
        surface: AdminColors.card,
        onSurface: AdminColors.textDark,
        error: AdminColors.danger,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: AdminColors.textDark,
        displayColor: AdminColors.textDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AdminColors.card,
        foregroundColor: AdminColors.textDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AdminColors.textDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: AdminColors.textGrey),
      ),
      cardTheme: CardThemeData(
        color: AdminColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AdminColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AdminColors.border,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AdminColors.card,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: const TextStyle(color: AdminColors.textLight),
        labelStyle: const TextStyle(color: AdminColors.textGrey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AdminColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AdminColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AdminColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AdminColors.danger),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          side: const BorderSide(color: AdminColors.border),
          foregroundColor: AdminColors.textDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      chipTheme: ChipThemeData(
        side: const BorderSide(color: AdminColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}

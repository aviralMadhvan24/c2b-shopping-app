import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const background = Color(0xFF0B0B0B);
  static const surface = Color(0xFF141414);
  static const card = Color(0xFF1A1A1A);

  static const gold = Color(0xFFD4AF37);
  static const goldLight = Color(0xFFF5D76E);

  static const success = Color(0xFF22C55E);
  static const danger = Color(0xFFEF4444);

  static const white = Colors.white;
  static const grey = Color(0xFF9CA3AF);
  static const border = Color(0xFF2A2A2A);

  static const gradientStart = Color(0xFF1E1E1E);
  static const gradientEnd = Color(0xFF111111);
}

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,

    brightness: Brightness.dark,

    scaffoldBackgroundColor: AppColors.background,

    colorScheme: const ColorScheme.dark(
      primary: AppColors.gold,
      secondary: AppColors.goldLight,
      surface: AppColors.surface,
    ),

    textTheme: GoogleFonts.poppinsTextTheme().apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      foregroundColor: Colors.white,
    ),

    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(
          color: AppColors.border,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 18,
      ),

      hintStyle: const TextStyle(
        color: AppColors.grey,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: AppColors.border,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: AppColors.gold,
          width: 1.5,
        ),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.black,

        minimumSize: const Size(
          double.infinity,
          56,
        ),

        elevation: 0,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),

        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.gold,
      unselectedItemColor: AppColors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    dividerColor: AppColors.border,
  );

  static BoxDecoration premiumCardDecoration = BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.gradientStart,
        AppColors.gradientEnd,
      ],
    ),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(
      color: AppColors.border,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.35),
        blurRadius: 30,
        spreadRadius: 2,
        offset: const Offset(0, 10),
      ),
    ],
  );

  static BoxDecoration glassDecoration = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.06),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.08),
    ),
  );

  static BoxDecoration heroBannerDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(30),
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF2D2D2D),
        Color(0xFF121212),
      ],
    ),
    boxShadow: [
      BoxShadow(
        color: AppColors.gold.withValues(alpha: 0.15),
        blurRadius: 40,
        spreadRadius: 2,
      ),
    ],
  );
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 40.0;
}

class AppRadius {
  static const sm = 12.0;
  static const md = 18.0;
  static const lg = 24.0;
  static const xl = 30.0;
}

class AppTextStyles {
  static const hero = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    height: 1.1,
  );

  static const sectionTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: Colors.white,
  );

  static const productTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static const subtitle = TextStyle(
    fontSize: 14,
    color: AppColors.grey,
  );

  static const price = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.gold,
  );
}
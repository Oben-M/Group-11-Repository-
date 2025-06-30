import 'package:flutter/material.dart';

class AppTheme {

  static const Color primaryColor = Color(0xFF1E88E5);
  static const Color secondaryColor = Color(0xFF26C6DA);
  static const Color accentColor = Color(0xFF00E676);
  

  static const Color neutralDark = Color(0xFF263238);
  static const Color neutralLight = Color(0xFFF5F7FA);
  

  static const Color goodColor = Color(0xFF00C853);
  static const Color mediumColor = Color(0xFFFFAB00);
  static const Color poorColor = Color(0xFFFF5252);
  
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        background: neutralLight,
        surface: Colors.white,
        onSurface: neutralDark.withOpacity(0.87),
      ),
      scaffoldBackgroundColor: neutralLight,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: neutralLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        labelStyle: const TextStyle(fontWeight: FontWeight.w500),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: primaryColor.withOpacity(0.2),
        labelTextStyle: MaterialStateProperty.all(
          const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        iconTheme: MaterialStateProperty.all(
          const IconThemeData(size: 24),
        ),
        backgroundColor: Colors.white,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 22, letterSpacing: 0.15),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, letterSpacing: 0.15),
        titleSmall: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, letterSpacing: 0.1),
        bodyLarge: TextStyle(fontSize: 16, letterSpacing: 0.5),
        bodyMedium: TextStyle(fontSize: 14, letterSpacing: 0.25),
        bodySmall: TextStyle(fontSize: 12, letterSpacing: 0.4),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        background: const Color(0xFF121212),
        surface: const Color(0xFF1E1E1E),
        onSurface: Colors.white.withOpacity(0.87),
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Color(0xFF1A1A1A),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        color: const Color(0xFF1E1E1E),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        labelStyle: const TextStyle(fontWeight: FontWeight.w500),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: primaryColor.withOpacity(0.3),
        labelTextStyle: MaterialStateProperty.all(
          const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        iconTheme: MaterialStateProperty.all(
          const IconThemeData(size: 24),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 22, letterSpacing: 0.15, color: Colors.white.withOpacity(0.87)),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, letterSpacing: 0.15, color: Colors.white.withOpacity(0.87)),
        titleSmall: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, letterSpacing: 0.1, color: Colors.white.withOpacity(0.87)),
        bodyLarge: TextStyle(fontSize: 16, letterSpacing: 0.5, color: Colors.white.withOpacity(0.87)),
        bodyMedium: TextStyle(fontSize: 14, letterSpacing: 0.25, color: Colors.white.withOpacity(0.6)),
        bodySmall: TextStyle(fontSize: 12, letterSpacing: 0.4, color: Colors.white.withOpacity(0.6)),
      ),
    );
  }
}

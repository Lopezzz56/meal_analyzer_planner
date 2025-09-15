import 'package:flutter/material.dart';

class AppTheme {
  // Light Mode Colors
  static final lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Colors.teal,
    onPrimary: Colors.white,
    secondary: Colors.tealAccent,
    onSecondary: Colors.black,
    background: Colors.white,
    onBackground: Colors.black87,
    surface: Colors.white,
    onSurface: Colors.black87,
    error: Colors.red,
    onError: Colors.white,
  );

  // Dark Mode Colors
  static final darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Colors.tealAccent,
    onPrimary: Colors.black,
    secondary: Colors.tealAccent,
    onSecondary: Colors.black,
    background: Colors.black,
    onBackground: Colors.white,
    surface: Colors.grey[900]!,
    onSurface: Colors.white,
    error: Colors.redAccent,
    onError: Colors.black,
  );

  // Light ThemeData
  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: lightColorScheme,
    primaryColor: lightColorScheme.primary,
    scaffoldBackgroundColor: lightColorScheme.background,
    appBarTheme: AppBarTheme(
      backgroundColor: lightColorScheme.primary,
      foregroundColor: lightColorScheme.onPrimary,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: lightColorScheme.secondary,
      foregroundColor: lightColorScheme.onSecondary,
    ),
    cardTheme: CardTheme(
      color: lightColorScheme.surface,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    textTheme: TextTheme(
      headlineMedium: TextStyle(color: lightColorScheme.onBackground),
      titleMedium: TextStyle(color: lightColorScheme.onBackground),
      bodyLarge: TextStyle(color: lightColorScheme.onBackground),
    ),
  );

  // Dark ThemeData
  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: darkColorScheme,
    primaryColor: darkColorScheme.primary,
    scaffoldBackgroundColor: darkColorScheme.background,
    appBarTheme: AppBarTheme(
      backgroundColor: darkColorScheme.primary,
      foregroundColor: darkColorScheme.onPrimary,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: darkColorScheme.secondary,
      foregroundColor: darkColorScheme.onSecondary,
    ),
    cardTheme: CardTheme(
      color: darkColorScheme.surface,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    textTheme: TextTheme(
      headlineMedium: TextStyle(color: darkColorScheme.onBackground),
      titleMedium: TextStyle(color: darkColorScheme.onBackground),
      bodyLarge: TextStyle(color: darkColorScheme.onBackground),
    ),
  );
}

import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  primaryColor: Color(0xFF1A632D), // Green as primary color (representative of Al-Aqsa)
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme(
    color: Color(0xFF1A632D),
    elevation: 0,
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: Color(0xFF1A632D),
    textTheme: ButtonTextTheme.primary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFF1A632D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Color(0xFF1A632D),
    ),
    displayMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Color(0xFF1A632D),
    ),
    displaySmall: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Color(0xFF1A632D),
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      color: Colors.black87,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: Colors.black87,
    ),
  ),
);

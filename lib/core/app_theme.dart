import 'package:flutter/material.dart';

class AppTheme {
  // ألوان الهوية من الشعار
  static const Color primaryRed = Color(0xFFD3392D);
  static const Color accentOrange = Color(0xFFE5A158);
  static const Color fieldGrey = Color(0xFFF9F9F9);

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryRed,
      scaffoldBackgroundColor: Colors.white,
      fontFamily: 'Cairo', // تأكد من إضافة الخط في pubspec.yaml

      // دعم اتجاه النصوص
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
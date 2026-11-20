import 'package:flutter/material.dart';

const kGreen = Color(0xFF14532D);
const kGold = Color(0xFFB8963E);
const kBeige = Color(0xFFF7F1E3);

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kGreen,
    primary: kGreen,
    onPrimary: Colors.white,
    secondary: kGold,
    surface: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kBeige,
    appBarTheme: const AppBarTheme(
      backgroundColor: kGreen,
      foregroundColor: Colors.white,
      centerTitle: true,
    ),
  );
}

/// تحويل الأرقام إلى الأرقام العربية الهندية.
String toArabicDigits(int n) => n
    .toString()
    .split('')
    .map((c) => c == '-' ? c : String.fromCharCode(0x0660 + int.parse(c)))
    .join();

import 'package:flutter/material.dart';

const kPink = Color(0xFFFFB6C1);
const kHotPink = Color(0xFFFF69B4);
const kCream = Color(0xFFFFF5F5);
const kGrey = Color(0xFF6B6B6B);
const kDanger = Color(0xFFE53935);

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: kHotPink).copyWith(primary: kHotPink),
    scaffoldBackgroundColor: kCream,
    appBarTheme: const AppBarTheme(
      backgroundColor: kPink,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kHotPink,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: kPink),
      ),
    ),
    textTheme: ThemeData.light().textTheme.apply(bodyColor: kGrey, displayColor: kGrey),
  );
}

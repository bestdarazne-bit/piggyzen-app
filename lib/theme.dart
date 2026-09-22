import 'package:flutter/material.dart';

// Bảng màu chính — pastel, không neon, không phủ hồng đậm toàn màn hình.
const kPink = Color(0xFFFFB6C1);
const kHotPink = Color(0xFFF45BAA);
const kAccentPink = Color(0xFFFFB6D2);
const kCream = Color(0xFFFFF7F8);
const kGrey = Color(0xFF6B6B6B);
const kDanger = Color(0xFFE53935);
const kWalletBlue = Color(0xFF5B8DEF);
const kSuccess = Color(0xFF2FAE66);

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: kHotPink).copyWith(primary: kHotPink),
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: kGrey,
      elevation: 0,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kHotPink,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        minimumSize: const Size(0, 52),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFF1DDE6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFF1DDE6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: kHotPink, width: 1.6),
      ),
    ),
    textTheme: ThemeData.light().textTheme.apply(bodyColor: kGrey, displayColor: kGrey),
  );
}

/// Nền pastel hiện đại: gradient nhẹ + vài blob mờ, không che nội dung,
/// không neon, không nhuộm cả màn hình thành hồng đậm.
class PiggyBackground extends StatelessWidget {
  final Widget child;
  const PiggyBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFEAF1), kCream, Color(0xFFFFF1F5)],
            ),
          ),
        ),
        Positioned(
          top: -60,
          right: -50,
          child: _blob(220, kHotPink.withAlpha(28)),
        ),
        Positioned(
          bottom: -70,
          left: -60,
          child: _blob(260, kAccentPink.withAlpha(36)),
        ),
        child,
      ],
    );
  }

  Widget _blob(double size, Color color) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withAlpha(0)]),
        ),
      ),
    );
  }
}

BoxDecoration cardDecoration({Color color = Colors.white}) => BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(26),
      boxShadow: [BoxShadow(color: kHotPink.withAlpha(22), blurRadius: 18, offset: const Offset(0, 8))],
    );

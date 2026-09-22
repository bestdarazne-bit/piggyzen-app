import 'package:flutter/material.dart';
import 'theme.dart';

/// Heo đất — cute, pastel, KHÔNG chạy animation liên tục khi user không
/// tương tác. Chỉ nhún một lần khi [bounceTick] đổi (cất tiền thành công)
/// hoặc ăn mừng ngắn khi [celebrateTick] đổi (đạt mục tiêu).
class PigMascot extends StatelessWidget {
  final bool angry;
  final int bounceTick;
  final int celebrateTick;
  final double size;
  const PigMascot({
    super.key,
    required this.angry,
    required this.bounceTick,
    this.celebrateTick = 0,
    this.size = 150,
  });

  @override
  Widget build(BuildContext context) {
    Widget img = ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Image.asset('assets/images/avatar.jpg', width: size, height: size, fit: BoxFit.cover),
    );
    if (angry) {
      img = ColorFiltered(
        colorFilter: const ColorFilter.mode(Color.fromRGBO(229, 57, 53, 0.26), BlendMode.srcATop),
        child: img,
      );
    }

    // Nhún nhẹ MỘT LẦN mỗi khi bounceTick thay đổi (ví dụ vừa cất tiền).
    Widget bounced = TweenAnimationBuilder<double>(
      key: ValueKey('bounce_$bounceTick'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (_, v, child) {
        return Transform.scale(scale: bounceTick == 0 ? 1.0 : 0.9 + 0.1 * v, child: child);
      },
      child: img,
    );

    // Ăn mừng ngắn khi đạt mục tiêu: nảy lên + xoay nhẹ, chỉ chạy 1 lần.
    Widget celebrated = TweenAnimationBuilder<double>(
      key: ValueKey('celebrate_$celebrateTick'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (_, v, child) {
        if (celebrateTick == 0) return child!;
        return Transform.translate(
          offset: Offset(0, -14 * (1 - v)),
          child: Transform.rotate(angle: (1 - v) * 0.12, child: child),
        );
      },
      child: bounced,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        celebrated,
        Positioned(
          right: -4,
          top: -4,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: angry ? kDanger : kHotPink, shape: BoxShape.circle),
            child: Text(angry ? '😡' : (celebrateTick > 0 ? '🎉' : '😊'), style: const TextStyle(fontSize: 20)),
          ),
        ),
      ],
    );
  }
}

/// Animation đồng xu rơi khi cất tiền thành công — chạy một lần rồi tự dọn,
/// không lặp, không tốn tài nguyên khi không có sự kiện.
void showCoinDrop(BuildContext context) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(builder: (_) => _CoinDrop(onDone: () => entry.remove()));
  overlay.insert(entry);
}

class _CoinDrop extends StatelessWidget {
  final VoidCallback onDone;
  const _CoinDrop({required this.onDone});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeIn,
        onEnd: onDone,
        builder: (_, v, __) {
          return Stack(
            children: [
              Positioned(
                left: size.width / 2 - 22,
                top: size.height * 0.1 + v * size.height * 0.18,
                child: Opacity(
                  opacity: (1 - v * v).clamp(0.0, 1.0).toDouble(),
                  child: Transform.rotate(angle: v * 6, child: const Text('🪙', style: TextStyle(fontSize: 44))),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

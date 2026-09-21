import 'dart:math';
import 'package:flutter/material.dart';
import 'theme.dart';

/// Linh vật heo: vui = nhún nhảy nhẹ, giận = rung + phủ đỏ + 😡.
class PigMascot extends StatefulWidget {
  final bool angry;
  final int bounceTick;
  final double size;
  const PigMascot({super.key, required this.angry, required this.bounceTick, this.size = 170});

  @override
  State<PigMascot> createState() => _PigMascotState();
}

class _PigMascotState extends State<PigMascot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget img = ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: Image.asset('assets/images/avatar.jpg', width: widget.size, height: widget.size, fit: BoxFit.cover),
    );
    if (widget.angry) {
      img = ColorFiltered(
        colorFilter: const ColorFilter.mode(Color.fromRGBO(255, 0, 0, 0.28), BlendMode.srcATop),
        child: img,
      );
    }

    final bounced = TweenAnimationBuilder<double>(
      key: ValueKey(widget.bounceTick),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (_, v, child) => Transform.scale(scale: 1 + 0.18 * sin(pi * v), child: child),
      child: img,
    );

    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = _c.value;
        final dx = widget.angry ? sin(t * 2 * pi * 8) * 4 : 0.0;
        final dy = widget.angry ? 0.0 : sin(t * 2 * pi) * 6;
        return Transform.translate(offset: Offset(dx, dy), child: child);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          bounced,
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: widget.angry ? kDanger : kHotPink,
                shape: BoxShape.circle,
              ),
              child: Text(widget.angry ? '😡' : '😊', style: const TextStyle(fontSize: 22)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animation đồng xu rơi vào heo.
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
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeIn,
        onEnd: onDone,
        builder: (_, v, __) {
          return Stack(
            children: [
              Positioned(
                left: size.width / 2 - 24,
                top: size.height * 0.08 + v * size.height * 0.2,
                child: Opacity(
                  opacity: (1 - v * v).clamp(0.0, 1.0).toDouble(),
                  child: Transform.rotate(
                    angle: v * 6,
                    child: const Text('🪙', style: TextStyle(fontSize: 48)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

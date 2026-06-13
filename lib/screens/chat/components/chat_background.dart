import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/bloc/app_bloc.dart';
import '../theme/chat_theme.dart';

/// Aurora background: soft radial colour blobs drifting slowly over the
/// theme's gradient. Falls back to a static gradient on low-end devices or
/// when the OS requests reduced motion, keeping budget phones smooth.
class ChatBackground extends StatefulWidget {
  final ChatTheme theme;
  final Widget? child;

  const ChatBackground({super.key, required this.theme, this.child});

  @override
  State<ChatBackground> createState() => _ChatBackgroundState();
}

class _ChatBackgroundState extends State<ChatBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Slow drift — barely perceptible so it never competes with content.
    _controller = AnimationController(
      duration: const Duration(seconds: 24),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lowEnd = context.select((AppBloc b) => b.isLowEndDevice);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final animate = !lowEnd && !reduceMotion;

    if (animate) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else if (_controller.isAnimating) {
      _controller.stop();
    }

    final theme = widget.theme;
    final base = theme.backgroundGradient;
    final blobs = [
      theme.outgoingAccent,
      theme.investedAccent,
      theme.incomingAccent,
    ];

    if (!animate) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: base,
          ),
        ),
        child: CustomPaint(
          painter: _AuroraPainter(t: 0.4, blobs: blobs, animate: false),
          child: widget.child,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: base,
            ),
          ),
          child: CustomPaint(
            painter: _AuroraPainter(
              t: _controller.value,
              blobs: blobs,
              animate: true,
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Paints 3 soft radial blobs whose centres drift on slow sine paths.
class _AuroraPainter extends CustomPainter {
  final double t;
  final List<Color> blobs;
  final bool animate;

  _AuroraPainter({required this.t, required this.blobs, required this.animate});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Phase-shifted anchor points so the three blobs never clump.
    final anchors = [
      Offset(0.20 * w, 0.18 * h),
      Offset(0.85 * w, 0.30 * h),
      Offset(0.65 * w, 0.88 * h),
    ];

    for (var i = 0; i < blobs.length; i++) {
      final phase = t * 2 * math.pi + i * 2.1;
      final drift = animate ? 0.06 : 0.0;
      final c = anchors[i].translate(
        math.cos(phase) * drift * w,
        math.sin(phase) * drift * h,
      );
      final radius = w * 0.55;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            blobs[i].withValues(alpha: 0.22),
            blobs[i].withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: radius));
      canvas.drawCircle(c, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.t != t || old.blobs != blobs;
}

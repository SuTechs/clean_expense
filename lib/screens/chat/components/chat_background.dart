import 'package:flutter/material.dart';

import '../theme/chat_theme.dart';

/// Animated gradient background for the chat screen.
/// Uses ChatTheme colors for consistent theming.
class ChatBackground extends StatefulWidget {
  final ChatTheme theme;
  final Widget? child;

  const ChatBackground({super.key, required this.theme, this.child});

  @override
  State<ChatBackground> createState() => _ChatBackgroundState();
}

class _ChatBackgroundState extends State<ChatBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.theme.backgroundGradient;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment(
                0.5 + (_animation.value * 0.5),
                1.0 - (_animation.value * 0.2),
              ),
              colors: [
                Color.lerp(colors[0], colors[1], _animation.value)!,
                Color.lerp(colors[1], colors[2], _animation.value)!,
                Color.lerp(colors[2], colors[0], _animation.value)!,
              ],
            ),
          ),
          child: child,
        );
      },
      child: CustomPaint(
        painter: _SubtlePatternPainter(color: widget.theme.patternColor),
        child: widget.child,
      ),
    );
  }
}

/// Paints a subtle dot pattern for texture
class _SubtlePatternPainter extends CustomPainter {
  final Color color;

  _SubtlePatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const spacing = 24.0;
    const dotRadius = 1.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SubtlePatternPainter oldDelegate) =>
      color != oldDelegate.color;
}

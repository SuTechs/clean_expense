import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/data/ai/ai_message.dart';
import '../../../theme.dart';
import 'ai_widget_renderer.dart';

class AiMessageBubble extends StatelessWidget {
  final AiMessage message;

  const AiMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == AiMessageRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primaryNavy : AppTheme.cardBackground,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: AppTheme.dividerColor),
        ),
        child: message.status == AiMessageStatus.pending
            ? const _TypingDots()
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: GoogleFonts.outfit(
                      fontSize: 14.5,
                      height: 1.45,
                      color: isUser
                          ? Colors.white
                          : (message.status == AiMessageStatus.error
                                ? AppTheme.dangerRed
                                : AppTheme.textPrimary),
                    ),
                  ),
                  if (message.widget != null)
                    AiWidgetRenderer(spec: message.widget!),
                ],
              ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_controller.value - i * 0.2) % 1.0;
            final bounce = t < 0.4 ? (1 - (t / 0.4 - 0.5).abs() * 2) : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
              child: Transform.translate(
                offset: Offset(0, -4 * bounce),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withValues(
                      alpha: 0.5 + 0.5 * bounce,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

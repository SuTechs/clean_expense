import 'package:flutter/material.dart';

import '../../../data/data/insight/insight.dart';
import '../theme/chat_theme.dart';

/// The "your money" message — an app-authored insight in the thread.
/// Deliberately NOT glass: a solid accent-tinted card so it reads as the app
/// speaking, distinct from the user's own transaction bubbles.
class InsightBubble extends StatelessWidget {
  final InsightData insight;
  final ChatTheme theme;

  const InsightBubble({super.key, required this.insight, required this.theme});

  @override
  Widget build(BuildContext context) {
    final accent = theme.insightAccent;

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82,
          ),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(5),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            border: Border.all(color: accent.withValues(alpha: 0.30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'YOUR MONEY',
                    style: TextStyle(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                insight.text,
                style: TextStyle(
                  color: theme.primaryText,
                  fontSize: 13.5,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (insight.bars.isNotEmpty) ...[
                const SizedBox(height: 11),
                _MiniBars(bars: insight.bars, accent: accent, theme: theme),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniBars extends StatelessWidget {
  final List<InsightBar> bars;
  final Color accent;
  final ChatTheme theme;
  const _MiniBars({
    required this.bars,
    required this.accent,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final bar in bars)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  child: Text(
                    '#${bar.label}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.secondaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, c) => Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Container(
                          height: 8,
                          width: c.maxWidth * bar.fraction.clamp(0.05, 1.0),
                          decoration: BoxDecoration(
                            color: accent.withValues(
                              alpha: 0.4 + 0.6 * bar.fraction.clamp(0.0, 1.0),
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/chat_theme.dart';
import '../theme/chat_theme_provider.dart';

/// Bottom sheet widget for selecting chat themes.
/// Shows preview cards for each available theme.
class ThemeSelectorSheet extends StatelessWidget {
  final ChatThemeProvider themeProvider;

  const ThemeSelectorSheet({super.key, required this.themeProvider});

  static void show(BuildContext context, ChatThemeProvider provider) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ThemeSelectorSheet(themeProvider: provider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = themeProvider.theme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(
        color: theme.inputContainerBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.secondaryText.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Choose Theme',
              style: TextStyle(
                color: theme.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Personalize your chat experience',
              style: TextStyle(color: theme.secondaryText, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Theme grid
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: themeProvider.availableThemes
                  .map(
                    (t) => _ThemeCard(
                      chatTheme: t,
                      isSelected: t.id == theme.id,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        themeProvider.setTheme(t);
                        Navigator.pop(context);
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final ChatTheme chatTheme;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.chatTheme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 64) / 2;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: chatTheme.backgroundGradient,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? chatTheme.outgoingAccent
                : chatTheme.patternColor.withValues(alpha: 0.2),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: chatTheme.outgoingAccent.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mini bubbles preview
            Row(
              children: [
                _MiniBubble(
                  color: chatTheme.incomingBg,
                  border: chatTheme.incomingBorder,
                ),
                const SizedBox(width: 6),
                _MiniBubble(
                  color: chatTheme.outgoingBg,
                  border: chatTheme.outgoingBorder,
                ),
                const SizedBox(width: 6),
                _MiniBubble(
                  color: chatTheme.investedBg,
                  border: chatTheme.investedBorder,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Theme name
            Row(
              children: [
                Text(chatTheme.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  chatTheme.name,
                  style: TextStyle(
                    color: chatTheme.primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: chatTheme.outgoingAccent,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBubble extends StatelessWidget {
  final Color color;
  final Color border;

  const _MiniBubble({required this.color, required this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 1),
      ),
    );
  }
}

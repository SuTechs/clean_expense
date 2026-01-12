import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../data/bloc/app_bloc.dart';
import '../../category/manage_category_screen.dart';
import '../theme/chat_theme.dart';
import '../theme/chat_theme_provider.dart';

/// Bottom sheet for chat screen settings.
/// Shows themes, manage categories, and currency options.
class ChatSettingsSheet extends StatelessWidget {
  final ChatThemeProvider themeProvider;

  const ChatSettingsSheet({super.key, required this.themeProvider});

  static void show(BuildContext context, ChatThemeProvider provider) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ChatSettingsSheet(themeProvider: provider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = themeProvider.theme;
    final appBloc = context.watch<AppBloc>();

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
              'Chat Settings',
              style: TextStyle(
                color: theme.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),

            // Options
            _buildOptionTile(
              context,
              icon: Icons.category_rounded,
              title: 'Manage Categories',
              subtitle: 'Add, edit or delete categories',
              theme: theme,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManageCategoryScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            _buildOptionTile(
              context,
              icon: Icons.currency_exchange_rounded,
              title: 'Currency',
              subtitle: appBloc.currency,
              theme: theme,
              onTap: () => _showCurrencyPicker(context, appBloc, theme),
            ),
            const SizedBox(height: 24),

            // Theme section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Theme',
                style: TextStyle(
                  color: theme.secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Theme grid
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: themeProvider.availableThemes
                  .map(
                    (t) => _ThemeCard(
                      chatTheme: t,
                      isSelected: t.id == theme.id,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        themeProvider.setTheme(t);
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

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required ChatTheme theme,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.inputFieldBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.outgoingAccent, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: theme.primaryText,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: theme.secondaryText, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.secondaryText,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker(
    BuildContext context,
    AppBloc appBloc,
    ChatTheme theme,
  ) {
    final currencies = ["₹", "\$", "€", "£", "¥", "₩", "₽"];

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.inputContainerBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Select Currency",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryText,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: currencies.map((c) {
                  final isSelected = appBloc.currency == c;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      appBloc.currency = c;
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.outgoingAccent
                            : theme.inputFieldBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        c,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : theme.primaryText,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
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
    final width = (MediaQuery.of(context).size.width - 60) / 3;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: chatTheme.backgroundGradient,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? chatTheme.outgoingAccent
                : chatTheme.patternColor.withValues(alpha: 0.3),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: chatTheme.outgoingAccent.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            // Mini bubbles
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MiniBubble(
                  color: chatTheme.incomingBg,
                  border: chatTheme.incomingBorder,
                ),
                const SizedBox(width: 4),
                _MiniBubble(
                  color: chatTheme.outgoingBg,
                  border: chatTheme.outgoingBorder,
                ),
                const SizedBox(width: 4),
                _MiniBubble(
                  color: chatTheme.investedBg,
                  border: chatTheme.investedBorder,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Theme name
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(chatTheme.emoji, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  chatTheme.name,
                  style: TextStyle(
                    color: chatTheme.primaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
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
      width: 16,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: border, width: 1),
      ),
    );
  }
}

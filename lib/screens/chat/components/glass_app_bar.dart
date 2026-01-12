import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/chat_theme_provider.dart';
import 'chat_settings_sheet.dart';

class GlassAppBar extends StatelessWidget {
  final ChatThemeProvider themeProvider;

  const GlassAppBar({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    final theme = themeProvider.theme;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          decoration: BoxDecoration(
            color: theme.appBarBg,
            border: Border(
              bottom: BorderSide(
                color: theme.patternColor.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
          ),
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                // Back button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.patternColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: theme.appBarText,
                    ),
                  ),
                ),

                const SizedBox(width: 4),

                // Avatar - tap to open settings
                GestureDetector(
                  onTap: () => ChatSettingsSheet.show(context, themeProvider),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.statusDot.withValues(alpha: 0.25),
                          theme.statusDot.withValues(alpha: 0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.statusDot.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'logo-big.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.account_balance_wallet_rounded,
                          color: theme.statusDot,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Name and status - tap to open settings
                Expanded(
                  child: GestureDetector(
                    onTap: () => ChatSettingsSheet.show(context, themeProvider),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Clean Expense',
                          style: TextStyle(
                            color: theme.appBarText,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: theme.statusDot,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Active now',
                              style: TextStyle(
                                color: theme.secondaryText,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Settings button
                IconButton(
                  onPressed: () =>
                      ChatSettingsSheet.show(context, themeProvider),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.patternColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: theme.appBarText,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

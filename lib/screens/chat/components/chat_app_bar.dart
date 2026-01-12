import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme.dart';

/// A chat-style app bar that shows the app avatar, name, and status.
/// Uses SliverAppBar for scroll-aware behavior.
class ChatAppBar extends StatelessWidget {
  final VoidCallback? onBackPressed;
  final VoidCallback? onSettingsPressed;

  const ChatAppBar({super.key, this.onBackPressed, this.onSettingsPressed});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      expandedHeight: 70,
      collapsedHeight: 70,
      toolbarHeight: 70,
      leading: _BackButton(onPressed: onBackPressed),
      title: const _ChatHeader(),
      centerTitle: false,
      actions: [
        _SettingsButton(onPressed: onSettingsPressed),
        const SizedBox(width: 8),
      ],
    );
  }
}

/// Back button with subtle background
class _BackButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _BackButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: IconButton(
        onPressed: onPressed ?? () => Navigator.pop(context),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryNavy.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppTheme.primaryNavy,
          ),
        ),
      ),
    );
  }
}

/// Chat header with avatar, name, and online status
class _ChatHeader extends StatelessWidget {
  const _ChatHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar with logo
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryGreen.withValues(alpha: 0.2),
                AppTheme.primaryGreen.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.primaryGreen.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'logo-big.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.account_balance_wallet_rounded,
                color: AppTheme.primaryGreen,
                size: 22,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Name and status
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Clean Expense',
              style: TextStyle(
                color: AppTheme.primaryNavy,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Active now',
                  style: TextStyle(
                    color: AppTheme.textSecondary.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// Settings button with subtle background
class _SettingsButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _SettingsButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryNavy.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.tune_rounded,
          size: 20,
          color: AppTheme.primaryNavy,
        ),
      ),
    );
  }
}

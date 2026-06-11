import 'package:flutter/material.dart';

import '../../../theme.dart';

/// Shared layout for onboarding pages: a flexible illustration area
/// followed by a title and subtitle.
class OnboardingPage extends StatelessWidget {
  final Widget illustration;
  final String title;
  final String subtitle;

  const OnboardingPage({
    super.key,
    required this.illustration,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Expanded(child: Center(child: illustration)),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryNavy,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

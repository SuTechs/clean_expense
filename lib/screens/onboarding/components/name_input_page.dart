import 'package:flutter/material.dart';

import '../../../theme.dart';

/// Onboarding page asking for the user's name. Optional — leaving it
/// empty keeps the default "Guest" profile.
class NameInputPage extends StatefulWidget {
  final TextEditingController controller;
  final bool isActive;

  const NameInputPage({
    super.key,
    required this.controller,
    required this.isActive,
  });

  @override
  State<NameInputPage> createState() => _NameInputPageState();
}

class _NameInputPageState extends State<NameInputPage> {
  final FocusNode _focusNode = FocusNode();

  @override
  void didUpdateWidget(NameInputPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _focusNode.requestFocus();
    } else if (!widget.isActive && oldWidget.isActive) {
      _focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryNavy.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.waving_hand_rounded,
                size: 44,
                color: AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "What should we call you?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryNavy,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Totally optional — you can change it anytime.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              textCapitalization: TextCapitalization.words,
              textAlign: TextAlign.center,
              textInputAction: TextInputAction.done,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: "Your name",
                hintStyle: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
                filled: true,
                fillColor: AppTheme.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryNavy,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

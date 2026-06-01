import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme.dart';
import 'category_chip.dart';

/// Payee identity block: avatar (initial) + name + UPI id. Display only — the
/// payee is never persisted.
class PayeeHeader extends StatelessWidget {
  final String name;
  final String vpa;

  const PayeeHeader({super.key, required this.name, required this.vpa});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return Column(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: AppTheme.primaryNavy,
          child: Text(
            initial,
            style: const TextStyle(
              color: AppTheme.textWhite,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryNavy,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          vpa,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

/// The large, centered amount input — the focal point of the screen.
class AmountField extends StatelessWidget {
  final TextEditingController controller;
  final bool autofocus;

  const AmountField({
    super.key,
    required this.controller,
    required this.autofocus,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
        ],
        style: GoogleFonts.outfit(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
        decoration: InputDecoration(
          isCollapsed: true,
          filled: false,
          prefixText: '₹ ',
          prefixStyle: GoogleFonts.outfit(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
          hintText: '0',
          hintStyle: GoogleFonts.outfit(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondary.withValues(alpha: 0.4),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}

/// Compact, chip-style optional note field.
class NoteField extends StatelessWidget {
  final TextEditingController controller;

  const NoteField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.inputFill,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        textCapitalization: TextCapitalization.sentences,
        style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
        decoration: const InputDecoration(
          isCollapsed: true,
          filled: false,
          hintText: 'Add a note',
          hintStyle: TextStyle(color: AppTheme.textSecondary),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}

/// Category label + quick-pick chips + a "More" chip that opens the full picker.
class CategorySection extends StatelessWidget {
  final String? selected;
  final List<String> quickPicks;
  final ValueChanged<String> onSelected;
  final VoidCallback onMore;

  const CategorySection({
    super.key,
    required this.selected,
    required this.quickPicks,
    required this.onSelected,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    // Show the selected category as a chip even if it isn't a quick pick.
    final picks = <String>[
      if (selected != null && !quickPicks.contains(selected)) selected!,
      ...quickPicks,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in picks)
              CategoryChip(
                label: c,
                selected: c == selected,
                onTap: () => onSelected(c),
              ),
            ActionChip(
              avatar: const Icon(Icons.tune_rounded,
                  size: 18, color: AppTheme.primaryNavy),
              label: const Text('More'),
              onPressed: onMore,
              backgroundColor: AppTheme.cardBackground,
              labelStyle: const TextStyle(
                color: AppTheme.primaryNavy,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: AppTheme.dividerColor),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Bottom action bar holding the primary "Select app to pay" button.
class PayBar extends StatelessWidget {
  final VoidCallback onPressed;

  const PayBar({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppTheme.cardBackground,
        boxShadow: [
          BoxShadow(
              color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, -4)),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.account_balance_wallet_rounded),
          label: const Text('Select app to pay'),
        ),
      ),
    );
  }
}

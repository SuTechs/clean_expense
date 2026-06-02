import 'package:flutter/material.dart';

import '../../../theme.dart';

/// A selectable, pill-shaped category chip shared by the payment screen and the
/// category picker sheet.
class CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      backgroundColor: AppTheme.inputFill,
      selectedColor: AppTheme.primaryNavy,
      labelStyle: TextStyle(
        color: selected ? AppTheme.textWhite : AppTheme.tagText,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide.none,
      ),
    );
  }
}

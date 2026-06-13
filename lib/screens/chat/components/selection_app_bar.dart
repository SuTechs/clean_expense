import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../theme.dart';
import '../theme/chat_theme.dart';

/// Contextual app bar shown while a transaction bubble is selected.
/// Mirrors the glass styling of [GlassAppBar].
class SelectionAppBar extends StatelessWidget {
  final ChatTheme theme;
  final VoidCallback onClose;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SelectionAppBar({
    super.key,
    required this.theme,
    required this.onClose,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
                IconButton(
                  onPressed: onClose,
                  icon: _iconChip(Icons.close_rounded, theme.appBarText),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '1 selected',
                    style: TextStyle(
                      color: theme.appBarText,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: _iconChip(Icons.edit_outlined, theme.appBarText),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: _iconChip(Icons.delete_outline_rounded, AppTheme.dangerRed),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconChip(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.patternColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

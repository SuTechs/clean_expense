import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/chat_theme.dart';

/// A minimal date header widget displayed between messages from different days.
/// Uses ChatTheme colors for consistent theming.
class DateHeader extends StatelessWidget {
  final DateTime date;
  final ChatTheme theme;

  const DateHeader({super.key, required this.date, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          _getLabel(),
          style: TextStyle(
            color: theme.dateText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  String _getLabel() {
    final now = DateTime.now();
    if (_isSameDay(date, now)) {
      return 'Today';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM d, y').format(date);
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}

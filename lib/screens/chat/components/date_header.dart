import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/chat_theme.dart';
import 'glass.dart';

/// Day divider that doubles as a daily summary chip:
/// "Today · −₹1,240 · 4 txns". Net is signed (incoming +, outgoing/invested −).
class DateHeader extends StatelessWidget {
  final DateTime date;
  final ChatTheme theme;
  final double net;
  final int count;
  final String currency;

  const DateHeader({
    super.key,
    required this.date,
    required this.theme,
    required this.net,
    required this.count,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final sign = net > 0
        ? '+'
        : net < 0
        ? '−'
        : '';
    final netText = '$sign$currency${net.abs().toStringAsFixed(0)}';
    final netColor = net >= 0 ? theme.incomingAccent : theme.outgoingAccent;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Glass(
          color: theme.appBarBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.patternColor.withValues(alpha: 0.25),
          ),
          sigma: 6,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _label(),
                  style: TextStyle(
                    color: theme.dateText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                if (count > 0) ...[
                  _dot(),
                  Text(
                    netText,
                    style: TextStyle(
                      color: netColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  _dot(),
                  Text(
                    '$count ${count == 1 ? "txn" : "txns"}',
                    style: TextStyle(
                      color: theme.secondaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dot() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 7),
    child: Text(
      '·',
      style: TextStyle(color: theme.secondaryText, fontSize: 12),
    ),
  );

  String _label() {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'Today';
    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    return DateFormat('MMMM d, y').format(date);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

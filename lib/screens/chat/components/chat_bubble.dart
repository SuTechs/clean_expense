import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/data/expense/expense.dart';
import '../../../../theme.dart';

class ChatBubble extends StatelessWidget {
  final String note;
  final double amount;
  final String category;
  final DateTime date;
  final TransactionType type;

  const ChatBubble({
    super.key,
    required this.note,
    required this.amount,
    required this.category,
    required this.date,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    // Left = Incoming. Right = Outgoing OR Invested.
    final bool isLeftAligned = type == TransactionType.incoming;
    final bool isInvested = type == TransactionType.invested;

    // Theme Logic
    Color bubbleBg;
    Color accentColor;
    Color? borderColor;
    IconData categoryIcon;

    switch (type) {
      case TransactionType.incoming:
        bubbleBg = AppTheme.primaryGreen.withValues(alpha: 0.1);
        accentColor = AppTheme.primaryGreen;
        categoryIcon = Icons.arrow_downward_rounded;
        borderColor = null;
        break;
      case TransactionType.outgoing:
        bubbleBg = AppTheme.dangerRed.withValues(alpha: 0.08);
        accentColor = AppTheme.dangerRed;
        categoryIcon = Icons.arrow_upward_rounded;
        borderColor = null;
        break;
      case TransactionType.invested:
        bubbleBg = AppTheme.accentPurple.withValues(alpha: 0.05);
        accentColor = AppTheme.accentPurple;
        categoryIcon = Icons.auto_graph_rounded;
        borderColor = AppTheme.accentPurple.withValues(alpha: 0.3);
        break;
    }

    return Align(
      alignment: isLeftAligned ? Alignment.centerLeft : Alignment.centerRight,
      child: Padding(
        // Add vertical padding here so bubbles don't bunch up
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: CustomPaint(
          painter: ModernBubblePainter(
            color: bubbleBg,
            borderColor: borderColor,
            isLeftAligned: isLeftAligned,
          ),
          child: Container(
            constraints: BoxConstraints(
              // Limit width to 75% of screen for readability
              maxWidth: MediaQuery.of(context).size.width * 0.75,
              minWidth: 120,
            ),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (note.isNotEmpty) ...[
                  _BubbleNote(note: note),
                  const SizedBox(height: 8),
                ],
                _BubbleAmount(amount: amount, type: type, color: accentColor),
                const SizedBox(height: 12),
                _BubbleFooter(
                  category: category,
                  date: date,
                  accentColor: accentColor,
                  icon: categoryIcon,
                  isInvested: isInvested,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Sub-Widgets for cleaner code ---

class _BubbleNote extends StatelessWidget {
  final String note;

  const _BubbleNote({required this.note});

  @override
  Widget build(BuildContext context) {
    return Text(
      note,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
    );
  }
}

class _BubbleAmount extends StatelessWidget {
  final double amount;
  final TransactionType type;
  final Color color;

  const _BubbleAmount({
    required this.amount,
    required this.type,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final symbol = type == TransactionType.incoming
        ? '+'
        : type == TransactionType.outgoing
        ? '-'
        : '';
    return Text(
      "$symbol₹${amount.toStringAsFixed(0)}",
      style: TextStyle(
        color: color,
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.0,
      ),
    );
  }
}

class _BubbleFooter extends StatelessWidget {
  final String category;
  final DateTime date;
  final Color accentColor;
  final IconData icon;
  final bool isInvested;

  const _BubbleFooter({
    required this.category,
    required this.date,
    required this.accentColor,
    required this.icon,
    required this.isInvested,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isInvested
                ? accentColor.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 10, color: accentColor),
              const SizedBox(width: 4),
              Text(
                category.toUpperCase(),
                style: TextStyle(
                  color: accentColor.withValues(alpha: 1.0),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Text(
          DateFormat('h:mm a').format(date).toLowerCase(),
          style: TextStyle(
            color: AppTheme.textSecondary.withValues(alpha: 0.8),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// Keep your ModernBubblePainter class here (omitted for brevity, use previous code)
class ModernBubblePainter extends CustomPainter {
  final Color color;
  final Color? borderColor;
  final bool isLeftAligned;

  ModernBubblePainter({
    required this.color,
    this.borderColor,
    required this.isLeftAligned,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    const double radius = 22.0;
    const double sharpRadius = 2.0;

    if (isLeftAligned) {
      path.moveTo(sharpRadius, 0);
      path.lineTo(size.width - radius, 0);
      path.quadraticBezierTo(size.width, 0, size.width, radius);
      path.lineTo(size.width, size.height - radius);
      path.quadraticBezierTo(
        size.width,
        size.height,
        size.width - radius,
        size.height,
      );
      path.lineTo(radius, size.height);
      path.quadraticBezierTo(0, size.height, 0, size.height - radius);
      path.lineTo(0, sharpRadius);
      path.quadraticBezierTo(0, 0, sharpRadius, 0);
    } else {
      path.moveTo(radius, 0);
      path.lineTo(size.width - sharpRadius, 0);
      path.quadraticBezierTo(size.width, 0, size.width, sharpRadius);
      path.lineTo(size.width, size.height - radius);
      path.quadraticBezierTo(
        size.width,
        size.height,
        size.width - radius,
        size.height,
      );
      path.lineTo(radius, size.height);
      path.quadraticBezierTo(0, size.height, 0, size.height - radius);
      path.lineTo(0, radius);
      path.quadraticBezierTo(0, 0, radius, 0);
    }
    path.close();
    canvas.drawPath(path, paint);

    if (borderColor != null) {
      final borderPaint = Paint()
        ..color = borderColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

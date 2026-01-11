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
    // -------------------------------------------------------------------------
    // 1. CONFIGURATION
    // -------------------------------------------------------------------------

    // LEFT = Incoming. RIGHT = Outgoing OR Invested.
    final bool isLeftAligned = type == TransactionType.incoming;
    final bool isInvested = type == TransactionType.invested;

    Color bubbleBg;
    Color accentColor;
    Color? borderColor; // Null for standard bubbles, colored for Investment
    IconData categoryIcon;

    switch (type) {
      case TransactionType.incoming:
        // Income: Clean Green, No Border
        bubbleBg = AppTheme.primaryGreen.withValues(alpha: 0.1);
        accentColor = AppTheme.primaryGreen;
        categoryIcon = Icons.arrow_downward_rounded;
        borderColor = null;
        break;

      case TransactionType.outgoing:
        // Expense: Soft Red, No Border (implies "money gone")
        bubbleBg = AppTheme.dangerRed.withValues(alpha: 0.08);
        accentColor = AppTheme.dangerRed;
        categoryIcon = Icons.arrow_upward_rounded;
        borderColor = null;
        break;

      case TransactionType.invested:
        // Investment: Premium Purple, WITH BORDER (implies "money secured/kept")
        bubbleBg = AppTheme.accentPurple.withValues(alpha: 0.05);
        accentColor = AppTheme.accentPurple;
        categoryIcon = Icons.auto_graph_rounded; // Specific "Growth" icon
        borderColor = AppTheme.accentPurple.withValues(alpha: 0.3);
        break;
    }

    return Align(
      alignment: isLeftAligned ? Alignment.centerLeft : Alignment.centerRight,
      child: CustomPaint(
        painter: ModernBubblePainter(
          color: bubbleBg,
          borderColor: borderColor, // Pass border config to painter
          isLeftAligned: isLeftAligned,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
            minWidth: 140,
          ),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // NOTE
              if (note.isNotEmpty) ...[
                Text(
                  note,
                  style: const TextStyle(
                    color: AppTheme.textPrimary, // Use Theme text color
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // AMOUNT
              Text(
                "${type == TransactionType.incoming
                    ? '+'
                    : type == TransactionType.outgoing
                    ? '-'
                    : ''}₹${amount.toStringAsFixed(0)}",
                style: TextStyle(
                  color: accentColor,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.0,
                ),
              ),

              const SizedBox(height: 12),

              // FOOTER (Category + Time)
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      // Invested gets a slightly darker badge background to pop
                      color: isInvested
                          ? accentColor.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(categoryIcon, size: 10, color: accentColor),
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

                  // Time
                  Text(
                    DateFormat('h:mm a').format(date).toLowerCase(),
                    style: TextStyle(
                      color: AppTheme.textSecondary.withValues(alpha: 0.8),
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
    );
  }
}

// -----------------------------------------------------------------------------
// PAINTER UPDATED FOR BORDER SUPPORT
// -----------------------------------------------------------------------------
class ModernBubblePainter extends CustomPainter {
  final Color color;
  final Color? borderColor; // New property
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

    // We define the path once so we can use it for both Fill and Stroke
    final path = Path();
    const double radius = 22.0;
    const double sharpRadius = 2.0;

    if (isLeftAligned) {
      // INCOMING (Left)
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
      // OUTGOING (Right)
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

    // 1. Draw Fill
    canvas.drawPath(path, paint);

    // 2. Draw Border (If provided) - Only for Investment
    if (borderColor != null) {
      final borderPaint = Paint()
        ..color = borderColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5; // Thin, precise border

      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/data/expense/expense.dart';
import '../theme/chat_theme.dart';

/// Chat bubble widget with custom shape and glass effect.
/// Uses ChatTheme colors for consistent theming.
class ChatBubble extends StatelessWidget {
  final String note;
  final double amount;
  final String category;
  final DateTime date;
  final TransactionType type;
  final ChatTheme theme;
  final String currency;

  const ChatBubble({
    super.key,
    required this.note,
    required this.amount,
    required this.category,
    required this.date,
    required this.type,
    required this.theme,
    this.currency = '₹',
  });

  @override
  Widget build(BuildContext context) {
    final bool isLeftAligned = type == TransactionType.incoming;

    // Get colors based on type from theme
    Color bubbleBg;
    Color accentColor;
    Color borderColor;
    IconData categoryIcon;

    switch (type) {
      case TransactionType.incoming:
        bubbleBg = theme.incomingBg;
        accentColor = theme.incomingAccent;
        borderColor = theme.incomingBorder;
        categoryIcon = Icons.arrow_downward_rounded;
        break;
      case TransactionType.outgoing:
        bubbleBg = theme.outgoingBg;
        accentColor = theme.outgoingAccent;
        borderColor = theme.outgoingBorder;
        categoryIcon = Icons.arrow_upward_rounded;
        break;
      case TransactionType.invested:
        bubbleBg = theme.investedBg;
        accentColor = theme.investedAccent;
        borderColor = theme.investedBorder;
        categoryIcon = Icons.auto_graph_rounded;
        break;
    }

    return Align(
      alignment: isLeftAligned ? Alignment.centerLeft : Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipPath(
            clipper: _BubbleClipper(isLeftAligned: isLeftAligned),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: CustomPaint(
                painter: _ModernBubblePainter(
                  color: bubbleBg,
                  borderColor: borderColor,
                  isLeftAligned: isLeftAligned,
                ),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                    minWidth: 120,
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (note.isNotEmpty) ...[
                        _BubbleNote(note: note, theme: theme),
                        const SizedBox(height: 6),
                      ],
                      _BubbleAmount(
                        amount: amount,
                        type: type,
                        color: accentColor,
                        currency: currency,
                      ),
                      const SizedBox(height: 10),
                      _BubbleFooter(
                        category: category,
                        date: date,
                        accentColor: accentColor,
                        icon: categoryIcon,
                        theme: theme,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom clipper for bubble shape with sharp corner
class _BubbleClipper extends CustomClipper<Path> {
  final bool isLeftAligned;

  _BubbleClipper({required this.isLeftAligned});

  @override
  Path getClip(Size size) {
    final path = Path();
    const double radius = 20.0;
    const double sharpRadius = 4.0;

    if (isLeftAligned) {
      // Left aligned: sharp top-left corner
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
      // Right aligned: sharp top-right corner
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
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Custom painter for bubble with border
class _ModernBubblePainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final bool isLeftAligned;

  _ModernBubblePainter({
    required this.color,
    required this.borderColor,
    required this.isLeftAligned,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    const double radius = 20.0;
    const double sharpRadius = 4.0;

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

    // Draw border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- Sub-Widgets ---

class _BubbleNote extends StatelessWidget {
  final String note;
  final ChatTheme theme;

  const _BubbleNote({required this.note, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(
      note,
      style: TextStyle(
        color: theme.primaryText,
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
  final String currency;

  const _BubbleAmount({
    required this.amount,
    required this.type,
    required this.color,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final symbol = type == TransactionType.incoming
        ? '+'
        : type == TransactionType.outgoing
        ? '-'
        : '';
    return Text(
      "$symbol$currency${amount.toStringAsFixed(0)}",
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
  final ChatTheme theme;

  const _BubbleFooter({
    required this.category,
    required this.date,
    required this.accentColor,
    required this.icon,
    required this.theme,
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
            color: accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 10, color: accentColor),
              const SizedBox(width: 4),
              Text(
                category.toUpperCase(),
                style: TextStyle(
                  color: accentColor,
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
            color: theme.secondaryText,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

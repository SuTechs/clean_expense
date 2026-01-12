import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../theme.dart';

class HighlightCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final String currency;
  final IconData icon;
  final bool fullWidth;

  const HighlightCard({
    super.key,
    required this.title,
    required this.amount,
    required this.color,
    required this.currency,
    required this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fullWidth
            ? color.withValues(alpha: 0.1)
            : AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: fullWidth
            ? Border.all(color: color.withValues(alpha: 0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              if (fullWidth)
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 1.0,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (!fullWidth)
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          if (!fullWidth) const SizedBox(height: 4),
          Text(
            "$currency${NumberFormat.currency(symbol: '', decimalDigits: 0).format(amount)}",
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryNavy,
            ),
          ),
        ],
      ),
    );
  }
}

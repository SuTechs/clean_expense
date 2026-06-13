import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/data/expense/expense.dart';
import '../../../data/utils/category_style.dart';
import '../theme/chat_theme.dart';
import 'glass.dart';

/// Chat bubble for a transaction. Glass surface (degrades on low-end), a
/// per-category icon chip, tabular-figure amount, and a thin accent bar on
/// the tail edge. Noteless transactions render as a compact single row.
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
    final isLeftAligned = type == TransactionType.incoming;
    final accent = _accentColor();
    final bg = _bubbleBg();
    final border = _borderColor();
    final icon = CategoryStyle.iconFor(category);
    final compact = note.isEmpty;

    // Accent bar sits on the tail side: left for incoming, right for the rest.
    final radius = BorderRadius.only(
      topLeft: Radius.circular(isLeftAligned ? 5 : 20),
      topRight: Radius.circular(isLeftAligned ? 20 : 5),
      bottomLeft: const Radius.circular(20),
      bottomRight: const Radius.circular(20),
    );

    return Align(
      alignment: isLeftAligned ? Alignment.centerLeft : Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        child: Glass(
          color: bg,
          borderRadius: radius,
          border: Border.all(color: border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.76,
              minWidth: compact ? 0 : 130,
            ),
            child: IntrinsicHeight(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tail-side accent bar for left-aligned (incoming) bubbles.
                  if (isLeftAligned) _AccentBar(color: accent),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 11),
                      child: compact
                          ? _CompactRow(
                              icon: icon,
                              amount: amount,
                              type: type,
                              accent: accent,
                              category: category,
                              currency: currency,
                              theme: theme,
                            )
                          : _FullBody(
                              icon: icon,
                              note: note,
                              amount: amount,
                              type: type,
                              accent: accent,
                              category: category,
                              date: date,
                              currency: currency,
                              theme: theme,
                            ),
                    ),
                  ),
                  if (!isLeftAligned) _AccentBar(color: accent),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _accentColor() => switch (type) {
    TransactionType.incoming => theme.incomingAccent,
    TransactionType.outgoing => theme.outgoingAccent,
    TransactionType.invested => theme.investedAccent,
  };

  Color _bubbleBg() => switch (type) {
    TransactionType.incoming => theme.incomingBg,
    TransactionType.outgoing => theme.outgoingBg,
    TransactionType.invested => theme.investedBg,
  };

  Color _borderColor() => switch (type) {
    TransactionType.incoming => theme.incomingBorder,
    TransactionType.outgoing => theme.outgoingBorder,
    TransactionType.invested => theme.investedBorder,
  };
}

class _AccentBar extends StatelessWidget {
  final Color color;
  const _AccentBar({required this.color});

  @override
  Widget build(BuildContext context) =>
      Container(width: 3, color: color.withValues(alpha: 0.9));
}

/// Square tinted icon chip identifying the category at a glance.
class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final double size;
  const _CategoryChip({
    required this.icon,
    required this.accent,
    this.size = 30,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(size * 0.33),
      ),
      child: Icon(icon, size: size * 0.55, color: accent),
    );
  }
}

class _AmountText extends StatelessWidget {
  final double amount;
  final TransactionType type;
  final Color color;
  final String currency;
  final double fontSize;
  const _AmountText({
    required this.amount,
    required this.type,
    required this.color,
    required this.currency,
    this.fontSize = 25,
  });

  @override
  Widget build(BuildContext context) {
    final sign = switch (type) {
      TransactionType.incoming => '+',
      TransactionType.outgoing => '-',
      TransactionType.invested => '',
    };
    return Text(
      "$sign$currency${amount.toStringAsFixed(0)}",
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.0,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String category;
  final Color accent;
  const _CategoryPill({required this.category, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "#${category.toLowerCase()}",
        style: TextStyle(
          color: accent,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _CompactRow extends StatelessWidget {
  final IconData icon;
  final double amount;
  final TransactionType type;
  final Color accent;
  final String category;
  final String currency;
  final ChatTheme theme;
  const _CompactRow({
    required this.icon,
    required this.amount,
    required this.type,
    required this.accent,
    required this.category,
    required this.currency,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CategoryChip(icon: icon, accent: accent, size: 28),
        const SizedBox(width: 10),
        _AmountText(
          amount: amount,
          type: type,
          color: accent,
          currency: currency,
          fontSize: 20,
        ),
        const SizedBox(width: 10),
        _CategoryPill(category: category, accent: accent),
      ],
    );
  }
}

class _FullBody extends StatelessWidget {
  final IconData icon;
  final String note;
  final double amount;
  final TransactionType type;
  final Color accent;
  final String category;
  final DateTime date;
  final String currency;
  final ChatTheme theme;
  const _FullBody({
    required this.icon,
    required this.note,
    required this.amount,
    required this.type,
    required this.accent,
    required this.category,
    required this.date,
    required this.currency,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CategoryChip(icon: icon, accent: accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note,
                    style: TextStyle(
                      color: theme.primaryText,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _AmountText(
                    amount: amount,
                    type: type,
                    color: accent,
                    currency: currency,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _CategoryPill(category: category, accent: accent),
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
        ),
      ],
    );
  }
}

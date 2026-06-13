import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../data/bloc/app_bloc.dart';
import '../../../data/bloc/expense_bloc.dart';
import '../../../data/bloc/insight_bloc.dart';
import '../../../data/data/expense/expense.dart';
import '../../../data/data/insight/insight.dart';
import '../state/chat_interaction_provider.dart';
import '../theme/chat_theme.dart';
import '../theme/chat_theme_provider.dart';
import 'chat_bubble.dart';
import 'date_header.dart';
import 'insight_bubble.dart';

/// One row in the chat thread: a transaction or an app-authored insight.
class _ChatItem {
  final DateTime date;
  final ExpenseData? expense;
  final InsightData? insight;
  _ChatItem.expense(this.expense) : date = expense!.date, insight = null;
  _ChatItem.insight(this.insight) : date = insight!.date, expense = null;
  bool get isInsight => insight != null;
}

/// Per-day rollup shown in the date divider (expenses only).
class _DaySummary {
  double net = 0;
  int count = 0;
}

/// A sliver list that interleaves transactions and "your money" insights,
/// grouped by day with summary dividers.
class TransactionList extends StatelessWidget {
  const TransactionList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ChatThemeProvider>().theme;
    final currency = context.watch<AppBloc>().currency;
    final expenseBloc = context.watch<ExpenseBloc>();
    final insightBloc = context.watch<InsightBloc>();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final expenses = expenseBloc.expenses
        .where((e) => e.date.isBefore(today) || _isSameDay(e.date, now))
        .toList();

    if (expenses.isEmpty && insightBloc.feed.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _EmptyState(theme: theme),
      );
    }

    // Per-day rollup from expenses (insights don't count toward spend).
    final summaries = <String, _DaySummary>{};
    for (final e in expenses) {
      final s = summaries.putIfAbsent(_dayKey(e.date), () => _DaySummary());
      s.net += e.type == TransactionType.incoming ? e.amount : -e.amount;
      s.count++;
    }

    final items = <_ChatItem>[
      ...expenses.map(_ChatItem.expense),
      ...insightBloc.feed.map(_ChatItem.insight),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 120, top: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = items[index];
          final isLast = index == items.length - 1;
          // Header sits at a day boundary (next item is older / a new day),
          // matching the reversed scroll so it caps the day's group.
          final showHeader =
              isLast || !_isSameDay(item.date, items[index + 1].date);
          final summary = summaries[_dayKey(item.date)];

          return _AnimatedTransactionItem(
            index: index,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showHeader)
                  DateHeader(
                    date: item.date,
                    theme: theme,
                    net: summary?.net ?? 0,
                    count: summary?.count ?? 0,
                    currency: currency,
                  ),
                if (item.isInsight)
                  InsightBubble(insight: item.insight!, theme: theme)
                else
                  _TransactionBubble(
                    expense: item.expense!,
                    theme: theme,
                    currency: currency,
                  ),
              ],
            ),
          );
        }, childCount: items.length),
      ),
    );
  }

  static String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Animated wrapper for thread items with staggered entrance.
class _AnimatedTransactionItem extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedTransactionItem({required this.index, required this.child});

  @override
  State<_AnimatedTransactionItem> createState() =>
      _AnimatedTransactionItemState();
}

class _AnimatedTransactionItemState extends State<_AnimatedTransactionItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    final delay = Duration(milliseconds: (widget.index.clamp(0, 5) * 50));
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(opacity: _fadeAnimation, child: widget.child),
    );
  }
}

/// Transaction bubble wrapper with tap/long-press interactions.
class _TransactionBubble extends StatefulWidget {
  final ExpenseData expense;
  final ChatTheme theme;
  final String currency;

  const _TransactionBubble({
    required this.expense,
    required this.theme,
    required this.currency,
  });

  @override
  State<_TransactionBubble> createState() => _TransactionBubbleState();
}

class _TransactionBubbleState extends State<_TransactionBubble> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final interaction = context.watch<ChatInteractionProvider>();
    final highlighted = interaction.isHighlighted(widget.expense.id);

    return GestureDetector(
      onTapDown: (_) => _onTapDown(),
      onTapUp: (_) => _onTapUp(),
      onTapCancel: _onTapUp,
      onTap: interaction.hasSelection
          ? () => interaction.toggle(widget.expense)
          : null,
      onLongPress: _onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: highlighted
            ? _accentColor().withValues(alpha: 0.12)
            : Colors.transparent,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: ChatBubble(
            note: widget.expense.note,
            amount: widget.expense.amount,
            category: widget.expense.category,
            date: widget.expense.date,
            type: widget.expense.type,
            theme: widget.theme,
            currency: widget.currency,
          ),
        ),
      ),
    );
  }

  Color _accentColor() {
    switch (widget.expense.type) {
      case TransactionType.outgoing:
        return widget.theme.outgoingAccent;
      case TransactionType.incoming:
        return widget.theme.incomingAccent;
      case TransactionType.invested:
        return widget.theme.investedAccent;
    }
  }

  void _onTapDown() => setState(() => _scale = 0.98);
  void _onTapUp() => setState(() => _scale = 1.0);

  void _onLongPress() {
    final interaction = context.read<ChatInteractionProvider>();
    if (interaction.isEditing) return;

    HapticFeedback.mediumImpact();
    setState(() => _scale = 1.0);
    interaction.select(widget.expense);
  }
}

/// Empty state when no transactions exist.
class _EmptyState extends StatelessWidget {
  final ChatTheme theme;

  const _EmptyState({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 64,
            color: theme.secondaryText.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 16,
              color: theme.secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first expense below',
            style: TextStyle(
              fontSize: 14,
              color: theme.secondaryText.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

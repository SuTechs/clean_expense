import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../data/bloc/app_bloc.dart';
import '../../../data/bloc/expense_bloc.dart';
import '../../../data/data/expense/expense.dart';
import '../theme/chat_theme.dart';
import '../theme/chat_theme_provider.dart';
import 'chat_bubble.dart';
import 'date_header.dart';

/// A sliver list that displays transactions with staggered animations.
class TransactionList extends StatelessWidget {
  const TransactionList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ChatThemeProvider>().theme;

    return Consumer<ExpenseBloc>(
      builder: (context, bloc, child) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day, 23, 59, 59);

        // Filter out future dated expenses and sort by date descending
        final expenses =
            bloc.expenses
                .where((e) => e.date.isBefore(today) || _isSameDay(e.date, now))
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));

        if (expenses.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyState(theme: theme),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.only(bottom: 120, top: 8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final expense = expenses[index];
              final isLastItem = index == expenses.length - 1;

              bool showDateHeader = false;
              if (isLastItem) {
                showDateHeader = true;
              } else {
                final nextExpense = expenses[index + 1];
                if (!_isSameDay(expense.date, nextExpense.date)) {
                  showDateHeader = true;
                }
              }

              return _AnimatedTransactionItem(
                index: index,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showDateHeader)
                      DateHeader(date: expense.date, theme: theme),
                    _TransactionBubble(
                      expense: expense,
                      theme: theme,
                      currency: context.watch<AppBloc>().currency,
                    ),
                  ],
                ),
              );
            }, childCount: expenses.length),
          ),
        );
      },
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}

/// Animated wrapper for transaction items with staggered entrance.
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
    return GestureDetector(
      onTapDown: (_) => _onTapDown(),
      onTapUp: (_) => _onTapUp(),
      onTapCancel: _onTapUp,
      onLongPress: _onLongPress,
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
    );
  }

  void _onTapDown() => setState(() => _scale = 0.98);
  void _onTapUp() => setState(() => _scale = 1.0);

  void _onLongPress() {
    HapticFeedback.mediumImpact();
    setState(() => _scale = 1.0);
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

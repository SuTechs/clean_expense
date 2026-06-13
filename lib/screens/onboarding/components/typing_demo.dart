import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/bloc/app_bloc.dart';
import '../../../data/data/expense/expense.dart';
import '../../chat/components/chat_bubble.dart';
import '../../chat/theme/chat_theme.dart';

/// Looping demo that types "dinner #food 500" into a mock input pill and
/// then pops in a real [ChatBubble] — so the demo always matches the product.
class TypingDemo extends StatefulWidget {
  const TypingDemo({super.key});

  @override
  State<TypingDemo> createState() => _TypingDemoState();
}

/// One example the demo can type out and turn into a bubble.
class _DemoEntry {
  final String input;
  final String note;
  final String category;
  final double amount;
  final TransactionType type;

  const _DemoEntry(
    this.input,
    this.note,
    this.category,
    this.amount,
    this.type,
  );
}

class _TypingDemoState extends State<TypingDemo> {
  static const _theme = ChatThemes.ocean;

  // Cycled every loop so the demo shows the format works in any order and
  // for every transaction type.
  static const _entries = [
    _DemoEntry(
      'dinner #food 500',
      'dinner',
      'food',
      500,
      TransactionType.outgoing,
    ),
    _DemoEntry(
      'got salary #salary 50000',
      'got salary',
      'salary',
      50000,
      TransactionType.incoming,
    ),
    _DemoEntry(
      '2 coffees #coffee 240',
      '2 coffees',
      'coffee',
      240,
      TransactionType.outgoing,
    ),
    _DemoEntry(
      '#sip 5000 monthly',
      'monthly',
      'sip',
      5000,
      TransactionType.invested,
    ),
    _DemoEntry(
      'uber to office #travel 250',
      'uber to office',
      'travel',
      250,
      TransactionType.outgoing,
    ),
  ];

  Timer? _timer;
  int _entryIndex = 0;
  int _charCount = 0;
  bool _showBubble = false;
  int _pauseTicks = 0;

  _DemoEntry get _entry => _entries[_entryIndex];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 120), _tick);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick(Timer timer) {
    if (!mounted) return;

    if (_charCount < _entry.input.length) {
      setState(() => _charCount++);
    } else if (!_showBubble) {
      setState(() => _showBubble = true);
      _pauseTicks = 18; // hold the result for ~2s before looping
    } else if (_pauseTicks > 0) {
      _pauseTicks--;
    } else {
      setState(() {
        _entryIndex = (_entryIndex + 1) % _entries.length;
        _charCount = 0;
        _showBubble = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<AppBloc>().currency;
    final typed = _entry.input.substring(0, _charCount);

    return SizedBox(
      width: 300,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Resulting chat bubble (fixed-height slot so the layout is stable)
          SizedBox(
            height: 148,
            child: AnimatedScale(
              scale: _showBubble ? 1.0 : 0.6,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              child: AnimatedOpacity(
                opacity: _showBubble ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: ChatBubble(
                  note: _entry.note,
                  amount: _entry.amount,
                  category: _entry.category,
                  date: DateTime.now(),
                  type: _entry.type,
                  theme: _theme,
                  currency: currency,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Mock input pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _theme.inputContainerBg,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _theme.inputFieldBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            typed,
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            style: TextStyle(
                              fontSize: 15,
                              color: _theme.primaryText,
                            ),
                          ),
                        ),
                        // Blinking cursor while typing
                        AnimatedOpacity(
                          opacity: !_showBubble && _charCount.isEven
                              ? 1.0
                              : 0.0,
                          duration: const Duration(milliseconds: 100),
                          child: Container(
                            width: 2,
                            height: 18,
                            color: _theme.outgoingAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _theme.outgoingAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_upward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/data/expense/expense.dart';
import '../../chat/theme/chat_theme.dart';

/// Static replica of the chat input's type-selector row with the highlight
/// cycling through Expense → Income → Invest.
class TypeSelectorDemo extends StatefulWidget {
  const TypeSelectorDemo({super.key});

  @override
  State<TypeSelectorDemo> createState() => _TypeSelectorDemoState();
}

class _TypeSelectorDemoState extends State<TypeSelectorDemo> {
  static const _theme = ChatThemes.ocean;

  static const _options = [
    (TransactionType.outgoing, "Expense", Icons.arrow_upward_rounded),
    (TransactionType.incoming, "Income", Icons.arrow_downward_rounded),
    (TransactionType.invested, "Invest", Icons.trending_up_rounded),
  ];

  Timer? _timer;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      if (mounted) {
        setState(() => _selectedIndex = (_selectedIndex + 1) % _options.length);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color _color(TransactionType type) {
    switch (type) {
      case TransactionType.outgoing:
        return _theme.outgoingAccent;
      case TransactionType.incoming:
        return _theme.incomingAccent;
      case TransactionType.invested:
        return _theme.investedAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _options[_selectedIndex];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The trigger icon as it appears next to the text field
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _color(selected.$1).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _color(selected.$1)),
          ),
          child: Icon(selected.$3, color: _color(selected.$1), size: 28),
        ),
        const SizedBox(height: 24),

        // The three options row (FittedBox guards narrow screens)
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _theme.inputFieldBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_options.length, (i) {
                final (type, label, icon) = _options[i];
                final isSelected = i == _selectedIndex;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _theme.inputContainerBg
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _theme.patternColor,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      Icon(icon, size: 16, color: _color(type)),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          color: isSelected
                              ? _theme.primaryText
                              : _theme.secondaryText,
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

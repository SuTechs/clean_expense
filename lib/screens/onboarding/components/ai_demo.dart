import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../data/bloc/app_bloc.dart';
import '../../../theme.dart';

/// Looping preview of the AI assistant for onboarding: a question appears,
/// the assistant "types", then answers — cycling through several examples.
class AiDemo extends StatefulWidget {
  const AiDemo({super.key});

  @override
  State<AiDemo> createState() => _AiDemoState();
}

enum _Phase { question, typing, answer }

/// One question/answer example. `{c}` in the answer is replaced with the
/// user's currency symbol. [bars] draws an optional mini chart.
class _AiDemoEntry {
  final String question;
  final String answer;
  final List<(String, double)> bars;

  const _AiDemoEntry(this.question, this.answer, [this.bars = const []]);
}

class _AiDemoState extends State<AiDemo> {
  static const _entries = [
    _AiDemoEntry(
      "Where am I spending most? 🤔",
      "Food is your top category, 42% of this month's spending.",
      [("food", 1.0), ("travel", 0.55), ("bills", 0.35)],
    ),
    _AiDemoEntry(
      "My biggest expense this month?",
      "Rent: {c}12,000 on the 1st. That's 28% of the month.",
    ),
    _AiDemoEntry(
      "How's my savings rate? 💰",
      "You saved 31% of your income this year. Nice!",
      [("income", 1.0), ("spent", 0.69)],
    ),
    _AiDemoEntry(
      "What did I spend this week?",
      "{c}3,240 this week, 12% less than last week 📉",
      [("last wk", 1.0), ("this wk", 0.88)],
    ),
  ];

  Timer? _timer;
  _Phase _phase = _Phase.question;
  int _entryIndex = 0;

  _AiDemoEntry get _entry => _entries[_entryIndex];

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  void _schedule() {
    final delay = switch (_phase) {
      _Phase.question => const Duration(milliseconds: 900),
      _Phase.typing => const Duration(milliseconds: 1100),
      _Phase.answer => const Duration(milliseconds: 2800),
    };
    _timer = Timer(delay, () {
      if (!mounted) return;
      setState(() {
        if (_phase == _Phase.answer) {
          // Next example starts with its own question.
          _entryIndex = (_entryIndex + 1) % _entries.length;
          _phase = _Phase.question;
        } else {
          _phase = _Phase.values[_phase.index + 1];
        }
      });
      _schedule();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<AppBloc>().currency;
    final answerText = _entry.answer.replaceAll('{c}', currency);

    return SizedBox(
      width: 300,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // User question bubble
          Align(
            alignment: Alignment.centerRight,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Container(
                key: ValueKey('q$_entryIndex'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryNavy,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(
                  _entry.question,
                  style: GoogleFonts.outfit(fontSize: 14, color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Assistant reply slot (fixed height so the page doesn't jump)
          SizedBox(
            height: 150,
            child: Align(
              alignment: Alignment.topLeft,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _phase == _Phase.question
                    ? const SizedBox.shrink()
                    : _phase == _Phase.typing
                    ? _bubble(
                        key: const ValueKey('typing'),
                        child: Text(
                          "✨ thinking…",
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      )
                    : _bubble(
                        key: ValueKey('answer$_entryIndex'),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              answerText,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                height: 1.35,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            if (_entry.bars.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              for (final (label, fraction) in _entry.bars)
                                _bar(label, fraction),
                            ],
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble({required Key key, required Widget child}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border.all(
          color: AppTheme.accentPurple.withValues(alpha: 0.25),
        ),
      ),
      child: child,
    );
  }

  Widget _bar(String label, double fraction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            height: 8,
            width: 136 * fraction,
            decoration: BoxDecoration(
              color: AppTheme.accentPurple.withValues(
                alpha: 0.35 + 0.65 * fraction,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

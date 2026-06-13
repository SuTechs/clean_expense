import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/bloc/app_bloc.dart';
import '../../../data/bloc/expense_bloc.dart';
import '../../../data/data/expense/expense.dart';
import '../theme/chat_theme.dart';
import '../theme/chat_theme_provider.dart';
import 'chat_settings_sheet.dart';
import 'glass.dart';

/// Chat app bar showing the user's live financial pulse — today's net plus a
/// 7-day sparkline — instead of a static "Active now". Tapping opens settings.
class GlassAppBar extends StatelessWidget {
  final ChatThemeProvider themeProvider;

  const GlassAppBar({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    final theme = themeProvider.theme;
    final bloc = context.watch<ExpenseBloc>();
    final currency = context.watch<AppBloc>().currency;

    final daily = _dailyNet(bloc.expenses, 7);
    final todayNet = daily.isNotEmpty ? daily.last : 0.0;

    final sign = todayNet > 0
        ? '+'
        : todayNet < 0
        ? '−'
        : '';
    final todayText = todayNet == 0
        ? 'No spending today'
        : '$sign$currency${todayNet.abs().toStringAsFixed(0)} today';
    final todayColor = todayNet >= 0 ? theme.statusDot : theme.outgoingAccent;

    return Glass(
      color: theme.appBarBg,
      borderRadius: BorderRadius.zero,
      border: Border(
        bottom: BorderSide(
          color: theme.patternColor.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      sigma: 20,
      child: Container(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: _chip(theme, Icons.arrow_back_ios_new_rounded, 16),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => ChatSettingsSheet.show(context, themeProvider),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.statusDot.withValues(alpha: 0.25),
                        theme.statusDot.withValues(alpha: 0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.statusDot.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'logo-big.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.account_balance_wallet_rounded,
                        color: theme.statusDot,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => ChatSettingsSheet.show(context, themeProvider),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your money',
                        style: TextStyle(
                          color: theme.appBarText,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            todayText,
                            style: TextStyle(
                              color: todayColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (daily.any((v) => v != 0)) ...[
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 46,
                              height: 16,
                              child: CustomPaint(
                                painter: _SparklinePainter(
                                  values: daily,
                                  color: theme.statusDot,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: () =>
                    ChatSettingsSheet.show(context, themeProvider),
                icon: _chip(theme, Icons.tune_rounded, 18),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(ChatTheme theme, IconData icon, double size) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.patternColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: size, color: theme.appBarText),
    );
  }

  /// Net flow (incoming − outgoing − invested) for each of the last [days]
  /// days, oldest first.
  List<double> _dailyNet(List<ExpenseData> expenses, int days) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final buckets = List<double>.filled(days, 0);
    for (final e in expenses) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      final diff = today.difference(d).inDays;
      if (diff < 0 || diff >= days) continue;
      final idx = days - 1 - diff;
      buckets[idx] += e.type == TransactionType.incoming ? e.amount : -e.amount;
    }
    return buckets;
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _SparklinePainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 1e-6 ? 1.0 : (maxV - minV);

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - ((values[i] - minV) / range) * size.height;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values || old.color != color;
}

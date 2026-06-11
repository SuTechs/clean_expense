import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/bloc/app_bloc.dart';
import '../../../theme.dart';

/// Onboarding page for picking the currency symbol. Applies straight to
/// [AppBloc] (persisted), same as the Settings picker — skipping keeps the
/// locale default.
class CurrencyInputPage extends StatefulWidget {
  const CurrencyInputPage({super.key});

  @override
  State<CurrencyInputPage> createState() => _CurrencyInputPageState();
}

class _CurrencyInputPageState extends State<CurrencyInputPage> {
  static const _presets = ["₹", "\$", "€", "£", "¥", "₩", "₽"];

  final TextEditingController _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appBloc = context.watch<AppBloc>();
    final current = appBloc.currency;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                current,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "Pick your currency",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryNavy,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Choose a symbol or type your own — you can change it anytime "
              "in Settings.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (final symbol in _presets)
                  _symbolChip(
                    appBloc,
                    symbol,
                    selected: current == symbol,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 180,
              child: TextField(
                controller: _customController,
                textAlign: TextAlign.center,
                maxLength: 4,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: "Custom (e.g. CHF)",
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                  counterText: "",
                  filled: true,
                  fillColor: AppTheme.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryNavy,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  final trimmed = value.trim();
                  if (trimmed.isNotEmpty) appBloc.currency = trimmed;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _symbolChip(AppBloc appBloc, String symbol, {required bool selected}) {
    return GestureDetector(
      onTap: () {
        _customController.clear();
        FocusScope.of(context).unfocus();
        appBloc.currency = symbol;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryNavy : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.primaryNavy : AppTheme.dividerColor,
          ),
        ),
        child: Text(
          symbol,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}

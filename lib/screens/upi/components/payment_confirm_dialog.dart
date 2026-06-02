import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme.dart';

/// Fallback confirmation shown when the UPI app does not report a clear success
/// status (common with Google Pay, and always the case on iOS, which can't
/// return transaction data). Lets the user confirm whether the payment actually
/// went through so genuine payments aren't silently dropped.
///
/// Resolves to `true` if the user confirms they paid, `false`/`null` otherwise.
class PaymentConfirmDialog extends StatelessWidget {
  final double amount;

  const PaymentConfirmDialog({super.key, required this.amount});

  static Future<bool?> show(BuildContext context, {required double amount}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PaymentConfirmDialog(amount: amount),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.accentPurple.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.help_outline_rounded,
                color: AppTheme.accentPurple,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Did the payment go through?',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "We couldn't automatically confirm your ₹${amount.toStringAsFixed(2)} "
              'payment. Add it to your expenses only if it was completed.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppTheme.inputFill,
                      foregroundColor: AppTheme.textSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "No, didn't pay",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Yes, paid'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

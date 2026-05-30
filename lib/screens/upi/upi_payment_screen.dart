import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../data/command/commands.dart';
import '../../data/command/expense/expense_command.dart';
import '../../data/data/expense/expense.dart';
import '../../data/utils/upi_uri.dart';
import '../../theme.dart';
import 'components/upi_app_picker_sheet.dart';

/// Collects the amount, category and an optional note for a scanned UPI QR,
/// saves it as an outgoing expense, then hands off to an installed UPI app.
///
/// We deliberately do NOT persist payee details — only amount + category (plus
/// the existing note/date/type). The payee is used solely to launch the
/// external payment app.
class UpiPaymentScreen extends StatefulWidget {
  final UpiQrData qr;
  const UpiPaymentScreen({super.key, required this.qr});

  @override
  State<UpiPaymentScreen> createState() => _UpiPaymentScreenState();
}

class _UpiPaymentScreenState extends State<UpiPaymentScreen> {
  static const _uuid = Uuid();

  late final TextEditingController _amountController = TextEditingController(
    text: widget.qr.amount?.toStringAsFixed(2) ?? '',
  );
  final TextEditingController _noteController = TextEditingController();

  String? _category;
  bool _paying = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _error(String message) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.dangerRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handlePay() async {
    if (_paying) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _error('Please enter a valid amount.');
      return;
    }
    if (_category == null) {
      _error('Please pick a category.');
      return;
    }

    final note = _noteController.text.trim();
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _paying = true);

    final expense = ExpenseData(
      id: _uuid.v4(),
      amount: amount,
      category: _category!.toLowerCase(),
      date: DateTime.now(),
      type: TransactionType.outgoing,
      note: note,
    );

    try {
      // Save locally FIRST — we track the expense regardless of what happens
      // in the external payment app.
      await ExpenseCommand().addExpense(expense);
    } catch (e) {
      if (mounted) {
        setState(() => _paying = false);
        _error('Failed to save expense: $e');
      }
      return;
    }

    if (!mounted) return;

    // Hand off to an installed UPI app to complete the actual payment.
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => UpiAppPickerSheet(
        vpa: widget.qr.vpa,
        payeeName: widget.qr.name ?? widget.qr.vpa,
        amount: amount,
        transactionNote: note.isNotEmpty ? note : _category!,
      ),
    );

    if (!mounted) return;
    Navigator.of(context).pop(); // back to home; expense already saved
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Expense saved'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final suggestions =
        BaseAppCommand.blocExpense.getSuggestionsForType(
      TransactionType.outgoing,
    );

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(title: const Text('New Payment')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // Payee summary (shown for context, not stored).
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppTheme.inputFill,
                  child: Icon(Icons.store_rounded,
                      color: AppTheme.textSecondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.qr.name ?? 'Paying to',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryNavy,
                        ),
                      ),
                      Text(
                        widget.qr.vpa,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Amount.
          Text('Amount', style: _labelStyle),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            autofocus: widget.qr.amount == null,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              prefixText: '₹ ',
              prefixStyle: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              hintText: '0.00',
            ),
          ),
          const SizedBox(height: 24),

          // Category.
          Text('Category', style: _labelStyle),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((c) {
              final selected = _category == c;
              return ChoiceChip(
                label: Text(c),
                selected: selected,
                onSelected: (_) => setState(() => _category = c),
                showCheckmark: false,
                backgroundColor: AppTheme.inputFill,
                selectedColor: AppTheme.primaryNavy,
                labelStyle: TextStyle(
                  color: selected ? AppTheme.textWhite : AppTheme.tagText,
                  fontWeight: FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide.none,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Note (optional).
          Text('Note (optional)', style: _labelStyle),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'What is this for?'),
          ),
          const SizedBox(height: 32),

          // Pay.
          ElevatedButton.icon(
            onPressed: _paying ? null : _handlePay,
            icon: _paying
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.account_balance_wallet_rounded),
            label: Text(_paying ? 'Saving…' : 'Pay'),
          ),
        ],
      ),
    );
  }

  TextStyle get _labelStyle => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
      );
}

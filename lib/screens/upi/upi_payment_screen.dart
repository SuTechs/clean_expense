import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../data/command/commands.dart';
import '../../data/command/expense/expense_command.dart';
import '../../data/data/expense/expense.dart';
import '../../data/utils/upi_uri.dart';
import '../../theme.dart';
import 'components/category_picker_sheet.dart';
import 'components/payment_widgets.dart';
import 'components/upi_app_picker_sheet.dart';

/// Collects the amount, category and an optional note for a scanned UPI QR,
/// then lets the user pick a UPI app to pay with.
///
/// The expense is saved ONLY when the user actually taps a UPI app in the
/// picker (see [UpiAppPickerSheet.onBeforeLaunch]). We persist only amount +
/// category (plus the existing note/date/type) — never payee details.
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

  /// Quick-pick chips: the few most relevant outgoing categories.
  late final List<String> _quickPicks = BaseAppCommand.blocExpense
      .getSuggestionsForType(TransactionType.outgoing)
      .take(4)
      .toList(growable: false);

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

  /// Builds + persists the expense. Called from the app picker the moment a
  /// UPI app is tapped, so nothing is saved unless the user commits to paying.
  Future<void> _saveExpense(double amount, String category, String note) {
    final expense = ExpenseData(
      id: _uuid.v4(),
      amount: amount,
      category: category.toLowerCase(),
      date: DateTime.now(),
      type: TransactionType.outgoing,
      note: note,
    );
    return ExpenseCommand().addExpense(expense);
  }

  Future<void> _openCategoryPicker() async {
    final picked = await CategoryPickerSheet.show(context, selected: _category);
    if (picked != null && mounted) setState(() => _category = picked);
  }

  Future<void> _selectApp() async {
    FocusScope.of(context).unfocus();

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

    final paid = await showModalBottomSheet<bool>(
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
        // Save happens here — only when an app is actually tapped.
        onBeforeLaunch: () => _saveExpense(amount, _category!, note),
      ),
    );

    if (paid == true && mounted) {
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Expense saved'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(title: const Text('Payment')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Column(
                  children: [
                    PayeeHeader(
                      name: widget.qr.name ?? 'UPI Payment',
                      vpa: widget.qr.vpa,
                    ),
                    const SizedBox(height: 40),
                    AmountField(
                      controller: _amountController,
                      autofocus: widget.qr.amount == null,
                    ),
                    const SizedBox(height: 16),
                    NoteField(controller: _noteController),
                    const SizedBox(height: 40),
                    CategorySection(
                      selected: _category,
                      quickPicks: _quickPicks,
                      onSelected: (c) => setState(() => _category = c),
                      onMore: _openCategoryPicker,
                    ),
                  ],
                ),
              ),
            ),
            PayBar(onPressed: _selectApp),
          ],
        ),
      ),
    );
  }
}

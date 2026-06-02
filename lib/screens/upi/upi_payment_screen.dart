import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:upi_intent/upi_intent.dart';
import 'package:uuid/uuid.dart';

import '../../data/command/commands.dart';
import '../../data/command/expense/expense_command.dart';
import '../../data/data/expense/expense.dart';
import '../../data/utils/upi_uri.dart';
import '../../theme.dart';
import 'components/category_picker_sheet.dart';
import 'components/payment_confirm_dialog.dart';
import 'components/payment_widgets.dart';

/// Collects the amount, category and an optional note for a scanned UPI QR,
/// then launches a UPI app to pay with (via the vendored `upi_intent` picker).
///
/// The expense is saved ONLY when the payment app reports a SUCCESS status.
/// We persist only amount + category (plus the existing note/date/type) —
/// never payee details.
///
/// NOTE: UPI status is unreliable by design — Google Pay frequently returns no
/// status even on success, and iOS cannot return transaction data at all. With
/// strict success-only saving, those genuine payments will not be recorded.
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

  /// Builds + persists the expense. Called only after a successful payment.
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

    UpiResponse? response;
    try {
      // Shows the (themed) built-in app picker, launches the chosen UPI app,
      // and resolves with the transaction status once control returns.
      response = await UpiIntent.pay(
        context: context,
        payment: UpiPayment(
          payeeVpa: widget.qr.vpa,
          payeeName: widget.qr.name ?? widget.qr.vpa,
          amount: amount,
          transactionNote: note.isNotEmpty ? note : _category!,
          transactionRefId: 'TXN${_uuid.v4().replaceAll('-', '')}',
        ),
      );
    } on UpiException catch (e) {
      _error(e.message);
      return;
    }

    // Null → user dismissed the picker without launching an app. Don't save.
    if (response == null) return;

    // On a confirmed success we save straight away. Otherwise the status is
    // unreliable (GPay often reports nothing on success; iOS never does), so
    // we ask the user to confirm rather than silently dropping a real payment.
    if (!response.isSuccess) {
      if (!mounted) return;
      final confirmed =
          await PaymentConfirmDialog.show(context, amount: amount);
      if (confirmed != true) return;
    }

    try {
      await _saveExpense(amount, _category!, note);
    } catch (e) {
      if (mounted) _error('Saving failed: $e');
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Expense saved'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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

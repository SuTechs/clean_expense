import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../data/command/commands.dart';
import '../../data/command/expense/expense_command.dart';
import '../../data/data/expense/expense.dart';
import '../../data/utils/upi_uri.dart';
import '../../theme.dart';
import 'components/category_picker_sheet.dart';
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
                    _payeeHeader(),
                    const SizedBox(height: 40),
                    _amountField(),
                    const SizedBox(height: 16),
                    _noteChip(),
                    const SizedBox(height: 40),
                    _categorySection(),
                  ],
                ),
              ),
            ),
            _payBar(),
          ],
        ),
      ),
    );
  }

  // --- Payee (name + id) ------------------------------------------------------

  Widget _payeeHeader() {
    final name = widget.qr.name ?? 'UPI Payment';
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return Column(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: AppTheme.primaryNavy,
          child: Text(
            initial,
            style: const TextStyle(
              color: AppTheme.textWhite,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryNavy,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          widget.qr.vpa,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  // --- Amount (hero) ----------------------------------------------------------

  Widget _amountField() {
    return IntrinsicWidth(
      child: TextField(
        controller: _amountController,
        autofocus: widget.qr.amount == null,
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
        ],
        style: GoogleFonts.outfit(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
        decoration: InputDecoration(
          isCollapsed: true,
          filled: false,
          prefixText: '₹ ',
          prefixStyle: GoogleFonts.outfit(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
          hintText: '0',
          hintStyle: GoogleFonts.outfit(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondary.withValues(alpha: 0.4),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  // --- Note (compact chip) ----------------------------------------------------

  Widget _noteChip() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.inputFill,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.edit_note_rounded,
              size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Flexible(
            child: TextField(
              controller: _noteController,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                isCollapsed: true,
                filled: false,
                hintText: 'Add a note',
                hintStyle: TextStyle(color: AppTheme.textSecondary),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Category (quick picks + "more" sheet) ---------------------------------

  Widget _categorySection() {
    // Show the selected category as a chip even if it isn't a quick pick.
    final picks = <String>[
      if (_category != null && !_quickPicks.contains(_category)) _category!,
      ..._quickPicks,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in picks) _categoryChip(c),
            _moreChip(),
          ],
        ),
      ],
    );
  }

  Widget _categoryChip(String c) {
    final selected = c == _category;
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
  }

  Widget _moreChip() {
    return ActionChip(
      avatar: const Icon(Icons.tune_rounded, size: 18, color: AppTheme.primaryNavy),
      label: const Text('More'),
      onPressed: _openCategoryPicker,
      backgroundColor: AppTheme.cardBackground,
      labelStyle: const TextStyle(
        color: AppTheme.primaryNavy,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppTheme.dividerColor),
      ),
    );
  }

  // --- Pay bar ----------------------------------------------------------------

  Widget _payBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppTheme.cardBackground,
        boxShadow: [
          BoxShadow(color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, -4)),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _selectApp,
          icon: const Icon(Icons.account_balance_wallet_rounded),
          label: const Text('Select app to pay'),
        ),
      ),
    );
  }
}

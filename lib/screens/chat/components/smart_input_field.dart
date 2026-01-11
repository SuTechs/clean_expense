import 'package:flutter/material.dart';

import '../../../../data/command/commands.dart';
import '../../../../data/data/expense/expense.dart';
import '../../../../theme.dart';

class SmartInputField extends StatefulWidget {
  final Function(
    String note,
    double amount,
    String category,
    TransactionType type,
  )
  onSend;

  const SmartInputField({super.key, required this.onSend});

  @override
  State<SmartInputField> createState() => _SmartInputFieldState();
}

class _SmartInputFieldState extends State<SmartInputField>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // State
  TransactionType _selectedType = TransactionType.outgoing;
  bool _isTypeSelectorExpanded = false;
  String? _categoryFilter;

  // Animation for Shaking
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    // Shake Animation Setup
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 24,
    ).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeController);
    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) _shakeController.reset();
    });

    // Listen for '#' typing
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text;
    final selection = _controller.selection;

    // Simple logic to find if we are currently typing a tag
    if (selection.baseOffset >= 0) {
      final textBeforeCursor = text.substring(0, selection.baseOffset);
      final words = textBeforeCursor.split(' ');
      if (words.isNotEmpty && words.last.startsWith('#')) {
        setState(() {
          _categoryFilter = words.last.substring(1).toLowerCase();
        });
      } else {
        if (_categoryFilter != null) setState(() => _categoryFilter = null);
      }
    }
    setState(() {}); // Rebuild to show/hide send button
  }

  void _handleSend() {
    final text = _controller.text;

    // 1. Parsing Logic
    // Extract Amount (find first number NOT inside a word, ideally)
    // Simple regex for floating point numbers
    final amountRegExp = RegExp(r'[0-9]+(\.[0-9]+)?');
    final allNumbers = amountRegExp.allMatches(text);

    // Heuristic: If multiple numbers, take the last one? Or first?
    // User: "Dinner 500 at KFC". Amount 500.
    // User: "2 Burgers 500". Amount 500.
    // Let's take the *last* number found as amount, assume quantity/street numbers come earlier.
    final amountMatch = allNumbers.isNotEmpty ? allNumbers.last : null;

    // Extract Category (find first word starting with #)
    final categoryRegExp = RegExp(r'#(\w+)');
    final categoryMatch = categoryRegExp.firstMatch(text);

    if (amountMatch == null || categoryMatch == null) {
      // Validation Failed: Shake and Show Error
      _shakeController.forward();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Please enter Amount (e.g. 500) and Category (e.g. #food)",
          ),
          backgroundColor: AppTheme.dangerRed,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 88),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    final amount = double.parse(amountMatch.group(0)!);
    final category = categoryMatch.group(1)!;

    // Remove amount matching string and category matching string to get Note
    // Caution: removing "500" might remove it from "500 Main St".
    // Better to remove based on indices?
    // For simplicity, let's remove the *matched instances*.

    String note = text;
    // Remove category
    note = note.replaceFirst(categoryMatch.group(0)!, '');
    // Remove amount (using the match index to be safe, but replaceFirst is okay if we assume uniqueness or just remove first occurrence of that amount string)
    // Actually using match range is safer.
    note = note.replaceRange(amountMatch.start, amountMatch.end, '');

    note = note.trim();
    // Clean up extra spaces
    note = note.replaceAll(RegExp(r'\s+'), ' ');

    widget.onSend(note, amount, category, _selectedType);
    _controller.clear();
    setState(() {
      _categoryFilter = null;
    });
  }

  void _insertTag(String tag) {
    final text = _controller.text;
    final selection = _controller.selection;
    final textBeforeCursor = text.substring(0, selection.baseOffset);
    final words = textBeforeCursor.split(' ');

    // Replace the last partial tag with the full tag
    words.removeLast();
    final newText = "${words.join(' ')} #$tag ";

    _controller.value = TextEditingValue(
      text: newText + text.substring(selection.baseOffset),
      selection: TextSelection.collapsed(offset: newText.length),
    );
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    // Get suggestions dynamically
    final allCategories = BaseAppCommand.blocExpense.allCategories;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // --- 1. Autocomplete Suggestions ---
        if (_categoryFilter != null)
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: AppTheme.scaffoldBackground,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: allCategories
                  .where(
                    (c) => c.toLowerCase().startsWith(
                      _categoryFilter!.toLowerCase(),
                    ),
                  )
                  .map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(
                        right: 8.0,
                        top: 8,
                        bottom: 8,
                      ),
                      child: ActionChip(
                        label: Text("#$c"),
                        backgroundColor: AppTheme.primaryNavy.withValues(
                          alpha: 0.1,
                        ),
                        labelStyle: const TextStyle(
                          color: AppTheme.primaryNavy,
                          fontWeight: FontWeight.bold,
                        ),
                        onPressed: () => _insertTag(c),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

        // --- 2. Input bar container UI (from reference) ---
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                _shakeAnimation.value *
                    double.parse(
                      (1 - (2 * (_shakeController.value * 3).round() % 2))
                          .toString(),
                    ),
                0,
              ),
              child: child,
            );
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  offset: const Offset(0, -4),
                  blurRadius: 16,
                ),
              ],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- Expanded type selector (from reference) ---
                  if (_isTypeSelectorExpanded)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.scaffoldBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildTypeOption(
                            TransactionType.outgoing,
                            "Expense",
                            Icons.arrow_upward_rounded,
                          ),
                          _buildTypeOption(
                            TransactionType.incoming,
                            "Income",
                            Icons.arrow_downward_rounded,
                          ),
                          _buildTypeOption(
                            TransactionType.invested,
                            "Invest",
                            Icons.trending_up_rounded,
                          ),
                        ],
                      ),
                    ),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // --- Collapsed type selector trigger (from reference) ---
                      GestureDetector(
                        onTap: () => setState(() {
                          _isTypeSelectorExpanded = !_isTypeSelectorExpanded;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _getTypeColor(
                              _selectedType,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isTypeSelectorExpanded
                                  ? _getTypeColor(_selectedType)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Icon(
                            _getTypeIcon(_selectedType),
                            color: _getTypeColor(_selectedType),
                            size: 22,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // --- Text field (same behavior, reference styling) ---
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.scaffoldBackground,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            minLines: 1,
                            maxLines: 4,
                            textCapitalization: TextCapitalization.sentences,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppTheme.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: "Lunch #food 150...",
                              hintStyle: TextStyle(
                                color: AppTheme.textSecondary.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // --- Send button (keep your conditional visibility) ---
                      if (_controller.text.trim().isNotEmpty)
                        GestureDetector(
                          onTap: _handleSend,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryNavy,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryNavy.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_upward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Type selector helpers (from reference) ---

  Widget _buildTypeOption(TransactionType type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    final color = _getTypeColor(type);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          _isTypeSelectorExpanded = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.outgoing:
        return AppTheme.dangerRed;
      case TransactionType.incoming:
        return AppTheme.primaryGreen;
      case TransactionType.invested:
        return AppTheme.accentPurple;
    }
  }

  IconData _getTypeIcon(TransactionType type) {
    switch (type) {
      case TransactionType.outgoing:
        return Icons.arrow_upward_rounded;
      case TransactionType.incoming:
        return Icons.arrow_downward_rounded;
      case TransactionType.invested:
        return Icons.trending_up_rounded;
    }
  }
}

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
  bool _showTypeSelector = false;
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

        // --- 2. Type Selector (Animated Pop-up) ---
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: _showTypeSelector ? 60 : 0,
          curve: Curves.easeOut,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildTypeChip(
                  TransactionType.outgoing,
                  "Expense",
                  Colors.red.shade100,
                  Colors.red,
                ),
                const SizedBox(width: 12),
                _buildTypeChip(
                  TransactionType.incoming,
                  "Income",
                  Colors.green.shade100,
                  Colors.green,
                ),
                const SizedBox(width: 12),
                _buildTypeChip(
                  TransactionType.invested,
                  "Invest",
                  Colors.blue.shade100,
                  Colors.blue,
                ),
              ],
            ),
          ),
        ),

        // --- 3. The Input Field Area ---
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                _shakeAnimation.value *
                    double.parse(
                      // Simple sine wave for shaking: -1, 1, -1, 1...
                      (1 - (2 * (_shakeController.value * 3).round() % 2))
                          .toString(),
                    ),
                0,
              ),
              child: child,
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Toggle Type Button
                IconButton(
                  onPressed: () =>
                      setState(() => _showTypeSelector = !_showTypeSelector),
                  icon: Icon(
                    _showTypeSelector ? Icons.close : Icons.add_circle_outline,
                    color: AppTheme.textSecondary,
                    size: 28,
                  ),
                ),

                const SizedBox(width: 8),

                // Text Field
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.inputFill,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: "Lunch #food 150...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Send Button (Only visible if text exists)
                if (_controller.text.trim().isNotEmpty)
                  GestureDetector(
                    onTap: _handleSend,
                    child: const CircleAvatar(
                      backgroundColor: AppTheme.primaryGreen,
                      radius: 22,
                      child: Icon(Icons.arrow_upward, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeChip(
    TransactionType type,
    String label,
    Color bg,
    Color text,
  ) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedType = type;
        _showTypeSelector = false; // Auto hide after selection
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? bg : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: text, width: 2) : null,
        ),
        child: Row(
          children: [
            Icon(
              type == TransactionType.incoming
                  ? Icons.arrow_downward
                  : type == TransactionType.outgoing
                  ? Icons.arrow_upward
                  : Icons.show_chart,
              size: 16,
              color: isSelected ? text : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? text : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

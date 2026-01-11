import 'package:flutter/material.dart';

import '../../../theme.dart';
import 'chat_bubble.dart';

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
  TransactionType _selectedType = TransactionType.expense;
  bool _showTypeSelector = false;
  String? _categoryFilter;

  // Animation for Shaking
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  // Dummy Categories for Autocomplete
  final List<String> _allCategories = [
    'food',
    'transport',
    'bills',
    'groceries',
    'shopping',
    'salary',
    'investment',
  ];

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
    // Finds the word at cursor. If it starts with #, trigger autocomplete
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
    // Extract Amount (find first number)
    final amountRegExp = RegExp(r'\d+(\.\d+)?');
    final amountMatch = amountRegExp.firstMatch(text);

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

    // Remove amount and category from text to get the Note
    String note = text
        .replaceAll(amountRegExp, '')
        .replaceAll(categoryRegExp, '')
        .trim();
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
              children: _allCategories
                  .where((c) => c.startsWith(_categoryFilter!))
                  .map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(
                        right: 8.0,
                        top: 8,
                        bottom: 8,
                      ),
                      child: ActionChip(
                        label: Text("#$c"),
                        backgroundColor: AppTheme.primaryNavy.withOpacity(0.1),
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
                  TransactionType.expense,
                  "Expense",
                  Colors.red.shade100,
                  Colors.red,
                ),
                const SizedBox(width: 12),
                _buildTypeChip(
                  TransactionType.income,
                  "Income",
                  Colors.green.shade100,
                  Colors.green,
                ),
                const SizedBox(width: 12),
                _buildTypeChip(
                  TransactionType.investment,
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
                  color: Colors.black.withOpacity(0.05),
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
                    child: CircleAvatar(
                      backgroundColor: AppTheme.primaryGreen,
                      radius: 22,
                      child: const Icon(
                        Icons.arrow_upward,
                        color: Colors.white,
                      ),
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
              type == TransactionType.income
                  ? Icons.arrow_downward
                  : type == TransactionType.expense
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

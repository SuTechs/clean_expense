import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../data/command/commands.dart';
import '../../../data/data/expense/expense.dart';
import '../../../data/utils/transaction_parser_service.dart';
import '../theme/chat_theme.dart';
import '../theme/chat_theme_provider.dart';

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

  TransactionType _selectedType = TransactionType.outgoing;
  bool _isTypeSelectorExpanded = false;
  String? _categoryFilter;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
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

    if (selection.baseOffset >= 0) {
      final textBeforeCursor = text.substring(0, selection.baseOffset);
      final words = textBeforeCursor.split(' ');
      if (words.isNotEmpty && words.last.startsWith('#')) {
        setState(() => _categoryFilter = words.last.substring(1).toLowerCase());
      } else {
        if (_categoryFilter != null) setState(() => _categoryFilter = null);
      }
    }
    setState(() {});
  }

  void _handleSend(ChatTheme theme) {
    final text = _controller.text;
    final result = TransactionParserService().parse(text);

    if (!result.isValid) {
      HapticFeedback.heavyImpact();
      _shakeController.forward();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Please enter Amount (e.g. 500) and Category (e.g. #food)",
          ),
          backgroundColor: theme.outgoingAccent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 88),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    widget.onSend(
      result.notes ?? '',
      result.amount!,
      result.category!,
      _selectedType,
    );
    _controller.clear();
    setState(() => _categoryFilter = null);
  }

  void _insertTag(String tag) {
    final text = _controller.text;
    final selection = _controller.selection;
    final textBeforeCursor = text.substring(0, selection.baseOffset);
    final words = textBeforeCursor.split(' ');
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
    final theme = context.watch<ChatThemeProvider>().theme;
    // Get type-specific category suggestions
    final suggestions = BaseAppCommand.blocExpense.getSuggestionsForType(
      _selectedType,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Autocomplete suggestions
        if (_categoryFilter != null)
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: theme.inputContainerBg,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: suggestions
                  .where(
                    (c) => c.toLowerCase().startsWith(
                      _categoryFilter!.toLowerCase(),
                    ),
                  )
                  .map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(
                        right: 8,
                        top: 8,
                        bottom: 8,
                      ),
                      child: ActionChip(
                        label: Text("#$c"),
                        backgroundColor: theme.outgoingBg,
                        side: BorderSide(color: theme.outgoingBorder),
                        labelStyle: TextStyle(
                          color: theme.outgoingAccent,
                          fontWeight: FontWeight.bold,
                        ),
                        onPressed: () => _insertTag(c),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

        // Input bar
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                _shakeAnimation.value *
                    (1 - (2 * (_shakeController.value * 3).round() % 2)),
                0,
              ),
              child: child,
            );
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: theme.inputContainerBg,
              boxShadow: [
                BoxShadow(
                  color: theme.patternColor,
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
                  // Expanded type selector
                  if (_isTypeSelectorExpanded)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.inputFieldBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildTypeOption(
                            theme,
                            TransactionType.outgoing,
                            "Expense",
                            Icons.arrow_upward_rounded,
                          ),
                          _buildTypeOption(
                            theme,
                            TransactionType.incoming,
                            "Income",
                            Icons.arrow_downward_rounded,
                          ),
                          _buildTypeOption(
                            theme,
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
                      // Type selector trigger
                      GestureDetector(
                        onTap: () => setState(
                          () => _isTypeSelectorExpanded =
                              !_isTypeSelectorExpanded,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _getTypeColor(
                              theme,
                              _selectedType,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isTypeSelectorExpanded
                                  ? _getTypeColor(theme, _selectedType)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Icon(
                            _getTypeIcon(_selectedType),
                            color: _getTypeColor(theme, _selectedType),
                            size: 22,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Text field
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          minLines: 1,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.primaryText,
                          ),
                          decoration: InputDecoration(
                            hintText: "Lunch #food 150...",
                            hintStyle: TextStyle(color: theme.secondaryText),
                            filled: true,
                            fillColor: theme.inputFieldBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: theme.inputBorder,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            isDense: true,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Send button
                      if (_controller.text.trim().isNotEmpty)
                        GestureDetector(
                          onTap: () => _handleSend(theme),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getTypeColor(theme, _selectedType),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _getTypeColor(
                                    theme,
                                    _selectedType,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.arrow_upward_rounded,
                              color: theme.id == 'midnight'
                                  ? Colors.black
                                  : Colors.white,
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

  Widget _buildTypeOption(
    ChatTheme theme,
    TransactionType type,
    String label,
    IconData icon,
  ) {
    final isSelected = _selectedType == type;
    final color = _getTypeColor(theme, type);

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
          color: isSelected ? theme.inputContainerBg : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.patternColor,
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
                color: isSelected ? theme.primaryText : theme.secondaryText,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(ChatTheme theme, TransactionType type) {
    switch (type) {
      case TransactionType.outgoing:
        return theme.outgoingAccent;
      case TransactionType.incoming:
        return theme.incomingAccent;
      case TransactionType.invested:
        return theme.investedAccent;
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

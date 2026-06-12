import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../data/bloc/app_bloc.dart';
import '../../../data/command/commands.dart';
import '../../../data/data/expense/expense.dart';
import '../../../data/utils/transaction_parser_service.dart';
import '../state/chat_interaction_provider.dart';
import '../theme/chat_theme.dart';
import '../theme/chat_theme_provider.dart';
import 'type_selector_coach_mark.dart';

class SmartInputField extends StatefulWidget {
  final Future<void> Function(
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

  /// Id of the transaction currently mirrored in the input, so the field
  /// only re-prefills when edit mode starts/changes (not on every rebuild).
  String? _lastEditingId;

  /// Draft typed before an edit started, restored when the edit ends so
  /// long-pressing a bubble doesn't destroy a half-typed expense.
  String? _draftBeforeEdit;

  // First-use hint pointing at the type selector.
  final LayerLink _typeSelectorLink = LayerLink();
  OverlayEntry? _coachMarkEntry;
  Timer? _coachMarkTimer;

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
    _maybeShowCoachMark();
  }

  @override
  void dispose() {
    _removeCoachMark();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  /// Shows the one-time type-selector hint after the screen's entrance
  /// transition has settled. Dismissed by any tap or a timeout.
  void _maybeShowCoachMark() {
    if (BaseAppCommand.blocApp.hasSeenTypeSelectorHint) return;

    _coachMarkTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted || _coachMarkEntry != null) return;

      final theme = context.read<ChatThemeProvider>().theme;
      _coachMarkEntry = OverlayEntry(
        builder: (_) => TypeSelectorCoachMark(
          link: _typeSelectorLink,
          theme: theme,
          onDismiss: _dismissCoachMark,
        ),
      );
      Overlay.of(context).insert(_coachMarkEntry!);
      _coachMarkTimer = Timer(const Duration(seconds: 6), _dismissCoachMark);
    });
  }

  /// Removes the overlay without marking the hint as seen (e.g. when the
  /// screen is popped while the hint is still up).
  void _removeCoachMark() {
    _coachMarkTimer?.cancel();
    _coachMarkTimer = null;
    _coachMarkEntry?.remove();
    _coachMarkEntry = null;
  }

  void _dismissCoachMark() {
    _removeCoachMark();
    if (!BaseAppCommand.blocApp.hasSeenTypeSelectorHint) {
      BaseAppCommand.blocApp.hasSeenTypeSelectorHint = true;
    }
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

  Future<void> _handleSend(ChatTheme theme) async {
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

    try {
      await widget.onSend(
        result.notes ?? '',
        result.amount!,
        result.category!,
        _selectedType,
      );
      _controller.clear();
      setState(() => _categoryFilter = null);
    } catch (e) {
      HapticFeedback.heavyImpact();
      _shakeController.forward();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to add transaction: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 88),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  /// Mirrors edit mode into the input: prefills the reconstructed text when
  /// editing starts and clears it when editing ends (sent or cancelled).
  void _syncEditingState(ChatInteractionProvider interaction) {
    final editing = interaction.editing;
    if (editing?.id == _lastEditingId) return;
    _lastEditingId = editing?.id;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (editing != null) {
        _draftBeforeEdit ??= _controller.text;
        final text = TransactionParserService().reconstruct(
          note: editing.note,
          category: editing.category,
          amount: editing.amount,
        );
        _controller.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
        setState(() {
          _selectedType = editing.type;
          _isTypeSelectorExpanded = false;
          _categoryFilter = null;
        });
        _focusNode.requestFocus();
      } else {
        // Edit ended (sent or cancelled): bring back whatever the user
        // had typed before the edit hijacked the field.
        _controller.text = _draftBeforeEdit ?? '';
        _draftBeforeEdit = null;
        setState(() => _categoryFilter = null);
      }
    });
  }

  Widget _buildEditingBanner(
    ChatTheme theme,
    ChatInteractionProvider interaction,
  ) {
    final expense = interaction.editing!;
    final color = _getTypeColor(theme, expense.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: theme.inputFieldBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Icon(Icons.edit_outlined, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editing transaction',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  expense.note.isEmpty
                      ? '#${expense.category}'
                      : '${expense.note} · #${expense.category}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: theme.secondaryText),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: interaction.cancelEditing,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.close_rounded,
              size: 18,
              color: theme.secondaryText,
            ),
          ),
        ],
      ),
    );
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
    final interaction = context.watch<ChatInteractionProvider>();
    _syncEditingState(interaction);

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

        // Input bar with Hero for FAB transition
        Hero(
          tag: 'chat_input_hero',
          child: Material(
            type: MaterialType.transparency,
            child: AnimatedBuilder(
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
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  MediaQuery.of(context).padding.bottom + 24,
                ),
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
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Editing indicator (WhatsApp reply-preview style)
                      if (interaction.isEditing)
                        _buildEditingBanner(theme, interaction),

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
                          CompositedTransformTarget(
                            link: _typeSelectorLink,
                            child: PulsingHighlight(
                              active: !context
                                  .watch<AppBloc>()
                                  .hasSeenTypeSelectorHint,
                              color: _getTypeColor(theme, _selectedType),
                              child: GestureDetector(
                                onTap: () {
                                  _dismissCoachMark();
                                  setState(
                                    () => _isTypeSelectorExpanded =
                                        !_isTypeSelectorExpanded,
                                  );
                                },
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
                                hintStyle: TextStyle(
                                  color: theme.secondaryText,
                                ),
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
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _handleSend(theme),
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

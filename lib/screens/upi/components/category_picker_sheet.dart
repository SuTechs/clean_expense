import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/command/commands.dart';
import '../../../data/data/expense/expense.dart';
import '../../../theme.dart';
import 'category_chip.dart';

/// Bottom sheet for picking an expense category.
///
/// Shows a search field, a "Most used" row (categories the user actually uses,
/// ordered by frequency) and the full alphabetical list. Returns the chosen
/// category string via [Navigator.pop].
class CategoryPickerSheet extends StatefulWidget {
  final String? selected;
  const CategoryPickerSheet({super.key, this.selected});

  /// Opens the sheet and resolves to the chosen category, or `null` if dismissed.
  static Future<String?> show(BuildContext context, {String? selected}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => CategoryPickerSheet(selected: selected),
    );
  }

  @override
  State<CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<CategoryPickerSheet> {
  final TextEditingController _search = TextEditingController();

  // Sorted by usage (most-used first), then defaults alphabetically.
  late final List<String> _all =
      BaseAppCommand.blocExpense.getSuggestionsForType(
    TransactionType.outgoing,
  );
  late final Set<String> _used =
      BaseAppCommand.blocExpense.usedCategories.toSet();

  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(
      () => setState(() => _query = _search.text.trim().toLowerCase()),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<String> get _mostUsed =>
      _all.where(_used.contains).take(8).toList(growable: false);

  List<String> get _filtered => _query.isEmpty
      ? _all
      : _all.where((c) => c.contains(_query)).toList(growable: false);

  void _pick(String category) => Navigator.of(context).pop(category);

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    final mostUsed = _mostUsed;
    final filtered = _filtered;

    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Text(
                      'Select category',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                  ],
                ),
              ),

              // Search.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _search,
                  autofocus: false,
                  decoration: const InputDecoration(
                    hintText: 'Search categories',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    if (_query.isEmpty && mostUsed.isNotEmpty) ...[
                      const _SectionLabel('Most used'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final c in mostUsed)
                            CategoryChip(
                              label: c,
                              selected: c == widget.selected,
                              onTap: () => _pick(c),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const _SectionLabel('All categories'),
                      const SizedBox(height: 8),
                    ],
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in filtered)
                          CategoryChip(
                            label: c,
                            selected: c == widget.selected,
                            onTap: () => _pick(c),
                          ),
                      ],
                    ),
                    if (filtered.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: Text(
                          'No matching categories.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

}

/// Small muted section heading used inside the category sheet.
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
      ),
    );
  }
}

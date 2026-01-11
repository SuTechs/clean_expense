import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/bloc/expense_bloc.dart';
import '../../data/command/commands.dart';
import '../../data/data/expense/expense.dart';
import '../../theme.dart';

class ManageCategoryScreen extends StatelessWidget {
  const ManageCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: const Text("Manage Categories"),
        centerTitle: true,
        backgroundColor: AppTheme.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          color: AppTheme.primaryNavy,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<ExpenseBloc>(
        builder: (context, bloc, child) {
          final grouped = bloc.categoriesByType;
          final hasCategories = grouped.values.any((list) => list.isNotEmpty);

          if (!hasCategories) {
            return const Center(
              child: Text(
                "No categories used yet.",
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            children: [
              if (grouped[TransactionType.outgoing]?.isNotEmpty ?? false)
                _buildSection(
                  context,
                  "Expenses",
                  grouped[TransactionType.outgoing]!,
                  bloc,
                ),
              if (grouped[TransactionType.incoming]?.isNotEmpty ?? false)
                _buildSection(
                  context,
                  "Income",
                  grouped[TransactionType.incoming]!,
                  bloc,
                ),
              if (grouped[TransactionType.invested]?.isNotEmpty ?? false)
                _buildSection(
                  context,
                  "Investments",
                  grouped[TransactionType.invested]!,
                  bloc,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<String> categories,
    ExpenseBloc bloc,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: 8,
            top: 16,
          ),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...categories.map((category) {
          // Note: count here is total count across all types if we use getCategoryCount
          // If we want count specific to this type, we need a new method or filter here.
          // For now, let's show total count to avoid confusion, or total?
          // Actually, if a category is "food", it's unlikely to be in Income.
          // If it is, "12 transactions" total is probably what user expects for "food".
          final count = bloc.getCategoryCount(category);
          return Column(
            children: [
              _CategoryItem(
                category: category,
                count: count,
                onTap: () => _showOptionsBottomSheet(context, category),
              ),
              const Divider(
                height: 1,
                color: AppTheme.dividerColor,
                indent: 16,
                endIndent: 16,
              ),
            ],
          );
        }),
      ],
    );
  }

  void _showOptionsBottomSheet(BuildContext context, String category) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.edit_outlined,
                  color: AppTheme.primaryNavy,
                ),
                title: const Text("Rename Category"),
                onTap: () {
                  Navigator.pop(context); // Close options
                  _showEditBottomSheet(context, category);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppTheme.dangerRed,
                ),
                title: const Text(
                  "Delete Category",
                  style: TextStyle(color: AppTheme.dangerRed),
                ),
                onTap: () {
                  Navigator.pop(context); // Close options
                  _showDeleteBottomSheet(context, category);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showEditBottomSheet(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Rename Category",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryNavy,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: "Category Name",
                  hintText: "Enter new name",
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  final newName = controller.text.trim().toLowerCase();
                  if (newName.isNotEmpty && newName != currentName) {
                    BaseAppCommand.blocExpense.renameCategory(
                      currentName,
                      newName,
                    );
                  }
                  Navigator.pop(context);
                },
                child: const Text("Save Changes"),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteBottomSheet(BuildContext context, String categoryName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Delete '#$categoryName'?",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryNavy,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                "Do you want to delete all transactions associated with this category, or just mark them as deleted?",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 32),

              // Keep Data Button
              OutlinedButton(
                onPressed: () {
                  BaseAppCommand.blocExpense.deleteCategory(
                    categoryName,
                    deleteTransactions: false,
                  );
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Keep Data (Mark Deleted)"),
              ),

              const SizedBox(height: 12),

              // Delete All Button
              ElevatedButton(
                onPressed: () {
                  BaseAppCommand.blocExpense.deleteCategory(
                    categoryName,
                    deleteTransactions: true,
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.dangerRed,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: const Text("Delete All"),
              ),

              const SizedBox(height: 12),

              // Cancel
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String category;
  final int count;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.category,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayCategory = "#${category.toLowerCase()}";

    return Container(
      color: Colors.white,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        title: Text(
          displayCategory,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: AppTheme.primaryNavy,
          ),
        ),
        subtitle: Text(
          "$count transactions",
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        trailing: const Icon(Icons.more_horiz, color: AppTheme.textSecondary),
      ),
    );
  }
}

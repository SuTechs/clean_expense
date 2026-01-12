import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../data/command/expense/expense_command.dart';
import '../../data/data/expense/expense.dart';
import 'components/chat_background.dart';
import 'components/chat_settings_sheet.dart';
import 'components/smart_input_field.dart';
import 'components/transaction_list.dart';
import 'theme/chat_theme_provider.dart';

/// Main chat screen for adding and viewing transactions.
/// Wrapped with ChatThemeProvider for theme management.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final Uuid _uuid = const Uuid();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _addTransaction(
    String note,
    double amount,
    String category,
    TransactionType type,
  ) async {
    final newExpense = ExpenseData(
      id: _uuid.v4(),
      amount: amount,
      category: category.toLowerCase(),
      date: DateTime.now(),
      type: type,
      note: note,
    );

    await ExpenseCommand().addExpense(newExpense);

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatThemeProvider(),
      child: Consumer<ChatThemeProvider>(
        builder: (context, themeProvider, _) {
          final theme = themeProvider.theme;
          final isDark = theme.id == 'midnight';

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: isDark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
            child: Scaffold(
              body: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: Stack(
                  children: [
                    // 1. Animated Background
                    Positioned.fill(child: ChatBackground(theme: theme)),

                    // 2. Main Content
                    Column(
                      children: [
                        // Fixed App Bar with glass effect
                        _buildGlassAppBar(context, themeProvider),

                        // Scrollable Transaction List
                        Expanded(
                          child: CustomScrollView(
                            controller: _scrollController,
                            reverse: true,
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            slivers: const [
                              TransactionList(),
                              SliverPadding(padding: EdgeInsets.only(top: 8)),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // 3. Fixed Bottom Input Field
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: SmartInputField(onSend: _addTransaction),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGlassAppBar(
    BuildContext context,
    ChatThemeProvider themeProvider,
  ) {
    final theme = themeProvider.theme;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          decoration: BoxDecoration(
            color: theme.appBarBg,
            border: Border(
              bottom: BorderSide(
                color: theme.patternColor.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
          ),
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                // Back button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.patternColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: theme.appBarText,
                    ),
                  ),
                ),

                const SizedBox(width: 4),

                // Avatar - tap to open settings
                GestureDetector(
                  onTap: () => _showSettings(themeProvider),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.statusDot.withValues(alpha: 0.25),
                          theme.statusDot.withValues(alpha: 0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.statusDot.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'logo-big.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.account_balance_wallet_rounded,
                          color: theme.statusDot,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Name and status - tap to open settings
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showSettings(themeProvider),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Clean Expense',
                          style: TextStyle(
                            color: theme.appBarText,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: theme.statusDot,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Active now',
                              style: TextStyle(
                                color: theme.secondaryText,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Settings button
                IconButton(
                  onPressed: () => _showSettings(themeProvider),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.patternColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: theme.appBarText,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSettings(ChatThemeProvider themeProvider) {
    ChatSettingsSheet.show(context, themeProvider);
  }
}

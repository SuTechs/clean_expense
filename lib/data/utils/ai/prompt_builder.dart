import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:intl/intl.dart';

/// Builds the system prompt and the single query_stats tool definition.
/// One tool with tight enums turns "function calling" into intent
/// classification + slot filling — the regime where a 0.6B model is
/// reliable.
class AiPromptBuilder {
  AiPromptBuilder._();

  static Tool buildTool() {
    return const Tool(
      name: 'query_stats',
      description:
          'Look up statistics about the user\'s transactions. Call this for '
          'ANY question about their money, spending, income, savings or '
          'investments.',
      parameters: {
        'type': 'object',
        'properties': {
          'metric': {
            'type': 'string',
            'enum': [
              'total_spending',
              'total_income',
              'total_invested',
              'total_saved',
              'savings_rate',
              'top_category',
              'category_breakdown',
              'largest_expense',
              'average_daily_spend',
              'most_frequent_category',
              'spending_trend',
              'day_of_week',
              'projection',
              'transaction_count',
              'list_transactions',
            ],
          },
          'period': {
            'type': 'string',
            'enum': ['D', 'W', 'M', 'Y', 'All'],
            'description': 'D=day, W=week, M=month, Y=year, All=all time',
          },
          'date_offset': {
            'type': 'integer',
            'description':
                '0 = current period, -1 = previous (e.g. last month)',
          },
          'type': {
            'type': 'string',
            'enum': ['outgoing', 'incoming', 'invested'],
            'description':
                'Optional filter: outgoing=expenses, incoming=income, '
                'invested=investments',
          },
          'category': {
            'type': 'string',
            'description': 'Optional category filter, e.g. food',
          },
          'top_n': {'type': 'integer'},
        },
        'required': ['metric', 'period'],
      },
    );
  }

  static String systemInstruction({
    required String currency,
    required DateTime now,
    required List<String> categories,
  }) {
    final topCategories = categories.take(30).join(', ');
    final today = DateFormat('EEEE, MMMM d, yyyy').format(now);

    return '''
You are the assistant inside Clean Expense, a private expense tracker.
Today is $today. The user's currency is $currency.
The user's transaction categories: $topCategories.

To answer ANY question about the user's money you MUST call query_stats.
Never invent or guess numbers — the app computes them.
Examples:
- "what did I spend this month" -> query_stats(metric=total_spending, period=M)
- "biggest expense last month on food" -> query_stats(metric=largest_expense, period=M, date_offset=-1, category=food)
- "where am I spending most" -> query_stats(metric=top_category, period=M)
- "show today's transactions" -> query_stats(metric=list_transactions, period=D)
- "yesterday's food transactions" -> query_stats(metric=list_transactions, period=D, date_offset=-1, category=food)
If the question is not about their finances, reply in one short sentence and
suggest a finance question.''';
  }
}

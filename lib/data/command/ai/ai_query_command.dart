import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/core/model_response.dart';
import 'package:uuid/uuid.dart';

import '../../api/ai/ai_engine.dart';
import '../../bloc/ai_bloc.dart';
import '../../data/ai/ai_intent.dart';
import '../../data/ai/ai_message.dart';
import '../../utils/ai/intent_executor.dart';
import '../../utils/ai/intent_fallback_parser.dart';
import '../commands.dart';
import 'ai_model_command.dart';

/// The question pipeline: model extracts an intent (single query_stats
/// tool), the app computes the numbers and builds the reply. The model is
/// ONLY an intent classifier — answer text and figures are always composed
/// by the app, so it can never hallucinate the user's numbers.
class AiQueryCommand extends BaseAppCommand {
  static const _uuid = Uuid();

  AiBloc get aiBloc => BaseAppCommand.blocAi;

  static const _helpText =
      "I can answer questions about your money — try \"What did I spend "
      "this month?\", \"Where am I spending most?\" or \"My biggest "
      "expense on food\".";

  Future<void> ask(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || aiBloc.isGenerating) return;

    aiBloc.addMessage(
      AiMessage(id: _uuid.v4(), role: AiMessageRole.user, text: trimmed),
    );

    final replyId = _uuid.v4();
    aiBloc.addMessage(
      AiMessage(
        id: replyId,
        role: AiMessageRole.assistant,
        text: '',
        status: AiMessageStatus.pending,
      ),
    );
    aiBloc.isGenerating = true;

    try {
      await AiModelCommand().ensureLoaded();

      final categories = expenseBloc.expenses
          .map((e) => e.category)
          .toSet()
          .toList();

      final intent =
          await _intentFromModel(trimmed, categories) ??
          IntentFallbackParser.parse(trimmed, categories: categories);

      if (intent == null) {
        _finish(replyId, const AiAnswer(text: _helpText));
        return;
      }

      final answer = IntentExecutor(
        expenses: expenseBloc.expenses,
        currency: appBloc.currency,
      ).execute(intent);

      _finish(replyId, answer);
    } catch (e) {
      debugPrint('AiQueryCommand.ask: $e');
      aiBloc.updateMessage(
        replyId,
        (m) => m.copyWith(
          text: "The AI had a hiccup — please try again.",
          status: AiMessageStatus.error,
        ),
      );
    } finally {
      aiBloc.isGenerating = false;
    }
  }

  void _finish(String replyId, AiAnswer answer) {
    aiBloc.updateMessage(
      replyId,
      (m) => m.copyWith(
        text: answer.text,
        widget: answer.widget,
        status: AiMessageStatus.done,
      ),
    );
  }

  Future<AiIntent?> _intentFromModel(
    String text,
    List<String> categories,
  ) async {
    try {
      final response = await AiEngine().ask(text);

      final call = switch (response) {
        FunctionCallResponse f => f,
        ParallelFunctionCallResponse p when p.calls.isNotEmpty => p.calls.first,
        _ => null,
      };
      if (call == null || call.name != 'query_stats') return null;

      return AiIntent.fromToolArgs(call.args, knownCategories: categories);
    } catch (e) {
      // Engine failure → fallback parser still gets a chance.
      debugPrint('AiQueryCommand._intentFromModel: $e');
      return null;
    }
  }
}

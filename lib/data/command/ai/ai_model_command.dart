import 'package:flutter/foundation.dart';

import '../../api/ai/ai_engine.dart';
import '../../api/ai/device_capability.dart';
import '../../api/ai/model_registry.dart';
import '../../api/hive/service_extension.dart';
import '../../bloc/ai_bloc.dart';
import '../../utils/ai/prompt_builder.dart';
import '../commands.dart';

class AiModelCommand extends BaseAppCommand {
  AiBloc get aiBloc => BaseAppCommand.blocAi;

  /// The registry model installed on this device (default when none yet).
  AiModelInfo get installedModel =>
      AiModelRegistry.byId(hive.getAiInstalledModelId);

  /// Cheap status check when the AI tab is first opened.
  Future<void> checkStatus() async {
    if (aiBloc.status != AiModelStatus.unknown) return;

    final reason = await DeviceCapability.unsupportedReason();
    if (reason != null) {
      aiBloc.setStatus(AiModelStatus.unsupported, reason: reason);
      return;
    }

    try {
      final installed = await AiEngine().isModelInstalled();
      aiBloc.setStatus(
        installed ? AiModelStatus.installed : AiModelStatus.notInstalled,
      );
    } catch (e) {
      debugPrint('AiModelCommand.checkStatus: $e');
      aiBloc.setStatus(AiModelStatus.notInstalled);
    }
  }

  Future<void> startDownload(AiModelInfo model) async {
    if (aiBloc.status == AiModelStatus.downloading) return;
    aiBloc.setDownloadProgress(0);

    try {
      await AiEngine().download(model, aiBloc.setDownloadProgress);
      await hive.setAiInstalledModelId(model.id);
      aiBloc.setStatus(AiModelStatus.installed);
    } on AiDownloadCancelled {
      aiBloc.setStatus(AiModelStatus.notInstalled);
    } catch (e, st) {
      debugPrint('AiModelCommand.startDownload: $e\n$st');
      aiBloc.setStatus(
        AiModelStatus.notInstalled,
        error: 'Download failed: ${_shortError(e)}',
      );
    }
  }

  void cancelDownload() => AiEngine().cancelDownload();

  /// Replaces the installed model with [model]: frees the old weights and
  /// downloads the new ones. Chat history survives (it lives in the bloc).
  Future<void> switchModel(AiModelInfo model) async {
    if (model.id == hive.getAiInstalledModelId) return;
    try {
      await AiEngine().deleteModel();
    } catch (e) {
      debugPrint('AiModelCommand.switchModel (delete old): $e');
    }
    await hive.setAiInstalledModelId(null);
    aiBloc.setStatus(AiModelStatus.notInstalled);
    await startDownload(model);
  }

  static String _shortError(Object e) {
    final text = e.toString();
    return text.length > 120 ? '${text.substring(0, 120)}…' : text;
  }

  /// Loads model weights into memory (takes seconds on first use).
  Future<void> ensureLoaded() async {
    if (AiEngine().isLoaded) {
      aiBloc.setStatus(AiModelStatus.ready);
      return;
    }
    aiBloc.setStatus(AiModelStatus.loading);

    final categories = expenseBloc.expenses
        .map((e) => e.category)
        .toSet()
        .toList();

    await AiEngine().load(
      model: installedModel,
      systemInstruction: AiPromptBuilder.systemInstruction(
        currency: appBloc.currency,
        now: DateTime.now(),
        categories: categories,
      ),
      tools: [AiPromptBuilder.buildTool()],
    );
    aiBloc.setStatus(AiModelStatus.ready);
  }

  /// Frees model memory; chat history (in bloc) survives.
  Future<void> unload() async {
    await AiEngine().unload();
    if (aiBloc.status == AiModelStatus.ready ||
        aiBloc.status == AiModelStatus.loading) {
      aiBloc.setStatus(AiModelStatus.installed);
    }
  }

  Future<void> deleteModel() async {
    await AiEngine().deleteModel();
    await hive.setAiInstalledModelId(null);
    aiBloc.clearMessages();
    aiBloc.setStatus(AiModelStatus.notInstalled);
  }
}

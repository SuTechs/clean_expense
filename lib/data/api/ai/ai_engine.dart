import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

import 'model_registry.dart';

/// Engine-agnostic "user cancelled the download" signal, so callers don't
/// need to know flutter_gemma's exception types.
class AiDownloadCancelled implements Exception {}

/// The ONLY file that touches the flutter_gemma API — keeps the eventual
/// 1.0 upgrade (or an engine swap) a one-file change.
class AiEngine {
  static final AiEngine _instance = AiEngine._();
  factory AiEngine() => _instance;
  AiEngine._();

  bool _frameworkReady = false;
  InferenceModel? _model;
  InferenceChat? _chat;

  /// Serializes load/ask/unload/delete. Without it, unload() during an
  /// in-flight load() was a silent no-op (model stayed resident in the
  /// background — the OOM we tuned against), and unload during generation
  /// closed the native session under a running inference.
  Future<void> _queue = Future.value();

  Future<T> _serial<T>(Future<T> Function() op) {
    final result = _queue.then((_) => op());
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  bool get isLoaded => _chat != null;

  Future<void> _ensureFramework() async {
    if (_frameworkReady) return;
    await FlutterGemma.initialize();
    _frameworkReady = true;
  }

  Future<bool> isModelInstalled() async {
    await _ensureFramework();
    return FlutterGemma.hasActiveModel();
  }

  CancelToken? _downloadCancelToken;

  /// Downloads + installs the model; the plugin retries transient network
  /// errors internally. [onProgress] receives 0-100.
  Future<void> download(
    AiModelInfo model,
    void Function(int percent) onProgress,
  ) async {
    await _ensureFramework();
    debugPrint('AiEngine.download: starting ${model.id} from ${model.url}');
    _downloadCancelToken = CancelToken();
    try {
      await FlutterGemma.installModel(
            modelType: model.modelType,
            fileType: ModelFileType.litertlm,
          )
          .fromNetwork(model.url)
          .withProgress((percent) {
            debugPrint('AiEngine.download: $percent%');
            onProgress(percent);
          })
          .withCancelToken(_downloadCancelToken!)
          .install();
      debugPrint('AiEngine.download: ${model.id} installed');
    } on DownloadCancelledException {
      throw AiDownloadCancelled();
    } finally {
      _downloadCancelToken = null;
    }
  }

  void cancelDownload() => _downloadCancelToken?.cancel('User cancelled');

  /// Loads the model into memory and opens a chat with the single
  /// query_stats tool. Expensive (seconds) — call lazily, never at startup.
  Future<void> load({
    required AiModelInfo model,
    required String systemInstruction,
    required List<Tool> tools,
  }) {
    return _serial(() async {
      if (isLoaded) return;
      await _ensureFramework();

      // 1024 tokens halves the KV-cache vs 2048 — the prompt + tool JSON +
      // a tool-call reply use ~600, so this fits with headroom. Budget 4 GB
      // phones OOM-crashed natively on first load with the larger context.
      // CPU explicitly: XNNPACK is the stable path on low-end devices and
      // skips the NPU/GPU dispatch probing.
      _model = await FlutterGemma.getActiveModel(
        maxTokens: 1024,
        preferredBackend: PreferredBackend.cpu,
      );
      _chat = await _model!.createChat(
        // Slot filling wants determinism, not creativity.
        temperature: 0.1,
        tokenBuffer: 256,
        tools: tools,
        supportsFunctionCalls: true,
        modelType: model.modelType,
        systemInstruction: systemInstruction,
      );
    });
  }

  /// Sends the user text and returns the model's response (a
  /// [FunctionCallResponse] when it picked the tool, else the full text).
  ///
  /// Uses the streaming generate API: it's the only one in flutter_gemma
  /// 0.16 with context-window management — the sync variant never trims,
  /// so at 1024 tokens the session overflowed after a handful of questions
  /// and silently degraded to the fallback parser for the rest of the
  /// session.
  Future<ModelResponse> ask(String text) {
    return _serial(() async {
      final chat = _chat;
      if (chat == null) throw StateError('AiEngine not loaded');

      await chat.addQuery(Message.text(text: text, isUser: true));

      FunctionCallResponse? call;
      final buffer = StringBuffer();
      await for (final event in chat.generateChatResponseAsync()) {
        switch (event) {
          case FunctionCallResponse f:
            call ??= f;
          case ParallelFunctionCallResponse p:
            if (p.calls.isNotEmpty) call ??= p.calls.first;
          case TextResponse t:
            buffer.write(t.token);
          case ThinkingResponse _:
            break;
        }
      }
      return call ?? TextResponse(buffer.toString());
    });
  }

  /// Frees model memory (app backgrounded / left the AI tab). Queued
  /// behind any in-flight load/ask so it can never miss a model that's
  /// still being created or close a session mid-inference.
  Future<void> unload() {
    return _serial(() async {
      await _model?.close();
      _model = null;
      _chat = null;
    });
  }

  Future<void> deleteModel() {
    return _serial(() async {
      await _model?.close();
      _model = null;
      _chat = null;
      await _ensureFramework();
      final manager = FlutterGemmaPlugin.instance.modelManager;
      final spec = manager.activeInferenceModel;
      if (spec != null) await manager.deleteModel(spec);
    });
  }
}

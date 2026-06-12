import '../data/ai/ai_message.dart';
import 'abstract.dart';

enum AiModelStatus {
  unknown,
  unsupported,
  notInstalled,
  downloading,
  installed, // downloaded but not loaded into memory
  loading,
  ready,
  error,
}

class AiBloc extends AbstractBloc {
  AiModelStatus _status = AiModelStatus.unknown;
  int _downloadProgress = 0;
  String? _unsupportedReason;
  String? _errorMessage;

  final List<AiMessage> _messages = [];
  bool _isGenerating = false;

  AiModelStatus get status => _status;
  int get downloadProgress => _downloadProgress;
  String? get unsupportedReason => _unsupportedReason;
  String? get errorMessage => _errorMessage;
  List<AiMessage> get messages => List.unmodifiable(_messages);
  bool get isGenerating => _isGenerating;

  void setStatus(AiModelStatus status, {String? error, String? reason}) =>
      notify(() {
        _status = status;
        _errorMessage = error;
        if (reason != null) _unsupportedReason = reason;
      });

  void setDownloadProgress(int percent) => notify(() {
    _status = AiModelStatus.downloading;
    _downloadProgress = percent;
  });

  /// Keeps the in-memory history bounded for long sessions.
  static const _maxMessages = 100;

  void addMessage(AiMessage message) => notify(() {
    _messages.add(message);
    if (_messages.length > _maxMessages) _messages.removeAt(0);
  });

  void updateMessage(String id, AiMessage Function(AiMessage) transform) {
    final index = _messages.indexWhere((m) => m.id == id);
    if (index == -1) return;
    notify(() => _messages[index] = transform(_messages[index]));
  }

  set isGenerating(bool value) => notify(() => _isGenerating = value);

  void clearMessages() => notify(_messages.clear);
}

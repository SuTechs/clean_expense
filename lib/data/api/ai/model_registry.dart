import 'package:flutter_gemma/flutter_gemma.dart';

class AiModelInfo {
  final String id;

  /// Short tier name shown on the picker card ("Light", "Pro").
  final String displayName;

  /// Technical description shown under the tier name.
  final String subtitle;
  final String url;
  final int sizeBytes;
  final ModelType modelType;
  final String license;

  /// Minimum device RAM (GB) to offer this tier. Cards are disabled below
  /// this — a bigger model on a weak phone is slower or OOM-killed, never
  /// better.
  final int minRamGb;

  const AiModelInfo({
    required this.id,
    required this.displayName,
    required this.subtitle,
    required this.url,
    required this.sizeBytes,
    required this.modelType,
    required this.license,
    required this.minRamGb,
  });

  bool fitsRam(int? deviceRamMb) =>
      deviceRamMb == null || deviceRamMb >= minRamGb * 1000;

  String get sizeLabel {
    final mb = sizeBytes / (1024 * 1024);
    return mb >= 1000
        ? '${(mb / 1024).toStringAsFixed(1)} GB'
        : '${mb.toStringAsFixed(0)} MB';
  }
}

/// Available on-device models. All entries are UNGATED (no HuggingFace
/// login) and permissively licensed — critical for a free, open-source app.
/// Gemma models stay out for now: their weights are gated behind HF auth.
class AiModelRegistry {
  AiModelRegistry._();

  static const light = AiModelInfo(
    id: 'qwen3-0.6b-int4',
    displayName: 'Light',
    subtitle: 'Qwen3 0.6B · fast on any phone',
    url:
        'https://huggingface.co/litert-community/Qwen3-0.6B/resolve/main/qwen3_0_6b_mixed_int4.litertlm',
    sizeBytes: 497664000, // ~475 MB
    modelType: ModelType.qwen3,
    license: 'Apache-2.0',
    minRamGb: 3,
  );

  static const quality = AiModelInfo(
    id: 'qwen3-0.6b-int8',
    displayName: 'Quality',
    subtitle: 'Qwen3 0.6B int8 · sharper answers',
    url:
        'https://huggingface.co/litert-community/Qwen3-0.6B/resolve/main/Qwen3-0.6B.litertlm',
    sizeBytes: 613416960, // ~585 MB
    modelType: ModelType.qwen3,
    license: 'Apache-2.0',
    minRamGb: 4,
  );

  static const pro = AiModelInfo(
    id: 'qwen2.5-1.5b-q8',
    displayName: 'Pro',
    subtitle: 'Qwen2.5 1.5B · better reasoning',
    url:
        'https://huggingface.co/litert-community/Qwen2.5-1.5B-Instruct/resolve/main/Qwen2.5-1.5B-Instruct_multi-prefill-seq_q8_ekv4096.litertlm',
    sizeBytes: 1597078528, // ~1.5 GB
    modelType: ModelType.qwen,
    license: 'Apache-2.0',
    minRamGb: 6,
  );

  static const max = AiModelInfo(
    id: 'gemma-4-e2b',
    displayName: 'Max',
    subtitle: 'Gemma 4 E2B · smartest, flagship phones only',
    url:
        'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm',
    sizeBytes: 2588000000, // ~2.4 GB
    modelType: ModelType.gemma4,
    license: 'Gemma Terms',
    minRamGb: 8,
  );

  static const models = [light, quality, pro, max];

  static const defaultModel = light;

  static AiModelInfo byId(String? id) =>
      models.firstWhere((m) => m.id == id, orElse: () => defaultModel);
}

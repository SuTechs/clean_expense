import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../data/api/ai/device_capability.dart';
import '../../../data/api/ai/model_registry.dart';
import '../../../data/bloc/ai_bloc.dart';
import '../../../data/command/ai/ai_model_command.dart';
import '../../../theme.dart';

/// "Initialize your AI" view: pick a model tier, then a one-time download
/// with progress.
class AiSetupView extends StatefulWidget {
  const AiSetupView({super.key});

  @override
  State<AiSetupView> createState() => _AiSetupViewState();
}

class _AiSetupViewState extends State<AiSetupView> {
  AiModelInfo _selectedModel = AiModelRegistry.defaultModel;
  int? _deviceRamMb;

  @override
  void initState() {
    super.initState();
    DeviceCapability.physicalRamMb().then((ram) {
      if (mounted) setState(() => _deviceRamMb = ram);
    });
  }

  @override
  Widget build(BuildContext context) {
    final aiBloc = context.watch<AiBloc>();
    final isDownloading = aiBloc.status == AiModelStatus.downloading;
    final model = _selectedModel;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppTheme.accentPurple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 52,
                color: AppTheme.accentPurple,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              "Initialize your AI",
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Download a small AI model once and ask anything about your "
              "spending, even offline.",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 15,
                height: 1.5,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            _bullet(
              Icons.lock_outline_rounded,
              "Runs 100% on your phone. Your financial data never leaves "
              "your device",
            ),
            _bullet(
              Icons.wifi_off_rounded,
              "Works fully offline after the download",
            ),
            _bullet(
              Icons.cloud_download_outlined,
              "One-time ${model.sizeLabel} download, Wi-Fi recommended",
            ),
            const SizedBox(height: 20),
            if (!isDownloading) ...[
              for (final m in AiModelRegistry.models) ...[
                _modelCard(m),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 12),
            ],
            if (isDownloading) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  // Indeterminate while the download is being set up.
                  value: aiBloc.downloadProgress == 0
                      ? null
                      : aiBloc.downloadProgress / 100,
                  minHeight: 8,
                  backgroundColor: AppTheme.inputFill,
                  color: AppTheme.accentPurple,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                aiBloc.downloadProgress == 0
                    ? "Starting download…"
                    : "Downloading… ${aiBloc.downloadProgress}%",
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => AiModelCommand().cancelDownload(),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.outfit(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ] else ...[
              if (aiBloc.errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerRed.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.dangerRed.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    aiBloc.errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: AppTheme.dangerRed,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => AiModelCommand().startDownload(model),
                  icon: const Icon(Icons.download_rounded, size: 20),
                  label: Text(
                    "Download AI model (${model.sizeLabel})",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentPurple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              "${model.displayName} · ${model.license}",
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modelCard(AiModelInfo m) {
    final selected = m.id == _selectedModel.id;
    final fits = m.fitsRam(_deviceRamMb);

    return GestureDetector(
      onTap: fits ? () => setState(() => _selectedModel = m) : null,
      child: Opacity(
        opacity: fits ? 1 : 0.45,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppTheme.accentPurple : AppTheme.dividerColor,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 20,
                color: selected
                    ? AppTheme.accentPurple
                    : AppTheme.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.displayName,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      fits
                          ? m.subtitle
                          : "Needs ${m.minRamGb} GB+ RAM, not enough on "
                                "this phone",
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                m.sizeLabel,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? AppTheme.accentPurple
                      : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bullet(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 13,
                height: 1.4,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

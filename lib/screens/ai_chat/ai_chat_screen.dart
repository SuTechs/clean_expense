import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/api/ai/device_capability.dart';
import '../../data/api/ai/model_registry.dart';
import '../../data/bloc/ai_bloc.dart';
import '../../data/command/ai/ai_model_command.dart';
import '../../data/command/ai/ai_query_command.dart';
import '../../data/command/commands.dart';
import '../../theme.dart';
import 'components/ai_message_bubble.dart';
import 'components/ai_setup_view.dart';

/// On-device AI assistant tab. First visit downloads the model; afterwards
/// the user asks questions about their spending and gets answers with
/// generated charts — fully offline.
class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const _suggestions = [
    "What did I spend this month?",
    "Where am I spending most?",
    "Show today's transactions",
    "My biggest expense this month",
    "What's my savings rate this year?",
    "Spending trend this month",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => AiModelCommand().checkStatus(),
    );
  }

  @override
  void dispose() {
    // The screen is a pushed route now — free the model's RAM on exit.
    // Chat history lives in the bloc and survives; reopening reloads the
    // weights in a few seconds.
    AiModelCommand().unload();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send([String? preset]) {
    final text = preset ?? _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    AiQueryCommand().ask(text);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final aiBloc = context.watch<AiBloc>();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBackground,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppTheme.primaryNavy),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "AI Assistant",
              style: GoogleFonts.outfit(
                color: AppTheme.primaryNavy,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "On-device · Private · Offline",
              style: GoogleFonts.outfit(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          if (aiBloc.status == AiModelStatus.installed ||
              aiBloc.status == AiModelStatus.ready ||
              aiBloc.status == AiModelStatus.loading)
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: AppTheme.primaryNavy,
              ),
              onSelected: (value) {
                if (value == 'clear') _confirmClearChat();
                if (value == 'delete') _confirmDeleteModel();
                if (value == 'switch') _showModelPicker();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: false,
                  height: 32,
                  child: Text(
                    "Model: ${AiModelCommand().installedModel.displayName}",
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                if (aiBloc.messages.isNotEmpty)
                  const PopupMenuItem(
                    value: 'clear',
                    child: Text("Clear chat"),
                  ),
                const PopupMenuItem(
                  value: 'switch',
                  child: Text("Switch model"),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text("Delete AI model"),
                ),
              ],
            ),
        ],
      ),
      body: switch (aiBloc.status) {
        AiModelStatus.unknown => const Center(
          child: CircularProgressIndicator(color: AppTheme.accentPurple),
        ),
        AiModelStatus.unsupported => _UnsupportedView(
          reason:
              aiBloc.unsupportedReason ?? "This device can't run on-device AI.",
        ),
        AiModelStatus.notInstalled ||
        AiModelStatus.downloading => const AiSetupView(),
        _ => _buildChat(aiBloc),
      },
    );
  }

  Widget _buildChat(AiBloc aiBloc) {
    final messages = aiBloc.messages.reversed.toList();

    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? _EmptyChat(onSuggestionTap: _send, suggestions: _suggestions)
              : ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) =>
                      AiMessageBubble(message: messages[index]),
                ),
        ),
        if (aiBloc.status == AiModelStatus.loading)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              "Waking up your assistant, first time can take a minute…",
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        _buildInput(aiBloc),
      ],
    );
  }

  Widget _buildInput(AiBloc aiBloc) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F2D3250),
            offset: Offset(0, -4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: "Ask about your spending…",
                hintStyle: GoogleFonts.outfit(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.inputFill,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: aiBloc.isGenerating ? null : _send,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: aiBloc.isGenerating
                    ? AppTheme.textSecondary
                    : AppTheme.accentPurple,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_upward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear chat?"),
        content: const Text("This removes all messages and starts fresh."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Clear",
              style: TextStyle(color: AppTheme.dangerRed),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    BaseAppCommand.blocAi.clearMessages();
    // Drop the model's conversation context too, so old questions can't
    // influence new answers. It reloads lazily on the next question.
    await AiModelCommand().unload();
  }

  Future<void> _showModelPicker() async {
    final installed = AiModelCommand().installedModel;
    final deviceRamMb = await DeviceCapability.physicalRamMb();
    if (!mounted) return;

    final picked = await showModalBottomSheet<AiModelInfo>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(
              "Choose AI model",
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: 8),
            for (final m in AiModelRegistry.models)
              ListTile(
                enabled: m.fitsRam(deviceRamMb),
                leading: Icon(
                  m.id == installed.id
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: m.id == installed.id
                      ? AppTheme.accentPurple
                      : AppTheme.textSecondary,
                ),
                title: Text(
                  "${m.displayName} · ${m.sizeLabel}",
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                  ),
                ),
                subtitle: Text(
                  m.fitsRam(deviceRamMb)
                      ? m.subtitle
                      : "Needs ${m.minRamGb} GB+ RAM, not enough on "
                            "this phone",
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                onTap: () => Navigator.pop(context, m),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (picked == null || picked.id == installed.id || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Switch to ${picked.displayName}?"),
        content: Text(
          "This removes the current model and downloads "
          "${picked.displayName} (${picked.sizeLabel}). "
          "Wi-Fi recommended.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Switch"),
          ),
        ],
      ),
    );
    if (confirmed == true) await AiModelCommand().switchModel(picked);
  }

  Future<void> _confirmDeleteModel() async {
    final model = AiModelCommand().installedModel;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete AI model?"),
        content: Text(
          "This frees ${model.sizeLabel} of storage. "
          "You can download it again anytime.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: AppTheme.dangerRed),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) await AiModelCommand().deleteModel();
  }
}

class _EmptyChat extends StatelessWidget {
  final List<String> suggestions;
  final void Function(String) onSuggestionTap;

  const _EmptyChat({required this.suggestions, required this.onSuggestionTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              size: 44,
              color: AppTheme.accentPurple,
            ),
            const SizedBox(height: 16),
            Text(
              "Ask me about your money",
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Answers are computed from your data, on your device.",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final s in suggestions)
                  ActionChip(
                    label: Text(
                      s,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                    backgroundColor: AppTheme.cardBackground,
                    side: const BorderSide(color: AppTheme.dividerColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onPressed: () => onSuggestionTap(s),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UnsupportedView extends StatelessWidget {
  final String reason;

  const _UnsupportedView({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.mobile_off_rounded,
              size: 52,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 20),
            Text(
              "On-device AI isn't available here",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              reason,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                height: 1.5,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

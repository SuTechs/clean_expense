import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart' show GoogleSignInException;
import 'package:provider/provider.dart';

import '../../data/bloc/app_bloc.dart';
import '../../data/bloc/sync_bloc.dart';
import '../../data/command/app/set_current_user_command.dart';
import '../../data/command/sync/sync_command.dart';
import '../../data/utils/time_utils.dart';
import '../../theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController = TextEditingController(
    text: context.read<AppBloc>().currentUser.name,
  );
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    final appBloc = context.read<AppBloc>();
    if (name.isEmpty || name == appBloc.currentUser.name) return;

    await SetCurrentUserCommand().run(
      appBloc.currentUser.copyWith(name: name, updatedAt: TimeUtils.nowMillis),
    );
    SyncCommand().scheduleBackup();

    if (mounted) {
      FocusScope.of(context).unfocus();
      _showSnack("Name updated");
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on GoogleSignInException catch (e) {
      // Cancelled sign-in is not an error worth shouting about.
      if (e.code.name != 'canceled') _showSnack("Sign-in failed: ${e.code.name}");
    } catch (e) {
      _showSnack("$e");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _confirmRestore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Restore from Drive?"),
        content: const Text(
          "This replaces the data on this device with your Drive backup.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Restore",
              style: TextStyle(color: AppTheme.dangerRed),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _run(() async {
      final found = await SyncCommand().restoreNow();
      _showSnack(found ? "Backup restored" : "No backup found on Drive");
    });
  }

  Future<void> _confirmDisconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Disconnect Google Drive?"),
        content: const Text(
          "Backups stop, but all data stays on this device.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Disconnect",
              style: TextStyle(color: AppTheme.dangerRed),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) await _run(() => SyncCommand().disconnect());
  }

  @override
  Widget build(BuildContext context) {
    final syncBloc = context.watch<SyncBloc>();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.primaryNavy,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Profile & Backup",
          style: GoogleFonts.outfit(
            color: AppTheme.primaryNavy,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader("PROFILE"),
            _card(
              child: Row(
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    color: AppTheme.primaryNavy,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryNavy,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: "Your name",
                        border: InputBorder.none,
                        hintStyle: GoogleFonts.outfit(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      onSubmitted: (_) => _saveName(),
                    ),
                  ),
                  TextButton(
                    onPressed: _saveName,
                    child: Text(
                      "Save",
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _sectionHeader("GOOGLE DRIVE BACKUP"),
            if (!SyncCommand().isConfigured)
              _notConfiguredCard()
            else if (!syncBloc.isConnected)
              _disconnectedCard()
            else
              _connectedCard(syncBloc),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                "Backups go to a hidden app folder in your Google Drive that "
                "only Clean Expense can see. Your data is never sent "
                "anywhere else.",
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _notConfiguredCard() {
    return _card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppTheme.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Drive backup isn't configured in this build. See "
                "docs/google-drive-sync-setup.md in the repo.",
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _disconnectedCard() {
    return _card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Keep your data safe",
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Back up automatically to your own Google Drive and restore "
              "on any device. Free forever.",
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _busy
                    ? null
                    : () => _run(() => SyncCommand().connect()),
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_outlined, size: 18),
                label: const Text("Connect Google Drive"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryNavy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _connectedCard(SyncBloc syncBloc) {
    final (chipText, chipColor) = switch (syncBloc.status) {
      SyncStatus.syncing => ("Syncing…", AppTheme.accentBlue),
      SyncStatus.offline => ("Offline", AppTheme.textSecondary),
      SyncStatus.error => ("Error", AppTheme.dangerRed),
      _ => ("Synced", AppTheme.primaryGreen),
    };

    return _card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_done_outlined, color: AppTheme.primaryNavy),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        syncBloc.accountEmail ?? "Google Drive",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryNavy,
                        ),
                      ),
                      Text(
                        syncBloc.lastSyncedAt != null
                            ? "Last synced ${TimeUtils.timeAgoFromMillis(syncBloc.lastSyncedAt!)}"
                            : "Not synced yet",
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: chipColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    chipText,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: chipColor,
                    ),
                  ),
                ),
              ],
            ),
            if (syncBloc.status == SyncStatus.error &&
                syncBloc.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                syncBloc.errorMessage!,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppTheme.dangerRed,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _run(
                            () => SyncCommand().syncNow(interactive: true),
                          ),
                    style: _outlinedStyle(),
                    child: const Text("Backup now"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : _confirmRestore,
                    style: _outlinedStyle(),
                    child: const Text("Restore"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _busy ? null : _confirmDisconnect,
                child: Text(
                  "Disconnect",
                  style: GoogleFonts.outfit(
                    color: AppTheme.dangerRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _outlinedStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppTheme.primaryNavy,
      side: const BorderSide(color: AppTheme.dividerColor),
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:provider/provider.dart';
import '../../../data/bloc/app_bloc.dart';
import '../../../data/bloc/sync_bloc.dart';
import '../../settings/settings_screen.dart';
import '../../transactions/transactions_screen.dart';

import '../../../theme.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final appBloc = context.watch<AppBloc>();
    final syncBloc = context.watch<SyncBloc>();

    return AppBar(
      toolbarHeight: kToolbarHeight + 16,
      backgroundColor: AppTheme.scaffoldBackground,
      elevation: 0,
      titleSpacing: 16,
      title: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              // Circle Avatar
              const CircleAvatar(
                backgroundColor: AppTheme.inputFill,
                child: Icon(Icons.person, color: AppTheme.textSecondary),
              ),
              const SizedBox(width: 12),

              //  Greeting & Sign In Prompt
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hello, ${appBloc.currentUser.name}",
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                  Text(
                    _syncLabel(syncBloc),
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: syncBloc.status == SyncStatus.error
                          ? AppTheme.dangerRed
                          : AppTheme.accentPurple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Transaction Button
        IconButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TransactionsScreen()),
          ),
          icon: const Icon(Icons.receipt_long_rounded),
          color: AppTheme.primaryNavy,
        ),

        const SizedBox(width: 8),
      ],
    );
  }

  /// Drive sync state, not auth state: the user id stays "guest" even when
  /// connected (we have no accounts of our own), so SyncBloc is the truth.
  String _syncLabel(SyncBloc syncBloc) {
    switch (syncBloc.status) {
      case SyncStatus.disabled:
        return "Sign in to sync data ->";
      case SyncStatus.syncing:
        return "Syncing…";
      case SyncStatus.offline:
        return "Offline, changes saved locally";
      case SyncStatus.error:
        return "Sync issue, tap to fix";
      case SyncStatus.idle:
        final at = syncBloc.lastSyncedAt;
        return at == null
            ? "Drive sync is on"
            : "Synced ${timeago.format(DateTime.fromMillisecondsSinceEpoch(at))}";
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 16);
}

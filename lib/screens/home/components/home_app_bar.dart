import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';
import '../../../data/bloc/app_bloc.dart';
import '../../settings/settings_screen.dart';
import '../../transactions/transactions_screen.dart';

import '../../../theme.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final appBloc = context.watch<AppBloc>();

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
                    appBloc.isGuestUser
                        ? "Sign in to sync data ->"
                        : "Data is synced",
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.accentPurple,
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

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 16);
}

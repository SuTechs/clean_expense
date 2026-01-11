import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: kToolbarHeight + 16,
      backgroundColor: AppTheme.scaffoldBackground,
      elevation: 0,
      titleSpacing: 16,
      title: Row(
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
                "Hello, Guest",
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryNavy,
                ),
              ),
              Text(
                "Sign in to sync data ->",
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
      actions: [
        // Transaction Button
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.receipt_long_rounded),
          // Similar to the document icon
          color: AppTheme.primaryNavy,
        ),

        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 16);
}

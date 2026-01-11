import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/bloc/app_bloc.dart';
import '../../theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appBloc = context.watch<AppBloc>();

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
          "Settings",
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
            _buildSectionHeader("ACCOUNT"),
            _buildSettingItem(
              icon: Icons.person_outline_rounded,
              title: "Profile & Storage",
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Coming Soon",
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentPurple,
                  ),
                ),
              ),
              onTap: () {},
            ),
            const SizedBox(height: 24),
            _buildSectionHeader("PREFERENCES"),
            _buildSettingItem(
              icon: Icons.currency_exchange_rounded,
              title: "Default Currency",
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.inputFill,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  appBloc.currency,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryNavy,
                  ),
                ),
              ),
              onTap: () => _showCurrencyPicker(context, appBloc),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader("SUPPORT & SOCIAL"),
            _buildSettingItem(
              icon: Icons.star_outline_rounded,
              title: "Rate the App",
              onTap: _rateApp,
            ),
            _buildSettingItem(
              icon: Icons.feedback_outlined,
              title: "Share Feedback",
              onTap: () => _launchEmail(
                "feedback@sutechs.com",
                "Feedback | Clean Expense",
              ),
            ),
            _buildSettingItem(
              icon: Icons.bug_report_outlined,
              title: "Report a Bug",
              onTap: () =>
                  _launchEmail("bug@sutechs.com", "Bug Report | Clean Expense"),
            ),
            const SizedBox(height: 12),
            _buildSettingItem(
              icon: Icons.language_rounded,
              title: "Website",
              onTap: () => _launchUrl("https://sutechs.com"),
            ),
            _buildSettingItem(
              icon: Icons.camera_alt_outlined,
              title: "Instagram",
              onTap: () => _launchUrl("https://instagram.com/sutechs"),
            ),
            _buildSettingItem(
              icon: Icons.link_rounded,
              title: "LinkedIn",
              onTap: () => _launchUrl("https://linkedin.com/in/su-mit"),
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                "Version ${AppBloc.kVersion}",
                style: GoogleFonts.outfit(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
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

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleFunctions.smooth(16),
        leading: Icon(icon, color: AppTheme.primaryNavy),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryNavy,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              )
            : null,
        trailing:
            trailing ??
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textSecondary,
            ),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, AppBloc appBloc) {
    final currencies = ["₹", "\$", "€", "£", "¥", "₩", "₽"];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Select Currency",
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryNavy,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: currencies.map((c) {
                  final isSelected = appBloc.currency == c;
                  return InkWell(
                    onTap: () {
                      appBloc.currency = c;
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.accentPurple
                            : AppTheme.inputFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        c,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.primaryNavy,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchEmail(String email, String subject) async {
    final Uri uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=${Uri.encodeComponent(subject)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _rateApp() async {
    final InAppReview inAppReview = InAppReview.instance;
    inAppReview.openStoreListing();
  }
}

class RoundedRectangleFunctions {
  static ShapeBorder smooth(double radius) =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/command/app/onboarding_command.dart';
import '../../theme.dart';
import 'components/ai_demo.dart';
import 'components/currency_input_page.dart';
import 'components/name_input_page.dart';
import 'components/onboarding_page.dart';
import 'components/type_selector_demo.dart';
import 'components/typing_demo.dart';

/// Hook for the "Enable Google Drive backup" flow on the final page.
/// Returns true on success (onboarding then completes immediately), false
/// when the user cancelled sign-in, and throws with a readable message on
/// failure. When null, the row renders disabled.
typedef RestoreBackupHandler = Future<bool> Function(BuildContext context);

/// First-launch onboarding: value prop, how-to demo, transaction types,
/// optional name, and a finish page with the backup-restore slot.
class OnboardingScreen extends StatefulWidget {
  final RestoreBackupHandler? onRestoreBackup;

  const OnboardingScreen({super.key, this.onRestoreBackup});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pageCount = 7;
  static const _typeSelectorPageIndex = 2;
  static const _namePageIndex = 4;

  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();

  int _currentPage = 0;
  int _maxVisitedPage = 0;
  bool _completing = false;

  bool _connectingDrive = false;
  String? _driveError;

  bool get _isLastPage => _currentPage == _pageCount - 1;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
      if (page > _maxVisitedPage) _maxVisitedPage = page;
    });
  }

  void _next() {
    if (_isLastPage) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    if (_completing) return;
    _completing = true;

    try {
      // Flipping the onboarding flag rebuilds _AppBootstrapper into
      // MainScreen.
      await OnboardingCommand().complete(
        name: _nameController.text,
        sawTypeSelectorPage: _maxVisitedPage >= _typeSelectorPageIndex,
      );
    } catch (e) {
      // Without the reset, one failed write makes every later Get
      // Started/Skip tap a silent no-op for the rest of the session.
      _completing = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Couldn't finish setup: $e"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleEnableDriveSync() async {
    final handler = widget.onRestoreBackup;
    if (handler == null || _connectingDrive) return;

    setState(() {
      _connectingDrive = true;
      _driveError = null;
    });

    try {
      final connected = await handler(context);
      // Sync is on and any existing backup is already merged in — done.
      if (connected && mounted) _finish();
    } catch (e) {
      if (mounted) setState(() => _driveError = '$e');
    } finally {
      if (mounted) setState(() => _connectingDrive = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Transparent status bar so onboarding reads as full-screen.
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        body: SafeArea(
          child: PopScope(
            // Back navigates a page back; on the first page it exits without
            // completing, so onboarding shows again next launch.
            canPop: _currentPage == 0,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
              );
            },
            child: Column(
              children: [
                SizedBox(
                  height: 48,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _isLastPage
                        ? null
                        : TextButton(
                            onPressed: _finish,
                            child: const Text(
                              "Skip",
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    children: [
                      OnboardingPage(
                        illustration: _buildLogo(),
                        title: "Welcome to Clean Expense",
                        subtitle:
                            "Track spending as fast as sending a text. "
                            "Offline, private and free forever.",
                      ),
                      const OnboardingPage(
                        illustration: TypingDemo(),
                        title: "Add expenses like a chat",
                        subtitle:
                            "Type a note, a #category and an amount "
                            "in any order. That's it.",
                      ),
                      const OnboardingPage(
                        illustration: TypeSelectorDemo(),
                        title: "More than just expenses",
                        subtitle:
                            "One tap switches between Expense, Income "
                            "and Invest.",
                      ),
                      const OnboardingPage(
                        illustration: AiDemo(),
                        title: "Your money, ask it anything",
                        subtitle:
                            "A built-in AI assistant that runs entirely on "
                            "your phone. Private, offline and free.",
                      ),
                      NameInputPage(
                        controller: _nameController,
                        isActive: _currentPage == _namePageIndex,
                      ),
                      const CurrencyInputPage(),
                      _buildFinishPage(),
                    ],
                  ),
                ),
                _buildDots(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryNavy,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _isLastPage ? "Get Started" : "Next",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryNavy.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          'logo-big.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.account_balance_wallet_rounded,
            color: AppTheme.primaryNavy,
            size: 48,
          ),
        ),
      ),
    );
  }

  Widget _buildFinishPage() {
    final hasDriveSync = widget.onRestoreBackup != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 56,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
          ),
          const Text(
            "You're all set!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryNavy,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Your data stays on your device. Private and free forever.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          if (hasDriveSync) _buildDriveSyncCard(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Sells the free Drive backup to new users; the merge it runs doubles as
  /// the restore for returning ones.
  Widget _buildDriveSyncCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(
                Icons.cloud_done_outlined,
                size: 22,
                color: AppTheme.accentBlue,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Free Google Drive backup",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Backs up automatically to your own Drive. Used Clean Expense "
            "before? Your data is restored too.",
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppTheme.textSecondary,
            ),
          ),
          if (_driveError != null) ...[
            const SizedBox(height: 10),
            Text(
              _driveError!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.dangerRed,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _connectingDrive ? null : _handleEnableDriveSync,
              icon: _connectingDrive
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_sync_outlined, size: 18),
              label: Text(
                _connectingDrive
                    ? "Connecting…"
                    : "Enable Drive backup & restore",
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryNavy,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pageCount, (i) {
        final isActive = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryNavy : AppTheme.primaryNavy100,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

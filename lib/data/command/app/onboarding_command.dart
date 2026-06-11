import '../../utils/time_utils.dart';
import '../commands.dart';
import 'set_current_user_command.dart';

class OnboardingCommand extends BaseAppCommand {
  /// Completes onboarding (called on both "Get Started" and "Skip").
  ///
  /// [sawTypeSelectorPage] suppresses the in-chat type-selector coach mark
  /// for users who already saw the explanation page; skippers still get it.
  Future<void> complete({String? name, bool sawTypeSelectorPage = false}) async {
    final trimmed = name?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      await SetCurrentUserCommand().run(
        appBloc.currentUser.copyWith(
          name: trimmed,
          updatedAt: TimeUtils.nowMillis,
        ),
      );
    }

    if (sawTypeSelectorPage) appBloc.hasSeenTypeSelectorHint = true;

    appBloc.completeOnboarding();
  }
}

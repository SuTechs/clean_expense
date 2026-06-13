import '../../utils/time_utils.dart';
import '../commands.dart';
import 'set_current_user_command.dart';

class OnboardingCommand extends BaseAppCommand {
  /// Completes onboarding (called on both "Get Started" and "Skip").
  ///
  /// Note: this does NOT mark the type-selector hint as seen. The onboarding
  /// demo only builds awareness that income/invest exist; the one-time
  /// in-chat coach mark still teaches *where* the control is, so every new
  /// user gets it on first opening the chat.
  Future<void> complete({String? name}) async {
    final trimmed = name?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      await SetCurrentUserCommand().run(
        appBloc.currentUser.copyWith(
          name: trimmed,
          updatedAt: TimeUtils.nowMillis,
        ),
      );
    }

    appBloc.completeOnboarding();
  }
}

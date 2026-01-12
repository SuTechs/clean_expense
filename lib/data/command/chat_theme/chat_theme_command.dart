import '../commands.dart';

/// Command for managing chat theme persistence.
class ChatThemeCommand extends BaseAppCommand {
  static const _prefKey = 'chat_theme_id';

  /// Get the saved chat theme ID from Hive
  String? getThemeId() {
    return hive.stringBox.get(_prefKey);
  }

  /// Save the chat theme ID to Hive
  Future<void> setThemeId(String themeId) async {
    await hive.stringBox.put(_prefKey, themeId);
  }
}

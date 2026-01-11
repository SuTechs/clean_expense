import 'package:expense/data/command/commands.dart';

class RefreshExpenseCommand extends BaseAppCommand {
  /// get expenses from hive (or server later on)
  /// ToDo: (sync local and server changes as well)
  Future<void> refresh() async {}
}

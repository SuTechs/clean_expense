import 'dart:developer';

import '../../data/user/user.dart';
import '../commands.dart';

class SetCurrentUserCommand extends BaseAppCommand {
  Future<void> run(UserData user) async {
    log("SetCurrentUserCommand: $user");
    // Update appBloc with new user. If user is null, this acts as a logout command.

    appBloc.currentUser = user;

    appBloc.save();
  }

  Future<void> logout() async {
    // reset other bloc as well
    // otherBloc.reset();

    // reset app bloc
    appBloc.reset();
  }
}

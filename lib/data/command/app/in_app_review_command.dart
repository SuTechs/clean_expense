import 'package:in_app_review/in_app_review.dart';

import '../commands.dart';

class InAppReviewCommand extends BaseAppCommand {
  // Future<void> requestReview() async {
  //   try {
  //     final InAppReview inAppReview = InAppReview.instance;
  //
  //     if (await inAppReview.isAvailable()) {
  //       inAppReview.requestReview();
  //     }
  //   } catch (e, s) {
  //     log('Error = $e and stacktrace = $s');
  //   }
  // }

  // bool shouldRequestReview() {
  //   try {
  //     if (appBloc.currentUser.totalXp < 100) return false;
  //
  //     return hive.canShowReview(); // logic to check when was last review asked
  //   } catch (e, s) {
  //     log('Error = $e and stacktrace = $s');
  //     return false;
  //   }
  // }

  void openStore() {
    final InAppReview inAppReview = InAppReview.instance;
    inAppReview.openStoreListing(appStoreId: '6757723320');
    // hive.updateReviewStatus();
  }
}

import 'package:get/get.dart';

import '../controllers/challenges_rewards_controller.dart';

class ChallengesRewardsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChallengesRewardsController>(() => ChallengesRewardsController());
  }
}

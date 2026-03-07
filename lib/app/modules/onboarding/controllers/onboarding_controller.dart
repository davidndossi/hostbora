import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../routes/app_pages.dart';

class OnboardingController extends BaseController {
  final PreferenceManager _preferenceManager =
      Get.find(tag: (PreferenceManager).toString());

  final PageController pageController = PageController();
  final currentPage = 0.obs;

  final List<OnboardingSlide> slides = [
    OnboardingSlide(
      title: 'Welcome to Paa Yangu',
      description:
          'Stay connected with your community. Get announcements, events, and resources in one place.',
      icon: Icons.groups_rounded,
    ),
    OnboardingSlide(
      title: 'Events & Announcements',
      description:
          'Never miss an event or important update. See what\'s happening in your community.',
      icon: Icons.calendar_today_rounded,
    ),
    OnboardingSlide(
      title: 'Join Communities',
      description:
          'Discover and join communities. Invite members and manage your groups easily.',
      icon: Icons.people_alt_rounded,
    ),
  ];

  void onPageChanged(int index) {
    currentPage.value = index;
  }

  Future<void> completeOnboarding() async {
    await _preferenceManager.setBool('seen_onboarding', true);
    Get.offAllNamed(Routes.AUTH);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}

class OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;

  OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
  });
}

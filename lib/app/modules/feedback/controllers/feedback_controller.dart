import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/feedback_pending_store.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/model/login_response.dart';
import '../../../data/repository/app_repository.dart';

enum FeedbackCategory { general, bug, feature, other }

class FeedbackController extends BaseController {
  final formKey = GlobalKey<FormState>();
  final messageController = TextEditingController();
  final emailController = TextEditingController();

  final selectedCategory = Rxn<FeedbackCategory>();
  final isSubmitting = false.obs;

  final PreferenceManager _preferenceManager = Get.find(
    tag: (PreferenceManager).toString(),
  );

  final AppRepository _repository = Get.find(
    tag: (AppRepository).toString(),
  );

  late final FeedbackPendingStore _pendingStore = FeedbackPendingStore(
    _preferenceManager,
  );

  static const String supportEmail = 'support@hostbora.co.tz';

  @override
  void onInit() {
    super.onInit();
    _prefillEmail();
  }

  @override
  void onClose() {
    messageController.dispose();
    emailController.dispose();
    super.onClose();
  }

  Future<void> _prefillEmail() async {
    try {
      final User user = await _preferenceManager.getUser();
      final email = user.email?.trim();
      if (email != null && email.isNotEmpty) {
        emailController.text = email;
      }
    } catch (e, st) {
      logger.e('_prefillEmail $e $st');
    }
  }

  String? validateMessage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return appLocalization.feedbackMessageRequired;
    }
    return null;
  }

  String? validateEmail(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final emailPattern = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailPattern.hasMatch(trimmed)) {
      return appLocalization.feedbackInvalidEmail;
    }
    return null;
  }

  String categoryLabel(FeedbackCategory category) {
    switch (category) {
      case FeedbackCategory.general:
        return appLocalization.feedbackCategoryGeneral;
      case FeedbackCategory.bug:
        return appLocalization.feedbackCategoryBug;
      case FeedbackCategory.feature:
        return appLocalization.feedbackCategoryFeature;
      case FeedbackCategory.other:
        return appLocalization.feedbackCategoryOther;
    }
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (isSubmitting.value) return;
    isSubmitting(true);
    try {
      final message = messageController.text.trim();
      final email = emailController.text.trim();
      final category = selectedCategory.value;
      final categoryText = category == null
          ? appLocalization.feedbackCategoryNone
          : categoryLabel(category);

      String appVersion = '—';
      try {
        final info = await PackageInfo.fromPlatform();
        appVersion = '${info.version} (${info.buildNumber})';
      } catch (_) {}

      final bodyLines = <String>[
        'Category: $categoryText',
        if (email.isNotEmpty) 'Reply-to: $email',
        '',
        message,
        '',
        '---',
        'App: Host Bora $appVersion',
        'Platform: ${GetPlatform.isIOS ? 'iOS' : 'Android'}',
      ];
      final body = bodyLines.join('\n');
      final subject = Uri.encodeComponent('Host Bora feedback');
      final mailto = Uri.parse(
        'mailto:$supportEmail?subject=$subject&body=${Uri.encodeComponent(body)}',
      );

      final entry = <String, dynamic>{
        'category': categoryText,
        'email': email,
        'message': message,
        'appVersion': appVersion,
      };

      if (await canLaunchUrl(mailto)) {
        await launchUrl(mailto, mode: LaunchMode.externalApplication);
        showSuccessMessage(appLocalization.feedbackThankYou);
      } else {
        await _pendingStore.saveEntry(entry);
        showSuccessMessage(appLocalization.feedbackThankYou);
      }

      // Always attempt API submission alongside mailto/pending-store path.
      try {
        await _repository.submitFeedback({
          'category': categoryText,
          'email': email,
          'message': message,
          'appVersion': appVersion,
        });
      } catch (_) {
        // Non-blocking — feedback already stored locally above.
      }
    } catch (e, st) {
      logger.e('submitFeedback $e $st');
      try {
        await _pendingStore.saveEntry({
          'message': messageController.text.trim(),
          'email': emailController.text.trim(),
        });
        showSuccessMessage(appLocalization.feedbackThankYou);
      } catch (_) {
        showErrorMessage(appLocalization.feedbackSubmitFailed);
      }
    } finally {
      isSubmitting(false);
    }
  }
}

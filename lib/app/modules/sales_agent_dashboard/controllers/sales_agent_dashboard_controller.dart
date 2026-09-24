import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/values/app_colors.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/local/service/currency_service.dart';
import '../../../data/model/sales_agent_models.dart';
import '../../../data/repository/app_repository.dart';
import '/app/core/base/base_controller.dart';

class SalesAgentDashboardController extends BaseController {
  final AppRepository _repository = Get.find(tag: (AppRepository).toString());
  final PreferenceManager _preferenceManager = Get.find(
    tag: (PreferenceManager).toString(),
  );

  final dashboard = Rxn<SalesAgentDashboard>();
  final isLoading = false.obs;
  final isInviting = false.obs;

  String _t(String en, String sw) => Get.locale?.languageCode == 'sw' ? sw : en;

  @override
  void onReady() {
    super.onReady();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    isLoading(true);
    try {
      final user = await _preferenceManager.getUser();
      final userId = user.id ?? '';
      if (userId.isEmpty) {
        showErrorMessage(_t('User not found', 'Mtumiaji hajapatikana'));
        return;
      }
      final res = await _repository.getSalesAgentDashboard(userId);
      final data = res.data;
      if (data is Map<String, dynamic>) {
        dashboard.value = SalesAgentDashboard.fromJson(data);
      } else {
        showErrorMessage(
          _t('Could not load dashboard', 'Imeshindikana kupakia dashibodi'),
        );
      }
    } catch (_) {
      showErrorMessage(
        _t('Could not load dashboard', 'Imeshindikana kupakia dashibodi'),
      );
    } finally {
      isLoading(false);
    }
  }

  String get referralCode => dashboard.value?.agent.agentCode ?? '';

  String get inviteUrl {
    final dash = dashboard.value;
    if (dash == null) return '';
    if (dash.inviteUrl.isNotEmpty) return dash.inviteUrl;
    if (referralCode.isEmpty) return '';
    return 'https://hostbora.co.tz/r/$referralCode';
  }

  String inviteMessage() {
    final code = referralCode;
    return _t(
      'Join Host Bora with my referral code $code\n$inviteUrl',
      'Jiunge Host Bora kwa kutumia msimbo wangu $code\n$inviteUrl',
    );
  }

  Future<void> copyReferralCode() async {
    final code = referralCode;
    if (code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    showSuccessMessage(_t('Code copied', 'Msimbo umenakiliwa'));
  }

  Future<void> invitePropertyOwner() async {
    if (referralCode.isEmpty || isInviting.value) return;
    isInviting(true);
    try {
      final res = await _repository.recordSalesAgentInvite();
      final data = res.data;
      if (data is Map<String, dynamic>) {
        dashboard.value = SalesAgentDashboard.fromJson(data);
      }
    } catch (_) {
      // Sharing still proceeds even if the invite counter is temporarily unavailable.
    } finally {
      isInviting(false);
    }
    await Share.share(inviteMessage(), subject: 'Host Bora');
  }

  void showInviteQr() {
    final url = inviteUrl;
    if (url.isEmpty) return;
    Get.dialog(
      AlertDialog(
        title: Text(_t('Invite QR', 'QR ya mwaliko')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: url,
              size: 220,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppColors.designAccent,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppColors.designAccent,
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              url,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(_t('Close', 'Funga')),
          ),
        ],
      ),
    );
  }

  String formatTzs(int amount) => Get.find<CurrencyService>().formatBase(amount);
}

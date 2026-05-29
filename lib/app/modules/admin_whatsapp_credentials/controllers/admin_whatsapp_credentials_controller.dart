import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';

class AdminWhatsappCredentialRow {
  AdminWhatsappCredentialRow({
    required this.userId,
    required this.username,
    required this.fullName,
    required this.status,
    required this.configured,
    this.phoneNumber,
    this.phoneNumberId,
    this.provider,
    this.lastError,
    this.apiKeyPreview,
  });

  final String userId;
  final String username;
  final String fullName;
  final String status;
  final bool configured;
  final String? phoneNumber;
  final String? phoneNumberId;
  final String? provider;
  final String? lastError;
  final String? apiKeyPreview;

  factory AdminWhatsappCredentialRow.fromMap(Map<String, dynamic> m) {
    return AdminWhatsappCredentialRow(
      userId: m['userId']?.toString() ?? '',
      username: m['username']?.toString() ?? '',
      fullName: m['fullName']?.toString() ?? '',
      status: m['status']?.toString() ?? 'PENDING',
      configured: m['configured'] == true,
      phoneNumber: m['phoneNumber']?.toString(),
      phoneNumberId: m['phoneNumberId']?.toString(),
      provider: m['provider']?.toString(),
      lastError: m['lastError']?.toString(),
      apiKeyPreview: m['apiKeyPreview']?.toString(),
    );
  }
}

class AdminWhatsappCredentialsController extends BaseController {
  final AppRepository _repository = Get.find(tag: (AppRepository).toString());

  final rows = <AdminWhatsappCredentialRow>[].obs;
  final configuredCount = 0.obs;
  final isLoadingList = false.obs;
  final searchQuery = ''.obs;

  String _t(String en, String sw) => Get.locale?.languageCode == 'sw' ? sw : en;

  List<AdminWhatsappCredentialRow> get filteredRows {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows
        .where(
          (r) =>
              r.username.toLowerCase().contains(q) ||
              r.fullName.toLowerCase().contains(q) ||
              r.userId.toLowerCase().contains(q) ||
              (r.phoneNumberId ?? '').toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  void onReady() {
    super.onReady();
    loadCredentials();
  }

  Future<void> loadCredentials() async {
    isLoadingList(true);
    try {
      final res = await _repository.getAdminWhatsAppCredentials();
      if (res.responseCode == '403') {
        showErrorMessage(
          _t('Admin access required', 'Uhitaji ruhusa ya msimamizi'),
        );
        Get.offNamed(Routes.SETTINGS);
        return;
      }
      if (res.responseCode != '0' || res.data is! Map) {
        showErrorMessage(
          res.message ?? _t('Failed to load credentials', 'Imeshindikana kupakia'),
        );
        rows.clear();
        configuredCount.value = 0;
        return;
      }
      final data = Map<String, dynamic>.from(res.data as Map);
      configuredCount.value = (data['configuredCount'] as num?)?.toInt() ?? 0;
      final rawRows = data['rows'];
      if (rawRows is List) {
        rows.assignAll(
          rawRows
              .whereType<Map>()
              .map((e) => AdminWhatsappCredentialRow.fromMap(
                    Map<String, dynamic>.from(e),
                  )),
        );
      } else {
        rows.clear();
      }
    } catch (e) {
      showErrorMessage(e.toString());
      rows.clear();
    } finally {
      isLoadingList(false);
    }
  }
}

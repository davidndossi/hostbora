import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../core/utils/haptic_feedback_util.dart';
import '../../../../data/local/db/rent_whatsapp_template_local_data_source.dart';

class RentWhatsappTemplateBuilderController extends BaseController {
  RentWhatsappTemplateBuilderController()
      : _local = Get.find<RentWhatsappTemplateLocalDataSource>();

  final RentWhatsappTemplateLocalDataSource _local;

  final loading = true.obs;
  final templates = <RentWhatsappTemplateRecord>[].obs;

  /// Active filter: null = all, otherwise one of [WaTemplateStatus.*].
  final statusFilter = RxnString();

  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  void onReady() {
    super.onReady();
    loadAll();
  }

  Future<void> loadAll() async {
    loading.value = true;
    try {
      final rows = await _local.getAllNewestFirst();
      templates.assignAll(rows);
    } finally {
      loading.value = false;
    }
  }

  List<RentWhatsappTemplateRecord> get filteredTemplates {
    final f = statusFilter.value;
    if (f == null) return templates;
    return templates.where((t) => t.status == f).toList();
  }

  int countByStatus(String status) =>
      templates.where((t) => t.status == status).length;

  void setStatusFilter(String? status) => statusFilter.value = status;

  /// Validates inputs and returns an error message (localized) or `null` when OK.
  String? validateDraft({
    required String name,
    required String bodyText,
    required String headerType,
    required String headerText,
    required String footerText,
    required List<String> sampleVariables,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return _isSw ? 'Weka jina la kiolezo' : 'Template name is required';
    }
    final valid = RegExp(r'^[a-z0-9_]{3,64}$');
    if (!valid.hasMatch(trimmedName)) {
      return _isSw
          ? 'Jina liruhusu herufi ndogo, nambari na _ (3-64)'
          : 'Use 3-64 chars: lowercase letters, digits, underscore';
    }
    if (bodyText.trim().isEmpty) {
      return _isSw ? 'Mwili wa ujumbe unahitajika' : 'Body text is required';
    }
    if (bodyText.length > 1024) {
      return _isSw
          ? 'Mwili usizidi herufi 1024'
          : 'Body must be 1024 characters or fewer';
    }
    if (headerType == WaTemplateHeaderType.text && headerText.trim().isEmpty) {
      return _isSw
          ? 'Ongeza maandishi ya kichwa au chagua hakuna kichwa'
          : 'Enter header text or remove the header';
    }
    if (headerText.length > 60) {
      return _isSw
          ? 'Kichwa kisizidi herufi 60'
          : 'Header must be 60 characters or fewer';
    }
    if (footerText.length > 60) {
      return _isSw
          ? 'Kijachini kisizidi herufi 60'
          : 'Footer must be 60 characters or fewer';
    }

    // Validate {{n}} variables are sequential and samples cover each one.
    final vars = RegExp(r'\{\{(\d+)\}\}')
        .allMatches(bodyText)
        .map((m) => int.parse(m.group(1)!))
        .toSet()
        .toList()
      ..sort();
    if (vars.isNotEmpty) {
      for (var i = 0; i < vars.length; i++) {
        if (vars[i] != i + 1) {
          return _isSw
              ? 'Vigezo viwe kwa mpangilio {{1}}, {{2}}, ...'
              : 'Variables must be sequential: {{1}}, {{2}}, ...';
        }
      }
      if (sampleVariables.length < vars.length) {
        return _isSw
            ? 'Toa mfano kwa kila kigezo kilichotumika'
            : 'Provide a sample value for each variable used';
      }
      for (var i = 0; i < vars.length; i++) {
        if (sampleVariables[i].trim().isEmpty) {
          return _isSw
              ? 'Mfano wa kigezo {{${i + 1}}} haupo'
              : 'Sample value for {{${i + 1}}} is missing';
        }
      }
    }
    return null;
  }

  Future<int> saveDraft({
    int? id,
    required String name,
    required String category,
    required String language,
    required String headerType,
    required String headerText,
    required String bodyText,
    required String footerText,
    required List<WaTemplateButton> buttons,
    required List<String> sampleVariables,
  }) async {
    final error = validateDraft(
      name: name,
      bodyText: bodyText,
      headerType: headerType,
      headerText: headerText,
      footerText: footerText,
      sampleVariables: sampleVariables,
    );
    if (error != null) {
      showErrorMessage(error);
      return -1;
    }
    try {
      if (id == null) {
        final newId = await _local.insert(
          name: name.trim(),
          category: category,
          language: language,
          headerType: headerType,
          headerText: headerText.trim(),
          bodyText: bodyText.trim(),
          footerText: footerText.trim(),
          buttons: buttons,
          sampleVariables: sampleVariables,
        );
        showSuccessMessage(
            _isSw ? 'Kiolezo kimehifadhiwa' : 'Template saved as draft');
        await loadAll();
        return newId;
      } else {
        await _local.update(
          id: id,
          name: name.trim(),
          category: category,
          language: language,
          headerType: headerType,
          headerText: headerText.trim(),
          bodyText: bodyText.trim(),
          footerText: footerText.trim(),
          buttons: buttons,
          sampleVariables: sampleVariables,
          status: WaTemplateStatus.draft,
        );
        showSuccessMessage(
            _isSw ? 'Kiolezo kimesasishwa' : 'Template updated');
        await loadAll();
        return id;
      }
    } catch (e) {
      showErrorMessage(e.toString());
      return -1;
    }
  }

  Future<bool> submitForApproval({
    required int id,
    required String name,
    required String category,
    required String language,
    required String headerType,
    required String headerText,
    required String bodyText,
    required String footerText,
    required List<WaTemplateButton> buttons,
    required List<String> sampleVariables,
  }) async {
    final error = validateDraft(
      name: name,
      bodyText: bodyText,
      headerType: headerType,
      headerText: headerText,
      footerText: footerText,
      sampleVariables: sampleVariables,
    );
    if (error != null) {
      showErrorMessage(error);
      return false;
    }
    await _local.update(
      id: id,
      name: name.trim(),
      category: category,
      language: language,
      headerType: headerType,
      headerText: headerText.trim(),
      bodyText: bodyText.trim(),
      footerText: footerText.trim(),
      buttons: buttons,
      sampleVariables: sampleVariables,
      status: WaTemplateStatus.approved, // WaTemplateStatus.submitted,
      submittedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    showSuccessMessage(
        _isSw ? 'Kimetumwa kwa ukaguzi' : 'Submitted for approval');
    await loadAll();
    return true;
  }

  Future<void> simulateApproval(int id) async {
    await _local.updateStatus(id: id, status: WaTemplateStatus.approved);
    showSuccessMessage(_isSw ? 'Kiolezo kimeidhinishwa' : 'Template approved');
    await loadAll();
  }

  Future<void> simulateRejection(int id, {required String reason}) async {
    await _local.updateStatus(
      id: id,
      status: WaTemplateStatus.rejected,
      rejectionReason: reason,
    );
    showSuccessMessage(_isSw ? 'Kiolezo kimekataliwa' : 'Template rejected');
    await loadAll();
  }

  Future<void> duplicate(RentWhatsappTemplateRecord t) async {
    final newName = '${t.name}_copy';
    await _local.insert(
      name: newName,
      category: t.category,
      language: t.language,
      headerType: t.headerType,
      headerText: t.headerText,
      bodyText: t.bodyText,
      footerText: t.footerText,
      buttons: t.buttons,
      sampleVariables: t.sampleVariables,
    );
    showSuccessMessage(_isSw ? 'Nakala imetengenezwa' : 'Duplicate created');
    await loadAll();
  }

  Future<void> delete(int id) async {
    hapticPrimaryConfirm();
    await _local.deleteById(id);
    await loadAll();
  }

  Future<void> restoreTemplate(RentWhatsappTemplateRecord t) async {
    await _local.insert(
      name: t.name,
      category: t.category,
      language: t.language,
      headerType: t.headerType,
      headerText: t.headerText,
      bodyText: t.bodyText,
      footerText: t.footerText,
      buttons: t.buttons,
      sampleVariables: t.sampleVariables,
      status: t.status,
    );
    showSuccessMessage(_isSw ? 'Kiolezo kimerudishwa' : 'Template restored');
    await loadAll();
  }

  /// Returns the body text with `{{n}}` replaced by sample values.
  static String renderPreview(String body, List<String> samples) {
    var out = body;
    for (var i = 0; i < samples.length; i++) {
      out = out.replaceAll('{{${i + 1}}}', samples[i]);
    }
    return out;
  }
}

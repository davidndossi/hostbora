import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/access/staff_access.dart';
import '../../../../core/utils/auth_messages.dart';
import '../../../../core/base/base_controller.dart';
import '../../../../data/local/db/property_local_data_source.dart';
import '../../../../data/local/preference/preference_manager.dart';
import '../widgets/staff_access_editor.dart';
import '../../../../core/base/feedback_extensions.dart';
import '../../../../core/utils/haptic_feedback_util.dart';
import '../../../../data/local/service/remote_account_sync_service.dart';
import '../../../../data/model/staff_request.dart';
import '../../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../../data/local/db/rent_staff_local_data_source.dart';
import '../../../../data/local/service/offline_sync_worker_service.dart';
import '../../../../data/repository/app_repository.dart';
import '../utils/rent_staff_pay_format.dart';
import '../widgets/staff_edit_sheet.dart';

/// One row in the rent staff list.
class RentStaffListItem {
  const RentStaffListItem({
    required this.id,
    required this.name,
    required this.jobTitle,
    required this.payAmountLabel,
    required this.payDayDisplay,
    required this.paymentType,
    required this.amountValue,
  });

  final String id;
  final String name;
  final String jobTitle;
  final String payAmountLabel;
  final String payDayDisplay;
  final String paymentType;
  final double amountValue;
}

class RentStaffManagementController extends BaseController {
  RentStaffManagementController()
    : _local = Get.find<RentStaffLocalDataSource>(),
      _repository = Get.find<AppRepository>(tag: (AppRepository).toString()),
      _syncQueue = Get.find<OfflineSyncQueueLocalDataSource>(),
      _syncWorker = Get.find<OfflineSyncWorkerService>();

  final RentStaffLocalDataSource _local;
  final AppRepository _repository;
  final OfflineSyncQueueLocalDataSource _syncQueue;
  final OfflineSyncWorkerService _syncWorker;
  final formKey = GlobalKey<FormState>();

  final staff = <RentStaffListItem>[].obs;
  final initialLoad = true.obs;

  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final notesController = TextEditingController();
  final amountController = TextEditingController();
  final payDateController = TextEditingController();

  final paymentType = RentStaffPayFormat.monthly.obs;
  final selectedPrimaryRole = ''.obs;
  final editingStaffId = Rxn<int>();
  final permissionRole = StaffPermissions.roleCleaner.obs;
  final grantedPermissions = StaffPermissions.preset(StaffPermissions.roleCleaner).obs;
  final allPropertiesAccess = false.obs;
  final selectedPropertyRefs = <String>{}.obs;
  final accessProperties = <StaffPropertyOption>[].obs;
  final legacyStaffAccess = false.obs;

  String _propertyRef = '';
  String _propertyName = '';

  static const primaryRoleOptions = [
    'Estate Manager',
    'Housekeeping',
    'Security',
    'Gardener',
    'Chef',
    'Receptionist',
    'Maintenance',
    'Other',
  ];

  String get amountFieldLabel {
    switch (paymentType.value) {
      case RentStaffPayFormat.hourly:
        return 'RATE (TSH/HR)';
      case RentStaffPayFormat.perWork:
        return 'RATE (TSH/JOB)';
      default:
        return 'MONTHLY SALARY (TSH)';
    }
  }

  String get amountHint {
    switch (paymentType.value) {
      case RentStaffPayFormat.hourly:
        return 'e.g. 5,000';
      case RentStaffPayFormat.perWork:
        return 'e.g. 50,000';
      default:
        return '450,000';
    }
  }

  /// Sum of monthly contracts only (excludes hourly / per-job rates).
  double get totalMonthlySalaryPool {
    return staff
        .where((s) => s.paymentType == RentStaffPayFormat.monthly)
        .fold(0.0, (a, b) => a + b.amountValue);
  }

  int get monthlyContractCount =>
      staff.where((s) => s.paymentType == RentStaffPayFormat.monthly).length;

  bool get isEditMode => editingStaffId.value != null;

  /// Used to scroll the registry form into view when Edit is tapped.
  final formSectionKey = GlobalKey();

  /// Staff list header. Scrolled into view only after a member is saved.
  final activeTeamSectionKey = GlobalKey();

  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      if (args['staffId'] != null) {
        final id = int.tryParse('${args['staffId']}');
        if (id != null) editingStaffId.value = id;
      }
      _propertyRef = (args['property_ref'] ??
              args['propertyRef'] ??
              args['property_id'] ??
              '')
          .toString()
          .trim();
      _propertyName = (args['property_name'] ??
              args['propertyName'] ??
              args['property'] ??
              '')
          .toString()
          .trim();
    }
    // Seed property scope so Register works when StaffAccessEditor isn't shown
    // (e.g. listing Staff tab) and Cleaner/Caretaker default to selected props.
    _resetAccess();
  }

  @override
  void onReady() {
    super.onReady();
    _loadAccessProperties();
    // Route args may be refreshed when navigating Add Staff with property context.
    _absorbRoutePropertyArgs();
    loadStaff().then((_) async {
      final id = editingStaffId.value;
      if (id != null) {
        // Opened via arguments (e.g. Team & Staff → Edit).
        await editStaffById('$id');
      }
    });
  }

  /// Keeps property scope in sync when this controller is reused across routes.
  void bindPropertyContext({String? propertyRef, String? propertyName}) {
    final ref = (propertyRef ?? '').trim();
    final name = (propertyName ?? '').trim();
    if (ref.isNotEmpty) _propertyRef = ref;
    if (name.isNotEmpty) _propertyName = name;
    if (_propertyRef.isNotEmpty &&
        !allPropertiesAccess.value &&
        !selectedPropertyRefs.contains(_propertyRef)) {
      selectedPropertyRefs.add(_propertyRef);
    }
  }

  void _absorbRoutePropertyArgs() {
    final args = Get.arguments;
    if (args is! Map) return;
    bindPropertyContext(
      propertyRef: (args['property_ref'] ??
              args['propertyRef'] ??
              args['property_id'] ??
              '')
          .toString(),
      propertyName: (args['property_name'] ??
              args['propertyName'] ??
              args['property'] ??
              '')
          .toString(),
    );
  }

  Future<void> loadStaff() async {
    // Never flip initialLoad back to true — that would tear down the Add Staff
    // form mid-edit when a background refresh runs.
    try {
      if (Get.isRegistered<RemoteAccountSyncService>()) {
        await Get.find<RemoteAccountSyncService>().syncStaffFromRemote();
      }
      final rows = await _local.getAllNewestFirst();
      staff.assignAll(
        rows.map(
          (r) => RentStaffListItem(
            id: '${r.id}',
            name: r.name,
            jobTitle: r.jobTitle,
            payAmountLabel: r.displayAmountLine,
            payDayDisplay: r.payDayLabel.trim().isEmpty
                ? ''
                : RentStaffPayFormat.payDayLine(r.payDayLabel.trim()),
            paymentType: r.paymentType,
            amountValue: r.amountValue,
          ),
        ),
      );
    } catch (e, st) {
      logger.e('loadStaff $e $st');
      Get.snackbar('Error', 'Could not load staff');
    } finally {
      if (initialLoad.value) initialLoad.value = false;
    }
  }

  double? _parseAmount(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^\d.]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  String? validateFullName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter full name';
    if (v.length < 3) return 'Name is too short';
    return null;
  }

  String? validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return 'Phone number is required';
    final normalized = _normalizePhone(phone);
    if (normalized == null) {
      return 'Enter a valid phone number (e.g. 0712345678)';
    }
    return null;
  }

  /// Matches backend StaffService phone rules used for login usernames.
  String? _normalizePhone(String raw) =>
      RentStaffLocalDataSource.normalizePhone(raw);

  String? validateAmount(String? value) {
    final parsed = _parseAmount(value ?? '');
    if (parsed == null || parsed <= 0) return 'Please enter a valid amount';
    return null;
  }

  String? validatePayDate(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return Get.locale?.languageCode == 'sw'
          ? 'Weka siku ya malipo'
          : 'Please enter payment day';
    }
    final day = int.tryParse(v);
    if (day == null || day < 1 || day > 31) {
      return Get.locale?.languageCode == 'sw'
          ? 'Siku lazima iwe kati ya 1 na 31'
          : 'Day must be between 1 and 31';
    }
    return null;
  }

  void updatePaymentType(String? value) {
    if (value != null && value.isNotEmpty) {
      paymentType.value = value;
    }
  }

  void updatePrimaryRole(String? value) {
    if (value != null && value.isNotEmpty) {
      selectedPrimaryRole.value = value;
    }
  }

  /// Brings the staff list on screen after a member has been saved.
  void _revealStaffList() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = activeTeamSectionKey.currentContext;
      if (context == null || !context.mounted) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.05,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  void _clearFormFields() {
    formKey.currentState?.reset();
    fullNameController.clear();
    phoneController.clear();
    notesController.clear();
    amountController.clear();
    payDateController.clear();
    selectedPrimaryRole.value = '';
    paymentType.value = RentStaffPayFormat.monthly;
    _resetAccess();
  }

  void _resetAccess() {
    permissionRole.value = StaffPermissions.roleCleaner;
    grantedPermissions.assignAll(StaffPermissions.preset(StaffPermissions.roleCleaner));
    allPropertiesAccess.value = false;
    selectedPropertyRefs
      ..clear()
      ..addAll(_propertyRef.isEmpty ? const <String>[] : [_propertyRef]);
    legacyStaffAccess.value = false;
  }

  void applyPermissionRole(String role) {
    permissionRole.value = role;
    grantedPermissions.assignAll(StaffPermissions.preset(role));
    allPropertiesAccess.value = StaffPermissions.defaultAllProperties(role);
    legacyStaffAccess.value = false;
  }

  void togglePermission(String key) {
    if (grantedPermissions.contains(key)) {
      grantedPermissions.remove(key);
    } else {
      grantedPermissions.add(key);
    }
    legacyStaffAccess.value = false;
  }

  void setAllPropertiesAccess(bool value) {
    allPropertiesAccess.value = value;
    legacyStaffAccess.value = false;
  }

  void togglePropertyRef(String ref) {
    if (selectedPropertyRefs.contains(ref)) {
      selectedPropertyRefs.remove(ref);
    } else {
      selectedPropertyRefs.add(ref);
    }
    legacyStaffAccess.value = false;
  }

  Future<void> _loadAccessProperties() async {
    try {
      final preferenceManager = Get.find<PreferenceManager>(
        tag: (PreferenceManager).toString(),
      );
      final userId = ((await preferenceManager.getUser()).id ?? '').trim();
      final propertyLocal = Get.find<PropertyLocalDataSource>();

      // Only properties visible to the logged-in user (owned or managed) —
      // not every local row left on the device from other accounts.
      final byRef = <String, PropertyRecord>{};
      final rows = await propertyLocal.getAllVisibleNewestFirst(
        userId: userId,
        workspaceType: '',
      );
      for (final row in rows) {
        final ref = row.propertyRef.trim().isNotEmpty
            ? row.propertyRef.trim()
            : 'local_${row.id}';
        byRef.putIfAbsent(ref, () => row);
      }

      accessProperties.assignAll(
        byRef.entries.map(
          (e) => StaffPropertyOption(
            ref: e.key,
            name: e.value.propertyName.trim().isNotEmpty
                ? e.value.propertyName.trim()
                : e.value.propertyLocation.trim(),
          ),
        ),
      );
    } catch (_) {}
  }

  Future<void> loadSavedAccess({required int localId, required String name}) async {
    try {
      final backendId = await _local.backendIdForLocal(localId);
      final res = await _repository.getStaffList();
      if (!res.isSuccess || res.data == null) return;
      final maps = _staffMaps(res.data);
      Map<String, dynamic>? match;
      for (final row in maps) {
        final id = (row['id'] ?? '').toString();
        final rowName = (row['name'] ?? '').toString().trim().toLowerCase();
        if (backendId != null && id == backendId) {
          match = row;
          break;
        }
        if (rowName.isNotEmpty && rowName == name.trim().toLowerCase()) {
          match ??= row;
        }
      }
      if (match != null) applyAccessMap(match);
    } catch (_) {}
  }

  void applyAccessMap(Map<String, dynamic> row) {
    final legacy = row['legacyAccess'] == true;
    legacyStaffAccess.value = legacy;
    final role = (row['permissionRole'] ?? '').toString();
    permissionRole.value = StaffPermissions.roles.contains(role)
        ? role
        : StaffPermissions.roleCleaner;
    final raw = row['permissions'];
    if (raw is List && raw.isNotEmpty) {
      grantedPermissions.assignAll(raw.map((e) => e.toString()));
    } else if (legacy) {
      grantedPermissions.assignAll(StaffPermissions.all);
    } else {
      grantedPermissions.assignAll(StaffPermissions.preset(permissionRole.value));
    }
    allPropertiesAccess.value = legacy || row['allProperties'] == true;
    selectedPropertyRefs.clear();
    final refs = row['propertyRefs'];
    if (refs is List) {
      selectedPropertyRefs.addAll(
        refs.map((e) => e.toString().trim()).where((e) => e.isNotEmpty),
      );
    }
  }

  List<Map<String, dynamic>> _staffMaps(dynamic raw) {
    if (raw is Map && raw['staff'] is List) {
      return (raw['staff'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (raw is List) {
      return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return const [];
  }

  bool _accessReady() {
    if (allPropertiesAccess.value) return true;
    if (selectedPropertyRefs.isNotEmpty) return true;
    // Listing Staff tab embeds this controller without StaffAccessEditor — bind
    // the current property automatically when we have route context.
    if (_propertyRef.isNotEmpty) {
      selectedPropertyRefs.add(_propertyRef);
      return true;
    }
    _surfaceError(appLocalization.staffAccessSelectProperty);
    return false;
  }

  /// Surfaces errors even when this controller is not hosted in its own BaseView
  /// (e.g. listing details Staff tab embeds the form).
  void _surfaceError(String msg) {
    final text = msg.trim();
    if (text.isEmpty) return;
    hapticValidationError();
    // Prefer a snackbar so embedded hosts always show it. Avoid showErrorMessage
    // here — BaseView would also snack and duplicate on the dedicated Staff page.
    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
    }
    Get.rawSnackbar(
      messageText: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFB91C1C),
      margin: const EdgeInsets.all(12),
      borderRadius: 10,
      duration: const Duration(seconds: 3),
    );
  }

  void _surfaceSuccess(String msg) {
    final text = msg.trim();
    if (text.isEmpty) return;
    hapticPrimaryConfirm();
    // Prefer a snackbar so embedded hosts (listing Staff tab) always show it.
    // Avoid showSuccessMessage here — BaseView would also toast and duplicate.
    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
    }
    Get.rawSnackbar(
      messageText: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF15803D),
      margin: const EdgeInsets.all(12),
      borderRadius: 10,
      duration: const Duration(seconds: 3),
    );
  }

  void cancelEdit() {
    editingStaffId.value = null;
    _clearFormFields();
  }

  Future<String> _apiStaffId(int localId) async {
    return await _local.backendIdForLocal(localId) ?? '$localId';
  }

  String? _backendIdFromResponse(dynamic data) {
    if (data is Map) {
      final nested = data['data'];
      if (nested is Map) {
        return (nested['id'] ?? nested['staffId'])?.toString();
      }
      return (data['id'] ?? data['staffId'])?.toString();
    }
    return null;
  }

  StaffRequest _buildStaffRequest({
    required String name,
    required String role,
    required double amount,
    required String payDay,
    String? id,
    String? startDate,
  }) {
    final phone =
        _normalizePhone(phoneController.text) ?? phoneController.text.trim();
    return StaffRequest(
      id: id,
      name: name,
      role: role,
      salary: amount,
      salaryFrequency: paymentType.value,
      phone: phone,
      notes: notesController.text.trim(),
      propertyName: _propertyName,
      propertyRef: _propertyRef,
      startDate: startDate,
      status: 'active',
      payDayLabel: payDay,
      permissionRole: permissionRole.value,
      permissions: grantedPermissions.toList(),
      allProperties: allPropertiesAccess.value,
      propertyRefs: selectedPropertyRefs.toList(),
    );
  }

  Future<void> registerStaff() async {
    final form = formKey.currentState;
    if (form == null) {
      _surfaceError(
        _isSw
            ? 'Fomu haiko tayari. Jaribu tena.'
            : 'The form is not ready. Please try again.',
      );
      return;
    }
    if (!form.validate()) return;
    final name = fullNameController.text.trim();
    final payDay = payDateController.text.trim();
    final role = selectedPrimaryRole.value.trim();
    final amount = _parseAmount(amountController.text);
    final phone = _normalizePhone(phoneController.text);

    if (role.isEmpty) {
      _surfaceError(
        _isSw ? 'Chagua jukumu la msingi' : 'Please select a primary role',
      );
      return;
    }
    if (amount == null) {
      _surfaceError(
        _isSw ? 'Weka kiasi sahihi' : 'Please enter a valid amount',
      );
      return;
    }
    if (!_accessReady()) return;
    if (phone == null) {
      _surfaceError(
        _isSw
            ? 'Weka namba sahihi ya simu (mf. 0712345678)'
            : 'Enter a valid phone number (e.g. 0712345678)',
      );
      return;
    }
    phoneController.text = phone;

    final duplicateMessage = await _duplicateStaffMessage(
      phone: phone,
      name: name,
      excludeLocalId: editingStaffId.value,
    );
    if (duplicateMessage != null) {
      _surfaceError(duplicateMessage);
      return;
    }

    await runBusy(() async {
      try {
        final editId = editingStaffId.value;
        if (editId != null) {
          await _local.updateById(
            id: editId,
            name: name,
            jobTitle: role,
            payDayLabel: payDay,
            paymentType: paymentType.value,
            amountValue: amount,
            phone: phone,
          );
          final request = _buildStaffRequest(
            name: name,
            role: role,
            amount: amount,
            payDay: payDay,
            id: '$editId',
          );
          final apiStaffId = await _apiStaffId(editId);
          try {
            final res =
                await _repository.updateStaff(apiStaffId, request.toApiJson());
            if (!res.isSuccess) throw Exception(res.message ?? 'API error');
          } catch (e) {
            if (_isClientValidationError(e)) rethrow;
            final payload = request.toApiJson()..['id'] = apiStaffId;
            await _syncQueue.enqueue(
              entityType: 'staff',
              operation: 'update',
              payloadJson: jsonEncode(payload),
              dedupeKey: 'staff:update:$apiStaffId',
            );
            _syncWorker.runNow();
          }
          editingStaffId.value = null;
          _clearFormFields();
          await loadStaff();
          _revealStaffList();
          _surfaceSuccess(
            _isSw ? 'Mfanyakazi amesasishwa' : 'Staff updated',
          );
          return;
        }

        await RemovedStaffPhones.forget(phone);
        final localId = await _local.insert(
          name: name,
          jobTitle: role,
          payDayLabel: payDay,
          paymentType: paymentType.value,
          amountValue: amount,
          phone: phone,
        );
        final today = DateTime.now();
        final startDate =
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        final request = _buildStaffRequest(
          name: name,
          role: role,
          amount: amount,
          payDay: payDay,
          startDate: startDate,
        );
        var provisionedOnline = false;
        try {
          final res = await _repository.createStaff(request.toApiJson());
          if (!res.isSuccess) throw Exception(res.message ?? 'API error');
          final backendId = _backendIdFromResponse(res.data);
          if (backendId != null) {
            await _local.saveBackendId(localId, backendId);
          }
          provisionedOnline = true;
        } catch (e) {
          if (_isClientValidationError(e)) rethrow;
          await _syncQueue.enqueue(
            entityType: 'staff',
            operation: 'create',
            payloadJson: jsonEncode(request.toApiJson()),
            dedupeKey: 'staff:create:$localId',
          );
          _syncWorker.runNow();
        }
        _clearFormFields();
        await loadStaff();
        _revealStaffList();
        _surfaceSuccess(
          provisionedOnline
              ? (_isSw
                  ? 'Mfanyakazi ameongezwa. Anaweza kuingia kwa namba $phone.'
                  : 'Staff added. They can log in with $phone.')
              : (_isSw
                  ? 'Mfanyakazi amehifadhiwa. Akaunti ya kuingia itaundwa baada ya kusawazisha.'
                  : 'Staff saved offline. Login account will be created after sync.'),
        );
      } catch (e, st) {
        logger.e('registerStaff $e $st');
        final msg = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
        _surfaceError(
          msg.isNotEmpty && msg != 'null'
              ? msg
              : (_isSw
                  ? 'Imeshindikana kuhifadhi mfanyakazi'
                  : 'Could not save staff'),
        );
      }
    });
  }

  /// Returns a user-facing message when [phone] / [name] already belong to staff.
  Future<String?> _duplicateStaffMessage({
    required String phone,
    required String name,
    int? excludeLocalId,
  }) async {
    final byPhone = await _local.findByPhone(
      phone,
      excludeId: excludeLocalId,
    );
    if (byPhone != null) {
      return _isSw
          ? 'Mfanyakazi mwenye namba hii ya simu tayari yupo (${byPhone.name}).'
          : 'A staff member with this phone number already exists (${byPhone.name}).';
    }

    final byName = await _local.findByNameIgnoreCase(
      name,
      excludeId: excludeLocalId,
    );
    if (byName != null) {
      final existingPhone =
          RentStaffLocalDataSource.normalizePhone(byName.phone) ??
              byName.phone.trim();
      // Same person re-entered: matching name with empty/legacy phone, or same phone.
      if (existingPhone.isEmpty || existingPhone == phone) {
        return _isSw
            ? 'Mfanyakazi "${byName.name}" tayari yupo. Badilisha jina au namba ya simu.'
            : 'Staff member "${byName.name}" already exists. Use a different name or phone number.';
      }
    }

    try {
      final pending = await _syncQueue.listUnsynced(
        entityType: 'staff',
        operation: 'create',
      );
      for (final item in pending) {
        Map<String, dynamic>? payload;
        try {
          final decoded = jsonDecode(item.payloadJson);
          if (decoded is Map) {
            payload = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {
          continue;
        }
        if (payload == null) continue;
        final pendingPhone = RentStaffLocalDataSource.normalizePhone(
              (payload['phone'] ?? '').toString(),
            ) ??
            (payload['phone'] ?? '').toString().trim();
        if (pendingPhone.isNotEmpty && pendingPhone == phone) {
          return _isSw
              ? 'Mfanyakazi mwenye namba hii ya simu tayari anasubiri kusawazishwa.'
              : 'A staff member with this phone number is already waiting to sync.';
        }
        final pendingName =
            (payload['name'] ?? '').toString().trim().toLowerCase();
        if (pendingName.isNotEmpty &&
            pendingName == name.trim().toLowerCase() &&
            (pendingPhone.isEmpty || pendingPhone == phone)) {
          return _isSw
              ? 'Mfanyakazi "$name" tayari anasubiri kusawazishwa.'
              : 'Staff member "$name" is already waiting to sync.';
        }
      }
    } catch (_) {}

    return null;
  }

  bool _isClientValidationError(Object e) {
    final text = e.toString().toLowerCase();
    return text.contains('phone') ||
        text.contains('required') ||
        text.contains('invalid') ||
        text.contains('400') ||
        text.contains('illegalargument');
  }

  Future<RentStaffRecord?> peekStaffRecord(int id) => _local.getById(id);

  /// Persists edits from [showStaffEditSheet]. Returns false on validation/save error.
  Future<bool> saveStaffEdits({
    required String staffId,
    required String name,
    required String role,
    required String paymentType,
    required String amountRaw,
    required String payDay,
  }) async {
    final editId = int.tryParse(staffId);
    if (editId == null) return false;
    final amount = _parseAmount(amountRaw);
    if (amount == null || amount <= 0) return false;
    if (name.trim().isEmpty || role.trim().isEmpty) return false;
    if (!_accessReady()) return false;

    final phone = _normalizePhone(phoneController.text);
    if (phone != null) {
      final duplicateMessage = await _duplicateStaffMessage(
        phone: phone,
        name: name.trim(),
        excludeLocalId: editId,
      );
      if (duplicateMessage != null) {
        _surfaceError(duplicateMessage);
        return false;
      }
    }

    try {
      await _local.updateById(
        id: editId,
        name: name.trim(),
        jobTitle: role.trim(),
        payDayLabel: payDay.trim(),
        paymentType: paymentType,
        amountValue: amount,
        phone: phone,
      );
      final request = _buildStaffRequest(
        name: name.trim(),
        role: role.trim(),
        amount: amount,
        payDay: payDay.trim(),
        id: '$editId',
      );
      // Align payment type used in request with the edited value.
      this.paymentType.value = paymentType;
      final apiStaffId = await _apiStaffId(editId);
      try {
        final res =
            await _repository.updateStaff(apiStaffId, request.toApiJson());
        if (!res.isSuccess) throw Exception(res.message ?? 'API error');
      } catch (_) {
        final payload = request.toApiJson()..['id'] = apiStaffId;
        await _syncQueue.enqueue(
          entityType: 'staff',
          operation: 'update',
          payloadJson: jsonEncode(payload),
          dedupeKey: 'staff:update:$apiStaffId',
        );
        _syncWorker.runNow();
      }
      editingStaffId.value = null;
      _clearFormFields();
      await loadStaff();
      showSuccessWithHaptic(
        _isSw ? 'Mfanyakazi amesasishwa' : 'Staff updated',
      );
      return true;
    } catch (e, st) {
      logger.e('saveStaffEdits $e $st');
      Get.snackbar(
        'Error',
        _isSw ? 'Haikuweza kusasisha' : 'Could not update staff',
      );
      return false;
    }
  }

  /// Opens a dedicated edit bottom sheet (visible response to Edit).
  Future<void> editStaff(RentStaffListItem member) async {
    final id = int.tryParse(member.id);
    if (id == null) {
      Get.snackbar(
        'Error',
        _isSw ? 'Mfanyakazi si sahihi' : 'Invalid staff member',
      );
      return;
    }
    editingStaffId.value = id;
    await loadSavedAccess(localId: id, name: member.name);
    await showStaffEditSheet(controller: this, member: member);
    // If user dismissed without saving, leave the page form clean.
    if (editingStaffId.value != null) {
      editingStaffId.value = null;
    }
  }

  Future<void> editStaffById(String staffId) async {
    final match = staff.firstWhereOrNull((s) => s.id == staffId);
    if (match != null) {
      await editStaff(match);
      return;
    }
    final id = int.tryParse(staffId);
    if (id == null) return;
    final record = await _local.getById(id);
    if (record == null) return;
    await editStaff(
      RentStaffListItem(
        id: '${record.id}',
        name: record.name,
        jobTitle: record.jobTitle,
        payAmountLabel: record.displayAmountLine,
        payDayDisplay: record.payDayLabel.trim().isEmpty
            ? ''
            : RentStaffPayFormat.payDayLine(record.payDayLabel.trim()),
        paymentType: record.paymentType,
        amountValue: record.amountValue,
      ),
    );
  }

  Future<void> removeStaff(String id) async {
    final parsed = int.tryParse(id);
    if (parsed == null) return;
    final snapshot = await _local.getById(parsed);
    if (snapshot == null) return;
    final backendStaffId = await _local.backendIdForLocal(parsed);
    final apiStaffId = backendStaffId ?? '$parsed';

    final confirmed = await confirmDestructive(
      title: 'Remove staff member?',
      message: 'Remove ${snapshot.name.trim()} from your team list?',
      confirmLabel: 'Remove',
    );
    if (!confirmed) return;

    await runDestructiveWithUndo(
      message: 'Staff member removed',
      duration: const Duration(seconds: 4),
      action: () async {
        await RemovedStaffPhones.remember(snapshot.phone);
        await _local.deleteById(parsed);
        try {
          final res = await _repository.deleteStaff(apiStaffId);
          if (!res.isSuccess) throw Exception(res.message ?? 'API error');
        } catch (_) {
          await _syncQueue.enqueue(
            entityType: 'staff',
            operation: 'delete',
            payloadJson: jsonEncode({'id': apiStaffId}),
            dedupeKey: 'staff:delete:$apiStaffId',
          );
          _syncWorker.runNow();
        }
        // Refresh from local only so a remote sync cannot rehydrate immediately.
        final rows = await _local.getAllNewestFirst();
        staff.assignAll(
          rows.map(
            (r) => RentStaffListItem(
              id: '${r.id}',
              name: r.name,
              jobTitle: r.jobTitle,
              payAmountLabel: r.displayAmountLine,
              payDayDisplay: r.payDayLabel.trim().isEmpty
                  ? ''
                  : RentStaffPayFormat.payDayLine(r.payDayLabel.trim()),
              paymentType: r.paymentType,
              amountValue: r.amountValue,
            ),
          ),
        );
      },
      onUndo: () async {
        await RemovedStaffPhones.forget(snapshot.phone);
        await _syncQueue.deleteByDedupeKey('staff:delete:$apiStaffId');
        await _local.restore(snapshot, backendStaffId: backendStaffId);
        await loadStaff();
      },
    );
  }

  @override
  void onClose() {
    fullNameController.dispose();
    phoneController.dispose();
    notesController.dispose();
    amountController.dispose();
    payDateController.dispose();
    super.onClose();
  }
}

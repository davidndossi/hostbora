import 'dart:convert';

import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../data/local/db/property_local_data_source.dart';
import '../../../../data/local/db/property_members_local_data_source.dart';
import '../../../../data/local/db/tenant_local_data_source.dart';
import '../../../../data/local/preference/preference_manager.dart';
import '../../../../data/local/service/workspace_context_service.dart';
import '../../../../data/repository/app_repository.dart';
import '../../../../routes/app_pages.dart';
import '../../add_new_listing/models/apartment_unit_draft.dart';
import '../../base_shell/controllers/rent_base_shell_controller.dart';

/// One apartment unit on a local property (for per-unit tenant actions).
class RentHubUnitSlot {
  const RentHubUnitSlot({
    required this.unitId,
    required this.unitName,
    required this.tenantCount,
  });

  final String unitId;
  final String unitName;
  final int tenantCount;
}

/// Property row for the concierge management hub cards (separate from [my_properties] models).
class RentHubPropertyRow {
  const RentHubPropertyRow({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.propertyTypeLabel,
    required this.activeTenants,
    this.isLocal = false,
    this.unitSlots = const [],
  });

  final String id;
  final String title;
  final String imageUrl;
  final String propertyTypeLabel;
  final int activeTenants;
  /// Stored in SQLite on this device — can open [Routes.RENT_ADD_NEW_LISTING] for editing.
  final bool isLocal;
  /// Populated for local apartments with [PropertyRecord.units_json].
  final List<RentHubUnitSlot> unitSlots;
}

class RentMyPropertiesHubController extends BaseController {
  RentMyPropertiesHubController()
      : _repository = Get.find<AppRepository>(tag: (AppRepository).toString()),
        _localRent = Get.find<PropertyLocalDataSource>(),
        _tenantLocal = Get.find<TenantLocalDataSource>(),
        _propertyMembers = Get.find<PropertyMembersLocalDataSource>(),
        _preferenceManager = Get.find<PreferenceManager>(
          tag: (PreferenceManager).toString(),
        ),
        _workspaceContext = Get.find<WorkspaceContextService>();

  final AppRepository _repository;
  final PropertyLocalDataSource _localRent;
  final TenantLocalDataSource _tenantLocal;
  final PropertyMembersLocalDataSource _propertyMembers;
  final PreferenceManager _preferenceManager;
  final WorkspaceContextService _workspaceContext;

  final properties = <RentHubPropertyRow>[].obs;
  final loading = false.obs;

  @override
  void onReady() {
    super.onReady();
    loadProperties();
  }

  Future<void> loadProperties() async {
    loading.value = true;
    var loggedInUserId = '';
    try {
      loggedInUserId = ((await _preferenceManager.getUser()).id ?? '').trim();
      final currentUserId = loggedInUserId;
      final localRecords = await _localRent.getAllVisibleNewestFirst(
        userId: currentUserId,
        workspaceType: 'rent',
      );
      final tenantRecords = await _tenantLocal.getAllNewestFirst();

      final localRows = localRecords
          .map((r) => _rowFromLocal(r, tenantRecords: tenantRecords))
          .toList();

      List<RentHubPropertyRow> remoteRows = [];
      try {
        final res = await _repository.getMyListings(status: null);
        final data = res.data;
        List<dynamic> rawList = [];
        if (data is List) {
          rawList = data;
        } else if (data is Map && data['content'] is List) {
          rawList = data['content'] as List;
        } else if (data is Map && data['listings'] is List) {
          rawList = data['listings'] as List;
        }
        final maps = rawList.whereType<Map<String, dynamic>>().toList();
        remoteRows = maps.map(_rowFromMap).where((e) => e.id.isNotEmpty).toList();
      } catch (_) {
        // Offline or API failure: still show SQLite properties.
      }
      properties.assignAll([...localRows, ...remoteRows]);
    } catch (e) {
      properties.clear();
      Get.snackbar('Error', 'Could not load properties');
    } finally {
      loading.value = false;
      _applyPostLoginRentListingsRedirectIfNeeded(loggedInUserId);
    }
  }

  /// After login, [RentBaseShellController] may request a one-shot switch to Listings when empty.
  void _applyPostLoginRentListingsRedirectIfNeeded(String userId) {
    if (!Get.isRegistered<RentBaseShellController>()) return;
    final shell = Get.find<RentBaseShellController>();
    if (!shell.pullPendingRentHubListingsRedirect()) return;
    if (userId.isEmpty || properties.isNotEmpty) return;
    if (shell.currentTab.value != RentBaseShellController.tabDashboard) return;
    shell.setTab(RentBaseShellController.tabListings);
  }

  static List<ApartmentUnitDraft> _parseUnitsFromPropertyJson(String unitsJson) {
    if (unitsJson.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(unitsJson);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((m) => ApartmentUnitDraft.fromJson(Map<String, dynamic>.from(m)))
          .where((u) => u.unitName.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static bool _tenantMatchesProperty(
    TenantRecord t,
    String propertyRef,
    String title,
    String loc,
    String suite,
  ) {
    final r = t.propertyRef.trim();
    if (r.isNotEmpty) {
      return r == propertyRef;
    }
    final pl = t.propertyLabel.trim();
    if (pl == title) return true;
    if (pl == loc) return true;
    if (suite.isNotEmpty && pl == '$loc · $suite') return true;
    return false;
  }

  static bool _tenantMatchesUnit(
    TenantRecord t,
    ApartmentUnitDraft u,
    String propertyRef,
    String title,
    String loc,
    String suite,
  ) {
    if (!_tenantMatchesProperty(t, propertyRef, title, loc, suite)) return false;
    final tid = t.apartmentUnitId.trim();
    final uid = u.unitId.trim();
    if (tid.isNotEmpty && uid.isNotEmpty) return tid == uid;
    return t.unitLabel.trim() == u.unitName.trim();
  }

  static RentHubPropertyRow _rowFromLocal(
    PropertyRecord r, {
    required List<TenantRecord> tenantRecords,
  }) {
    final loc = r.propertyLocation.trim();
    final suite = r.propertyName.trim();
    final title = suite.isNotEmpty ? '$loc · $suite' : (loc.isNotEmpty ? loc : 'Property');
    final propertyRef = r.propertyRef.isNotEmpty ? r.propertyRef : 'legacy_${r.id}';
    final drafts = _parseUnitsFromPropertyJson(r.unitsJson);

    if (drafts.isEmpty) {
      final tenantCount = tenantRecords
          .where((t) => _tenantMatchesProperty(t, propertyRef, title, loc, suite))
          .length;
      return RentHubPropertyRow(
        id: propertyRef,
        title: title,
        imageUrl: '',
        propertyTypeLabel: r.propertyType.toUpperCase(),
        activeTenants: tenantCount,
        isLocal: true,
        unitSlots: const [],
      );
    }

    final slots = <RentHubUnitSlot>[];
    var total = 0;
    for (final u in drafts) {
      final n = tenantRecords
          .where((t) => _tenantMatchesUnit(t, u, propertyRef, title, loc, suite))
          .length;
      slots.add(RentHubUnitSlot(unitId: u.unitId, unitName: u.unitName, tenantCount: n));
      total += n;
    }
    return RentHubPropertyRow(
      id: propertyRef,
      title: title,
      imageUrl: '',
      propertyTypeLabel: r.propertyType.toUpperCase(),
      activeTenants: total,
      isLocal: true,
      unitSlots: slots,
    );
  }

  static RentHubPropertyRow _rowFromMap(Map<String, dynamic> m) {
    final id = m['id']?.toString() ?? m['listingId']?.toString() ?? '';
    final title = m['propertyName']?.toString() ?? m['title']?.toString() ?? 'Property';
    final imageUrl = m['coverPhotoUrl']?.toString() ?? m['coverPhoto']?.toString() ?? m['imageUrl']?.toString() ?? '';
    final propertyTypeLabel =
        (m['propertyType'] ?? m['propertyCategory'] ?? m['category'])?.toString().toUpperCase() ?? 'PROPERTY';
    final activeTenants = (m['activeTenants'] as num?)?.toInt() ?? (m['tenantCount'] as num?)?.toInt() ?? 0;
    return RentHubPropertyRow(
      id: id,
      title: title,
      imageUrl: imageUrl,
      propertyTypeLabel: propertyTypeLabel,
      activeTenants: activeTenants,
      isLocal: false,
      unitSlots: const [],
    );
  }

  void addTenantForUnit({
    required String propertyHubId,
    required String propertyTitle,
    required RentHubUnitSlot slot,
  }) {
    final future = Get.toNamed(
      Routes.RENT_ADD_TENANT_FORM,
      parameters: {
        'property': propertyTitle,
        'propertyRef': propertyHubId,
        if (slot.unitId.trim().isNotEmpty) 'unitId': slot.unitId.trim(),
        'unitName': slot.unitName.trim(),
      },
    );
    future?.then((value) {
      if (value == true) {
        loadProperties();
      }
    });
  }

  Future<void> addProperty() async {
    final value = await Get.toNamed(Routes.RENT_ADD_NEW_LISTING);
    if (value == true) {
      showSuccessMessage('Listing saved');
      await loadProperties();
    }
  }

  Future<void> editProperty(String propertyHubId) async {
    final value = await Get.toNamed(
      Routes.EDIT_LISTING,
      parameters: {'property_ref': propertyHubId},
    );
    if (value == true) {
      showSuccessMessage('Listing updated');
      await loadProperties();
    }
  }

  Future<void> addCoHost({
    required String propertyRef,
    required String coHostUserId,
  }) async {
    final targetUser = coHostUserId.trim();
    if (targetUser.isEmpty) {
      Get.snackbar('Error', 'Co-host user ID is required');
      return;
    }
    await _propertyMembers.upsertMember(
      propertyRef: propertyRef,
      userId: targetUser,
      workspaceType: await _workspaceContext.getWorkspaceType(),
      role: 'co_host',
    );
    Get.snackbar('Success', 'Co-host access granted');
  }

  Future<List<PropertyMemberRecord>> listCoHosts({
    required String propertyRef,
  }) async {
    return _propertyMembers.listMembers(
      propertyRef: propertyRef,
      workspaceType: await _workspaceContext.getWorkspaceType(),
    );
  }

  Future<void> removeCoHost({
    required String propertyRef,
    required String coHostUserId,
  }) async {
    final targetUser = coHostUserId.trim();
    if (targetUser.isEmpty) return;
    await _propertyMembers.removeMember(
      propertyRef: propertyRef,
      userId: targetUser,
      workspaceType: await _workspaceContext.getWorkspaceType(),
    );
    Get.snackbar('Success', 'Co-host removed');
  }
}

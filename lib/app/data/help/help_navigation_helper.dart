import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/local/db/property_local_data_source.dart';
import '../../data/local/db/tenant_local_data_source.dart';
import '../../data/local/preference/preference_manager.dart';
import '../../routes/app_pages.dart';
import 'help_center_models.dart';

/// Opens Help routes, prompting for property/tenant when required.
class HelpNavigationHelper {
  HelpNavigationHelper._();

  static bool get _isSw => Get.locale?.languageCode == 'sw';

  static Future<void> openFeature(HelpFeature feature) async {
    await openRoute(
      route: feature.route,
      requiresContext: feature.requiresContext,
      baseParameters: feature.routeParameters,
      baseArguments: feature.routeArguments,
    );
  }

  static Future<void> openStep(HelpGuideStep step) async {
    if (step.route == null || step.route!.isEmpty) return;
    await openRoute(
      route: step.route!,
      requiresContext: step.requiresContext,
      baseParameters: step.routeParameters,
      baseArguments: step.routeArguments,
    );
  }

  static Future<void> openRoute({
    required String route,
    HelpNavContext requiresContext = HelpNavContext.none,
    Map<String, String>? baseParameters,
    Map<String, dynamic>? baseArguments,
  }) async {
    if (requiresContext == HelpNavContext.none) {
      _navigate(
        route,
        parameters: baseParameters ?? const {},
        arguments: baseArguments,
      );
      return;
    }

    final ctx = Get.context;
    if (ctx == null) return;

    final selection = await showModalBottomSheet<_HelpContextSelection>(
      context: ctx,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) => _HelpContextPickerSheet(
        requiresContext: requiresContext,
        isSw: _isSw,
      ),
    );
    if (selection == null) return;

    final params = <String, String>{
      ...?baseParameters,
      ...selection.parameters,
    };
    final args = <String, dynamic>{
      ...?baseArguments,
      ...selection.arguments,
    };
    _navigate(route, parameters: params, arguments: args);
  }

  static void _navigate(
    String route, {
    required Map<String, String> parameters,
    Map<String, dynamic>? arguments,
  }) {
    // Listing details expects arguments, not only parameters.
    if (route == Routes.LISTING_DETAILS) {
      Get.toNamed(
        route,
        arguments: {
          'property_id': parameters['propertyRef'] ??
              parameters['property_id'] ??
              '',
          'property_name': parameters['propertySuite'] ??
              parameters['propertyTitle'] ??
              '',
          'property_location': parameters['propertyLoc'] ?? '',
          ...?arguments,
        },
      );
      return;
    }

    if (arguments != null && arguments.isNotEmpty) {
      Get.toNamed(route, parameters: parameters, arguments: arguments);
    } else {
      Get.toNamed(route, parameters: parameters);
    }
  }
}

class _HelpContextSelection {
  const _HelpContextSelection({
    required this.parameters,
    required this.arguments,
  });

  final Map<String, String> parameters;
  final Map<String, dynamic> arguments;
}

class _HelpContextPickerSheet extends StatefulWidget {
  const _HelpContextPickerSheet({
    required this.requiresContext,
    required this.isSw,
  });

  final HelpNavContext requiresContext;
  final bool isSw;

  @override
  State<_HelpContextPickerSheet> createState() =>
      _HelpContextPickerSheetState();
}

class _HelpContextPickerSheetState extends State<_HelpContextPickerSheet> {
  final _properties = <PropertyRecord>[].obs;
  final _tenants = <TenantRecord>[].obs;
  final _loading = true.obs;
  final _selectedPropertyRef = RxnString();
  final _selectedTenantId = RxnInt();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final propertyLocal = Get.find<PropertyLocalDataSource>();
      final prefs = Get.find<PreferenceManager>(
        tag: (PreferenceManager).toString(),
      );
      final userId = (await prefs.getUser()).id ?? '';
      final rowsByKey = <String, PropertyRecord>{};
      for (final workspace in const ['bnb', 'rent', 'both', 'all']) {
        final rows = await propertyLocal.getAllVisibleNewestFirst(
          userId: userId,
          workspaceType: workspace,
        );
        for (final row in rows) {
          final key = row.propertyRef.trim().isNotEmpty
              ? row.propertyRef.trim()
              : 'local_${row.id}';
          rowsByKey[key] = row;
        }
      }
      final rows = rowsByKey.values.toList();
      _properties.assignAll(rows);
      if (rows.isNotEmpty) {
        final first = rows.first;
        _selectedPropertyRef.value = first.propertyRef.trim().isNotEmpty
            ? first.propertyRef.trim()
            : 'local_${first.id}';
        await _loadTenantsForSelected();
      }
    } catch (_) {
      try {
        final propertyLocal = Get.find<PropertyLocalDataSource>();
        final rows = await propertyLocal.getAllNewestFirst();
        _properties.assignAll(rows);
        if (rows.isNotEmpty) {
          final first = rows.first;
          _selectedPropertyRef.value = first.propertyRef.trim().isNotEmpty
              ? first.propertyRef.trim()
              : 'local_${first.id}';
          await _loadTenantsForSelected();
        }
      } catch (_) {}
    } finally {
      _loading.value = false;
    }
  }

  Future<void> _loadTenantsForSelected() async {
    if (widget.requiresContext != HelpNavContext.tenant) return;
    final ref = _selectedPropertyRef.value ?? '';
    final tenantLocal = Get.find<TenantLocalDataSource>();
    final all = await tenantLocal.getAllNewestFirst();
    final filtered = all.where((t) {
      if (ref.isEmpty) return true;
      final tr = t.propertyRef.trim();
      if (tr.isNotEmpty && (tr == ref || tr == 'local_${_selectedProperty?.id}')) {
        return true;
      }
      final prop = _selectedProperty;
      if (prop == null) return false;
      final label = t.propertyLabel.trim().toLowerCase();
      final name = prop.propertyName.trim().toLowerCase();
      final loc = prop.propertyLocation.trim().toLowerCase();
      return (name.isNotEmpty && label.contains(name)) ||
          (loc.isNotEmpty && label.contains(loc));
    }).toList();
    _tenants.assignAll(filtered);
    _selectedTenantId.value =
        filtered.isEmpty ? null : filtered.first.id;
  }

  PropertyRecord? get _selectedProperty {
    final ref = _selectedPropertyRef.value;
    if (ref == null) return null;
    for (final p in _properties) {
      final pr = p.propertyRef.trim().isNotEmpty
          ? p.propertyRef.trim()
          : 'local_${p.id}';
      if (pr == ref) return p;
    }
    return null;
  }

  String _propertyLabel(PropertyRecord p) {
    final name = p.propertyName.trim();
    final loc = p.propertyLocation.trim();
    if (name.isNotEmpty && loc.isNotEmpty) return '$name · $loc';
    if (name.isNotEmpty) return name;
    if (loc.isNotEmpty) return loc;
    return p.propertyRef.trim().isNotEmpty
        ? p.propertyRef.trim()
        : 'Property ${p.id}';
  }

  void _continue() {
    final prop = _selectedProperty;
    if (prop == null) {
      Get.snackbar(
        widget.isSw ? 'Chagua mali' : 'Select a property',
        widget.isSw
            ? 'Hakuna mali iliyochaguliwa.'
            : 'No property selected.',
      );
      return;
    }
    final ref = prop.propertyRef.trim().isNotEmpty
        ? prop.propertyRef.trim()
        : 'local_${prop.id}';
    final title = _propertyLabel(prop);

    if (widget.requiresContext == HelpNavContext.tenant) {
      final tid = _selectedTenantId.value;
      if (tid == null) {
        Get.snackbar(
          widget.isSw ? 'Chagua mpangaji' : 'Select a tenant',
          widget.isSw
              ? 'Hakuna mpangaji kwa mali hii.'
              : 'No tenant selected for this property.',
        );
        return;
      }
      TenantRecord? tenant;
      for (final t in _tenants) {
        if (t.id == tid) tenant = t;
      }
      if (tenant == null) return;
      Navigator.of(context).pop(
        _HelpContextSelection(
          parameters: {
            'id': '${tenant.id}',
            'tenantId': '${tenant.id}',
            'name': tenant.tenantName,
            'property': tenant.propertyLabel,
            'propertyRef': ref,
            'propertyTitle': title,
            'propertyLoc': prop.propertyLocation,
            'propertySuite': prop.propertyName,
            'ws': 'rent',
          },
          arguments: {
            'propertyRef': ref,
            'propertyTitle': title,
            'ws': 'rent',
          },
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      _HelpContextSelection(
        parameters: {
          'propertyRef': ref,
          'property_id': ref,
          'propertyTitle': title,
          'propertyLabel': title,
          'propertyLoc': prop.propertyLocation,
          'propertySuite': prop.propertyName,
          'propertyName': prop.propertyName,
          'propertyLocation': prop.propertyLocation,
          'ws': prop.workspaceType.trim().toLowerCase() == 'bnb' ? 'bnb' : 'rent',
        },
        arguments: {
          'property_id': ref,
          'property_name': prop.propertyName,
          'property_location': prop.propertyLocation,
          'propertyRef': ref,
          'property_ref': ref,
          'propertyTitle': title,
          'ws': prop.workspaceType.trim().toLowerCase() == 'bnb' ? 'bnb' : 'rent',
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final isSw = widget.isSw;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottom),
      child: Obx(() {
        if (_loading.value) {
          return const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (_properties.isEmpty) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isSw ? 'Hakuna mali bado' : 'No properties yet',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                isSw
                    ? 'Ongeza mali kwanza, kisha rudi hapa.'
                    : 'Add a property first, then come back here.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Get.toNamed(Routes.ADD_LISTING);
                },
                child: Text(isSw ? 'Ongeza mali' : 'Add property'),
              ),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.requiresContext == HelpNavContext.tenant
                  ? (isSw ? 'Chagua mali na mpangaji' : 'Select property & tenant')
                  : (isSw ? 'Chagua mali' : 'Select a property'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              isSw
                  ? 'Hatua hii inahitaji muktadha kabla ya kufungua skrini.'
                  : 'This screen needs context before it can open.',
              style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Text(
              isSw ? 'Mali' : 'Property',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedPropertyRef.value,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                for (final p in _properties)
                  DropdownMenuItem(
                    value: p.propertyRef.trim().isNotEmpty
                        ? p.propertyRef.trim()
                        : 'local_${p.id}',
                    child: Text(
                      _propertyLabel(p),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) async {
                _selectedPropertyRef.value = v;
                await _loadTenantsForSelected();
              },
            ),
            if (widget.requiresContext == HelpNavContext.tenant) ...[
              const SizedBox(height: 14),
              Text(
                isSw ? 'Mpangaji' : 'Tenant',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
              const SizedBox(height: 6),
              if (_tenants.isEmpty)
                Text(
                  isSw
                      ? 'Hakuna wapangaji kwa mali hii.'
                      : 'No tenants for this property.',
                  style: TextStyle(color: Theme.of(context).hintColor),
                )
              else
                DropdownButtonFormField<int>(
                  value: _selectedTenantId.value,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    for (final t in _tenants)
                      DropdownMenuItem(
                        value: t.id,
                        child: Text(
                          t.tenantName.trim().isEmpty
                              ? 'Tenant ${t.id}'
                              : t.tenantName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => _selectedTenantId.value = v,
                ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _continue,
              child: Text(isSw ? 'Endelea' : 'Continue'),
            ),
          ],
        );
      }),
    );
  }
}

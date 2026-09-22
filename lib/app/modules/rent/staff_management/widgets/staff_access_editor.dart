import 'package:flutter/material.dart';

import '../../../../core/access/staff_access.dart';
import '../../../../core/values/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';

class StaffPropertyOption {
  const StaffPropertyOption({required this.ref, required this.name});
  final String ref;
  final String name;
}

/// Role, grouped permission checklist, and property scope.
class StaffAccessEditor extends StatelessWidget {
  const StaffAccessEditor({
    super.key,
    required this.role,
    required this.permissions,
    required this.allProperties,
    required this.propertyRefs,
    required this.properties,
    required this.onRoleChanged,
    required this.onPermissionToggled,
    required this.onAllPropertiesChanged,
    required this.onPropertyToggled,
    this.legacy = false,
    this.accent = AppColors.colorPrimary,
  });

  final String role;
  final Set<String> permissions;
  final bool allProperties;
  final Set<String> propertyRefs;
  final List<StaffPropertyOption> properties;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<String> onPermissionToggled;
  final ValueChanged<bool> onAllPropertiesChanged;
  final ValueChanged<String> onPropertyToggled;
  final bool legacy;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.staffAccessRole.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: onSurface.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: ValueKey(role),
          initialValue: StaffPermissions.roles.contains(role) ? role : StaffPermissions.roleCleaner,
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.surfaceContainerHigh
                : const Color(0xFFF2F2F2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          items: StaffPermissions.roles
              .map(
                (key) => DropdownMenuItem(
                  value: key,
                  child: Text(_roleLabel(l10n, key)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onRoleChanged(value);
          },
        ),
        const SizedBox(height: 18),
        Text(
          l10n.staffAccessCustomize,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: onSurface,
          ),
        ),
        if (legacy) ...[
          const SizedBox(height: 8),
          Text(
            l10n.staffAccessLegacyNote,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
        const SizedBox(height: 8),
        for (final group in StaffPermissions.groups) ...[
          const SizedBox(height: 8),
          Text(
            _groupLabel(l10n, group.id),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          for (final key in group.keys)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              activeColor: accent,
              value: permissions.contains(key),
              title: Text(
                _permLabel(l10n, key),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              onChanged: (_) => onPermissionToggled(key),
            ),
        ],
        const SizedBox(height: 8),
        Text(
          l10n.staffAccessScope,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: onSurface,
          ),
        ),
        _ScopeChoice(
          selected: allProperties,
          label: l10n.staffAccessAllProperties,
          accent: accent,
          onTap: () => onAllPropertiesChanged(true),
        ),
        _ScopeChoice(
          selected: !allProperties,
          label: l10n.staffAccessSelectedProperties,
          accent: accent,
          onTap: () => onAllPropertiesChanged(false),
        ),
        if (!allProperties)
          if (properties.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l10n.inventoryNoPropertiesYet,
                style: TextStyle(color: onSurface.withValues(alpha: 0.7)),
              ),
            )
          else
            for (final property in properties)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                activeColor: accent,
                value: propertyRefs.contains(property.ref),
                title: Text(property.name.isEmpty ? property.ref : property.name),
                onChanged: (_) => onPropertyToggled(property.ref),
              ),
      ],
    );
  }

  static String _roleLabel(AppLocalizations l10n, String role) {
    switch (role) {
      case StaffPermissions.roleCaretaker:
        return l10n.staffRoleCaretaker;
      case StaffPermissions.roleFrontDesk:
        return l10n.staffRoleFrontDesk;
      case StaffPermissions.roleAccountant:
        return l10n.staffRoleAccountant;
      case StaffPermissions.roleManager:
        return l10n.staffRoleManager;
      default:
        return l10n.staffRoleCleaner;
    }
  }

  static String _groupLabel(AppLocalizations l10n, String id) {
    switch (id) {
      case 'bookings':
        return l10n.staffAccessGroupBookings;
      case 'payments':
        return l10n.staffAccessGroupPayments;
      case 'expenses':
        return l10n.staffAccessGroupExpenses;
      case 'reports':
        return l10n.staffAccessGroupReports;
      case 'inventory':
        return l10n.staffAccessGroupInventory;
      case 'tasks':
        return l10n.staffAccessGroupTasks;
      case 'tenants':
        return l10n.staffAccessGroupTenants;
      default:
        return l10n.staffAccessGroupProperties;
    }
  }

  static String _permLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case StaffPermissions.editProperties:
        return l10n.staffPermEditProperties;
      case StaffPermissions.viewBookings:
        return l10n.staffPermViewBookings;
      case StaffPermissions.checkInOut:
        return l10n.staffPermCheckInOut;
      case StaffPermissions.messageGuest:
        return l10n.staffPermMessageGuest;
      case StaffPermissions.manageBookings:
        return l10n.staffPermManageBookings;
      case StaffPermissions.viewPayments:
        return l10n.staffPermViewPayments;
      case StaffPermissions.recordPayment:
        return l10n.staffPermRecordPayment;
      case StaffPermissions.viewExpenses:
        return l10n.staffPermViewExpenses;
      case StaffPermissions.manageExpenses:
        return l10n.staffPermManageExpenses;
      case StaffPermissions.viewReports:
        return l10n.staffPermViewReports;
      case StaffPermissions.exportReports:
        return l10n.staffPermExportReports;
      case StaffPermissions.viewInventory:
        return l10n.staffPermViewInventory;
      case StaffPermissions.manageInventory:
        return l10n.staffPermManageInventory;
      case StaffPermissions.viewTasks:
        return l10n.staffPermViewTasks;
      case StaffPermissions.completeTasks:
        return l10n.staffPermCompleteTasks;
      case StaffPermissions.manageTasks:
        return l10n.staffPermManageTasks;
      case StaffPermissions.viewTenants:
        return l10n.staffPermViewTenants;
      case StaffPermissions.manageTenants:
        return l10n.staffPermManageTenants;
      default:
        return l10n.staffPermViewProperties;
    }
  }
}

class _ScopeChoice extends StatelessWidget {
  const _ScopeChoice({
    required this.selected,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? accent : muted,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

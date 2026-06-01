import 'package:flutter/material.dart';
import 'package:host_bora/app/core/widget/skeleton_presets.dart';

import 'package:host_bora/app/core/theme/app_theme_tokens.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_view.dart';
import '../../../../core/base/rent_base_view.dart';
import '../../../../core/widget/undo_snackbar.dart';
import '../../../../data/local/db/rent_whatsapp_template_local_data_source.dart';
import '../../rent_theme.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_whatsapp_template_builder_controller.dart';
import 'rent_whatsapp_template_editor_view.dart';

class RentWhatsappTemplateBuilderView
    extends RentBaseView<RentWhatsappTemplateBuilderController> {
  RentWhatsappTemplateBuilderView({super.key});

  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  PreferredSizeWidget? appBar(BuildContext context) =>
      rentAppBar(_isSw ? 'Violezo vya WhatsApp' : 'WhatsApp Templates');

  @override
  Widget? floatingActionButton() {
    return FloatingActionButton.extended(
      backgroundColor: RentTheme.conciergeTeal,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_rounded),
      label: Text(_isSw ? 'KIOLEZO KIPYA' : 'NEW TEMPLATE', style: TextStyle(fontSize: 14)),
      onPressed: () => _openEditor(),
    );
  }

  @override
  FloatingActionButtonLocation floatingActionButtonLocation() =>
      FloatingActionButtonLocation.endFloat;

  @override
  Widget body(BuildContext context) {
    return Obx(() {
      if (controller.loading.value) {
        return const Center(
            child: const DefaultScreenSkeleton());
      }
      return RefreshIndicator(
        color: RentTheme.teal,
        onRefresh: controller.loadAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            _introCard(context),
            const SizedBox(height: 14),
            _statusFilters(context),
            const SizedBox(height: 14),
            _listSection(context),
          ],
        ),
      );
    });
  }

  Widget _introCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D5C5A), Color(0xFF149C95)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.chat_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSw
                      ? 'Jenga violezo vilivyoidhinishwa'
                      : 'Build approval-ready templates',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isSw
                      ? 'Andika, hakiki na tuma violezo vya huduma, matangazo au uthibitisho kwa WhatsApp.'
                      : 'Author, preview and submit utility, marketing and authentication templates for WhatsApp.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusFilters(BuildContext context) {
    final tiles = [
      _StatusTileData(
        label: _isSw ? 'Zote' : 'All',
        count: controller.templates.length,
        status: null,
        color: RentTheme.teal,
      ),
      _StatusTileData(
        label: _isSw ? 'Rasimu' : 'Drafts',
        count: controller.countByStatus(WaTemplateStatus.draft),
        status: WaTemplateStatus.draft,
        color: const Color(0xFF6B7280),
      ),
      _StatusTileData(
        label: _isSw ? 'Ukaguzi' : 'Review',
        count: controller.countByStatus(WaTemplateStatus.submitted),
        status: WaTemplateStatus.submitted,
        color: const Color(0xFFD97706),
      ),
      _StatusTileData(
        label: _isSw ? 'Zilizoidhinishwa' : 'Approved',
        count: controller.countByStatus(WaTemplateStatus.approved),
        status: WaTemplateStatus.approved,
        color: const Color(0xFF16A34A),
      ),
      _StatusTileData(
        label: _isSw ? 'Zilizokataliwa' : 'Rejected',
        count: controller.countByStatus(WaTemplateStatus.rejected),
        status: WaTemplateStatus.rejected,
        color: const Color(0xFFDC2626),
      ),
    ];

    return Obx(() {
      final selected = controller.statusFilter.value;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: 4),
        child: Row(
          children: [
            for (final t in tiles) ...[
              _filterChip(context, t, isActive: selected == t.status),
              const SizedBox(width: 8),
            ],
          ],
        ),
      );
    });
  }

  Widget _filterChip(BuildContext context, _StatusTileData t,
      {required bool isActive}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isActive
        ? t.color
        : (isDark ? context.tokens.cardBackground : Colors.white);
    final fg = isActive
        ? Colors.white
        : (isDark ? Colors.white : RentTheme.navy);
    return InkWell(
      onTap: () => controller.setStatusFilter(t.status),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive
                ? t.color
                : (isDark ? context.tokens.elevatedSurface : RentTheme.border),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.2)
                    : t.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${t.count}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isActive ? Colors.white : t.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _listSection(BuildContext context) {
    final items = controller.filteredTemplates;
    if (items.isEmpty) return _emptyState(context);
    return Column(
      children: [
        for (final t in items) ...[
          _templateCard(context, t),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _emptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? context.tokens.cardBackground : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? context.tokens.elevatedSurface : RentTheme.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.chat_bubble_outline_rounded,
              size: 44, color: RentTheme.teal),
          const SizedBox(height: 12),
          Text(
            _isSw ? 'Hakuna violezo bado' : 'No templates yet',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : RentTheme.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isSw
                ? 'Gonga KIOLEZO KIPYA ili kutengeneza wa kwanza.'
                : 'Tap NEW TEMPLATE to create your first one.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : RentTheme.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _templateCard(BuildContext context, RentWhatsappTemplateRecord t) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : RentTheme.navy;
    final mutedColor = isDark ? Colors.white70 : RentTheme.muted;
    return Material(
      color: isDark ? context.tokens.cardBackground : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openEditor(existing: t),
        onLongPress: () => _openActionsSheet(context, t),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark ? context.tokens.elevatedSurface : RentTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t.name,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _statusBadge(t.status),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _tinyPill(WaTemplateCategory.label(t.category)),
                  const SizedBox(width: 6),
                  _tinyPill(t.language),
                  const Spacer(),
                  Text(
                    _relativeUpdated(t.updatedAtMs),
                    style: TextStyle(fontSize: 11, color: mutedColor),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                t.bodyText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: titleColor,
                  height: 1.35,
                ),
              ),
              if (t.buttons.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final b in t.buttons) _buttonPill(b.label, b.type),
                  ],
                ),
              ],
              if (t.status == WaTemplateStatus.rejected &&
                  t.rejectionReason.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 16, color: Color(0xFFDC2626)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          t.rejectionReason,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFDC2626),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final config = _statusConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 12, color: config.fg),
          const SizedBox(width: 4),
          Text(
            _localizedStatus(status),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: config.fg,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  _StatusBadgeConfig _statusConfig(String status) {
    switch (status) {
      case WaTemplateStatus.draft:
        return const _StatusBadgeConfig(
          Icons.edit_note_rounded,
          Color(0xFFE5E7EB),
          Color(0xFF374151),
        );
      case WaTemplateStatus.submitted:
        return const _StatusBadgeConfig(
          Icons.hourglass_bottom_rounded,
          Color(0xFFFEF3C7),
          Color(0xFF92400E),
        );
      case WaTemplateStatus.approved:
        return const _StatusBadgeConfig(
          Icons.verified_rounded,
          Color(0xFFDCFCE7),
          Color(0xFF166534),
        );
      case WaTemplateStatus.rejected:
        return const _StatusBadgeConfig(
          Icons.block_rounded,
          Color(0xFFFEE2E2),
          Color(0xFF991B1B),
        );
    }
    return const _StatusBadgeConfig(
      Icons.circle_outlined,
      Color(0xFFE5E7EB),
      Color(0xFF374151),
    );
  }

  String _localizedStatus(String status) {
    if (!_isSw) return WaTemplateStatus.label(status).toUpperCase();
    switch (status) {
      case WaTemplateStatus.draft:
        return 'RASIMU';
      case WaTemplateStatus.submitted:
        return 'UKAGUZI';
      case WaTemplateStatus.approved:
        return 'IMETHIBITISHWA';
      case WaTemplateStatus.rejected:
        return 'IMEKATALIWA';
    }
    return status.toUpperCase();
  }

  Widget _tinyPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: RentTheme.teal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: RentTheme.teal,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buttonPill(String label, String type) {
    IconData icon;
    switch (type) {
      case 'url':
        icon = Icons.open_in_new_rounded;
        break;
      case 'phone_number':
        icon = Icons.phone_rounded;
        break;
      default:
        icon = Icons.reply_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: RentTheme.conciergeTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: RentTheme.conciergeTeal.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: RentTheme.conciergeTeal),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: RentTheme.conciergeTeal,
            ),
          ),
        ],
      ),
    );
  }

  void _openEditor({RentWhatsappTemplateRecord? existing}) {
    Get.to(
      () => RentWhatsappTemplateEditorView(existing: existing),
      transition: Transition.cupertino,
    );
  }

  void _openActionsSheet(BuildContext context,
      RentWhatsappTemplateRecord t) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? context.tokens.scaffoldBackground : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD8D4CB),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: RentTheme.teal),
              title: Text(_isSw ? 'Hariri' : 'Edit'),
              onTap: () {
                Navigator.pop(context);
                _openEditor(existing: t);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.copy_all_rounded, color: RentTheme.teal),
              title: Text(_isSw ? 'Nakili' : 'Duplicate'),
              onTap: () {
                Navigator.pop(context);
                controller.duplicate(t);
              },
            ),
            if (t.status == WaTemplateStatus.submitted) ...[
              ListTile(
                leading: const Icon(Icons.verified_rounded,
                    color: Color(0xFF16A34A)),
                title: Text(
                    _isSw ? 'Alika idhini (demo)' : 'Simulate approval'),
                onTap: () {
                  Navigator.pop(context);
                  controller.simulateApproval(t.id);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.block_rounded, color: Color(0xFFDC2626)),
                title: Text(
                    _isSw ? 'Alika kukataliwa (demo)' : 'Simulate rejection'),
                onTap: () {
                  Navigator.pop(context);
                  controller.simulateRejection(
                    t.id,
                    reason: _isSw
                        ? 'Haifuati sera za Meta'
                        : 'Does not comply with Meta policy',
                  );
                },
              ),
            ],
            ListTile(
              leading:
                  const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: Text(
                _isSw ? 'Futa' : 'Delete',
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () async {
                Navigator.pop(context);
                final ok = await Get.dialog<bool>(
                  AlertDialog(
                    title: Text(_isSw ? 'Futa kiolezo?' : 'Delete template?'),
                    content: Text(_isSw
                        ? 'Kitendo hiki hakitafutika.'
                        : 'This cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(result: false),
                        child: Text(_isSw ? 'Sitisha' : 'Cancel'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: Colors.red),
                        onPressed: () => Get.back(result: true),
                        child: Text(_isSw ? 'Futa' : 'Delete'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  final snapshot = t;
                  await controller.delete(t.id);
                  if (context.mounted) {
                    UndoSnackBar.show(
                      context,
                      message: _isSw ? 'Kiolezo kimefutwa' : 'Template deleted',
                      undoLabel: _isSw ? 'Rudisha' : 'Undo',
                      onUndo: () => controller.restoreTemplate(snapshot),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _relativeUpdated(int ms) {
    if (ms == 0) return '';
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return _isSw ? 'sasa hivi' : 'just now';
    if (diff.inHours < 1) {
      return _isSw ? 'dakika ${diff.inMinutes}' : '${diff.inMinutes}m';
    }
    if (diff.inDays < 1) {
      return _isSw ? 'saa ${diff.inHours}' : '${diff.inHours}h';
    }
    if (diff.inDays < 7) {
      return _isSw ? 'siku ${diff.inDays}' : '${diff.inDays}d';
    }
    return DateFormat('MMM d').format(d);
  }
}

class _StatusTileData {
  const _StatusTileData({
    required this.label,
    required this.count,
    required this.status,
    required this.color,
  });

  final String label;
  final int count;
  final String? status;
  final Color color;
}

class _StatusBadgeConfig {
  const _StatusBadgeConfig(this.icon, this.bg, this.fg);
  final IconData icon;
  final Color bg;
  final Color fg;
}

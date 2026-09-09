import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/form_surface_colors.dart';
import '/app/core/base/rent_base_view.dart';
import '/app/core/values/app_colors.dart';
import '/app/core/widget/custom_app_bar.dart';
import '/app/core/widget/skeleton_presets.dart';
import '/app/data/local/db/inventory_item_local_data_source.dart';
import '/app/data/local/db/inventory_movement_local_data_source.dart';
import '../controllers/inventory_tracking_controller.dart';

class InventoryTrackingView extends RentBaseView<InventoryTrackingController> {
  InventoryTrackingView({super.key});

  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    final name = (Get.parameters['propertyName'] ?? '').trim();
    final isGlobal = (Get.parameters['propertyRef'] ?? '').trim().isEmpty;
    return CustomAppBar(
      appBarTitleText: name.isNotEmpty
          ? name
          : isGlobal
              ? (_isSw ? 'Vifaa — Mali Zote' : 'Inventory — All Properties')
              : (_isSw ? 'Orodha ya Vifaa' : 'Inventory tracking'),
      showLanguageToggle: false,
      showThemeToggle: false,
      actions: [
        Obx(
          () => IconButton(
            onPressed: controller.exporting.value
                ? null
                : () => controller.exportToCsv(shareContext: context),
            icon: controller.exporting.value
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file_outlined),
            tooltip: _isSw ? 'Hamisha CSV' : 'Export CSV',
          ),
        ),
        // Import CSV requires a property context — hide in global mode
        if (!isGlobal)
          IconButton(
            onPressed: () => _showImportSheet(context),
            icon: const Icon(Icons.download_outlined),
            tooltip: _isSw ? 'Ingiza CSV' : 'Import CSV',
          ),
      ],
    );
  }

  Future<void> _showImportSheet(BuildContext context) async {
    final isSw = _isSw;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSw ? 'Ingiza CSV' : 'Import from CSV',
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              isSw
                  ? 'Tumia "Hamisha CSV" kwanza, hariri kwa Excel/Sheets, '
                    'kisha bandike hapa au shiriki faili.'
                  : 'Use "Export CSV" first, edit in Excel/Sheets, '
                    'then paste here or share the file back.',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            _CsvPasteField(controller: controller, isSw: isSw),
          ],
        ),
      ),
    );
  }

  @override
  Widget? floatingActionButton() {
    // In global mode (no property context) we can't add items without knowing
    // which property they belong to, so the FAB is hidden.
    if (controller.isGlobalMode) return null;
    return FloatingActionButton.extended(
      onPressed: controller.onAddItem,
      backgroundColor: AppColors.colorPrimary,
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: Text(
        _isSw ? 'Ongeza' : 'Add',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    final u = FormSurfaceColors.of(context);
    return SafeArea(
      child: Obx(() {
        if (controller.loading.value) {
          return const Center(child: DefaultScreenSkeleton());
        }
        return RefreshIndicator(
          color: AppColors.colorPrimary,
          onRefresh: controller.loadAll,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            children: [
              _summaryCard(u),
              if (controller.availableUnits.isNotEmpty) ...[
                const SizedBox(height: 14),
                _unitTabs(u),
              ],
              const SizedBox(height: 16),
              if (controller.items.isEmpty)
                _emptyPlaceholder(u)
              else
                ...controller.items.map((item) => _itemCard(u, item)),
            ],
          ),
        );
      }),
    );
  }

  Widget _summaryCard(FormSurfaceColors u) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: u.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSw ? 'Muhtasari wa Mali' : 'Property summary',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: u.hint,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _summaryStat(
                  u,
                  label: _isSw ? 'Jumla' : 'Total items',
                  value: '${controller.totalItems.value}',
                  icon: Icons.inventory_2_outlined,
                ),
              ),
              Expanded(
                child: _summaryStat(
                  u,
                  label: _isSw ? 'Hisa chini' : 'Low stock',
                  value: '${controller.lowStockCount.value}',
                  icon: Icons.warning_amber_rounded,
                  accent: controller.lowStockCount.value > 0
                      ? const Color(0xFFD97706)
                      : null,
                ),
              ),
              Expanded(
                child: _summaryStat(
                  u,
                  label: _isSw ? 'Mabadiliko' : 'Recent changes',
                  value: '${controller.recentlyChangedCount.value}',
                  icon: Icons.history_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryStat(
    FormSurfaceColors u, {
    required String label,
    required String value,
    required IconData icon,
    Color? accent,
  }) {
    final color = accent ?? AppColors.colorPrimary;
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: u.headline,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: u.hint),
        ),
      ],
    );
  }

  Widget _unitTabs(FormSurfaceColors u) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isSw ? 'Chagua Unit' : 'Units',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: u.hint,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Obx(() {
            final selected = controller.selectedUnitId.value;
            return Row(
              children: [
                _unitChip(
                  u: u,
                  label: _isSw ? 'Zote' : 'All units',
                  selected: selected.isEmpty,
                  onTap: () => controller.selectUnit(''),
                ),
                ...controller.availableUnits.map(
                  (unit) => _unitChip(
                    u: u,
                    label: unit.unitName,
                    selected: selected == unit.unitId,
                    onTap: () => controller.selectUnit(unit.unitId),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _unitChip({
    required FormSurfaceColors u,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.colorPrimary
                : u.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.colorPrimary
                  : u.border.withValues(alpha: 0.7),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : u.headline,
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyPlaceholder(FormSurfaceColors u) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.colorPrimary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 36,
                color: AppColors.colorPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isSw ? 'Hakuna vifaa bado' : 'No inventory items yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: u.headline,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _isSw
                  ? 'Gusa Ongeza kuongeza kipengele cha hesabu.'
                  : 'Tap Add to record your first item.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: u.hint),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemCard(FormSurfaceColors u, InventoryItemRecord item) {
    final low = item.isLowStock;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: u.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _openHistorySheet(u, item),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: low
                    ? const Color(0xFFD97706).withValues(alpha: 0.45)
                    : u.border.withValues(alpha: 0.6),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: u.headline,
                        ),
                      ),
                    ),
                    if (low)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              size: 12,
                              color: Color(0xFFD97706),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _isSw ? 'Hisa chini' : 'Low stock',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${item.category} · ${item.condition}',
                      style: TextStyle(fontSize: 12, color: u.hint),
                    ),
                    if (item.locationNote.trim().isNotEmpty) ...[
                      Text(' · ', style: TextStyle(fontSize: 12, color: u.hint)),
                      Expanded(
                        child: Text(
                          item.locationNote.trim(),
                          style: TextStyle(fontSize: 12, color: u.hint),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Qty + reorder progress
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            _isSw ? 'Idadi: ' : 'Qty: ',
                            style: TextStyle(fontSize: 13, color: u.hint),
                          ),
                          Text(
                            '${item.quantity}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: low
                                  ? const Color(0xFFD97706)
                                  : u.headline,
                            ),
                          ),
                          if (item.reorderLevel > 0) ...[
                            Text(
                              ' / ${item.reorderLevel}',
                              style: TextStyle(fontSize: 12, color: u.hint),
                            ),
                          ],
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _openAdjustSheet(u, item),
                      icon: const Icon(Icons.tune_rounded, size: 16),
                      label: Text(_isSw ? 'Rekebisha' : 'Adjust',
                          style: const TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.colorPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    IconButton(
                      onPressed: () => controller.onEditItem(item),
                      icon: Icon(Icons.edit_outlined, color: u.hint, size: 18),
                      tooltip: _isSw ? 'Hariri' : 'Edit',
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Movement history sheet ──────────────────────────────────────────────

  Future<void> _openHistorySheet(FormSurfaceColors u, InventoryItemRecord item) async {
    final movements = await controller.loadMovements(item);
    await Get.bottomSheet(
      _HistorySheet(u: u, item: item, movements: movements, isSw: _isSw,
          onAdjust: () { Get.back(); _openAdjustSheet(u, item); },
          onEdit: () { Get.back(); controller.onEditItem(item); }),
      isScrollControlled: true,
    );
  }

  Future<void> _openAdjustSheet(
    FormSurfaceColors u,
    InventoryItemRecord item,
  ) async {
    final host = Get.context;
    if (host == null) return;

    final qtyController = TextEditingController(text: '1');
    final notesController = TextEditingController();
    var movementType = 'add';
    var saving = false;

    // Use Flutter's sheet, not Get.bottomSheet: GetX's route pads the whole
    // sheet by the keyboard inset and can pin an unconstrained child to the
    // top of the screen (content hidden behind the status bar).
    await showModalBottomSheet<void>(
      context: host,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final media = MediaQuery.of(context);
            final qtyLabel = movementType == 'adjust'
                ? (_isSw ? 'Idadi mpya' : 'New quantity')
                : (_isSw ? 'Idadi' : 'Quantity');
            return Padding(
              padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Material(
                  color: u.card,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: media.size.height * 0.85,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 36,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: u.hint.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                          Text(
                            _isSw ? 'Rekebisha hisa' : 'Adjust stock',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: u.headline,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.name} · ${_isSw ? 'sasa' : 'now'} ${item.quantity}',
                            style: TextStyle(fontSize: 13, color: u.hint),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            children: [
                              _movementChip(
                                u,
                                label: _isSw ? 'Ongeza' : 'Add',
                                selected: movementType == 'add',
                                onTap: () => setState(() {
                                  movementType = 'add';
                                  if (qtyController.text.trim().isEmpty ||
                                      qtyController.text.trim() ==
                                          '${item.quantity}') {
                                    qtyController.text = '1';
                                  }
                                }),
                              ),
                              _movementChip(
                                u,
                                label: _isSw ? 'Tumia' : 'Use',
                                selected: movementType == 'use',
                                onTap: () => setState(() {
                                  movementType = 'use';
                                  if (qtyController.text.trim() ==
                                      '${item.quantity}') {
                                    qtyController.text = '1';
                                  }
                                }),
                              ),
                              _movementChip(
                                u,
                                label: _isSw ? 'Uharibifu' : 'Damage',
                                selected: movementType == 'damage',
                                onTap: () => setState(() {
                                  movementType = 'damage';
                                  if (qtyController.text.trim() ==
                                      '${item.quantity}') {
                                    qtyController.text = '1';
                                  }
                                }),
                              ),
                              _movementChip(
                                u,
                                label: _isSw ? 'Sahihisha' : 'Set',
                                selected: movementType == 'adjust',
                                onTap: () => setState(() {
                                  movementType = 'adjust';
                                  qtyController.text = '${item.quantity}';
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: qtyController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              labelText: qtyLabel,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: notesController,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              labelText: _isSw
                                  ? 'Maelezo (si lazima)'
                                  : 'Notes (optional)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: saving
                                  ? null
                                  : () async {
                                      FocusScope.of(context).unfocus();
                                      final qty = int.tryParse(
                                            qtyController.text.trim(),
                                          ) ??
                                          0;
                                      if (qty <= 0) {
                                        controller.showErrorMessage(
                                          _isSw
                                              ? 'Weka idadi halali.'
                                              : 'Enter a valid quantity.',
                                        );
                                        return;
                                      }
                                      var delta = qty;
                                      if (movementType == 'use' ||
                                          movementType == 'damage') {
                                        delta = -qty;
                                      } else if (movementType == 'adjust') {
                                        delta = qty - item.quantity;
                                        if (delta == 0) {
                                          controller.showErrorMessage(
                                            _isSw
                                                ? 'Idadi haijabadilika.'
                                                : 'Quantity is unchanged.',
                                          );
                                          return;
                                        }
                                      }
                                      setState(() => saving = true);
                                      final ok = await controller.adjustStock(
                                        item: item,
                                        movementType: movementType,
                                        quantityDelta: delta,
                                        notes: notesController.text.trim(),
                                      );
                                      if (!ok) {
                                        if (context.mounted) {
                                          setState(() => saving = false);
                                        }
                                        return;
                                      }
                                      if (sheetContext.mounted) {
                                        Navigator.of(sheetContext).pop();
                                      }
                                    },
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.colorPrimary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: saving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _isSw ? 'Hifadhi' : 'Save',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    qtyController.dispose();
    notesController.dispose();
  }

  Widget _movementChip(
    FormSurfaceColors u, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.colorPrimary.withValues(alpha: 0.18),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: selected ? AppColors.colorPrimary : u.headline,
      ),
    );
  }
}

// ── CSV paste field ─────────────────────────────────────────────────────────

class _CsvPasteField extends StatefulWidget {
  const _CsvPasteField({
    required this.controller,
    required this.isSw,
  });
  final InventoryTrackingController controller;
  final bool isSw;

  @override
  State<_CsvPasteField> createState() => _CsvPasteFieldState();
}

class _CsvPasteFieldState extends State<_CsvPasteField> {
  final _tc = TextEditingController();

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _tc,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: 'Name,Category,Quantity,…',
            border: const OutlineInputBorder(),
            labelText: widget.isSw ? 'Bandika CSV hapa' : 'Paste CSV here',
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () => FilledButton(
            onPressed: widget.controller.importing.value
                ? null
                : () async {
                    final csv = _tc.text.trim();
                    if (csv.isEmpty) return;
                    Get.back();
                    await widget.controller.importFromCsv(csv);
                  },
            child: widget.controller.importing.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    widget.isSw ? 'Ingiza' : 'Import',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }
}

// ── Movement history bottom sheet ──────────────────────────────────────────

class _HistorySheet extends StatelessWidget {
  const _HistorySheet({
    required this.u,
    required this.item,
    required this.movements,
    required this.isSw,
    required this.onAdjust,
    required this.onEdit,
  });

  final FormSurfaceColors u;
  final InventoryItemRecord item;
  final List<InventoryMovementRecord> movements;
  final bool isSw;
  final VoidCallback onAdjust;
  final VoidCallback onEdit;

  static const _amber = Color(0xFFD97706);
  static const _red   = Color(0xFFDC2626);
  static const _green = Color(0xFF16A34A);
  static const _blue  = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: u.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: u.headline,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.category} · ${item.condition}'
                      '${item.locationNote.trim().isNotEmpty ? ' · ${item.locationNote.trim()}' : ''}',
                      style: TextStyle(fontSize: 12, color: u.hint),
                    ),
                  ],
                ),
              ),
              // Low-stock pill
              if (item.isLowStock)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 12, color: _amber),
                      const SizedBox(width: 3),
                      const Text(
                        'Low',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _amber,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Qty row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.colorPrimary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 18, color: AppColors.colorPrimary),
                const SizedBox(width: 8),
                Text(
                  isSw ? 'Idadi ya sasa: ' : 'Current qty: ',
                  style: TextStyle(fontSize: 13, color: u.hint),
                ),
                Text(
                  '${item.quantity}',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: item.isLowStock ? _amber : u.headline,
                  ),
                ),
                if (item.reorderLevel > 0) ...[
                  Text(
                    '  ·  ${isSw ? 'kiwango cha chini' : 'reorder at'} ${item.reorderLevel}',
                    style: TextStyle(fontSize: 12, color: u.hint),
                  ),
                ],
                const Spacer(),
                TextButton(
                  onPressed: onAdjust,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    foregroundColor: AppColors.colorPrimary,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(isSw ? 'Rekebisha' : 'Adjust',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: Icon(Icons.edit_outlined, color: u.hint, size: 18),
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isSw ? 'Historia ya mabadiliko' : 'Movement history',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: u.hint,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          // Movement list
          Flexible(
            child: movements.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        isSw
                            ? 'Hakuna historia ya mabadiliko bado.'
                            : 'No movement history yet.',
                        style: TextStyle(fontSize: 13, color: u.hint),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: movements.length,
                    separatorBuilder: (context, _) =>
                        Divider(height: 1, color: u.border),
                    itemBuilder: (_, i) =>
                        _movementTile(movements[i]),
                  ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _movementTile(InventoryMovementRecord m) {
    final isPositive = m.quantityDelta > 0;
    final type = m.movementType.toLowerCase();

    Color typeColor;
    IconData typeIcon;
    switch (type) {
      case 'add':
      case 'restock':
        typeColor = _green;
        typeIcon = Icons.add_circle_outline_rounded;
        break;
      case 'use':
        typeColor = _blue;
        typeIcon = Icons.remove_circle_outline_rounded;
        break;
      case 'damage':
        typeColor = _red;
        typeIcon = Icons.report_outlined;
        break;
      default:
        typeColor = isPositive ? _green : _amber;
        typeIcon = isPositive
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded;
    }

    final dt = DateTime.fromMillisecondsSinceEpoch(m.createdAtMs);
    final dateLabel = DateFormat('d MMM yyyy · HH:mm').format(dt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(typeIcon, size: 18, color: typeColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _typeLabel(type),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: u.headline,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dateLabel,
                      style: TextStyle(fontSize: 11, color: u.hint),
                    ),
                  ],
                ),
                if (m.notes.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    m.notes.trim(),
                    style: TextStyle(fontSize: 12, color: u.hint),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isPositive ? '+' : ''}${m.quantityDelta}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: typeColor,
            ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'add':     return isSw ? 'Ongezeko' : 'Added';
      case 'use':     return isSw ? 'Imetumika' : 'Used';
      case 'damage':  return isSw ? 'Uharibifu' : 'Damaged';
      case 'restock': return isSw ? 'Kujaza tena' : 'Restocked';
      case 'adjust':  return isSw ? 'Marekebisho' : 'Adjusted';
      default:        return type;
    }
  }
}

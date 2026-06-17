import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/app/core/theme/form_surface_colors.dart';
import '/app/core/values/app_colors.dart';
import '/app/data/local/db/inventory_item_local_data_source.dart';
import '/app/data/local/db/inventory_movement_local_data_source.dart';
import '../controllers/inventory_tracking_controller.dart';

/// Pre-checkout inventory check for BnB.
///
/// Shows all items for [propertyRef] / optional [apartmentUnitId] and lets the
/// host mark each one OK, Used, or Damaged.  Damaged marks automatically write
/// a 'damage' movement and decrement the item's quantity before proceeding.
///
/// Returns `true` when the user confirms checkout, `false` when they cancel.
Future<bool> showInventoryCheckoutChecklist({
  required BuildContext context,
  required String propertyRef,
  String apartmentUnitId = '',
  String propertyName = '',
}) async {
  final result = await Get.bottomSheet<bool>(
    _ChecklistSheet(
      propertyRef: propertyRef,
      apartmentUnitId: apartmentUnitId,
      propertyName: propertyName,
    ),
    isScrollControlled: true,
    ignoreSafeArea: false,
  );
  return result == true;
}

// ── Internal widget ─────────────────────────────────────────────────────────

enum _ItemStatus { ok, used, damaged }

class _ChecklistSheet extends StatefulWidget {
  const _ChecklistSheet({
    required this.propertyRef,
    required this.apartmentUnitId,
    required this.propertyName,
  });

  final String propertyRef;
  final String apartmentUnitId;
  final String propertyName;

  @override
  State<_ChecklistSheet> createState() => _ChecklistSheetState();
}

class _ChecklistSheetState extends State<_ChecklistSheet> {
  bool _loading = true;
  bool _saving  = false;
  List<InventoryItemRecord> _items = const [];
  final Map<int, _ItemStatus> _status = {};

  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final src = Get.find<InventoryItemLocalDataSource>();
    final rows = await src.listForProperty(
      propertyRef: widget.propertyRef,
      apartmentUnitId: widget.apartmentUnitId,
    );
    for (final r in rows) {
      _status[r.id] = _ItemStatus.ok;
    }
    if (mounted) setState(() { _items = rows; _loading = false; });
  }

  Future<void> _confirm() async {
    setState(() => _saving = true);
    try {
      final itemSrc     = Get.find<InventoryItemLocalDataSource>();
      final movementSrc = Get.find<InventoryMovementLocalDataSource>();

      for (final item in _items) {
        final st = _status[item.id] ?? _ItemStatus.ok;
        if (st == _ItemStatus.ok) continue;

        final movementType = st == _ItemStatus.damaged ? 'damage' : 'use';
        final delta = -1;
        final newQty = (item.quantity + delta).clamp(0, 999999);

        await itemSrc.updateQuantity(item.id, newQty);
        await movementSrc.insert(
          itemLocalId: item.id,
          clientMovementId:
              'co_${DateTime.now().microsecondsSinceEpoch}_${item.id}',
          movementType: movementType,
          quantityDelta: delta,
          notes: _isSw ? 'Kutoka ukaguzi wa checkout' : 'From checkout checklist',
        );
      }

      // Try to sync via controller if available
      try {
        final ctrl = Get.find<InventoryTrackingController>();
        await ctrl.loadAll();
      } catch (_) {}

      Get.back(result: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = FormSurfaceColors.of(context);
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.80,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: u.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Icon(Icons.checklist_rounded,
                  color: AppColors.colorPrimary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isSw ? 'Ukaguzi wa Checkout' : 'Checkout checklist',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: u.headline,
                  ),
                ),
              ),
            ],
          ),
          if (widget.propertyName.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              widget.propertyName,
              style: TextStyle(fontSize: 13, color: u.hint),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            _isSw
                ? 'Angalia hali ya kila kitu kabla ya mgeni kuondoka.'
                : 'Review every item condition before the guest departs.',
            style: TextStyle(fontSize: 12.5, color: u.hint),
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  _isSw
                      ? 'Hakuna vifaa vilivyorekodiwa kwa mali hii.'
                      : 'No inventory items recorded for this property.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: u.hint),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _items.length,
                separatorBuilder: (context, _) =>
                    Divider(height: 1, color: u.border),
                itemBuilder: (_, i) => _itemRow(u, _items[i]),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Get.back(result: false),
                  child: Text(
                    _isSw ? 'Ghairi' : 'Cancel',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _saving || _loading ? null : _confirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.colorPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _isSw ? 'Thibitisha checkout' : 'Confirm checkout',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _itemRow(FormSurfaceColors u, InventoryItemRecord item) {
    final st = _status[item.id] ?? _ItemStatus.ok;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: u.headline,
                  ),
                ),
                Text(
                  '${item.category}'
                  '${item.locationNote.trim().isNotEmpty ? ' · ${item.locationNote.trim()}' : ''}'
                  ' · qty ${item.quantity}',
                  style: TextStyle(fontSize: 12, color: u.hint),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SegmentedButton<_ItemStatus>(
            segments: [
              ButtonSegment(
                value: _ItemStatus.ok,
                label: Text(_isSw ? 'Sawa' : 'OK',
                    style: const TextStyle(fontSize: 11)),
              ),
              ButtonSegment(
                value: _ItemStatus.used,
                label: Text(_isSw ? 'Tumika' : 'Used',
                    style: const TextStyle(fontSize: 11)),
              ),
              ButtonSegment(
                value: _ItemStatus.damaged,
                label: Text(_isSw ? 'Uharibifu' : 'Damaged',
                    style: const TextStyle(fontSize: 11)),
              ),
            ],
            selected: {st},
            onSelectionChanged: (s) =>
                setState(() => _status[item.id] = s.first),
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

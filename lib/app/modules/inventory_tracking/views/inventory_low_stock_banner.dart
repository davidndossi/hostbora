import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/app/core/values/app_colors.dart';
import '/app/data/local/db/inventory_item_local_data_source.dart';
import '/app/routes/app_pages.dart';

/// A compact banner widget that shows a low-stock / inventory summary across
/// all properties.  Designed to embed on the home screen or finance overview.
///
/// It self-loads from SQLite, so it requires no controller — just drop it
/// in any widget tree after [LocalSourceBindings] have registered the
/// [InventoryItemLocalDataSource].
class InventoryLowStockBanner extends StatefulWidget {
  const InventoryLowStockBanner({super.key});

  @override
  State<InventoryLowStockBanner> createState() =>
      _InventoryLowStockBannerState();
}

class _InventoryLowStockBannerState extends State<InventoryLowStockBanner> {
  int _total    = 0;
  int _lowStock = 0;
  bool _loaded  = false;

  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final src = Get.find<InventoryItemLocalDataSource>();
      final db = await src.database;
      const t = 'inventory_item';
      final totalRes = await db.rawQuery(
          "SELECT COUNT(*) as c FROM $t");
      final lowRes = await db.rawQuery(
          "SELECT COUNT(*) as c FROM $t "
          "WHERE reorder_level > 0 AND quantity <= reorder_level");
      if (!mounted) return;
      setState(() {
        _total    = (totalRes.first['c'] as num?)?.toInt() ?? 0;
        _lowStock = (lowRes.first['c'] as num?)?.toInt() ?? 0;
        _loaded   = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _total == 0) return const SizedBox.shrink();

    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg   = dark ? const Color(0xFF1C1C1E) : Colors.white;
    final border = dark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E7EB);

    return GestureDetector(
      onTap: () => Get.toNamed(Routes.INVENTORY_TRACKING),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _lowStock > 0
                ? const Color(0xFFD97706).withValues(alpha: 0.45)
                : border.withValues(alpha: 0.7),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: (_lowStock > 0
                        ? const Color(0xFFD97706)
                        : AppColors.colorPrimary)
                    .withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _lowStock > 0
                    ? Icons.warning_amber_rounded
                    : Icons.inventory_2_outlined,
                size: 20,
                color: _lowStock > 0
                    ? const Color(0xFFD97706)
                    : AppColors.colorPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isSw ? 'Ufuatiliaji wa Vifaa' : 'Inventory',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: dark
                          ? const Color(0xFFF2F2F7)
                          : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _lowStock > 0
                        ? (_isSw
                            ? '$_lowStock ${_lowStock == 1 ? 'kifaa kinahitaji' : 'vifaa vinahitaji'} kujazwa tena · jumla $_total'
                            : '$_lowStock item${_lowStock == 1 ? '' : 's'} low on stock · $_total total')
                        : (_isSw
                            ? 'Vifaa $_total, hisa yote inatosha'
                            : '$_total item${_total == 1 ? '' : 's'}, all stock levels OK'),
                    style: TextStyle(
                      fontSize: 12,
                      color: _lowStock > 0
                          ? const Color(0xFFD97706)
                          : (dark
                              ? const Color(0xFFAEAEB2)
                              : const Color(0xFF6B7280)),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: dark
                  ? const Color(0xFFAEAEB2)
                  : const Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }
}


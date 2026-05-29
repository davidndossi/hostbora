import 'package:flutter/material.dart';
import 'package:paa_yangu/app/core/widget/skeleton_presets.dart';

import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/property_unit_floor.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/unit_occupancy_controller.dart';

/// Legend / card colors aligned with host reference UI.
abstract final class _UnitOccColors {
  static const available = Color(0xFF2ECC71);
  static const occupied = Color(0xFFE74C3C);
  static const reserved = Color(0xFFF1C40F);
  static const maintenance = Color(0xFF7F8C8D);
  static const cleaning = Color(0xFF1ABC9C);
  static const refreshBlue = Color(0xFF4A90E2);
}

class UnitOccupancyView extends BaseView<UnitOccupancyController> {
  UnitOccupancyView({super.key});

  Color _cardColor(UnitOccupancyPalette p) {
    switch (p) {
      case UnitOccupancyPalette.available:
        return _UnitOccColors.available;
      case UnitOccupancyPalette.occupied:
        return _UnitOccColors.occupied;
      case UnitOccupancyPalette.reserved:
        return _UnitOccColors.reserved;
      case UnitOccupancyPalette.maintenance:
        return _UnitOccColors.maintenance;
      case UnitOccupancyPalette.cleaning:
        return _UnitOccColors.cleaning;
    }
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CustomAppBar(
      appBarTitleText: l10n.unitOccupancyTitle,
      isCentered: true,
    );
  }

  @override
  Widget body(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bg = Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.surface
        : const Color(0xFFF3F4F6);

    return ColoredBox(
      color: bg,
      child: Obx(() {
        if (controller.loading.value) {
          return const DefaultScreenSkeleton();
        }
        final building = controller.buildingTitle.value;
        final sections = controller.floorSections;
        if (sections.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l10n.unitOccupancyEmpty,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.reloadOccupancy,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
            children: [
              _legendBar(context, l10n),
              const SizedBox(height: 12),
              ...sections.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _floorSection(
                      context,
                      l10n,
                      building,
                      s,
                    ),
                  )),
            ],
          ),
        );
      }),
    );
  }

  Widget _legendBar(BuildContext context, AppLocalizations l10n) {
    final onSurf = Theme.of(context).colorScheme.onSurface;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _legendSwatch(context, l10n.unitOccupancyLegendAvailable, _UnitOccColors.available, onSurf),
              _legendSwatch(context, l10n.unitOccupancyLegendOccupied, _UnitOccColors.occupied, onSurf),
              _legendSwatch(context, l10n.unitOccupancyLegendReserved, _UnitOccColors.reserved, onSurf),
              _legendSwatch(context, l10n.unitOccupancyLegendMaintenance, _UnitOccColors.maintenance, onSurf),
              _legendSwatch(context, l10n.unitOccupancyLegendCleaning, _UnitOccColors.cleaning, onSurf),
            ],
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: controller.reloadOccupancy,
          icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
          label: Text(
            l10n.unitOccupancyRefresh,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Colors.white,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: _UnitOccColors.refreshBlue,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _legendSwatch(BuildContext context, String label, Color color, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.black12),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _floorSection(
    BuildContext context,
    AppLocalizations l10n,
    String building,
    UnitOccupancyFloorSectionVm section,
  ) {
    final floorTitle = PropertyUnitFloor.label(l10n, section.floorIndex);
    final floorNumber = section.floorIndex + 1;
    final rightLabel = l10n.unitOccupancyFloorLine(floorTitle, floorNumber);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      building.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2563EB),
                        letterSpacing: 0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      rightLabel,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
              child: LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth;
                  const spacing = 6.0;
                  var cross = 3;
                  if (w > 520) cross = 4;
                  if (w > 720) cross = 5;
                  final tileW = (w - spacing * (cross - 1)) / cross;
                  final aspect = (tileW / 92).clamp(0.72, 1.1).toDouble();
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: section.tiles.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cross,
                      mainAxisSpacing: spacing,
                      crossAxisSpacing: spacing,
                      childAspectRatio: aspect,
                    ),
                    itemBuilder: (context, i) {
                      final t = section.tiles[i];
                      return _unitCard(t);
                    },
                  );
                },
              ),
            ),
          ],
        ),
    );
  }

  Widget _unitCard(UnitOccupancyTileVm t) {
    final bg = _cardColor(t.palette);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              t.unitNumberLabel,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              t.typeLine,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                height: 1.15,
              ),
            ),
            const Spacer(),
            Text(
              t.priceLine,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

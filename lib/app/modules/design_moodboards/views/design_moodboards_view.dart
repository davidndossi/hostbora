import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../controllers/design_moodboards_controller.dart';

class DesignMoodboardsView extends BaseView<DesignMoodboardsController> {
  DesignMoodboardsView({super.key});

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  String _t(BuildContext context, {required String en, required String sw}) {
    final code =
        Get.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    return code == 'sw' ? sw : en;
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) => null;

  @override
  FloatingActionButtonLocation floatingActionButtonLocation() =>
      FloatingActionButtonLocation.endFloat;

  @override
  Widget? floatingActionButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FloatingActionButton(
        onPressed: controller.createNewMoodboard,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = _isDark(context);
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Row(
              children: [
                _circleIcon(
                  context,
                  Icons.arrow_back_ios_new_rounded,
                  onTap: Get.back,
                ),
                const Spacer(),
                _circleIcon(context, Icons.search_rounded, onTap: () {}),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text(
              _t(
                context,
                en: 'My Design Moodboards',
                sw: 'Moodboard Zangu za Ubunifu',
              ),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? theme.colorScheme.onSurface
                    : const Color(0xFF1A1A1A),
                height: 1.15,
              ),
            ),
          ),
          _filterChips(context),

          Expanded(
            child: Obx(() {
              final list = controller.filteredItems;
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.8,
                ),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final item = list[index];
                  return _MoodboardCard(
                    item: item,
                    onTap: () => controller.openMoodboardDetail(item),
                    t: _t,
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _filterChips(BuildContext context) {
    return Obx(() {
      final f = controller.filter.value;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            _FilterChip(
              label: _t(context, en: 'All Boards', sw: 'Bodi Zote'),
              selected: f == MoodboardFilter.all,
              onTap: () => controller.setFilter(MoodboardFilter.all),
            ),
            const SizedBox(width: 10),
            _FilterChip(
              label: _t(context, en: 'AI Concepts', sw: 'Dhana za AI'),
              selected: f == MoodboardFilter.aiConcepts,
              onTap: () => controller.setFilter(MoodboardFilter.aiConcepts),
            ),
            const SizedBox(width: 10),
            _FilterChip(
              label: _t(context, en: 'Materials', sw: 'Vifaa'),
              selected: f == MoodboardFilter.materials,
              onTap: () => controller.setFilter(MoodboardFilter.materials),
            ),
          ],
        ),
      );
    });
  }

  Widget _circleIcon(
    BuildContext context,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = _isDark(context);
    return Material(
      color: isDark
          ? theme.colorScheme.surfaceContainerHigh
          : AppColors.colorWhite,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 20,
            color: isDark
                ? theme.colorScheme.onSurface
                : AppColors.textColorPrimary,
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.colorPrimary : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? AppColors.colorPrimary
                  : const Color(0xFFE8E4DC),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF8A8680),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoodboardCard extends StatelessWidget {
  const _MoodboardCard({
    required this.item,
    required this.onTap,
    required this.t,
  });

  final MoodboardListItem item;
  final VoidCallback onTap;
  final String Function(
    BuildContext context, {
    required String en,
    required String sw,
  })
  t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: SizedBox(
                    width: double.infinity,
                    child: Image.asset(
                      item.assetPath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: isDark
                            ? theme.colorScheme.surfaceContainerHighest
                            : const Color(0xFFE8E4DC),
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                  ),
                ),
                if (item.showAiBadge)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 14,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'AI',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? theme.colorScheme.onSurface
                  : const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${item.savedCount} ${t(context, en: 'Saved Items', sw: 'Vipengee Vilivyohifadhiwa')}',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? theme.colorScheme.onSurfaceVariant
                  : const Color(0xFF8A8680),
            ),
          ),
        ],
      ),
    );
  }
}

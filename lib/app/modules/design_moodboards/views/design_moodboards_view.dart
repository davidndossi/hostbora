import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_decorations.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/design_moodboards_controller.dart';
import '../widgets/moodboard_image.dart';

class DesignMoodboardsView extends BaseView<DesignMoodboardsController> {
  DesignMoodboardsView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.designMoodboardsTitle,
      isCentered: true,
      actions: [
        IconButton(
          tooltip: appLocalization.designMoodboardOpenHomeDesigns,
          onPressed: controller.openHomeDesignsWeb,
          icon: const Icon(Icons.open_in_new_rounded),
        ),
      ],
    );
  }

  @override
  FloatingActionButtonLocation floatingActionButtonLocation() =>
      FloatingActionButtonLocation.endFloat;

  @override
  Widget? floatingActionButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FloatingActionButton.extended(
        onPressed: controller.createNewMoodboard,
        backgroundColor: AppColors.colorPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(appLocalization.designMoodboardsCreateBoard),
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? theme.colorScheme.surface : AppColors.pageBackground;

    return ColoredBox(
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!controller.isHomeDesignsConfigured)
            _apiBanner(context),
          _filterChips(context),
          Expanded(
            child: Obx(() {
              if (controller.loadFailed.value) {
                return _errorState(context);
              }
              final list = controller.filteredItems;
              if (list.isEmpty) {
                return _emptyState(context);
              }
              return RefreshIndicator(
                onRefresh: controller.reloadBoards,
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  physics: const AlwaysScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return _MoodboardCard(
                      item: item,
                      onTap: () => controller.openMoodboardDetail(item),
                      savedLabel: appLocalization.designMoodboardsSavedItems(
                        item.savedCount,
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _apiBanner(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: AppColors.colorPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: controller.openHomeDesignsWeb,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.colorPrimary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    appLocalization.designMoodboardApiNotConfigured,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      height: 1.35,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterChips(BuildContext context) {
    return Obx(() {
      final f = controller.filter.value;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(
          children: [
            _FilterChip(
              label: appLocalization.designMoodboardsFilterAll,
              selected: f == MoodboardFilter.all,
              onTap: () => controller.setFilter(MoodboardFilter.all),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: appLocalization.designMoodboardsFilterAi,
              selected: f == MoodboardFilter.aiConcepts,
              onTap: () => controller.setFilter(MoodboardFilter.aiConcepts),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: appLocalization.designMoodboardsFilterMaterials,
              selected: f == MoodboardFilter.materials,
              onTap: () => controller.setFilter(MoodboardFilter.materials),
            ),
          ],
        ),
      );
    });
  }

  Widget _emptyState(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 48),
        Icon(
          Icons.dashboard_customize_outlined,
          size: 64,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
        ),
        const SizedBox(height: 20),
        Text(
          appLocalization.designMoodboardsEmptyTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          appLocalization.designMoodboardsEmptyBody,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: FilledButton.icon(
            onPressed: controller.createNewMoodboard,
            icon: const Icon(Icons.add),
            label: Text(appLocalization.designMoodboardsCreateBoard),
          ),
        ),
      ],
    );
  }

  Widget _errorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 16),
            Text(
              appLocalization.designMoodboardsLoadError,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: controller.reloadBoards,
              icon: const Icon(Icons.refresh),
              label: Text(appLocalization.designMoodboardRetry),
            ),
          ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.colorPrimary
                : (isDark
                    ? Theme.of(context).colorScheme.surfaceContainerHigh
                    : AppColors.colorWhite),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? AppColors.colorPrimary
                  : AppColors.designInputBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurfaceVariant,
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
    required this.savedLabel,
  });

  final MoodboardListItem item;
  final VoidCallback onTap;
  final String savedLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardDeco = isDark
        ? BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          )
        : AppDecorations.cardWithRadius(16);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: DecoratedBox(
          decoration: cardDeco,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: MoodboardImage(
                        ref: item.imageRef,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (item.showAiBadge)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _AiBadge(),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      savedLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 12, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'AI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

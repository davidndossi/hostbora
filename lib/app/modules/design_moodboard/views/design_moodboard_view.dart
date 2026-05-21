import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_decorations.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../design_moodboards/widgets/moodboard_image.dart';
import '../controllers/design_moodboard_controller.dart';

class DesignMoodboardView extends BaseView<DesignMoodboardController> {
  DesignMoodboardView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: controller.moodboardTitle.isNotEmpty
          ? controller.moodboardTitle
          : appLocalization.designMoodboardsTitle,
      isCentered: false,
    );
  }

  @override
  Widget body(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? theme.colorScheme.surface : AppColors.pageBackground;

    return ColoredBox(
      color: bg,
      child: Obx(() {
        if (controller.loadFailed.value) {
          return _errorBody(context);
        }
        if (controller.board.value == null) {
          return _errorBody(context);
        }
        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.reloadBoard,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!controller.isHomeDesignsConfigured)
                        _apiHint(context),
                      Text(
                        controller.subtitleLine,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _sectionTitle(
                        context,
                        appLocalization.designMoodboardDesignConcepts,
                      ),
                      const SizedBox(height: 12),
                      _conceptsGrid(context),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: controller.addPhotoFromGallery,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: Text(appLocalization.designMoodboardAddPhoto),
                      ),
                      const SizedBox(height: 20),
                      _sectionTitle(
                        context,
                        appLocalization.designMoodboardColorPalette,
                      ),
                      const SizedBox(height: 12),
                      _paletteCard(context),
                      if (controller.textures.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _sectionTitle(
                          context,
                          appLocalization.designMoodboardFurnitureTextures,
                        ),
                        const SizedBox(height: 12),
                        _texturesRow(context),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            _bottomBar(context),
          ],
        );
      }),
    );
  }

  Widget _apiHint(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.colorPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          dense: true,
          leading: Icon(Icons.info_outline, color: AppColors.colorPrimary),
          title: Text(
            appLocalization.designMoodboardApiNotConfigured,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: TextButton(
            onPressed: controller.openApiGuide,
            child: Text(appLocalization.designMoodboardApiGuide),
          ),
        ),
      ),
    );
  }

  Widget _errorBody(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              appLocalization.designMoodboardsLoadError,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: controller.reloadBoard,
              icon: const Icon(Icons.refresh),
              label: Text(appLocalization.designMoodboardRetry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.colorPrimary,
        fontSize: 12,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _conceptsGrid(BuildContext context) {
    return Obx(() {
      final items = controller.concepts;
      if (items.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: AppDecorations.card,
          child: Text(
            appLocalization.designMoodboardsEmptyBody,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.92,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                MoodboardImage(ref: item.image, fit: BoxFit.cover),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                ),
                if (item.fromAi)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: _AiChip(),
                  ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _paletteCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Obx(() {
      final selected = controller.selectedPaletteIndex.value;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        decoration: isDark
            ? BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              )
            : AppDecorations.cardWithRadius(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(controller.palette.length, (i) {
            final sw = controller.palette[i];
            final isSel = i == selected;
            final fill = _fromHex(sw.hex);
            return Expanded(
              child: InkWell(
                onTap: () => controller.selectPalette(i),
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: fill,
                        border: Border.all(
                          color: isSel
                              ? AppColors.colorPrimary
                              : AppColors.designInputBorder,
                          width: isSel ? 3 : 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      sw.hex,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                        color: isSel
                            ? AppColors.colorPrimary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      );
    });
  }

  Widget _texturesRow(BuildContext context) {
    return Obx(() {
      return SizedBox(
        height: 140,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: controller.textures.length,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) => ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 120,
              child: MoodboardImage(
                ref: controller.textures[index],
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _bottomBar(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() {
              if (!controller.generating.value) return const SizedBox.shrink();
              return const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: LinearProgressIndicator(),
              );
            }),
            Row(
              children: [
                IconButton(
                  onPressed: () async {
                    await Share.share(
                      '${controller.moodboardTitle} — ${controller.subtitleLine}',
                      subject: controller.moodboardTitle,
                    );
                  },
                  icon: const Icon(Icons.share_outlined),
                ),
                IconButton(
                  onPressed: () => _showMoreMenu(context),
                  icon: const Icon(Icons.more_vert),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Obx(
                    () => FilledButton.icon(
                      onPressed: controller.generating.value
                          ? null
                          : controller.generateMoreLikeThis,
                      icon: controller.generating.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_awesome, size: 20),
                      label: Text(
                        controller.isHomeDesignsConfigured
                            ? appLocalization.designMoodboardGenerateMore
                            : appLocalization.designMoodboardOpenHomeDesigns,
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.colorPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Text(
              appLocalization.designMoodboardPoweredBy,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(appLocalization.designMoodboardRename),
              onTap: () {
                Navigator.pop(ctx);
                controller.renameMoodboard();
              },
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: Text(appLocalization.designMoodboardOpenHomeDesigns),
              onTap: () {
                Navigator.pop(ctx);
                controller.openHomeDesignsWeb();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(ctx).colorScheme.error,
              ),
              title: Text(appLocalization.designMoodboardDelete),
              onTap: () {
                Navigator.pop(ctx);
                controller.deleteMoodboard();
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _fromHex(String hex) {
    final value = hex.replaceAll('#', '');
    return Color(int.parse('FF$value', radix: 16));
  }
}

class _AiChip extends StatelessWidget {
  const _AiChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.colorPrimary.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'AI',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

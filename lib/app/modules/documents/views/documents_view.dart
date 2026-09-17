import 'package:flutter/material.dart';
import '../../../core/theme/form_surface_colors.dart';

import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../core/widget/skeleton_presets.dart';
import '../controllers/documents_controller.dart';

const _pdfRed = Color(0xFFE53935);
const _excelGreen = Color(0xFF2E7D32);
const _imageBlue = Color(0xFF1976D2);

class DocumentsView extends BaseView<DocumentsController> {
  DocumentsView({super.key});

  String _t(BuildContext context, {required String en, required String sw}) {
    return Get.locale?.languageCode == 'sw' ? sw : en;
  }

  

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    final title = controller.directoryName?.isNotEmpty == true
        ? controller.directoryName!
        : _t(
            context,
            en: appLocalization.legalDocuments,
            sw: 'Nyaraka za kisheria',
          );
    final c = FormSurfaceColors.of(context);
    return CustomAppBar(
      appBarTitleText: title,
      isCentered: true,
      actions: [
        IconButton(
          onPressed: controller.openSearch,
          icon: const Icon(Icons.search),
          style: IconButton.styleFrom(
            backgroundColor: c.isDark
                ? Colors.white.withValues(alpha: 0.14)
                : AppColors.lightGreyColor.withValues(alpha: 0.5),
            foregroundColor: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  @override
  Widget body(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Column(
      children: [
        _buildFilterChips(context),
        Expanded(
          child: Obx(() {
            if (controller.loading.value) {
              return const DefaultScreenSkeleton();
            }
            if (controller.documents.isEmpty) {
              return Center(
                child: Text(
                  appLocalization.noDocuments,
                  style: TextStyle(
                    fontSize: 16,
                    color: c.isDark
                        ? Colors.white70
                        : AppColors.textColorSecondary,
                  ),
                ),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: [
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.documents.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = controller.documents[index];
                      return _DocumentCard(
                        item: item,
                        syncedText: _t(
                          context,
                          en: 'SYNCED',
                          sw: 'IMESAWAZISHWA',
                        ),
                        onTap: item.isDirectory
                            ? () => controller.openDocumentOptions(item)
                            : null,
                        onOptionsTap: item.isDirectory
                            ? null
                            : () => controller.openDocumentOptions(item),
                      );
                    },
                  ),
                  if (!controller.recentOnly) ...[
                    const SizedBox(height: 24),
                    _buildUploadButton(context),
                  ],
                  SizedBox(height: 80 + MediaQuery.of(context).padding.bottom),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Obx(
        () => Row(
          children: [
            _FilterChip(
              label: _t(context, en: 'All', sw: 'Zote'),
              isSelected: controller.selectedFilter.value == DocumentFilter.all,
              onTap: () => controller.selectFilter(DocumentFilter.all),
            ),
            const SizedBox(width: 10),
            _FilterChip(
              label: _t(context, en: 'Urgent', sw: 'Haraka'),
              isSelected:
                  controller.selectedFilter.value == DocumentFilter.urgent,
              leadingIcon: Icons.circle,
              leadingIconColor: AppColors.paaYanguAlert,
              leadingIconSize: 8,
              onTap: () => controller.selectFilter(DocumentFilter.urgent),
            ),
            const SizedBox(width: 10),
            _FilterChip(
              label: _t(context, en: 'Verified', sw: 'Imethibitishwa'),
              isSelected:
                  controller.selectedFilter.value == DocumentFilter.verified,
              leadingIcon: Icons.check_circle_outline,
              leadingIconColor: Theme.of(context).colorScheme.primary,
              onTap: () => controller.selectFilter(DocumentFilter.verified),
            ),
            const SizedBox(width: 10),
            _FilterChip(
              label: _t(context, en: 'More', sw: 'Zaidi'),
              isSelected:
                  controller.selectedFilter.value == DocumentFilter.more,
              leadingIcon: Icons.format_list_bulleted,
              leadingIconColor: FormSurfaceColors.of(context).secondary,
              onTap: () => controller.selectFilter(DocumentFilter.more),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: AppValues.formButtonHeight + 8,
      child: ElevatedButton.icon(
        onPressed: controller.uploadDocument,
        icon: Icon(Icons.upload_outlined, size: 22, color: scheme.onPrimary),
        label: Text(
          appLocalization.uploadDocument,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: scheme.onPrimary,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppValues.radius_6),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final IconData? leadingIcon;
  final Color? leadingIconColor;
  final double? leadingIconSize;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.leadingIcon,
    this.leadingIconColor,
    this.leadingIconSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: isSelected ? scheme.primary : c.chipUnselectedBg,
      borderRadius: BorderRadius.circular(AppValues.roundedButtonRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppValues.roundedButtonRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingIcon != null) ...[
                Icon(
                  leadingIcon!,
                  size: leadingIconSize ?? 18,
                  color: isSelected
                      ? scheme.onPrimary
                      : (leadingIconColor ?? c.secondary),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final DocumentItem item;
  final VoidCallback? onTap;
  final VoidCallback? onOptionsTap;
  final String syncedText;

  const _DocumentCard({
    required this.item,
    this.onTap,
    this.onOptionsTap,
    required this.syncedText,
  });

  Widget get _fileTypeIcon {
    if (item.isDirectory) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.colorPrimary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppValues.radius_6),
        ),
        child: const Icon(
          Icons.folder_outlined,
          color: AppColors.colorPrimary,
          size: 24,
        ),
      );
    }
    switch (item.fileType) {
      case DocumentFileType.pdf:
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _pdfRed.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppValues.radius_6),
          ),
          child: Center(
            child: Text(
              'PDF',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _pdfRed,
              ),
            ),
          ),
        );
      case DocumentFileType.xlsx:
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _excelGreen.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppValues.radius_6),
          ),
          child: Icon(Icons.grid_on, color: _excelGreen, size: 24),
        );
      case DocumentFileType.image:
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _imageBlue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppValues.radius_6),
          ),
          child: Icon(Icons.image_outlined, color: _imageBlue, size: 24),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    final displayName = item.name.length > 28
        ? '${item.name.substring(0, 25)}...'
        : item.name;
    final scheme = Theme.of(context).colorScheme;
    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        border: Border.all(color: c.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: c.isDark
                ? Colors.black.withValues(alpha: 0.28)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _fileTypeIcon,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      item.size,
                      style: TextStyle(
                        fontSize: 13,
                        color: c.secondary,
                      ),
                    ),
                    if (item.synced && !item.isDirectory) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        syncedText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (onOptionsTap != null)
            IconButton(
              onPressed: onOptionsTap,
              icon: const Icon(Icons.more_vert),
              color: c.secondary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      ),
    );

    if (onTap == null) return card;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}

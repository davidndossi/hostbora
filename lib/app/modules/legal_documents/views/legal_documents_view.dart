import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/legal_documents_controller.dart';

const _vaultTeal = Color(0xFF00BCD4);
const _uploadButtonBlue = Color(0xFF1A237E);
const _pdfRed = Color(0xFFE53935);
const _excelGreen = Color(0xFF2E7D32);
const _imageBlue = Color(0xFF1976D2);

class LegalDocumentsView extends BaseView<LegalDocumentsController> {
  LegalDocumentsView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.legalDocuments,
      isCentered: true,
      actions: [
        IconButton(
          onPressed: controller.openSearch,
          icon: const Icon(Icons.search),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.lightGreyColor.withOpacity(0.5),
            foregroundColor: AppColors.textColorPrimary,
          ),
        ),
      ],
    );
  }

  @override
  Widget body(BuildContext context) {
    return Column(
      children: [
        _buildFilterChips(context),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.documents.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _DocumentCard(
                      item: controller.documents[index],
                      onOptionsTap: () =>
                          controller.openDocumentOptions(controller.documents[index]),
                    );
                  },
                ),
                const SizedBox(height: 24),
                _buildUploadButton(context),
                SizedBox(height: 80 + MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
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
              label: 'All',
              isSelected: controller.selectedFilter.value == DocumentFilter.all,
              onTap: () => controller.selectFilter(DocumentFilter.all),
            ),
            const SizedBox(width: 10),
            _FilterChip(
              label: 'Urgent',
              isSelected: controller.selectedFilter.value == DocumentFilter.urgent,
              leadingIcon: Icons.circle,
              leadingIconColor: AppColors.paaYanguAlert,
              leadingIconSize: 8,
              onTap: () => controller.selectFilter(DocumentFilter.urgent),
            ),
            const SizedBox(width: 10),
            _FilterChip(
              label: 'Verified',
              isSelected:
                  controller.selectedFilter.value == DocumentFilter.verified,
              leadingIcon: Icons.check_circle_outline,
              leadingIconColor: _vaultTeal,
              onTap: () => controller.selectFilter(DocumentFilter.verified),
            ),
            const SizedBox(width: 10),
            _FilterChip(
              label: 'More',
              isSelected: controller.selectedFilter.value == DocumentFilter.more,
              leadingIcon: Icons.format_list_bulleted,
              leadingIconColor: AppColors.textColorSecondary,
              onTap: () => controller.selectFilter(DocumentFilter.more),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppValues.formButtonHeight + 8,
      child: ElevatedButton.icon(
        onPressed: controller.uploadDocument,
        icon: const Icon(Icons.upload_outlined, size: 22, color: Colors.white),
        label: const Text(
          'Upload Document',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _uploadButtonBlue,
          foregroundColor: Colors.white,
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
    return Material(
      color: isSelected ? _vaultTeal : AppColors.lightGreyColor.withOpacity(0.4),
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
                      ? Colors.white
                      : (leadingIconColor ?? AppColors.textColorSecondary),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : AppColors.textColorPrimary,
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
  final LegalDocumentItem item;
  final VoidCallback onOptionsTap;

  const _DocumentCard({
    required this.item,
    required this.onOptionsTap,
  });

  Color get _fileTypeColor {
    switch (item.fileType) {
      case DocumentFileType.pdf:
        return _pdfRed;
      case DocumentFileType.xlsx:
        return _excelGreen;
      case DocumentFileType.image:
        return _imageBlue;
    }
  }

  Widget get _fileTypeIcon {
    switch (item.fileType) {
      case DocumentFileType.pdf:
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _pdfRed.withOpacity(0.15),
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
            color: _excelGreen.withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppValues.radius_6),
          ),
          child: Icon(Icons.grid_on, color: _excelGreen, size: 24),
        );
      case DocumentFileType.image:
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _imageBlue.withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppValues.radius_6),
          ),
          child: Icon(Icons.image_outlined, color: _imageBlue, size: 24),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = item.name.length > 28
        ? '${item.name.substring(0, 25)}...'
        : item.name;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.colorWhite,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
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
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textColorPrimary,
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
                        color: AppColors.textColorSecondary,
                      ),
                    ),
                    if (item.synced) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: AppColors.colorSuccessGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'SYNCED',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.colorSuccessGreen,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onOptionsTap,
            icon: const Icon(Icons.more_vert),
            color: AppColors.textColorSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

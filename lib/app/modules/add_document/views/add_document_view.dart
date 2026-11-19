import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/theme/form_surface_colors.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../core/widget/module_default_text_scope.dart';
import '../../../data/local/vault_directories_store.dart';
import '../controllers/add_document_controller.dart';

const _teal = Color(0xFF1C6E64);

class AddDocumentView extends BaseView<AddDocumentController> {
  AddDocumentView({super.key});

  bool get _isSw => Get.locale?.languageCode == 'sw';

  String _t({required String en, required String sw}) =>
      _isSw ? sw : en;

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: _t(en: 'Add Document', sw: 'Ongeza Hati'),
    );
  }

  @override
  Widget body(BuildContext context) {
    final theme = Theme.of(context);
    final c = FormSurfaceColors.of(context);

    return ModuleDefaultTextScope(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionLabel(context, _t(en: 'DOCUMENT DETAILS', sw: 'MAELEZO YA HATI')),
              const SizedBox(height: 10),
              _buildTitleField(context, c, theme),
              const SizedBox(height: 16),
              _buildFolderDropdown(context, c, theme),
              const SizedBox(height: 28),
              _buildSectionLabel(context, _t(en: 'ADD FROM', sw: 'ONGEZA KUTOKA')),
              const SizedBox(height: 12),
              _buildSourceOptions(context, c, theme),
              const SizedBox(height: 20),
              _buildPreview(context, c, theme),
              const SizedBox(height: 20),
              _buildSaveButton(context),
            ],
          ),
        ),
      )
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: _teal,
      ),
    );
  }

  Widget _buildTitleField(
    BuildContext context,
    FormSurfaceColors c,
    ThemeData theme,
  ) {
    return TextFormField(
      controller: controller.titleController,
      textCapitalization: TextCapitalization.sentences,
      style: TextStyle(
        color: c.headline,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: _t(en: 'Document name (optional)', sw: 'Jina la hati (si lazima)'),
        labelStyle: TextStyle(
          color: c.isDark
              ? theme.colorScheme.onSurfaceVariant
              : AppColors.textColorSecondary,
        ),
        prefixIcon: Icon(
          Icons.drive_file_rename_outline,
          size: 20,
          color: _teal.withValues(alpha: 0.8),
        ),
        filled: true,
        fillColor: c.isDark
            ? theme.colorScheme.surfaceContainerHigh
            : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppValues.radius_12),
          borderSide: BorderSide(
            color: c.isDark
                ? theme.colorScheme.outlineVariant
                : AppColors.designInputBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppValues.radius_12),
          borderSide: BorderSide(
            color: c.isDark
                ? theme.colorScheme.outlineVariant
                : AppColors.designInputBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppValues.radius_12),
          borderSide: const BorderSide(color: _teal, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildFolderDropdown(
    BuildContext context,
    FormSurfaceColors c,
    ThemeData theme,
  ) {
    return Obx(() {
      final dirs = controller.directories;
      final selected = controller.selectedDirectory.value;
      return DropdownButtonFormField<VaultDirectoryDef>(
        initialValue: selected,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: _t(en: 'Save to folder', sw: 'Hifadhi kwenye folda'),
          labelStyle: TextStyle(
            color: c.isDark
                ? theme.colorScheme.onSurfaceVariant
                : AppColors.textColorSecondary,
          ),
          prefixIcon: Icon(
            Icons.folder_outlined,
            size: 20,
            color: _teal.withValues(alpha: 0.8),
          ),
          filled: true,
          fillColor: c.isDark
              ? theme.colorScheme.surfaceContainerHigh
              : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppValues.radius_12),
            borderSide: BorderSide(
              color: c.isDark
                  ? theme.colorScheme.outlineVariant
                  : AppColors.designInputBorder,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppValues.radius_12),
            borderSide: BorderSide(
              color: c.isDark
                  ? theme.colorScheme.outlineVariant
                  : AppColors.designInputBorder,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppValues.radius_12),
            borderSide: const BorderSide(color: _teal, width: 1.5),
          ),
        ),
        items: dirs
            .map(
              (def) => DropdownMenuItem(
                value: def,
                child: Text(
                  controller.directoryDisplayName(def),
                  style: TextStyle(
                    fontSize: 14,
                    color: c.headline,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: controller.selectDirectory,
      );
    });
  }

  Widget _buildSourceOptions(
    BuildContext context,
    FormSurfaceColors c,
    ThemeData theme,
  ) {
    return Column(
      children: [
        _SourceOptionCard(
          icon: Icons.document_scanner_outlined,
          title: _t(en: 'Scan Document', sw: 'Scan Hati'),
          subtitle: _t(
            en: 'Use camera to scan a physical document',
            sw: 'Tumia kamera kuchanganua hati ya karatasi',
          ),
          accentColor: _teal,
          backgroundColor: c.isDark
              ? theme.colorScheme.surfaceContainerHigh
              : Colors.white,
          onTap: controller.goToScanner,
        ),
        const SizedBox(height: 12),
        _SourceOptionCard(
          icon: Icons.photo_library_outlined,
          title: _t(en: 'Upload from Gallery', sw: 'Pakia kutoka Galeria'),
          subtitle: _t(
            en: 'Choose an existing photo or image file',
            sw: 'Chagua picha iliyopo',
          ),
          accentColor: const Color(0xFF3B82F6),
          backgroundColor: c.isDark
              ? theme.colorScheme.surfaceContainerHigh
              : Colors.white,
          onTap: controller.pickFromGallery,
        ),
        const SizedBox(height: 12),
        _SourceOptionCard(
          icon: Icons.attach_file_outlined,
          title: _t(en: 'Upload File', sw: 'Pakia Faili'),
          subtitle: _t(
            en: 'Choose a file from your device storage',
            sw: 'Chagua faili kutoka kumbukumbu ya simu',
          ),
          accentColor: const Color(0xFF8B5CF6),
          backgroundColor: c.isDark
              ? theme.colorScheme.surfaceContainerHigh
              : Colors.white,
          onTap: controller.pickFile,
        ),
      ],
    );
  }

  Widget _buildPreview(
    BuildContext context,
    FormSurfaceColors c,
    ThemeData theme,
  ) {
    return Obx(() {
      if (!controller.hasPendingFile) return const SizedBox.shrink();
      final path = controller.pendingPath.value!;
      final name = controller.pendingFileName.value;
      final isImage = controller.pendingIsImage.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel(context, _t(en: 'PREVIEW', sw: 'ONYESHO')),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: c.isDark
                  ? theme.colorScheme.surfaceContainerHigh
                  : Colors.white,
              borderRadius: BorderRadius.circular(AppValues.radius_12),
              border: Border.all(color: _teal.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isImage)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppValues.radius_12),
                    ),
                    child: Image.file(
                      File(path),
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _filePreview(name, c),
                    ),
                  )
                else
                  _filePreview(name, c),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: c.headline,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: controller.clearPendingFile,
                        child: Text(_t(en: 'Remove', sw: 'Ondoa')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _filePreview(String name, FormSurfaceColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.insert_drive_file_outlined,
              color: Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: c.headline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return Obx(() {
      final enabled = controller.hasPendingFile && !controller.saving.value;
      return SizedBox(
        width: double.infinity,
        height: AppValues.formButtonHeight + 8,
        child: ElevatedButton(
          onPressed: enabled ? controller.savePendingDocument : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _teal,
            disabledBackgroundColor: _teal.withValues(alpha: 0.35),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppValues.radius_6),
            ),
            elevation: 0,
          ),
          child: controller.saving.value
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  _t(en: 'Add Document', sw: 'Ongeza Hati'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      );
    });
  }
}

class _SourceOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _SourceOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(AppValues.radius_12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppValues.radius_12),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 24, color: accentColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textColorSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_outlined,
                size: 22,
                color: accentColor.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/base/base_view.dart';
import '../controllers/design_moodboard_controller.dart';

/// Moodboard detail — cream background & spec teal accent (#0D6D6D).
const Color _kTealAccent = Color(0xFF0D6D6D);
const Color _kTitleNavy = Color(0xFF1B2838);

class DesignMoodboardView extends BaseView<DesignMoodboardController> {
  DesignMoodboardView({super.key});

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
  Widget body(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = _isDark(context);
    return Column(
      children: [
        Expanded(
          child: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _topBar(context),
                  const SizedBox(height: 16),
                  Text(
                    controller.moodboardTitle,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: isDark ? theme.colorScheme.onSurface : _kTitleNavy,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.subtitleLine,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.3,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _sectionTitle(
                    context,
                    _t(context, en: 'DESIGN CONCEPTS', sw: 'DHANA ZA UBUNIFU'),
                  ),
                  const SizedBox(height: 14),
                  _conceptsGrid(),
                  const SizedBox(height: 28),
                  _sectionTitle(
                    context,
                    _t(context, en: 'COLOR PALETTE', sw: 'PALETI YA RANGI'),
                  ),
                  const SizedBox(height: 14),
                  _paletteCard(context),
                  const SizedBox(height: 28),
                  _sectionTitle(
                    context,
                    _t(
                      context,
                      en: 'FURNITURE & TEXTURES',
                      sw: 'SAMANI NA MICHORO',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _texturesRow(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
        _bottomCta(context),
      ],
    );
  }

  Widget _topBar(BuildContext context) {
    return Row(
      children: [
        _roundIcon(context, Icons.arrow_back_ios_new_rounded, onTap: Get.back),
        const Spacer(),
        _roundIcon(
          context,
          Icons.share_outlined,
          onTap: () async {
            await Share.share(
              '${controller.moodboardTitle} — ${controller.subtitleLine}',
              subject: controller.moodboardTitle,
            );
          },
        ),
        const SizedBox(width: 10),
        _roundIcon(
          context,
          Icons.more_vert,
          onTap: () => _showMoreMenu(context),
        ),
      ],
    );
  }

  void _showMoreMenu(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = _isDark(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark
          ? theme.colorScheme.surfaceContainerHigh
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.edit_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              title: Text(
                _t(
                  context,
                  en: 'Rename moodboard',
                  sw: 'Badili jina la moodboard',
                ),
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: theme.colorScheme.error,
              ),
              title: Text(
                _t(context, en: 'Delete', sw: 'Futa'),
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundIcon(
    BuildContext context,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = _isDark(context);
    return Material(
      color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            size: 20,
            color: isDark ? theme.colorScheme.onSurface : _kTitleNavy,
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: TextStyle(
        color: _isDark(context) ? theme.colorScheme.primary : _kTealAccent,
        fontSize: 12,
        letterSpacing: 1.6,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _conceptsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.concepts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.92,
      ),
      itemBuilder: (context, index) {
        final item = controller.concepts[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                item.image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : const Color(0xFFE8E6E1),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
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
              if (item.editable)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.92),
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {},
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: _kTitleNavy,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _paletteCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = _isDark(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark
              ? theme.colorScheme.outlineVariant
              : const Color(0xFFE8E6E1),
        ),
      ),
      child: Obx(() {
        final selected = controller.selectedPaletteIndex.value;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(controller.palette.length, (i) {
            final sw = controller.palette[i];
            final isSel = i == selected;
            final fill = _fromHex(sw.hex);
            return Expanded(
              child: InkWell(
                onTap: () => controller.selectPalette(i),
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: fill,
                          border: Border.all(
                            color: isSel
                                ? _kTealAccent
                                : const Color(0xFFE0DDD8),
                            width: isSel ? 3 : 1,
                          ),
                          boxShadow: isSel
                              ? [
                                  BoxShadow(
                                    color: _kTealAccent.withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sw.hex,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                          color: isSel
                              ? (isDark
                                    ? theme.colorScheme.primary
                                    : _kTealAccent)
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (sw.label != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          sw.label!,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  Widget _texturesRow() {
    return SizedBox(
      height: 176,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: controller.textures.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) => ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: 140,
            height: 140,
            child: Image.asset(
              controller.textures[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.surfaceContainerHighest
                    : const Color(0xFFE8E6E1),
                alignment: Alignment.center,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomCta(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: controller.generateMoreLikeThis,
            icon: const Icon(Icons.auto_awesome, size: 20, color: Colors.white),
            label: Text(
              _t(
                context,
                en: 'Generate More Like This',
                sw: 'Tengeneza Mengine Yanayofanana',
              ),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: _kTealAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 2,
              shadowColor: _kTealAccent.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }

  Color _fromHex(String hex) {
    final value = hex.replaceAll('#', '');
    return Color(int.parse('FF$value', radix: 16));
  }
}

import 'package:flutter/material.dart';
import 'package:paa_yangu/app/core/theme/app_theme_tokens.dart';

import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../data/model/calendar_subscription.dart';
import '../controllers/calendar_sync_controller.dart';

class CalendarSyncView extends BaseView<CalendarSyncController> {
  CalendarSyncView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = controller.listingName;
    return CustomAppBar(
      appBarTitleText: name.isEmpty
          ? l10n.calendarSyncTitle
          : l10n.calendarSyncTitleForListing(name),
      isCentered: true,
    );
  }

  @override
  Widget body(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? context.tokens.cardBackground : Colors.white;
    final muted = isDark ? const Color(0xFFAEAEB2) : const Color(0xFF6B7280);

    if (controller.listingId.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.calendarSyncMissingListing,
            textAlign: TextAlign.center,
            style: TextStyle(color: muted),
          ),
        ),
      );
    }

    return Obx(() {
      if (controller.loading.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.colorPrimary),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.loadSubscriptions,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text(
              l10n.calendarSyncIntro,
              style: TextStyle(fontSize: 14, height: 1.4, color: muted),
            ),
            const SizedBox(height: 20),
            _sectionTitle(l10n.calendarSyncImportSection),
            const SizedBox(height: 8),
            TextField(
              controller: controller.importUrlController,
              decoration: InputDecoration(
                labelText: l10n.calendarSyncImportUrlLabel,
                hintText: l10n.calendarSyncImportUrlHint,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller.importLabelController,
              decoration: InputDecoration(
                labelText: l10n.calendarSyncImportLabelOptional,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.addImportSubscription,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.colorPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(l10n.calendarSyncSaveImport),
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle(l10n.calendarSyncExportSection),
            const SizedBox(height: 8),
            Text(
              l10n.calendarSyncExportHint,
              style: TextStyle(fontSize: 13, color: muted, height: 1.35),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: controller.createExportSubscription,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.colorPrimary),
                ),
                child: Text(l10n.calendarSyncCreateExport),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _sectionTitle(l10n.calendarSyncSubscriptions)),
                Obx(
                  () => controller.syncing.value
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : TextButton(
                          onPressed: controller.syncListing,
                          child: Text(l10n.calendarSyncSyncNow),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.calendarSyncBlocksNote,
              style: TextStyle(fontSize: 12, color: muted, height: 1.3),
            ),
            const SizedBox(height: 12),
            if (controller.subscriptions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    l10n.calendarSyncNoSubscriptions,
                    style: TextStyle(color: muted),
                  ),
                ),
              )
            else
              ...controller.subscriptions.map(
                (sub) => _subscriptionCard(
                  context,
                  l10n: l10n,
                  sub: sub,
                  cardColor: cardColor,
                  muted: muted,
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.textColorPrimary,
      ),
    );
  }

  Widget _subscriptionCard(
    BuildContext context, {
    required AppLocalizations l10n,
    required CalendarSubscription sub,
    required Color cardColor,
    required Color muted,
  }) {
    final isImport = sub.isImport;
    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isImport ? Icons.download_outlined : Icons.upload_outlined,
                  size: 20,
                  color: AppColors.colorPrimary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isImport
                        ? l10n.calendarSyncDirectionImport
                        : l10n.calendarSyncDirectionExport,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (!sub.enabled)
                  Text(
                    l10n.calendarSyncDisabled,
                    style: TextStyle(fontSize: 11, color: muted),
                  ),
              ],
            ),
            if ((sub.label ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(sub.label!, style: TextStyle(fontSize: 13, color: muted)),
            ],
            if (isImport && (sub.sourceUrl ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                sub.sourceUrl!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: muted),
              ),
            ],
            if (!isImport && (sub.exportUrl ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              SelectableText(
                sub.exportUrl!,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: () => controller.copyExportUrl(sub.exportUrl!),
                    icon: const Icon(Icons.copy, size: 18),
                    label: Text(l10n.calendarSyncCopyUrl),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '${l10n.calendarSyncLastSync}: ${controller.formatLastSync(sub)}',
              style: TextStyle(fontSize: 12, color: muted),
            ),
            if ((sub.lastSyncMessage ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                sub.lastSyncMessage!,
                style: TextStyle(fontSize: 12, color: muted),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                if (isImport)
                  TextButton(
                    onPressed: controller.syncing.value
                        ? null
                        : () => controller.syncSubscription(sub),
                    child: Text(l10n.calendarSyncSyncFeed),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => controller.deleteSubscription(sub),
                  child: Text(
                    l10n.calendarSyncRemove,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

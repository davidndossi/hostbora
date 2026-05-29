import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../data/help/help_center_models.dart';
import '../controllers/help_guide_detail_controller.dart';

class HelpGuideDetailView extends BaseView<HelpGuideDetailController> {
  HelpGuideDetailView({super.key});

  static const _teal = Color(0xFF005F5F);

  String _t(String en, String sw) => controller.isSw ? sw : en;

  @override
  PreferredSizeWidget? appBar(BuildContext context) => CustomAppBar(
        appBarTitleText: _t('Step-by-step guide', 'Mwongozo wa hatua'),
        isCentered: true,
      );

  @override
  Widget body(BuildContext context) {
    return Obx(() {
      final guide = controller.guide.value;
      if (guide == null) {
        return Center(child: Text(_t('Guide not found', 'Mwongozo haupatikani')));
      }

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            guide.title(controller.isSw),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            guide.summary(controller.isSw),
            style: TextStyle(fontSize: 15, height: 1.45, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: controller.startGuidedTour,
              icon: const Icon(Icons.play_circle_outline),
              label: Text(_t('Start guided tour', 'Anza ziara ya mwongozo')),
              style: FilledButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _t('Steps', 'Hatua'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...List.generate(guide.steps.length, (i) {
            final step = guide.steps[i];
            return Obx(
              () => _StepTile(
                index: i + 1,
                step: step,
                isSw: controller.isSw,
                done: controller.isStepDone(i),
                onToggleDone: () => controller.toggleStepDone(i),
                onOpen: step.route != null && step.route!.isNotEmpty
                    ? () => controller.goToStep(step)
                    : null,
              ),
            );
          }),
        ],
      );
    });
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.index,
    required this.step,
    required this.isSw,
    required this.done,
    required this.onToggleDone,
    this.onOpen,
  });

  final int index;
  final HelpGuideStep step;
  final bool isSw;
  final bool done;
  final VoidCallback onToggleDone;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: done ? HelpGuideDetailView._teal : Colors.grey.shade300,
                  child: Text(
                    '$index',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: done ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title(isSw),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        step.body(isSw),
                        style: TextStyle(fontSize: 13, height: 1.4, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                Checkbox(value: done, onChanged: (_) => onToggleDone()),
              ],
            ),
            if (onOpen != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(isSw ? 'Fungua skrini' : 'Open screen'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

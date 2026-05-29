import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/theme/form_surface_colors.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../controllers/ai_manager_controller.dart';

class AiManagerView extends BaseView<AiManagerController> {
  AiManagerView({super.key});

  String _t(BuildContext context, {required String en, required String sw}) {
    return Get.locale?.languageCode == 'sw' ? sw : en;
  }

  

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return PreferredSize(
      preferredSize: const Size.fromHeight(72),
      child: SafeArea(
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              bottom: BorderSide(
                color: c.isDark
                    ? Colors.white.withValues(alpha: 0.14)
                    : AppColors.designInputBorder,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: Get.back,
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _t(context, en: 'AI Manager', sw: 'Msimamizi wa AI'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.colorPrimary,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF31C453),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Obx(
                          () => Text(
                            controller.isReplying.value
                                ? _t(context, en: 'Thinking', sw: 'Inafikiria')
                                : _t(context, en: 'Online', sw: 'Mtandaoni'),
                            style: TextStyle(
                              fontSize: 12,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w600,
                              color: c.isDark
                                  ? Colors.white70
                                  : AppColors.textColorSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Obx(
            () => ListView.builder(
              controller: controller.scrollController,
              padding: const EdgeInsets.fromLTRB(
                14 + AppValues.padding,
                12,
                14 + AppValues.padding,
                8,
              ),
              itemCount: controller.messages.length,
              itemBuilder: (context, index) {
                final item = controller.messages[index];
                return _ChatBubble(item: item, isDark: FormSurfaceColors.of(context).isDark);
              },
            ),
          ),
        ),
        _buildQuickActions(context),
        _buildComposer(context),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Obx(
      () => SizedBox(
        height: 44,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            final action = controller.quickActions[index];
            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: controller.isReplying.value
                  ? null
                  : () => controller.sendQuickAction(action),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color:
                      c.isDark ? const Color(0xFF1F1F1F) : AppColors.colorWhite,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: c.isDark
                        ? Colors.white.withValues(alpha: 0.18)
                        : AppColors.designInputBorder,
                  ),
                ),
                child: Text(
                  action,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.colorPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
          separatorBuilder: (_, index) => const SizedBox(width: 8),
          itemCount: controller.quickActions.length,
        ),
      ),
    );
  }

  Widget _buildComposer(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Obx(
      () {
        final busy = controller.isReplying.value;
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        c.isDark ? const Color(0xFF1F1F1F) : AppColors.colorWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: c.isDark
                          ? Colors.white.withValues(alpha: 0.18)
                          : AppColors.designInputBorder,
                    ),
                  ),
                  child: TextField(
                    onChanged: controller.setInput,
                    controller: controller.inputController,
                    enabled: !busy,
                    textInputAction: TextInputAction.send,
                    onSubmitted: busy ? null : (_) => controller.send(),
                    decoration: InputDecoration(
                      hintText: _t(
                        context,
                        en: 'Ask about your properties...',
                        sw: 'Uliza kuhusu mali zako...',
                      ),
                      hintStyle: TextStyle(
                        color: c.isDark
                            ? Colors.white70
                            : AppColors.textColorSecondary,
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: busy
                      ? AppColors.colorPrimary.withValues(alpha: 0.45)
                      : AppColors.colorPrimary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.colorPrimary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: busy ? null : controller.send,
                  icon: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final AiChatMessage item;
  final bool isDark;

  const _ChatBubble({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final align = item.fromAssistant
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.end;
    final bubbleColor = item.fromAssistant
        ? (isDark ? const Color(0xFF1F1F1F) : AppColors.colorWhite)
        : AppColors.colorPrimary;
    final textColor = item.fromAssistant
        ? Theme.of(context).colorScheme.onSurface
        : Colors.white;

    return Column(
      crossAxisAlignment: align,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: item.fromAssistant
              ? MainAxisAlignment.start
              : MainAxisAlignment.end,
          children: [
            if (item.fromAssistant)
              Container(
                width: 30,
                height: 30,
                margin: const EdgeInsets.only(top: 6, right: 8),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF0E3030), Color(0xFF1CCCCC)],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            Flexible(
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: item.fromAssistant
                        ? (isDark
                              ? Colors.white.withValues(alpha: 0.18)
                              : AppColors.designInputBorder)
                        : Colors.transparent,
                  ),
                ),
                child: item.isTyping
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.colorPrimary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              item.text,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: textColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Text(
                        item.text,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),
            if (!item.fromAssistant)
              Container(
                width: 30,
                height: 30,
                margin: const EdgeInsets.only(top: 6, left: 8),
                decoration: const BoxDecoration(
                  color: Colors.black12,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  size: 18,
                  color: Colors.black54,
                ),
              ),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(
            top: 4,
            left: item.fromAssistant ? 38 : 0,
            right: item.fromAssistant ? 0 : 38,
            bottom: 10,
          ),
          child: Text(
            '${item.role} • ${item.time}',
            style: TextStyle(
              fontSize: 12,
              color: FormSurfaceColors.of(context).secondary,
            ),
          ),
        ),
      ],
    );
  }
}

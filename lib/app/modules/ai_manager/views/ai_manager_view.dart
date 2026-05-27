import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../controllers/ai_manager_controller.dart';

class AiManagerView extends BaseView<AiManagerController> {
  AiManagerView({super.key});

  String _t(BuildContext context, {required String en, required String sw}) {
    return Get.locale?.languageCode == 'sw' ? sw : en;
  }

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  String _localizeQuickAction(BuildContext context, String action) {
    final map = <String, String>{
      'Show me pricing insights': 'Nionyeshe uchambuzi wa bei',
      'Optimize weekend rates': 'Boresha bei za wikendi',
      'Check occupancy forecast': 'Kagua utabiri wa ukodishaji',
      'Suggest promotion ideas': 'Pendekeza mawazo ya promosheni',
    };
    return Get.locale?.languageCode == 'sw' ? (map[action] ?? action) : action;
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    final isDark = _isDark(context);
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
                color: isDark
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
                        Text(
                          _t(context, en: 'ONLINE', sw: 'MTANDAONI'),
                          style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white70
                                : AppColors.textColorSecondary,
                          ),
                        ),
                      ],
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

  @override
  Widget body(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Obx(
            () => ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(
                14 + AppValues.padding,
                12,
                14 + AppValues.padding,
                8,
              ),
              itemCount: controller.messages.length,
              itemBuilder: (context, index) {
                final item = controller.messages[index];
                return _ChatBubble(item: item, isDark: _isDark(context));
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
    final isDark = _isDark(context);
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final action = controller.quickActions[index];
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => controller.tapQuickAction(action),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F1F1F) : AppColors.colorWhite,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.18)
                      : AppColors.designInputBorder,
                ),
              ),
              child: Text(
                _localizeQuickAction(context, action),
                style: TextStyle(
                  fontSize: 14,
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
    );
  }

  Widget _buildComposer(BuildContext context) {
    final isDark = _isDark(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F1F1F) : AppColors.colorWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.18)
                      : AppColors.designInputBorder,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      onChanged: controller.setInput,
                      controller: controller.inputController,
                      decoration: InputDecoration(
                        hintText: _t(
                          context,
                          en: 'Message AI Manager...',
                          sw: 'Tuma ujumbe kwa Msimamizi wa AI...',
                        ),
                        hintStyle: TextStyle(
                          color: isDark
                              ? Colors.white70
                              : AppColors.textColorSecondary,
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.mic_none_rounded,
                      color: AppColors.colorPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.colorPrimary,
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
              onPressed: controller.send,
              icon: const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
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
                child: Text(
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
              color: isDark ? Colors.white70 : AppColors.textColorSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

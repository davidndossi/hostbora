import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../controllers/ai_manager_controller.dart';

class AiManagerView extends BaseView<AiManagerController> {
  AiManagerView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(72),
      child: SafeArea(
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.pageBackground,
            border: Border(bottom: BorderSide(color: AppColors.designInputBorder)),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: Get.back,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'AI Manager',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Roboto',
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
                          'ONLINE',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textColorSecondary,
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
                return _ChatBubble(item: item);
              },
            ),
          ),
        ),
        _buildQuickActions(),
        _buildComposer(),
      ],
    );
  }

  Widget _buildQuickActions() {
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
                color: AppColors.colorWhite,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.designInputBorder),
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
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: controller.quickActions.length,
      ),
    );
  }

  Widget _buildComposer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.colorWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.designInputBorder),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      onChanged: controller.setInput,
                      controller: controller.inputController,
                      decoration: InputDecoration(
                        hintText: 'Message AI Manager...',
                        hintStyle: TextStyle(color: AppColors.textColorSecondary),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.mic_none_rounded, color: AppColors.colorPrimary),
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
                  color: AppColors.colorPrimary.withOpacity(0.25),
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

  const _ChatBubble({required this.item});

  @override
  Widget build(BuildContext context) {
    final align = item.fromAssistant ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    final bubbleColor = item.fromAssistant ? AppColors.colorWhite : AppColors.colorPrimary;
    final textColor = item.fromAssistant ? AppColors.textColorPrimary : Colors.white;

    return Column(
      crossAxisAlignment: align,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: item.fromAssistant ? MainAxisAlignment.start : MainAxisAlignment.end,
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
                  border: Border.all(color: item.fromAssistant ? AppColors.designInputBorder : Colors.transparent),
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
                child: const Icon(Icons.person, size: 18, color: Colors.black54),
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
              color: AppColors.textColorSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

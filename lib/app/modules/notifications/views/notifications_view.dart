import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/notifications_controller.dart';


class NotificationsView extends BaseView<NotificationsController> {
  NotificationsView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.notifications,
      actions: [
        IconButton(
          onPressed: controller.onRefreshPage,
          icon: const Icon(Icons.refresh_outlined),
        ),
      ],
    );
  }

  @override
  Widget body(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() => Center(child: Text(controller.heading.value))),
          const SizedBox(height: 20),
          Expanded(
            child: GetBuilder<NotificationsController>(
              builder: (controller) => controller.isLoading.value
                  ?
              const Center(child: CircularProgressIndicator())
                  :
              ListView.separated(
                shrinkWrap: true,
                itemCount: controller.notificationsLength.value,
                itemBuilder: (context, index) {
                  final notification = controller.notifications[index];

                  return controller.notificationsLength.value == 0 ?
                  Center(child: Text(controller.heading.value))
                      :
                  Card(
                    child: ListTile(
                      title: Text(notification.title!),
                      leading: notification.delivered! ? Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.black38,
                          shape: BoxShape.circle,
                        )
                      ) : Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        )
                      ),
                      subtitle: Text(notification.msg!),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.arrow_forward_ios,
                        ),
                        onPressed: () {
                          controller.deliverNotification(notification.id!);
                          controller.showNotification(notification);
                        },
                      ),
                      onTap: () {
                        controller.deliverNotification(notification.id!);
                        controller.showNotification(notification);
                      },
                    ),
                  );
                },
                separatorBuilder: (context, index) {
                  return const Divider();
                },
              ),
            ),
          ),
        ]
      ),
    );
  }
}

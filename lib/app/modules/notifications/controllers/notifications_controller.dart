import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/model/general_response.dart';
import '../../../data/model/login_response.dart';
import '../../../data/model/notification.dart' as n;
import '../../../data/model/page_request.dart';
import '../../../data/model/page_response.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';

class NotificationsController extends BaseController {
  final _notifications = <n.Notification>[].obs;
  final notificationsLength = 0.obs;
  final heading = 'No new notification'.obs;
  final userId = ''.obs;
  final isLoading = false.obs;

  int pageNumber = 0;
  bool endOfList = false;

  final PreferenceManager _preferenceManager =
  Get.find(tag: (PreferenceManager).toString());
  final AppRepository _repository = Get.find(tag: (AppRepository).toString());

  List<n.Notification> get notifications => _notifications.toList();

  @override
  void onInit() async {
    getPrefValues();
    super.onInit();
  }

  void getPrefValues() async {
    User user = await _preferenceManager.getUser();
    userId(user.id);
    fetchNotifications();
  }

  void fetchNotifications() async {
    if (endOfList) return;

    isLoading(true);

    PageRequest pageRequest = PageRequest(
      page: pageNumber,
      size: 10
    );

    var notificationSearchService = _repository.getUserNotifications(userId.value, pageRequest);

    callDataService(
      notificationSearchService,
      onSuccess: _handleNotificationListResponseSuccess,
      onError: _handleNotificationListResponseError
    );
  }

  void initRefresh() {
    _notifications([]);
    notificationsLength(0);
    heading('No new notification');
    pageNumber = 0;
    isLoading(false);
    endOfList = false;
  }

  void onRefreshPage() {
    initRefresh();
    fetchNotifications();
  }

  void onLoadNextPage() {
    logger.i('On load next');
    fetchNotifications();
  }

  void _handleNotificationListResponseSuccess(GeneralResponse res) async {
    if (res.responseCode == '0') {
      PageResponse pageResponse = PageResponse.fromJson(res.data, (v) => n.Notification.fromJson(v));
      List<n.Notification> notificationList = pageResponse.content!.map((e) => e as n.Notification).toList();
      if (notificationList.isNotEmpty) {
        _notifications.addAll(notificationList);
        pageNumber++;
      } else {
        endOfList = true;
      }
      notificationsLength(notifications.length);

      if (notificationsLength > 1) {
        heading('$notificationsLength new notifications');
      } else if (notificationsLength > 0) {
        heading('$notificationsLength new notification');
      }
      update();
    } else {
      showErrorMessage(appLocalization.failedNotifications);
      endOfList = true;
    }
    isLoading(false);
  }

  void _handleNotificationListResponseError(Exception e) {
    isLoading(false);
  }

  void _handleDeliverNotificationResponseSuccess(GeneralResponse res) {}

  void deliverNotification(String id) {
    callDataServiceSilent(
      _repository.deliverNotification(id),
      onSuccess: _handleDeliverNotificationResponseSuccess,
      onError: _handleNotificationListResponseError
    );
  }

  void showNotification(n.Notification notification) {
    // Show modal bottom sheet with details
    showModalBottomSheet(
      context: Get.context!,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            children: [
              Center(
                child: Container(
                  height: 5,
                  width: 50,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Center(
                child: Text(
                  '${notification.title}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              Text(notification.msg ?? '-'),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => acceptRejectNotificationRequest(notification.id!, 'accepted'),
                      child: const Text('Accept'),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () => acceptRejectNotificationRequest(notification.id!, 'rejected'),
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _handleQueryResponseError(Exception e) {}

  void returnToDashboard() {
    Get.offAllNamed(Routes.MAIN);
  }

  void _handleUpdateNotificationResponseSuccess(GeneralResponse res) {
    if (res.responseCode == '0') {
      showDialog(
        context: Get.context!,
        builder: (context) => AlertDialog(
          shape: const RoundedRectangleBorder(
              borderRadius:
              BorderRadius.all(Radius.circular(15))),
          title: const Text('Success!'),
          // content: Text('User joined successfully!', textAlign: TextAlign.center),
          icon: SizedBox(
            height: 50,
            width: 50,
            child: SvgPicture.asset(
              'images/tick-circle.svg',
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Get.back(closeOverlays: true),
              child: const Text('OK'),
            )
          ],
        ));
    } else {
      showErrorMessage(res.message!);
    }
    Navigator.of(Get.context!).pop();
  }

  void acceptRejectNotificationRequest(String id, String action) {
    callDataServiceSilent(
      _repository.updateNotification(id, action),
      onSuccess: _handleUpdateNotificationResponseSuccess,
      onError: _handleQueryResponseError
    );
  }
}
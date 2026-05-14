import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '/app/main_app.dart';
import '/flavors/build_config.dart';
import '/flavors/env_config.dart';
import '/flavors/environment.dart';
import 'app/core/config/tuya_config.dart';
import 'app/data/local/service/storage_service.dart';
import 'app/data/local/service/lease_reminder_workmanager.dart';
import 'app/data/service/tuya_service.dart';
import 'app/data/service/tuya_smart_lock_service.dart';
import 'app/routes/app_pages.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
      name: 'paa_yangu',
      options: DefaultFirebaseOptions.currentPlatform
  );
  await setupFlutterNotifications();
  showFlutterNotification(message);
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  // print('Handling a background message ${message.messageId}');
}

/// Create a [AndroidNotificationChannel] for heads up notifications
late AndroidNotificationChannel channel;

bool isFlutterLocalNotificationsInitialized = false;

Future<void> setupFlutterNotifications() async {
  if (isFlutterLocalNotificationsInitialized) {
    return;
  }
  channel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description:
    'This channel is used for important notifications.', // description
    importance: Importance.high,
  );

  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Create an Android Notification Channel.
  ///
  /// We use this channel in the `AndroidManifest.xml` file to override the
  /// default FCM channel to enable heads up notifications.
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  /// Update the iOS foreground notification presentation options to allow
  /// heads up notifications.
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  isFlutterLocalNotificationsInitialized = true;
}

void showFlutterNotification(RemoteMessage message) {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;
  if (notification != null && android != null) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: 'launch_background',
        ),
      ),
    );
  }
}

void showAlert(RemoteMessage message) {
  Map<String, dynamic> data = message.data;
  if (data.isNotEmpty) {
    RemoteNotification? notification = message.notification;
    if (notification != null) {
      String title = notification.title!;
      String content = notification.body!;
      showDialog(
          context: Get.context!,
          builder: (context) => AlertDialog(
            shape: const RoundedRectangleBorder(
                borderRadius:
                BorderRadius.all(Radius.circular(15))),
            title: Text(title),
            content: Text(content),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () =>
                    Get.offAndToNamed(Routes.HOME,
                        arguments: {
                          'service': title,
                          'receiptBody': content
                        }),
                child: const Text('View'),
              ),
              TextButton(
                onPressed: () => Get.back(closeOverlays: true),
                child: const Text('Cancel'),
              )
            ],
          ));
    }
  }
}

/// Initialize the [FlutterLocalNotificationsPlugin] package.
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

Future<String?> _waitForApnsToken({
  int maxAttempts = 8,
  Duration delay = const Duration(milliseconds: 500),
}) async {
  for (var i = 0; i < maxAttempts; i++) {
    final token = await FirebaseMessaging.instance.getAPNSToken();
    if (token != null && token.isNotEmpty) return token;
    await Future.delayed(delay);
  }
  return null;
}

void requestUserPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    announcement: true,
  );
  final authStatus = settings.authorizationStatus;
  final enabled = authStatus == AuthorizationStatus.authorized ||
      authStatus == AuthorizationStatus.provisional;
  if (kDebugMode) {
    print('firebaseEnabled: $enabled');
  }
  if (enabled) {
    if (kDebugMode) {
      print('Authorization status:${authStatus.name}');
    }
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apns = await _waitForApnsToken();
        if (kDebugMode) {
          print('APNS Token ready: ${apns != null && apns.isNotEmpty}');
        }
        // APNS may still be unavailable right after app start. Avoid crashing,
        // onTokenRefresh below will pick up token updates later.
        if (apns == null || apns.isEmpty) {
          return;
        }
      }

      final token = await messaging.getToken();
      if (kDebugMode) {
        print('FCM Token: $token');
      }
    } catch (e) {
      if (kDebugMode) {
        print('FCM token fetch failed: $e');
      }
    }
  }
  messaging.onTokenRefresh.listen((newToken) {
    if (kDebugMode) {
      print('Token: $newToken');
    }
  });
}

void main() async {
  EnvConfig devConfig = EnvConfig(
    appName: 'Host Bora',
    baseUrl: 'http://167.86.89.92:8082',
    // baseUrl: 'http://www.hostbora.co.tz:8082',
    shouldCollectCrashLog: true,
    // Optional: enable Push to Pay (AzamPay) in Add Booking. Get credentials from https://developerdocs.azampay.co.tz
    azamPayAppName: 'AHADI',
    azamPayClientId: '216c9880-2361-499a-b252-1a4c10415c05',
    azamPayClientSecret: 'RYEW0PbvpM1a08dCxhFr8z/mw9krKBtA74hqpkW2oaf3clWkEi0KMo92NF8/+RGRs1QJUr+RsDBGhQw0FBZ/6b8rhnbNekKTpcxHtcDhVkcJMM4gRo6JiGdeYC80pVp8fobWQF7i6rzUuBkQ0tm/2iA7RBvP2D3L+vM0NGyhtp3rPSQIXKnmvNglB4dq9a165Vc0lFJWLyv/pxd2VyxtsC14xGfNhgD+UEgXxhdOQi2PxYBLK6DoLK/c1gutDfUjrWQiwZZuYVPYWd7VERoTIDeA8DE5AMsRjzQNVTkjxi+ltVowpM38TITT5ZLtZ20neJHWtIwsZdfrA7Ne1TZC9tV46UYUy35MIjzo1TECcH9mFXN3tQigIsVzgvrr7sORhN70cyARkCa/iQCIEjc66QdIGeMvEsyDmGKP12iUMr7CT4R2CAavI9X7fBGHWSF5/eButFCsKuIjRSPMyaCf/AMPlmASQ9jj/kaPH6tviXHxv6pu5I4zO1cqgnjr8KnCAlhIqB/e9NbgPDIKT+A9odmyKgAAX3a3nQzuGOKsyAzPu4w5aEpybyocP2er3SI0AfTGHBxgQPULzEfcCU8KNbTaOEAn5XnMMB7ZGPwr63UD6oJVhHetpbeBHTSw75JiuUjouyynTqnKfoES2vy5UdnwMavGO1bg69NrQJ+PaxI=',
    azamPaySandbox: true,
  );

  BuildConfig.instantiate(
    envType: Environment.DEVELOPMENT,
    envConfig: devConfig,
  );

  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown
  ]);

  SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,        // or any color you want
        statusBarIconBrightness: Brightness.dark,  // Android: dark icons
        statusBarBrightness: Brightness.light,     // iOS: dark icons
      )
  );

  await Firebase.initializeApp(
      name: 'paa_yangu',
      options: DefaultFirebaseOptions.currentPlatform
  );

  await setupFlutterNotifications();

  requestUserPermission();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseMessaging.onMessage.listen((event) => showAlert(event));
  FirebaseMessaging.onMessageOpenedApp.listen((event) =>
      showFlutterNotification(event));

  await GetStorage.init();
  await Get.putAsync(() => StorageService().init());
  await initializeLeaseReminderWorkmanager(
    appName: devConfig.appName,
    baseUrl: devConfig.baseUrl,
  );

  // Tuya IoT + Smart Lock: initialize when config is provided (see TUYA_INTEGRATION.md)
  final tuyaConfig = TuyaConfig.fromEnvironment();
  if (tuyaConfig.isEnabled) {
    Get.put(TuyaService(config: tuyaConfig));
    await Get.find<TuyaService>().init();
    Get.put(TuyaSmartLockService(tuyaService: Get.find<TuyaService>()));
  }

  runApp(const MainApp());
}

import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';


class NotificationManager {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    AndroidInitializationSettings initializationSettingsAndroid =
    const AndroidInitializationSettings('app_icon');

    DarwinInitializationSettings initializationIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      // todo: отключил, т.к. после pub upgrade здесь ошибка
      // onDidReceiveLocalNotification: (id, title, body, payload) {},
    );
    InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationIOS,
    );
    await notificationsPlugin.initialize(initializationSettings,
      onDidReceiveNotificationResponse: (details) { },
    );
  }

  Future<void> showPushNotification(
      String channelId,
      String channelTitle,
      String title,
      String message,
      ) async {
    AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      channelId,
      channelTitle,
      priority: Priority.high,
      importance: Importance.max,
      icon: 'app_icon',
      channelShowBadge: true,
      largeIcon: const DrawableResourceAndroidBitmap('app_icon'),
    );

    NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails
    );

    // todo: генерю рандомный id, улучшить
    var rng = Random();
    final id = rng.nextInt(1000);
    await notificationsPlugin.show(
      id,
      title,
      message,
      notificationDetails,
    );
  }
}

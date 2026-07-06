import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );
  }

  Future<void> bildirimKur({
    required int id,
    required String baslik,
    required String icerik,
    required DateTime zaman,
  }) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: baslik,
      body: icerik,
      scheduledDate: tz.TZDateTime.from(zaman, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'hatirlatici_kanali', 
          'Hatırlatıcılar',
          channelDescription: 'Planlanmış hatırlatıcı bildirimleri',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> bildirimIptalEt(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id: id);
  }
}
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart'; // YENİ EKLENEN PAKET

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Zaman dilimi veritabanını yükle
    tz.initializeTimeZones();

    try {
      final timeZone = await FlutterTimezone.getLocalTimezone();
      
      tz.setLocalLocation(tz.getLocation(timeZone.toString()));
      
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );

    // Android 13+ İzinleri
    final androidImplementation = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
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
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'hatirlatici_kanali', 
          'Hatırlatıcılar',
          channelDescription: 'Planlanmış hatırlatıcı bildirimleri',
          importance: Importance.max,
          priority: Priority.high,
          
          // Tema Rengi (İkon ve butonlar bu renk olur)
          color: const Color(0xFF4D319C),
          
          // Telefonun LED ışığı (Destekleyen cihazlarda mor yanıp söner)
          enableLights: true,
          ledColor: const Color(0xFF4D319C),
          ledOnMs: 1000,
          ledOffMs: 500,

          // Uzun metinler için Genişletilmiş Görünüm
          styleInformation: BigTextStyleInformation(
            icerik, // Genişletildiğinde görünecek tam metin
            contentTitle: baslik, // Genişletildiğinde görünecek başlık
            summaryText: 'Planlı Görev', // Bildirimin sağ üstünde duran küçük özet metni
          ),
          
          // Bildirim geldiğinde ekran kapalıysa uyandırır (Destekleyen cihazlarda)
          visibility: NotificationVisibility.public,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> bildirimIptalEt(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id: id);
  }
}
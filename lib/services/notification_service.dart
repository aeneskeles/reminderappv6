import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/reminder.dart';
import 'database_helper.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  NotificationService._init();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Android için özel kanal oluştur
    const androidChannel = AndroidNotificationChannel(
      'reminder_channel',
      'Hatırlatıcı Bildirimleri',
      description: 'Hatırlatıcı uygulaması bildirimleri için kanal',
      importance: Importance.high,
      playSound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Bildirime tıklandığında yapılacak işlemler
    print('Bildirime tıklandı: ${response.payload}');
  }

  Future<void> scheduleNotification(Reminder reminder) async {
    if (reminder.isCompleted) return;

    final scheduledDate = tz.TZDateTime.from(
      reminder.dateTime,
      tz.local,
    );

    // Geçmiş tarih kontrolü
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Hatırlatıcı Bildirimleri',
      channelDescription: 'Hatırlatıcı uygulaması bildirimleri için kanal',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      reminder.id ?? 0,
      reminder.title,
      reminder.description,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: reminder.id.toString(),
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> rescheduleAllNotifications() async {
    await cancelAllNotifications();
    final reminders = await DatabaseHelper.instance.getActiveReminders();
    
    for (final reminder in reminders) {
      if (reminder.dateTime.isAfter(DateTime.now())) {
        await scheduleNotification(reminder);
      }
    }
  }

  Future<void> updateNotification(Reminder reminder) async {
    await cancelNotification(reminder.id ?? 0);
    if (!reminder.isCompleted) {
      await scheduleNotification(reminder);
    }
  }
}


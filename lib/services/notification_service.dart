import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications/src/platform_specifics/android/enums.dart' as android_enums;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/reminder.dart' as reminder_model;
import 'database_helper.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Bildirim aksiyon ID'leri
  static const String completeActionId = 'complete_action';
  static const String snoozeActionId = 'snooze_action';

  NotificationService._init();

  Future<void> initialize(Function(NotificationResponse)? onNotificationTap) async {
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
      onDidReceiveNotificationResponse: onNotificationTap ?? _onNotificationTapped,
    );

    // Android için öncelik bazlı kanallar oluştur
    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    // Önemli hatırlatıcılar kanalı (Yüksek öncelik)
    const importantChannel = AndroidNotificationChannel(
      'important_reminders',
      'Önemli Hatırlatıcılar',
      description: 'Yüksek öncelikli hatırlatıcı bildirimleri',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // Normal hatırlatıcılar kanalı
    const normalChannel = AndroidNotificationChannel(
      'normal_reminders',
      'Normal Hatırlatıcılar',
      description: 'Normal öncelikli hatırlatıcı bildirimleri',
      importance: Importance.defaultImportance,
      playSound: true,
      enableVibration: false,
      showBadge: true,
    );

    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.createNotificationChannel(importantChannel);
    await androidImplementation?.createNotificationChannel(normalChannel);
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('Bildirime tıklandı: ${response.payload}');
  }

  // Bildirim aksiyonlarını oluştur
  List<AndroidNotificationAction> _buildNotificationActions(int reminderId) {
    return [
      const AndroidNotificationAction(
        completeActionId,
        'Tamamlandı',
        showsUserInterface: false,
      ),
      const AndroidNotificationAction(
        snoozeActionId,
        '10 dk Ertele',
        showsUserInterface: false,
      ),
    ];
  }

  // Kanal adını önceliğe göre belirle
  String _getChannelId(reminder_model.Priority priority) {
    return priority == reminder_model.Priority.high ? 'important_reminders' : 'normal_reminders';
  }

  // Önceliğe göre importance belirle
  Importance _getImportance(reminder_model.Priority priority) {
    return priority == reminder_model.Priority.high ? Importance.high : Importance.defaultImportance;
  }

  // Bildirim zamanını hesapla (notificationBeforeMinutes ile)
  tz.TZDateTime _calculateNotificationTime(reminder_model.Reminder reminder) {
    final reminderTime = tz.TZDateTime.from(reminder.dateTime, tz.local);
    
    if (reminder.notificationBeforeMinutes > 0) {
      return reminderTime.subtract(Duration(minutes: reminder.notificationBeforeMinutes));
    }
    
    return reminderTime;
  }

  // Tekrarlayan bildirim için sonraki tarihi hesapla
  tz.TZDateTime? _calculateNextRecurrenceDate(reminder_model.Reminder reminder, tz.TZDateTime currentDate) {
    switch (reminder.recurrenceType) {
      case reminder_model.RecurrenceType.hourly:
        return currentDate.add(const Duration(hours: 1));
      
      case reminder_model.RecurrenceType.daily:
        return currentDate.add(const Duration(days: 1));
      
      case reminder_model.RecurrenceType.weekly:
        if (reminder.weeklyDays.isEmpty) return null;
        
        // Haftanın gününü bul (1 = Pazartesi, 7 = Pazar)
        int currentWeekday = currentDate.weekday;
        
        // Seçili günlerden bir sonraki günü bul
        for (int day in reminder.weeklyDays) {
          int daysToAdd = (day - currentWeekday) % 7;
          if (daysToAdd == 0) daysToAdd = 7; // Aynı günse bir sonraki hafta
          
          final nextDate = currentDate.add(Duration(days: daysToAdd));
          if (nextDate.isAfter(currentDate)) {
            return nextDate;
          }
        }
        
        // Eğer bu hafta geçtiyse, bir sonraki haftanın ilk seçili günü
        int firstDay = reminder.weeklyDays.first;
        int daysToAdd = (firstDay - currentWeekday + 7) % 7;
        if (daysToAdd == 0) daysToAdd = 7;
        return currentDate.add(Duration(days: daysToAdd));
      
      case reminder_model.RecurrenceType.monthly:
        if (reminder.monthlyDay == null) return null;
        
        // Bir sonraki ayın aynı günü
        int nextMonth = currentDate.month + 1;
        int nextYear = currentDate.year;
        if (nextMonth > 12) {
          nextMonth = 1;
          nextYear++;
        }
        
        // Ayın son gününü kontrol et
        int day = reminder.monthlyDay!;
        final daysInMonth = DateTime(nextYear, nextMonth + 1, 0).day;
        if (day > daysInMonth) day = daysInMonth;
        
        return tz.TZDateTime(
          tz.local,
          nextYear,
          nextMonth,
          day,
          currentDate.hour,
          currentDate.minute,
        );
      
      case reminder_model.RecurrenceType.yearly:
        // Bir sonraki yılın aynı günü
        return tz.TZDateTime(
          tz.local,
          currentDate.year + 1,
          currentDate.month,
          currentDate.day,
          currentDate.hour,
          currentDate.minute,
        );
      
      case reminder_model.RecurrenceType.none:
        return null;
    }
  }

  Future<void> scheduleNotification(reminder_model.Reminder reminder) async {
    if (reminder.isCompleted) return;

    // Ana bildirim zamanı
    final scheduledDate = _calculateNotificationTime(reminder);

    // Geçmiş tarih kontrolü
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      // Eğer tekrarlayan bir hatırlatıcıysa, sonraki tarihi hesapla
      if (reminder.isRecurring && reminder.recurrenceType != reminder_model.RecurrenceType.none) {
        final nextDate = _calculateNextRecurrenceDate(reminder, tz.TZDateTime.from(reminder.dateTime, tz.local));
        if (nextDate == null || nextDate.isBefore(tz.TZDateTime.now(tz.local))) {
          return;
        }
        // Tekrarlayan hatırlatıcı için sonraki tarihi kullan
        final nextReminder = reminder.copyWith(dateTime: nextDate.toLocal());
        await scheduleNotification(nextReminder);
        return;
      }
      return;
    }

    final channelId = _getChannelId(reminder.priority);
    final importance = _getImportance(reminder.priority);
    final actions = _buildNotificationActions(reminder.id ?? 0);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      reminder.priority == reminder_model.Priority.high ? 'Önemli Hatırlatıcılar' : 'Normal Hatırlatıcılar',
      channelDescription: reminder.priority == reminder_model.Priority.high 
          ? 'Yüksek öncelikli hatırlatıcı bildirimleri'
          : 'Normal öncelikli hatırlatıcı bildirimleri',
      importance: importance,
      priority: reminder.priority == reminder_model.Priority.high 
          ? android_enums.Priority.high 
          : android_enums.Priority.defaultPriority,
      showWhen: true,
      enableVibration: reminder.priority == reminder_model.Priority.high,
      actions: actions,
      category: AndroidNotificationCategory.reminder,
      autoCancel: false, // Kullanıcı aksiyon alana kadar açık kalsın
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      reminder.id ?? 0,
      reminder.title,
      reminder.description.isNotEmpty ? reminder.description : 'Hatırlatıcı zamanı geldi',
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: reminder.id.toString(),
      matchDateTimeComponents: reminder.isRecurring && reminder.recurrenceType == reminder_model.RecurrenceType.daily
          ? DateTimeComponents.time
          : null,
    );

    // Eğer tekrarlayan bir hatırlatıcıysa, sonraki tekrarları da planla
    if (reminder.isRecurring && reminder.recurrenceType != reminder_model.RecurrenceType.none) {
      await _scheduleRecurringNotifications(reminder);
    }
  }

  // Tekrarlayan bildirimleri planla (gelecek 10 tekrar için)
  Future<void> _scheduleRecurringNotifications(reminder_model.Reminder reminder) async {
    if (reminder.recurrenceType == reminder_model.RecurrenceType.none) return;

    tz.TZDateTime currentDate = tz.TZDateTime.from(reminder.dateTime, tz.local);
    int scheduledCount = 0;
    const maxRecurrences = 10; // Gelecek 10 tekrarı planla

    while (scheduledCount < maxRecurrences) {
      final nextDate = _calculateNextRecurrenceDate(reminder, currentDate);
      if (nextDate == null) break;

      // Geçmiş tarih kontrolü
      if (nextDate.isBefore(tz.TZDateTime.now(tz.local))) {
        currentDate = nextDate;
        continue;
      }

      // Bildirim zamanını hesapla
      final notificationTime = nextDate.subtract(
        Duration(minutes: reminder.notificationBeforeMinutes),
      );

      if (notificationTime.isBefore(tz.TZDateTime.now(tz.local))) {
        currentDate = nextDate;
        continue;
      }

      // Tekrarlayan bildirim için benzersiz ID (reminderId * 1000 + recurrenceIndex)
      final notificationId = (reminder.id ?? 0) * 1000 + scheduledCount + 1;

      final channelId = _getChannelId(reminder.priority);
      final importance = _getImportance(reminder.priority);
      final actions = _buildNotificationActions(reminder.id ?? 0);

      final androidDetails = AndroidNotificationDetails(
        channelId,
        reminder.priority == reminder_model.Priority.high ? 'Önemli Hatırlatıcılar' : 'Normal Hatırlatıcılar',
        channelDescription: reminder.priority == reminder_model.Priority.high 
            ? 'Yüksek öncelikli hatırlatıcı bildirimleri'
            : 'Normal öncelikli hatırlatıcı bildirimleri',
        importance: importance,
        priority: reminder.priority == reminder_model.Priority.high 
            ? android_enums.Priority.high 
            : android_enums.Priority.defaultPriority,
        showWhen: true,
        enableVibration: reminder.priority == reminder_model.Priority.high,
        actions: actions,
        category: AndroidNotificationCategory.reminder,
        autoCancel: false,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        notificationId,
        reminder.title,
        reminder.description.isNotEmpty ? reminder.description : 'Hatırlatıcı zamanı geldi',
        notificationTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: reminder.id.toString(),
        matchDateTimeComponents: reminder.recurrenceType == reminder_model.RecurrenceType.daily
            ? DateTimeComponents.time
            : null,
      );

      currentDate = nextDate;
      scheduledCount++;
    }
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    // Tekrarlayan bildirimleri de iptal et (id * 1000 + 1'den id * 1000 + 10'a kadar)
    for (int i = 1; i <= 10; i++) {
      await _notifications.cancel(id * 1000 + i);
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> rescheduleAllNotifications() async {
    await cancelAllNotifications();
    final reminders = await DatabaseHelper.instance.getActiveReminders();
    
    for (final reminder in reminders) {
      await scheduleNotification(reminder);
    }
  }

  Future<void> updateNotification(reminder_model.Reminder reminder) async {
    await cancelNotification(reminder.id ?? 0);
    if (!reminder.isCompleted) {
      await scheduleNotification(reminder);
    }
  }

  // Erteleme (Snooze) - 10 dakika sonra tekrar bildirim gönder
  Future<void> snoozeNotification(int reminderId) async {
    final reminder = await DatabaseHelper.instance.getReminder(reminderId);
    if (reminder == null || reminder.isCompleted) return;

    // 10 dakika sonraki zamanı hesapla
    final snoozeTime = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 10));
    
    // Snooze için benzersiz ID (negatif ID kullan)
    final snoozeId = -(reminderId * 1000 + DateTime.now().millisecondsSinceEpoch % 1000);

    final channelId = _getChannelId(reminder.priority);
    final importance = _getImportance(reminder.priority);
    final actions = _buildNotificationActions(reminder.id ?? 0);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      reminder.priority == reminder_model.Priority.high ? 'Önemli Hatırlatıcılar' : 'Normal Hatırlatıcılar',
      channelDescription: reminder.priority == reminder_model.Priority.high 
          ? 'Yüksek öncelikli hatırlatıcı bildirimleri'
          : 'Normal öncelikli hatırlatıcı bildirimleri',
      importance: importance,
      priority: reminder.priority == reminder_model.Priority.high 
          ? android_enums.Priority.high 
          : android_enums.Priority.defaultPriority,
      showWhen: true,
      enableVibration: reminder.priority == reminder_model.Priority.high,
      actions: actions,
      category: AndroidNotificationCategory.reminder,
      autoCancel: false,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      snoozeId,
      reminder.title,
      '${reminder.description.isNotEmpty ? reminder.description : "Hatırlatıcı"} (Ertelendi)',
      snoozeTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: reminder.id.toString(),
    );
  }

  // Bildirim aksiyonunu işle
  Future<void> handleNotificationAction(String actionId, int reminderId) async {
    if (actionId == completeActionId) {
      // Hatırlatıcıyı tamamlandı olarak işaretle
      final reminder = await DatabaseHelper.instance.getReminder(reminderId);
      if (reminder != null && !reminder.isCompleted) {
        final updated = reminder.copyWith(isCompleted: true);
        await DatabaseHelper.instance.updateReminder(updated);
        await cancelNotification(reminderId);
      }
    } else if (actionId == snoozeActionId) {
      // Bildirimi 10 dakika ertele
      await snoozeNotification(reminderId);
    }
  }
}

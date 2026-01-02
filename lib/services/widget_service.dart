import 'package:home_widget/home_widget.dart';
import '../models/reminder.dart';
import '../services/database_helper.dart';

class WidgetService {
  static final WidgetService _instance = WidgetService._internal();
  factory WidgetService() => _instance;
  WidgetService._internal();

  final _dbHelper = DatabaseHelper.instance;

  /// Widget'ı başlat
  Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId('group.reminderappv6');
    } catch (e) {
      print('Widget başlatma hatası: $e');
    }
  }

  /// Widget'ı güncelle
  Future<void> updateWidget() async {
    try {
      // Bugünkü hatırlatıcıları getir
      final reminders = await _getTodayReminders();
      
      // Widget verilerini ayarla
      await HomeWidget.saveWidgetData<String>(
        'widget_title',
        'Bugünkü Hatırlatıcılar',
      );
      
      await HomeWidget.saveWidgetData<int>(
        'reminder_count',
        reminders.length,
      );

      // İlk 5 hatırlatıcıyı widget'a ekle
      for (int i = 0; i < reminders.length && i < 5; i++) {
        final reminder = reminders[i];
        await HomeWidget.saveWidgetData<String>(
          'reminder_${i}_title',
          reminder.title,
        );
        await HomeWidget.saveWidgetData<String>(
          'reminder_${i}_time',
          _formatTime(reminder.dateTime),
        );
        await HomeWidget.saveWidgetData<bool>(
          'reminder_${i}_completed',
          reminder.isCompleted,
        );
        await HomeWidget.saveWidgetData<int>(
          'reminder_${i}_priority',
          reminder.priority.index,
        );
      }

      // Widget'ı güncelle
      await HomeWidget.updateWidget(
        name: 'ReminderWidgetProvider',
        androidName: 'ReminderWidgetProvider',
        iOSName: 'ReminderWidget',
      );
    } catch (e) {
      print('Widget güncelleme hatası: $e');
    }
  }

  /// Bugünkü hatırlatıcıları getir
  Future<List<Reminder>> _getTodayReminders() async {
    try {
      final allReminders = await _dbHelper.getReminders();
      final now = DateTime.now();
      
      return allReminders.where((reminder) {
        return reminder.dateTime.year == now.year &&
               reminder.dateTime.month == now.month &&
               reminder.dateTime.day == now.day &&
               !reminder.isCompleted;
      }).toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    } catch (e) {
      print('Bugünkü hatırlatıcıları getirme hatası: $e');
      return [];
    }
  }

  /// Zamanı formatla
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Widget'tan gelen tıklamaları işle
  Future<void> handleWidgetClick(Uri? uri) async {
    if (uri == null) return;

    try {
      final action = uri.host;
      final reminderId = uri.queryParameters['id'];

      if (action == 'open_reminder' && reminderId != null) {
        // Hatırlatıcıyı aç
        print('Hatırlatıcı açılıyor: $reminderId');
      } else if (action == 'complete_reminder' && reminderId != null) {
        // Hatırlatıcıyı tamamla
        final id = int.tryParse(reminderId);
        if (id != null) {
          await _completeReminder(id);
          await updateWidget();
        }
      } else if (action == 'open_app') {
        // Uygulamayı aç
        print('Uygulama açılıyor');
      }
    } catch (e) {
      print('Widget tıklama işleme hatası: $e');
    }
  }

  /// Hatırlatıcıyı tamamla
  Future<void> _completeReminder(int reminderId) async {
    try {
      final reminder = await _dbHelper.getReminder(reminderId);
      if (reminder != null) {
        final updatedReminder = reminder.copyWith(isCompleted: true);
        await _dbHelper.updateReminder(updatedReminder);
      }
    } catch (e) {
      print('Hatırlatıcı tamamlama hatası: $e');
    }
  }

  /// Widget verilerini temizle
  Future<void> clearWidgetData() async {
    try {
      await HomeWidget.saveWidgetData<String>('widget_title', null);
      await HomeWidget.saveWidgetData<int>('reminder_count', null);
      
      for (int i = 0; i < 5; i++) {
        await HomeWidget.saveWidgetData<String>('reminder_${i}_title', null);
        await HomeWidget.saveWidgetData<String>('reminder_${i}_time', null);
        await HomeWidget.saveWidgetData<bool>('reminder_${i}_completed', null);
        await HomeWidget.saveWidgetData<int>('reminder_${i}_priority', null);
      }

      await HomeWidget.updateWidget(
        name: 'ReminderWidgetProvider',
        androidName: 'ReminderWidgetProvider',
        iOSName: 'ReminderWidget',
      );
    } catch (e) {
      print('Widget verilerini temizleme hatası: $e');
    }
  }

  /// Tamamlanan hatırlatıcı sayısını widget'a ekle
  Future<void> updateCompletedCount() async {
    try {
      final reminders = await _dbHelper.getReminders();
      final completedCount = reminders.where((r) => r.isCompleted).length;
      
      await HomeWidget.saveWidgetData<int>(
        'completed_count',
        completedCount,
      );

      await HomeWidget.updateWidget(
        name: 'ReminderWidgetProvider',
        androidName: 'ReminderWidgetProvider',
        iOSName: 'ReminderWidget',
      );
    } catch (e) {
      print('Tamamlanan sayı güncelleme hatası: $e');
    }
  }

  /// Yaklaşan hatırlatıcıları widget'a ekle
  Future<void> updateUpcomingReminders() async {
    try {
      final reminders = await _getUpcomingReminders();
      
      await HomeWidget.saveWidgetData<String>(
        'widget_title',
        'Yaklaşan Hatırlatıcılar',
      );
      
      await HomeWidget.saveWidgetData<int>(
        'reminder_count',
        reminders.length,
      );

      for (int i = 0; i < reminders.length && i < 5; i++) {
        final reminder = reminders[i];
        await HomeWidget.saveWidgetData<String>(
          'reminder_${i}_title',
          reminder.title,
        );
        await HomeWidget.saveWidgetData<String>(
          'reminder_${i}_time',
          _formatDateTime(reminder.dateTime),
        );
        await HomeWidget.saveWidgetData<bool>(
          'reminder_${i}_completed',
          reminder.isCompleted,
        );
        await HomeWidget.saveWidgetData<int>(
          'reminder_${i}_priority',
          reminder.priority.index,
        );
      }

      await HomeWidget.updateWidget(
        name: 'ReminderWidgetProvider',
        androidName: 'ReminderWidgetProvider',
        iOSName: 'ReminderWidget',
      );
    } catch (e) {
      print('Yaklaşan hatırlatıcılar güncelleme hatası: $e');
    }
  }

  /// Yaklaşan hatırlatıcıları getir (sonraki 7 gün)
  Future<List<Reminder>> _getUpcomingReminders() async {
    try {
      final allReminders = await _dbHelper.getReminders();
      final now = DateTime.now();
      final weekLater = now.add(const Duration(days: 7));
      
      return allReminders.where((reminder) {
        return reminder.dateTime.isAfter(now) &&
               reminder.dateTime.isBefore(weekLater) &&
               !reminder.isCompleted;
      }).toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    } catch (e) {
      print('Yaklaşan hatırlatıcıları getirme hatası: $e');
      return [];
    }
  }

  /// Tarih ve saati formatla
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final reminderDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dateStr;
    if (reminderDate == today) {
      dateStr = 'Bugün';
    } else if (reminderDate == tomorrow) {
      dateStr = 'Yarın';
    } else {
      dateStr = '${dateTime.day}/${dateTime.month}';
    }

    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$dateStr $hour:$minute';
  }
}


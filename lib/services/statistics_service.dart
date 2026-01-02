import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reminder.dart';
import '../services/database_helper.dart';

class StatisticsService {
  static final StatisticsService _instance = StatisticsService._internal();
  factory StatisticsService() => _instance;
  StatisticsService._internal();

  final _supabase = Supabase.instance.client;
  final _dbHelper = DatabaseHelper.instance;

  /// Toplam hatırlatıcı sayısı
  Future<int> getTotalRemindersCount() async {
    try {
      final reminders = await _dbHelper.getReminders();
      return reminders.length;
    } catch (e) {
      print('Toplam hatırlatıcı sayısı hatası: $e');
      return 0;
    }
  }

  /// Tamamlanan hatırlatıcı sayısı
  Future<int> getCompletedRemindersCount() async {
    try {
      final reminders = await _dbHelper.getReminders();
      return reminders.where((r) => r.isCompleted).length;
    } catch (e) {
      print('Tamamlanan hatırlatıcı sayısı hatası: $e');
      return 0;
    }
  }

  /// Aktif hatırlatıcı sayısı
  Future<int> getActiveRemindersCount() async {
    try {
      final reminders = await _dbHelper.getReminders();
      return reminders.where((r) => !r.isCompleted).length;
    } catch (e) {
      print('Aktif hatırlatıcı sayısı hatası: $e');
      return 0;
    }
  }

  /// Kategoriye göre hatırlatıcı dağılımı
  Future<Map<String, int>> getRemindersByCategory() async {
    try {
      final reminders = await _dbHelper.getReminders();
      final Map<String, int> categoryCount = {};
      
      for (final reminder in reminders) {
        categoryCount[reminder.category] = (categoryCount[reminder.category] ?? 0) + 1;
      }
      
      return categoryCount;
    } catch (e) {
      print('Kategoriye göre hatırlatıcı hatası: $e');
      return {};
    }
  }

  /// Önceliğe göre hatırlatıcı dağılımı
  Future<Map<Priority, int>> getRemindersByPriority() async {
    try {
      final reminders = await _dbHelper.getReminders();
      final Map<Priority, int> priorityCount = {
        Priority.low: 0,
        Priority.normal: 0,
        Priority.high: 0,
      };
      
      for (final reminder in reminders) {
        priorityCount[reminder.priority] = (priorityCount[reminder.priority] ?? 0) + 1;
      }
      
      return priorityCount;
    } catch (e) {
      print('Önceliğe göre hatırlatıcı hatası: $e');
      return {Priority.low: 0, Priority.normal: 0, Priority.high: 0};
    }
  }

  /// Haftalık tamamlanma oranı
  Future<Map<String, double>> getWeeklyCompletionRate() async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final reminders = await _dbHelper.getReminders();
      
      final Map<String, double> weeklyRate = {};
      
      for (int i = 0; i < 7; i++) {
        final day = weekStart.add(Duration(days: i));
        final dayKey = _getDayName(day.weekday);
        
        final dayReminders = reminders.where((r) {
          return r.dateTime.year == day.year &&
                 r.dateTime.month == day.month &&
                 r.dateTime.day == day.day;
        }).toList();
        
        if (dayReminders.isEmpty) {
          weeklyRate[dayKey] = 0.0;
        } else {
          final completed = dayReminders.where((r) => r.isCompleted).length;
          weeklyRate[dayKey] = (completed / dayReminders.length) * 100;
        }
      }
      
      return weeklyRate;
    } catch (e) {
      print('Haftalık tamamlanma oranı hatası: $e');
      return {};
    }
  }

  /// Aylık hatırlatıcı sayısı
  Future<Map<String, int>> getMonthlyRemindersCount() async {
    try {
      final now = DateTime.now();
      final reminders = await _dbHelper.getReminders();
      
      final Map<String, int> monthlyCount = {};
      
      for (int i = 11; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final monthKey = '${month.month}/${month.year}';
        
        final monthReminders = reminders.where((r) {
          return r.dateTime.year == month.year && r.dateTime.month == month.month;
        }).length;
        
        monthlyCount[monthKey] = monthReminders;
      }
      
      return monthlyCount;
    } catch (e) {
      print('Aylık hatırlatıcı sayısı hatası: $e');
      return {};
    }
  }

  /// Favori hatırlatıcı sayısı
  Future<int> getFavoriteRemindersCount() async {
    try {
      final reminders = await _dbHelper.getReminders();
      return reminders.where((r) => r.isFavorite).length;
    } catch (e) {
      print('Favori hatırlatıcı sayısı hatası: $e');
      return 0;
    }
  }

  /// Paylaşılan hatırlatıcı sayısı
  Future<int> getSharedRemindersCount() async {
    try {
      final reminders = await _dbHelper.getReminders();
      return reminders.where((r) => r.isShared).length;
    } catch (e) {
      print('Paylaşılan hatırlatıcı sayısı hatası: $e');
      return 0;
    }
  }

  /// Tekrarlanan hatırlatıcı sayısı
  Future<int> getRecurringRemindersCount() async {
    try {
      final reminders = await _dbHelper.getReminders();
      return reminders.where((r) => r.isRecurring).length;
    } catch (e) {
      print('Tekrarlanan hatırlatıcı sayısı hatası: $e');
      return 0;
    }
  }

  /// Ortalama tamamlanma süresi (gün)
  Future<double> getAverageCompletionTime() async {
    try {
      final reminders = await _dbHelper.getReminders();
      final completedReminders = reminders.where((r) => 
        r.isCompleted && r.createdAt != null && r.updatedAt != null
      ).toList();
      
      if (completedReminders.isEmpty) return 0.0;
      
      double totalDays = 0;
      for (final reminder in completedReminders) {
        final duration = reminder.updatedAt!.difference(reminder.createdAt!);
        totalDays += duration.inDays;
      }
      
      return totalDays / completedReminders.length;
    } catch (e) {
      print('Ortalama tamamlanma süresi hatası: $e');
      return 0.0;
    }
  }

  /// En çok kullanılan kategori
  Future<String?> getMostUsedCategory() async {
    try {
      final categoryCount = await getRemindersByCategory();
      if (categoryCount.isEmpty) return null;
      
      return categoryCount.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    } catch (e) {
      print('En çok kullanılan kategori hatası: $e');
      return null;
    }
  }

  /// Bugünkü tamamlanma oranı
  Future<double> getTodayCompletionRate() async {
    try {
      final now = DateTime.now();
      final reminders = await _dbHelper.getReminders();
      
      final todayReminders = reminders.where((r) {
        return r.dateTime.year == now.year &&
               r.dateTime.month == now.month &&
               r.dateTime.day == now.day;
      }).toList();
      
      if (todayReminders.isEmpty) return 0.0;
      
      final completed = todayReminders.where((r) => r.isCompleted).length;
      return (completed / todayReminders.length) * 100;
    } catch (e) {
      print('Bugünkü tamamlanma oranı hatası: $e');
      return 0.0;
    }
  }

  /// Genel tamamlanma oranı
  Future<double> getOverallCompletionRate() async {
    try {
      final total = await getTotalRemindersCount();
      if (total == 0) return 0.0;
      
      final completed = await getCompletedRemindersCount();
      return (completed / total) * 100;
    } catch (e) {
      print('Genel tamamlanma oranı hatası: $e');
      return 0.0;
    }
  }

  /// Gün adını getir
  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Pzt';
      case 2: return 'Sal';
      case 3: return 'Çar';
      case 4: return 'Per';
      case 5: return 'Cum';
      case 6: return 'Cmt';
      case 7: return 'Paz';
      default: return '';
    }
  }

  /// Tüm istatistikleri getir
  Future<Map<String, dynamic>> getAllStatistics() async {
    try {
      return {
        'total': await getTotalRemindersCount(),
        'completed': await getCompletedRemindersCount(),
        'active': await getActiveRemindersCount(),
        'favorite': await getFavoriteRemindersCount(),
        'shared': await getSharedRemindersCount(),
        'recurring': await getRecurringRemindersCount(),
        'byCategory': await getRemindersByCategory(),
        'byPriority': await getRemindersByPriority(),
        'weeklyRate': await getWeeklyCompletionRate(),
        'monthlyCount': await getMonthlyRemindersCount(),
        'todayRate': await getTodayCompletionRate(),
        'overallRate': await getOverallCompletionRate(),
        'avgCompletionTime': await getAverageCompletionTime(),
        'mostUsedCategory': await getMostUsedCategory(),
      };
    } catch (e) {
      print('Tüm istatistikleri getirme hatası: $e');
      return {};
    }
  }
}


import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reminder.dart';
import 'auth_service.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

  DatabaseHelper._init();

  // Kullanıcı ID'sini al
  String? get _userId => _authService.currentUser?.id;

  Future<int> createReminder(Reminder reminder) async {
    try {
      if (_userId == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      final data = {
        'user_id': _userId,
        'title': reminder.title,
        'description': reminder.description,
        'date_time': reminder.dateTime.toIso8601String(),
        'is_recurring': reminder.isRecurring,
        'category': reminder.category,
        'is_completed': reminder.isCompleted,
        'is_all_day': reminder.isAllDay,
        'recurrence_type': reminder.recurrenceType.name,
        'weekly_days': reminder.weeklyDays.isEmpty ? null : reminder.weeklyDays.join(','),
        'monthly_day': reminder.monthlyDay,
        'notification_before_minutes': reminder.notificationBeforeMinutes,
        'priority': reminder.priority.name,
        'color_tag': reminder.colorTag,
      };

      final response = await _supabase
          .from('reminders')
          .insert(data)
          .select('id')
          .single();

      final id = response['id'] as int;
      print('Hatırlatıcı Supabase\'e eklendi, ID: $id');
      return id;
    } catch (e) {
      print('Hatırlatıcı oluşturulurken hata: $e');
      rethrow;
    }
  }

  Future<List<Reminder>> getAllReminders() async {
    try {
      if (_userId == null) {
        return [];
      }

      final response = await _supabase
          .from('reminders')
          .select()
          .eq('user_id', _userId!)
          .order('date_time', ascending: true);

      final reminders = (response as List)
          .map((map) => _reminderFromSupabaseMap(map as Map<String, dynamic>))
          .toList();

      print('Supabase\'den ${reminders.length} hatırlatıcı alındı');
      return reminders;
    } catch (e) {
      print('Hatırlatıcılar alınırken hata: $e');
      rethrow;
    }
  }

  Future<List<Reminder>> getActiveReminders() async {
    if (_userId == null) {
      return [];
    }

    final response = await _supabase
        .from('reminders')
        .select()
        .eq('user_id', _userId!)
        .eq('is_completed', false)
        .order('date_time', ascending: true);

    return (response as List)
        .map((map) => _reminderFromSupabaseMap(map as Map<String, dynamic>))
        .toList();
  }

  Future<List<Reminder>> getCompletedReminders() async {
    if (_userId == null) {
      return [];
    }

    final response = await _supabase
        .from('reminders')
        .select()
        .eq('user_id', _userId!)
        .eq('is_completed', true)
        .order('date_time', ascending: false);

    return (response as List)
        .map((map) => _reminderFromSupabaseMap(map as Map<String, dynamic>))
        .toList();
  }

  Future<List<Reminder>> searchReminders(String query) async {
    if (_userId == null) {
      return [];
    }

    // Türkçe karakter desteği için ilike kullanıyoruz (PostgreSQL case-insensitive)
    // Supabase ilike zaten Türkçe karakterleri destekler
    final response = await _supabase
        .from('reminders')
        .select()
        .eq('user_id', _userId!)
        .or('title.ilike.%$query%,description.ilike.%$query%,category.ilike.%$query%')
        .order('date_time', ascending: true);

    return (response as List)
        .map((map) => _reminderFromSupabaseMap(map as Map<String, dynamic>))
        .toList();
  }

  Future<List<Reminder>> getRemindersByCategory(String category) async {
    if (_userId == null) {
      return [];
    }

    final response = await _supabase
        .from('reminders')
        .select()
        .eq('user_id', _userId!)
        .eq('category', category)
        .order('date_time', ascending: true);

    return (response as List)
        .map((map) => _reminderFromSupabaseMap(map as Map<String, dynamic>))
        .toList();
  }

  Future<List<Reminder>> getRemindersByDate(DateTime date) async {
    if (_userId == null) {
      return [];
    }

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final response = await _supabase
        .from('reminders')
        .select()
        .eq('user_id', _userId!)
        .gte('date_time', startOfDay.toIso8601String())
        .lte('date_time', endOfDay.toIso8601String())
        .order('date_time', ascending: true);

    return (response as List)
        .map((map) => _reminderFromSupabaseMap(map as Map<String, dynamic>))
        .toList();
  }

  Future<Reminder?> getReminder(int id) async {
    if (_userId == null) {
      return null;
    }

    try {
      final response = await _supabase
          .from('reminders')
          .select()
          .eq('id', id)
          .eq('user_id', _userId!)
          .single();

      return _reminderFromSupabaseMap(response as Map<String, dynamic>);
    } catch (e) {
      print('Hatırlatıcı bulunamadı: $e');
      return null;
    }
  }

  Future<int> updateReminder(Reminder reminder) async {
    if (_userId == null || reminder.id == null) {
      return 0;
    }

    try {
      final data = {
        'title': reminder.title,
        'description': reminder.description,
        'date_time': reminder.dateTime.toIso8601String(),
        'is_recurring': reminder.isRecurring,
        'category': reminder.category,
        'is_completed': reminder.isCompleted,
        'is_all_day': reminder.isAllDay,
        'recurrence_type': reminder.recurrenceType.name,
        'weekly_days': reminder.weeklyDays.isEmpty ? null : reminder.weeklyDays.join(','),
        'monthly_day': reminder.monthlyDay,
        'notification_before_minutes': reminder.notificationBeforeMinutes,
        'priority': reminder.priority.name,
        'color_tag': reminder.colorTag,
      };

      await _supabase
          .from('reminders')
          .update(data)
          .eq('id', reminder.id!)
          .eq('user_id', _userId!);

      return 1;
    } catch (e) {
      print('Hatırlatıcı güncellenirken hata: $e');
      return 0;
    }
  }

  Future<int> deleteReminder(int id) async {
    if (_userId == null) {
      return 0;
    }

    try {
      await _supabase
          .from('reminders')
          .delete()
          .eq('id', id)
          .eq('user_id', _userId!);

      return 1;
    } catch (e) {
      print('Hatırlatıcı silinirken hata: $e');
      return 0;
    }
  }

  Future<List<String>> getAllCategories() async {
    if (_userId == null) {
      return [];
    }

    try {
      final response = await _supabase
          .from('reminders')
          .select('category')
          .eq('user_id', _userId!);

      final categories = (response as List)
          .map((map) => (map as Map<String, dynamic>)['category'] as String)
          .toSet()
          .toList();
      
      categories.sort();
      return categories;
    } catch (e) {
      print('Kategoriler alınırken hata: $e');
      return [];
    }
  }

  // Supabase map'ini Reminder'a çevir
  Reminder _reminderFromSupabaseMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      dateTime: DateTime.parse(map['date_time'] as String),
      isRecurring: map['is_recurring'] as bool? ?? false,
      category: map['category'] as String? ?? 'Genel',
      isCompleted: map['is_completed'] as bool? ?? false,
      isAllDay: map['is_all_day'] as bool? ?? false,
      recurrenceType: RecurrenceType.values.firstWhere(
        (e) => e.name == (map['recurrence_type'] as String? ?? 'none'),
        orElse: () => RecurrenceType.none,
      ),
      weeklyDays: (map['weekly_days'] as String? ?? '').split(',').where((e) => e.isNotEmpty).map((e) => int.parse(e)).toList(),
      monthlyDay: map['monthly_day'] as int?,
      notificationBeforeMinutes: map['notification_before_minutes'] as int? ?? 0,
      priority: Priority.values.firstWhere(
        (e) => e.name == (map['priority'] as String? ?? 'normal'),
        orElse: () => Priority.normal,
      ),
      colorTag: map['color_tag'] as int? ?? 0,
    );
  }
}


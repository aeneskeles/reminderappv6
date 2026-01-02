import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reminder.dart';
import 'auth_service.dart';
import 'sync_service.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  final SyncService _syncService = SyncService.instance;
  final AuthService _authService = AuthService();

  DatabaseHelper._init();

  // Kullanıcı ID'sini al
  String? get _userId => _authService.currentUser?.id;

  // Create reminder (using sync service)
  Future<int> createReminder(Reminder reminder) async {
    try {
      if (_userId == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      return await _syncService.createReminder(reminder);
    } catch (e) {
      print('Hatırlatıcı oluşturulurken hata: $e');
      rethrow;
    }
  }

  // Get all reminders (using sync service - from local db)
  Future<List<Reminder>> getAllReminders() async {
    try {
      if (_userId == null) {
        return [];
      }

      return await _syncService.getAllReminders();
    } catch (e) {
      print('Hatırlatıcılar alınırken hata: $e');
      return [];
    }
  }

  // Get active reminders
  Future<List<Reminder>> getActiveReminders() async {
    try {
      final allReminders = await getAllReminders();
      return allReminders.where((r) => !r.isCompleted).toList();
    } catch (e) {
      print('Aktif hatırlatıcılar alınırken hata: $e');
      return [];
    }
  }

  // Get completed reminders
  Future<List<Reminder>> getCompletedReminders() async {
    try {
      final allReminders = await getAllReminders();
      return allReminders.where((r) => r.isCompleted).toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    } catch (e) {
      print('Tamamlanan hatırlatıcılar alınırken hata: $e');
      return [];
    }
  }

  // Search reminders
  Future<List<Reminder>> searchReminders(String query) async {
    try {
      final allReminders = await getAllReminders();
      final lowerQuery = query.toLowerCase();
      
      return allReminders.where((r) {
        return r.title.toLowerCase().contains(lowerQuery) ||
            r.description.toLowerCase().contains(lowerQuery) ||
            r.category.toLowerCase().contains(lowerQuery);
      }).toList();
    } catch (e) {
      print('Hatırlatıcılar aranırken hata: $e');
      return [];
    }
  }

  // Get reminders by category
  Future<List<Reminder>> getRemindersByCategory(String category) async {
    try {
      final allReminders = await getAllReminders();
      return allReminders.where((r) => r.category == category).toList();
    } catch (e) {
      print('Kategoriye göre hatırlatıcılar alınırken hata: $e');
      return [];
    }
  }

  // Get reminders by date
  Future<List<Reminder>> getRemindersByDate(DateTime date) async {
    try {
      final allReminders = await getAllReminders();
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      return allReminders.where((r) {
        return r.dateTime.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
            r.dateTime.isBefore(endOfDay.add(const Duration(seconds: 1)));
      }).toList();
    } catch (e) {
      print('Tarihe göre hatırlatıcılar alınırken hata: $e');
      return [];
    }
  }

  // Get reminder by ID
  Future<Reminder?> getReminder(int id) async {
    try {
      final allReminders = await getAllReminders();
      return allReminders.firstWhere(
        (r) => r.id == id,
        orElse: () => throw Exception('Hatırlatıcı bulunamadı'),
      );
    } catch (e) {
      print('Hatırlatıcı bulunamadı: $e');
      return null;
    }
  }

  // Update reminder (using sync service)
  Future<int> updateReminder(Reminder reminder) async {
    try {
      if (_userId == null || reminder.id == null) {
        return 0;
      }

      await _syncService.updateReminder(reminder);
      return 1;
    } catch (e) {
      print('Hatırlatıcı güncellenirken hata: $e');
      return 0;
    }
  }

  // Delete reminder (using sync service)
  Future<int> deleteReminder(int id) async {
    try {
      if (_userId == null) {
        return 0;
      }

      await _syncService.deleteReminder(id);
      return 1;
    } catch (e) {
      print('Hatırlatıcı silinirken hata: $e');
      return 0;
    }
  }

  // Get all categories
  Future<List<String>> getAllCategories() async {
    try {
      final allReminders = await getAllReminders();
      final categories = allReminders
          .map((r) => r.category)
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList();
      
      categories.sort();
      return categories;
    } catch (e) {
      print('Kategoriler alınırken hata: $e');
      return [];
    }
  }

  // Force sync with server
  Future<bool> syncWithServer() async {
    try {
      return await _syncService.forceSync();
    } catch (e) {
      print('Senkronizasyon hatası: $e');
      return false;
    }
  }

  // Check if online
  Future<bool> isOnline() async {
    return await _syncService.isOnline();
  }

  // Get last sync time
  DateTime? get lastSyncTime => _syncService.lastSyncTime;

  // Check if syncing
  bool get isSyncing => _syncService.isSyncing;

  // Get reminders (alias for getAllReminders)
  Future<List<Reminder>> getReminders() async {
    return await getAllReminders();
  }

  // Get favorite reminders
  Future<List<Reminder>> getFavoriteReminders() async {
    try {
      final allReminders = await getAllReminders();
      return allReminders.where((r) => r.isFavorite).toList();
    } catch (e) {
      print('Favori hatırlatıcılar alınırken hata: $e');
      return [];
    }
  }

  // Get shared reminders
  Future<List<Reminder>> getSharedReminders() async {
    try {
      final allReminders = await getAllReminders();
      return allReminders.where((r) => r.isShared).toList();
    } catch (e) {
      print('Paylaşılan hatırlatıcılar alınırken hata: $e');
      return [];
    }
  }

  // Toggle favorite
  Future<bool> toggleFavorite(int id) async {
    try {
      final reminder = await getReminder(id);
      if (reminder == null) return false;

      final updated = reminder.copyWith(isFavorite: !reminder.isFavorite);
      await updateReminder(updated);
      return true;
    } catch (e) {
      print('Favori durumu değiştirilirken hata: $e');
      return false;
    }
  }

  // Get reminders with attachments
  Future<List<Reminder>> getRemindersWithAttachments() async {
    try {
      final allReminders = await getAllReminders();
      return allReminders.where((r) => r.attachments.isNotEmpty).toList();
    } catch (e) {
      print('Ekli hatırlatıcılar alınırken hata: $e');
      return [];
    }
  }
}

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/reminder.dart';

enum NotificationStatus { sent, dismissed, snoozed, missed, opened }

class NotificationHistoryItem {
  final int? id;
  final int reminderId;
  final String reminderTitle;
  final DateTime notificationTime;
  final NotificationStatus status;
  final DateTime? actionTime;
  final String? actionNote;

  NotificationHistoryItem({
    this.id,
    required this.reminderId,
    required this.reminderTitle,
    required this.notificationTime,
    required this.status,
    this.actionTime,
    this.actionNote,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reminder_id': reminderId,
      'reminder_title': reminderTitle,
      'notification_time': notificationTime.toIso8601String(),
      'status': status.name,
      'action_time': actionTime?.toIso8601String(),
      'action_note': actionNote,
    };
  }

  factory NotificationHistoryItem.fromMap(Map<String, dynamic> map) {
    return NotificationHistoryItem(
      id: map['id'] as int?,
      reminderId: map['reminder_id'] as int,
      reminderTitle: map['reminder_title'] as String,
      notificationTime: DateTime.parse(map['notification_time'] as String),
      status: NotificationStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String),
        orElse: () => NotificationStatus.sent,
      ),
      actionTime: map['action_time'] != null 
          ? DateTime.parse(map['action_time'] as String) 
          : null,
      actionNote: map['action_note'] as String?,
    );
  }
}

class NotificationHistoryService {
  static final NotificationHistoryService _instance = NotificationHistoryService._internal();
  factory NotificationHistoryService() => _instance;
  NotificationHistoryService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'notification_history.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notification_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            reminder_id INTEGER NOT NULL,
            reminder_title TEXT NOT NULL,
            notification_time TEXT NOT NULL,
            status TEXT NOT NULL,
            action_time TEXT,
            action_note TEXT
          )
        ''');
      },
    );
  }

  /// Bildirim geçmişi ekle
  Future<int> addHistory(NotificationHistoryItem item) async {
    try {
      final db = await database;
      return await db.insert('notification_history', item.toMap());
    } catch (e) {
      print('Bildirim geçmişi ekleme hatası: $e');
      return -1;
    }
  }

  /// Bildirim durumunu güncelle
  Future<bool> updateStatus(
    int historyId,
    NotificationStatus status, {
    String? note,
  }) async {
    try {
      final db = await database;
      await db.update(
        'notification_history',
        {
          'status': status.name,
          'action_time': DateTime.now().toIso8601String(),
          'action_note': note,
        },
        where: 'id = ?',
        whereArgs: [historyId],
      );
      return true;
    } catch (e) {
      print('Bildirim durumu güncelleme hatası: $e');
      return false;
    }
  }

  /// Tüm bildirim geçmişini getir
  Future<List<NotificationHistoryItem>> getAllHistory() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'notification_history',
        orderBy: 'notification_time DESC',
      );
      return maps.map((map) => NotificationHistoryItem.fromMap(map)).toList();
    } catch (e) {
      print('Bildirim geçmişi getirme hatası: $e');
      return [];
    }
  }

  /// Kaçırılan bildirimleri getir
  Future<List<NotificationHistoryItem>> getMissedNotifications() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'notification_history',
        where: 'status = ?',
        whereArgs: [NotificationStatus.missed.name],
        orderBy: 'notification_time DESC',
      );
      return maps.map((map) => NotificationHistoryItem.fromMap(map)).toList();
    } catch (e) {
      print('Kaçırılan bildirimler getirme hatası: $e');
      return [];
    }
  }

  /// Belirli bir hatırlatıcının bildirim geçmişini getir
  Future<List<NotificationHistoryItem>> getHistoryByReminder(int reminderId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'notification_history',
        where: 'reminder_id = ?',
        whereArgs: [reminderId],
        orderBy: 'notification_time DESC',
      );
      return maps.map((map) => NotificationHistoryItem.fromMap(map)).toList();
    } catch (e) {
      print('Hatırlatıcı bildirim geçmişi getirme hatası: $e');
      return [];
    }
  }

  /// Tarih aralığına göre bildirim geçmişini getir
  Future<List<NotificationHistoryItem>> getHistoryByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'notification_history',
        where: 'notification_time BETWEEN ? AND ?',
        whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
        orderBy: 'notification_time DESC',
      );
      return maps.map((map) => NotificationHistoryItem.fromMap(map)).toList();
    } catch (e) {
      print('Tarih aralığı bildirim geçmişi getirme hatası: $e');
      return [];
    }
  }

  /// Duruma göre bildirim geçmişini getir
  Future<List<NotificationHistoryItem>> getHistoryByStatus(
    NotificationStatus status,
  ) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'notification_history',
        where: 'status = ?',
        whereArgs: [status.name],
        orderBy: 'notification_time DESC',
      );
      return maps.map((map) => NotificationHistoryItem.fromMap(map)).toList();
    } catch (e) {
      print('Duruma göre bildirim geçmişi getirme hatası: $e');
      return [];
    }
  }

  /// Bildirim geçmişini sil
  Future<bool> deleteHistory(int historyId) async {
    try {
      final db = await database;
      await db.delete(
        'notification_history',
        where: 'id = ?',
        whereArgs: [historyId],
      );
      return true;
    } catch (e) {
      print('Bildirim geçmişi silme hatası: $e');
      return false;
    }
  }

  /// Tüm bildirim geçmişini temizle
  Future<bool> clearAllHistory() async {
    try {
      final db = await database;
      await db.delete('notification_history');
      return true;
    } catch (e) {
      print('Tüm bildirim geçmişi temizleme hatası: $e');
      return false;
    }
  }

  /// Eski kayıtları temizle (30 günden eski)
  Future<bool> clearOldHistory({int daysToKeep = 30}) async {
    try {
      final db = await database;
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      await db.delete(
        'notification_history',
        where: 'notification_time < ?',
        whereArgs: [cutoffDate.toIso8601String()],
      );
      return true;
    } catch (e) {
      print('Eski bildirim geçmişi temizleme hatası: $e');
      return false;
    }
  }

  /// Bildirim istatistikleri
  Future<Map<String, int>> getStatistics() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> result = await db.rawQuery('''
        SELECT status, COUNT(*) as count
        FROM notification_history
        GROUP BY status
      ''');

      final Map<String, int> stats = {};
      for (final row in result) {
        stats[row['status'] as String] = row['count'] as int;
      }
      return stats;
    } catch (e) {
      print('Bildirim istatistikleri getirme hatası: $e');
      return {};
    }
  }

  /// Bugünkü bildirim sayısı
  Future<int> getTodayNotificationCount() async {
    try {
      final db = await database;
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final result = await db.rawQuery('''
        SELECT COUNT(*) as count
        FROM notification_history
        WHERE notification_time BETWEEN ? AND ?
      ''', [startOfDay.toIso8601String(), endOfDay.toIso8601String()]);

      return result.first['count'] as int? ?? 0;
    } catch (e) {
      print('Bugünkü bildirim sayısı getirme hatası: $e');
      return 0;
    }
  }

  /// Kaçırılan bildirim sayısı
  Future<int> getMissedNotificationCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT COUNT(*) as count
        FROM notification_history
        WHERE status = ?
      ''', [NotificationStatus.missed.name]);

      return result.first['count'] as int? ?? 0;
    } catch (e) {
      print('Kaçırılan bildirim sayısı getirme hatası: $e');
      return 0;
    }
  }
}


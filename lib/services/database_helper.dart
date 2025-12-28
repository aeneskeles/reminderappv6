import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/reminder.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('Web platformında sqflite desteklenmiyor. Web desteği için shared_preferences kullanılıyor.');
    }
    if (_database != null) return _database!;
    _database = await _initDB('reminders.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        dateTime TEXT NOT NULL,
        isRecurring INTEGER NOT NULL,
        category TEXT NOT NULL,
        isCompleted INTEGER NOT NULL
      )
    ''');
  }

  Future<int> createReminder(Reminder reminder) async {
    try {
      if (kIsWeb) {
        return await _createReminderWeb(reminder);
      }
      final db = await database;
      final id = await db.insert('reminders', reminder.toMap());
      print('Hatırlatıcı veritabanına eklendi, ID: $id');
      return id;
    } catch (e) {
      print('Hatırlatıcı oluşturulurken hata: $e');
      rethrow;
    }
  }

  Future<int> _createReminderWeb(Reminder reminder) async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getStringList('reminders') ?? [];
    
    // Mevcut ID'lerden en büyüğünü bul
    int maxId = 0;
    for (final json in remindersJson) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      final id = map['id'] as int? ?? 0;
      if (id > maxId) maxId = id;
    }
    
    final nextId = maxId + 1;
    final reminderWithId = reminder.copyWith(id: nextId);
    remindersJson.add(jsonEncode(reminderWithId.toMap()));
    await prefs.setStringList('reminders', remindersJson);
    print('Hatırlatıcı web\'e eklendi, ID: $nextId');
    return nextId;
  }

  Future<List<Reminder>> getAllReminders() async {
    try {
      if (kIsWeb) {
        return await _getAllRemindersWeb();
      }
      final db = await database;
      final result = await db.query('reminders', orderBy: 'dateTime ASC');
      print('Veritabanından ${result.length} hatırlatıcı alındı');
      return result.map((map) => Reminder.fromMap(map)).toList();
    } catch (e) {
      print('Hatırlatıcılar alınırken hata: $e');
      rethrow;
    }
  }

  Future<List<Reminder>> _getAllRemindersWeb() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getStringList('reminders') ?? [];
    final reminders = remindersJson
        .map((json) => Reminder.fromMap(jsonDecode(json) as Map<String, dynamic>))
        .toList();
    reminders.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    print('Web\'den ${reminders.length} hatırlatıcı alındı');
    return reminders;
  }

  Future<List<Reminder>> getActiveReminders() async {
    if (kIsWeb) {
      final all = await _getAllRemindersWeb();
      return all.where((r) => !r.isCompleted).toList();
    }
    final db = await database;
    final result = await db.query(
      'reminders',
      where: 'isCompleted = ?',
      whereArgs: [0],
      orderBy: 'dateTime ASC',
    );
    return result.map((map) => Reminder.fromMap(map)).toList();
  }

  Future<List<Reminder>> getCompletedReminders() async {
    if (kIsWeb) {
      final all = await _getAllRemindersWeb();
      final completed = all.where((r) => r.isCompleted).toList();
      completed.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return completed;
    }
    final db = await database;
    final result = await db.query(
      'reminders',
      where: 'isCompleted = ?',
      whereArgs: [1],
      orderBy: 'dateTime DESC',
    );
    return result.map((map) => Reminder.fromMap(map)).toList();
  }

  Future<List<Reminder>> searchReminders(String query) async {
    if (kIsWeb) {
      final all = await _getAllRemindersWeb();
      final lowerQuery = query.toLowerCase();
      return all.where((r) {
        return r.title.toLowerCase().contains(lowerQuery) ||
            r.description.toLowerCase().contains(lowerQuery) ||
            r.category.toLowerCase().contains(lowerQuery);
      }).toList();
    }
    final db = await database;
    final result = await db.query(
      'reminders',
      where: 'title LIKE ? OR description LIKE ? OR category LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'dateTime ASC',
    );
    return result.map((map) => Reminder.fromMap(map)).toList();
  }

  Future<List<Reminder>> getRemindersByCategory(String category) async {
    if (kIsWeb) {
      final all = await _getAllRemindersWeb();
      return all.where((r) => r.category == category).toList();
    }
    final db = await database;
    final result = await db.query(
      'reminders',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'dateTime ASC',
    );
    return result.map((map) => Reminder.fromMap(map)).toList();
  }

  Future<List<Reminder>> getRemindersByDate(DateTime date) async {
    if (kIsWeb) {
      final all = await _getAllRemindersWeb();
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      return all.where((r) {
        return r.dateTime.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
            r.dateTime.isBefore(endOfDay.add(const Duration(seconds: 1)));
      }).toList();
    }
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    final result = await db.query(
      'reminders',
      where: 'dateTime >= ? AND dateTime <= ?',
      whereArgs: [
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ],
      orderBy: 'dateTime ASC',
    );
    return result.map((map) => Reminder.fromMap(map)).toList();
  }

  Future<Reminder?> getReminder(int id) async {
    if (kIsWeb) {
      final all = await _getAllRemindersWeb();
      try {
        return all.firstWhere((r) => r.id == id);
      } catch (e) {
        return null;
      }
    }
    final db = await database;
    final result = await db.query(
      'reminders',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return Reminder.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateReminder(Reminder reminder) async {
    if (kIsWeb) {
      return await _updateReminderWeb(reminder);
    }
    final db = await database;
    return await db.update(
      'reminders',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<int> _updateReminderWeb(Reminder reminder) async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getStringList('reminders') ?? [];
    final index = remindersJson.indexWhere((json) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return map['id'] == reminder.id;
    });
    if (index != -1) {
      remindersJson[index] = jsonEncode(reminder.toMap());
      await prefs.setStringList('reminders', remindersJson);
      return 1;
    }
    return 0;
  }

  Future<int> deleteReminder(int id) async {
    if (kIsWeb) {
      return await _deleteReminderWeb(id);
    }
    final db = await database;
    return await db.delete(
      'reminders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> _deleteReminderWeb(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getStringList('reminders') ?? [];
    remindersJson.removeWhere((json) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return map['id'] == id;
    });
    await prefs.setStringList('reminders', remindersJson);
    return 1;
  }

  Future<List<String>> getAllCategories() async {
    if (kIsWeb) {
      final reminders = await _getAllRemindersWeb();
      final categories = reminders.map((r) => r.category).toSet().toList();
      categories.sort();
      return categories;
    }
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT category FROM reminders ORDER BY category',
    );
    return result.map((map) => map['category'] as String).toList();
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}


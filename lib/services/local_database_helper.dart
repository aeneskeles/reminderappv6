import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/reminder.dart';

class LocalDatabaseHelper {
  static final LocalDatabaseHelper instance = LocalDatabaseHelper._init();
  static Database? _database;

  LocalDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('reminders_local.db');
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
        server_id INTEGER,
        user_id TEXT,
        title TEXT NOT NULL,
        description TEXT,
        date_time TEXT NOT NULL,
        is_recurring INTEGER NOT NULL DEFAULT 0,
        category TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0,
        is_all_day INTEGER NOT NULL DEFAULT 0,
        recurrence_type TEXT,
        weekly_days TEXT,
        monthly_day INTEGER,
        notification_before_minutes INTEGER,
        priority TEXT,
        color_tag INTEGER,
        is_synced INTEGER NOT NULL DEFAULT 0,
        needs_sync INTEGER NOT NULL DEFAULT 1,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Index for faster queries
    await db.execute('CREATE INDEX idx_user_id ON reminders(user_id)');
    await db.execute('CREATE INDEX idx_server_id ON reminders(server_id)');
    await db.execute('CREATE INDEX idx_is_synced ON reminders(is_synced)');
    await db.execute('CREATE INDEX idx_needs_sync ON reminders(needs_sync)');
  }

  // Create reminder locally
  Future<int> createReminder(Reminder reminder, String userId) async {
    final db = await database;
    final data = {
      'server_id': reminder.id,
      'user_id': userId,
      'title': reminder.title,
      'description': reminder.description,
      'date_time': reminder.dateTime.toIso8601String(),
      'is_recurring': reminder.isRecurring ? 1 : 0,
      'category': reminder.category,
      'is_completed': reminder.isCompleted ? 1 : 0,
      'is_all_day': reminder.isAllDay ? 1 : 0,
      'recurrence_type': reminder.recurrenceType.name,
      'weekly_days': reminder.weeklyDays.isEmpty ? null : reminder.weeklyDays.join(','),
      'monthly_day': reminder.monthlyDay,
      'notification_before_minutes': reminder.notificationBeforeMinutes,
      'priority': reminder.priority.name,
      'color_tag': reminder.colorTag,
      'is_synced': 0,
      'needs_sync': 1,
      'is_deleted': 0,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    return await db.insert('reminders', data);
  }

  // Get all reminders for a user
  Future<List<Reminder>> getAllReminders(String userId) async {
    final db = await database;
    final maps = await db.query(
      'reminders',
      where: 'user_id = ? AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'date_time ASC',
    );

    return maps.map((map) => reminderFromMap(map)).toList();
  }

  // Get reminder by local ID
  Future<Reminder?> getReminder(int localId) async {
    final db = await database;
    final maps = await db.query(
      'reminders',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [localId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return reminderFromMap(maps.first);
  }

  // Get reminder by server ID
  Future<Reminder?> getReminderByServerId(int serverId, String userId) async {
    final db = await database;
    final maps = await db.query(
      'reminders',
      where: 'server_id = ? AND user_id = ? AND is_deleted = 0',
      whereArgs: [serverId, userId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return reminderFromMap(maps.first);
  }

  // Update reminder
  Future<int> updateReminder(Reminder reminder, String userId) async {
    final db = await database;
    final data = {
      'title': reminder.title,
      'description': reminder.description,
      'date_time': reminder.dateTime.toIso8601String(),
      'is_recurring': reminder.isRecurring ? 1 : 0,
      'category': reminder.category,
      'is_completed': reminder.isCompleted ? 1 : 0,
      'is_all_day': reminder.isAllDay ? 1 : 0,
      'recurrence_type': reminder.recurrenceType.name,
      'weekly_days': reminder.weeklyDays.isEmpty ? null : reminder.weeklyDays.join(','),
      'monthly_day': reminder.monthlyDay,
      'notification_before_minutes': reminder.notificationBeforeMinutes,
      'priority': reminder.priority.name,
      'color_tag': reminder.colorTag,
      'needs_sync': 1,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (reminder.id != null) {
      // Update by local ID
      return await db.update(
        'reminders',
        data,
        where: 'id = ? AND user_id = ?',
        whereArgs: [reminder.id, userId],
      );
    } else {
      return 0;
    }
  }

  // Delete reminder (soft delete)
  Future<int> deleteReminder(int localId, String userId) async {
    final db = await database;
    return await db.update(
      'reminders',
      {
        'is_deleted': 1,
        'needs_sync': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [localId, userId],
    );
  }

  // Get unsynced reminders
  Future<List<Map<String, dynamic>>> getUnsyncedReminders(String userId) async {
    final db = await database;
    return await db.query(
      'reminders',
      where: 'user_id = ? AND needs_sync = 1',
      whereArgs: [userId],
    );
  }

  // Mark reminder as synced
  Future<int> markAsSynced(int localId, int? serverId) async {
    final db = await database;
    final data = {
      'is_synced': 1,
      'needs_sync': 0,
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    if (serverId != null) {
      data['server_id'] = serverId;
    }

    return await db.update(
      'reminders',
      data,
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  // Upsert reminder from server
  Future<int> upsertFromServer(Reminder reminder, String userId) async {
    final db = await database;
    
    // Check if reminder exists by server_id
    final existing = await db.query(
      'reminders',
      where: 'server_id = ? AND user_id = ?',
      whereArgs: [reminder.id, userId],
      limit: 1,
    );

    final data = {
      'server_id': reminder.id,
      'user_id': userId,
      'title': reminder.title,
      'description': reminder.description,
      'date_time': reminder.dateTime.toIso8601String(),
      'is_recurring': reminder.isRecurring ? 1 : 0,
      'category': reminder.category,
      'is_completed': reminder.isCompleted ? 1 : 0,
      'is_all_day': reminder.isAllDay ? 1 : 0,
      'recurrence_type': reminder.recurrenceType.name,
      'weekly_days': reminder.weeklyDays.isEmpty ? null : reminder.weeklyDays.join(','),
      'monthly_day': reminder.monthlyDay,
      'notification_before_minutes': reminder.notificationBeforeMinutes,
      'priority': reminder.priority.name,
      'color_tag': reminder.colorTag,
      'is_synced': 1,
      'needs_sync': 0,
      'is_deleted': 0,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (existing.isEmpty) {
      // Insert new
      data['created_at'] = DateTime.now().toIso8601String();
      return await db.insert('reminders', data);
    } else {
      // Update existing
      return await db.update(
        'reminders',
        data,
        where: 'server_id = ? AND user_id = ?',
        whereArgs: [reminder.id, userId],
      );
    }
  }

  // Clear all local data (for logout)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('reminders');
  }

  // Clear synced data
  Future<void> clearSyncedData(String userId) async {
    final db = await database;
    await db.delete(
      'reminders',
      where: 'user_id = ? AND is_synced = 1 AND needs_sync = 0',
      whereArgs: [userId],
    );
  }

  // Convert map to Reminder
  Reminder reminderFromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      dateTime: DateTime.parse(map['date_time'] as String),
      isRecurring: (map['is_recurring'] as int) == 1,
      category: map['category'] as String? ?? 'Genel',
      isCompleted: (map['is_completed'] as int) == 1,
      isAllDay: (map['is_all_day'] as int?) == 1,
      recurrenceType: RecurrenceType.values.firstWhere(
        (e) => e.name == (map['recurrence_type'] as String? ?? 'none'),
        orElse: () => RecurrenceType.none,
      ),
      weeklyDays: (map['weekly_days'] as String? ?? '')
          .split(',')
          .where((e) => e.isNotEmpty)
          .map((e) => int.parse(e))
          .toList(),
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


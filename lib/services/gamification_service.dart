import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/achievement.dart';
import '../models/reminder.dart';
import 'database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GamificationService {
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  static Database? _database;
  final _dbHelper = DatabaseHelper.instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'gamification.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Achievements tablosu
        await db.execute('''
          CREATE TABLE achievements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL UNIQUE,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            emoji TEXT NOT NULL,
            points INTEGER NOT NULL,
            unlocked_at TEXT,
            is_unlocked INTEGER NOT NULL DEFAULT 0,
            progress INTEGER NOT NULL DEFAULT 0,
            target INTEGER NOT NULL
          )
        ''');

        // User stats tablosu
        await db.execute('''
          CREATE TABLE user_stats (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            total_points INTEGER NOT NULL DEFAULT 0,
            current_streak INTEGER NOT NULL DEFAULT 0,
            longest_streak INTEGER NOT NULL DEFAULT 0,
            on_time_count INTEGER NOT NULL DEFAULT 0,
            early_bird_count INTEGER NOT NULL DEFAULT 0,
            night_owl_count INTEGER NOT NULL DEFAULT 0,
            weekend_count INTEGER NOT NULL DEFAULT 0,
            last_completion_date TEXT,
            total_completed INTEGER NOT NULL DEFAULT 0
          )
        ''');

        // Completion history tablosu
        await db.execute('''
          CREATE TABLE completion_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            reminder_id INTEGER NOT NULL,
            completed_at TEXT NOT NULL,
            was_on_time INTEGER NOT NULL DEFAULT 0,
            points_earned INTEGER NOT NULL DEFAULT 0
          )
        ''');

        // İlk stats kaydını oluştur
        await db.insert('user_stats', {
          'total_points': 0,
          'current_streak': 0,
          'longest_streak': 0,
          'on_time_count': 0,
          'early_bird_count': 0,
          'night_owl_count': 0,
          'weekend_count': 0,
          'total_completed': 0,
        });

        // Tüm rozetleri ekle
        final achievements = AchievementDefinitions.getAllAchievements();
        for (final achievement in achievements) {
          await db.insert('achievements', achievement.toMap());
        }
      },
    );
  }

  /// Hatırlatıcı tamamlandığında çağrılır
  Future<Map<String, dynamic>> onReminderCompleted(Reminder reminder) async {
    final db = await database;
    final now = DateTime.now();
    final wasOnTime = _isCompletedOnTime(reminder, now);
    
    // Puan hesapla
    int pointsEarned = 0;
    if (wasOnTime) {
      pointsEarned = _calculatePoints(reminder);
    }

    // Completion history'ye ekle
    await db.insert('completion_history', {
      'reminder_id': reminder.id,
      'completed_at': now.toIso8601String(),
      'was_on_time': wasOnTime ? 1 : 0,
      'points_earned': pointsEarned,
    });

    // Stats güncelle
    await _updateStats(wasOnTime, now);

    // Rozetleri kontrol et
    final unlockedAchievements = await _checkAchievements();

    return {
      'points_earned': pointsEarned,
      'was_on_time': wasOnTime,
      'unlocked_achievements': unlockedAchievements,
    };
  }

  /// Hatırlatıcının zamanında tamamlanıp tamamlanmadığını kontrol et
  bool _isCompletedOnTime(Reminder reminder, DateTime completedAt) {
    // Hatırlatıcı zamanından sonraki 1 saat içinde tamamlanmışsa zamanında sayılır
    final deadline = reminder.dateTime.add(const Duration(hours: 1));
    return completedAt.isBefore(deadline);
  }

  /// Puan hesapla
  int _calculatePoints(Reminder reminder) {
    int basePoints = 10;

    // Önceliğe göre bonus
    switch (reminder.priority) {
      case Priority.high:
        basePoints += 5;
        break;
      case Priority.normal:
        basePoints += 2;
        break;
      case Priority.low:
        break;
    }

    // Tekrarlayan hatırlatıcı bonusu
    if (reminder.isRecurring) {
      basePoints += 3;
    }

    return basePoints;
  }

  /// İstatistikleri güncelle
  Future<void> _updateStats(bool wasOnTime, DateTime completedAt) async {
    final db = await database;
    final stats = await getUserStats();

    int newPoints = stats['total_points'] as int;
    int currentStreak = stats['current_streak'] as int;
    int longestStreak = stats['longest_streak'] as int;
    int onTimeCount = stats['on_time_count'] as int;
    int earlyBirdCount = stats['early_bird_count'] as int;
    int nightOwlCount = stats['night_owl_count'] as int;
    int weekendCount = stats['weekend_count'] as int;
    int totalCompleted = stats['total_completed'] as int;

    // Toplam tamamlanan
    totalCompleted++;

    // Zamanında tamamlama
    if (wasOnTime) {
      onTimeCount++;
      newPoints += 10;

      // Streak kontrolü
      final lastCompletionDate = stats['last_completion_date'] as String?;
      if (lastCompletionDate != null) {
        final lastDate = DateTime.parse(lastCompletionDate);
        final daysDiff = completedAt.difference(lastDate).inDays;
        
        if (daysDiff == 1) {
          // Ardışık gün
          currentStreak++;
          if (currentStreak > longestStreak) {
            longestStreak = currentStreak;
          }
        } else if (daysDiff > 1) {
          // Streak kırıldı
          currentStreak = 1;
        }
      } else {
        currentStreak = 1;
      }
    }

    // Saat bazlı rozetler
    final hour = completedAt.hour;
    if (hour >= 6 && hour < 9) {
      earlyBirdCount++;
    } else if (hour >= 21 && hour < 24) {
      nightOwlCount++;
    }

    // Hafta sonu
    if (completedAt.weekday == DateTime.saturday || completedAt.weekday == DateTime.sunday) {
      weekendCount++;
    }

    // Stats'ı güncelle
    await db.update(
      'user_stats',
      {
        'total_points': newPoints,
        'current_streak': currentStreak,
        'longest_streak': longestStreak,
        'on_time_count': onTimeCount,
        'early_bird_count': earlyBirdCount,
        'night_owl_count': nightOwlCount,
        'weekend_count': weekendCount,
        'last_completion_date': completedAt.toIso8601String(),
        'total_completed': totalCompleted,
      },
      where: 'id = 1',
    );
  }

  /// Rozetleri kontrol et ve kilidi aç
  Future<List<Achievement>> _checkAchievements() async {
    final db = await database;
    final stats = await getUserStats();
    final unlockedAchievements = <Achievement>[];

    final achievements = await getAllAchievements();

    for (final achievement in achievements) {
      if (achievement.isUnlocked) continue;

      bool shouldUnlock = false;
      int progress = 0;

      switch (achievement.type) {
        case AchievementType.firstReminder:
          progress = stats['total_completed'] as int;
          shouldUnlock = progress >= 1;
          break;

        case AchievementType.streak3:
          progress = stats['current_streak'] as int;
          shouldUnlock = progress >= 3;
          break;

        case AchievementType.streak7:
          progress = stats['current_streak'] as int;
          shouldUnlock = progress >= 7;
          break;

        case AchievementType.streak30:
          progress = stats['current_streak'] as int;
          shouldUnlock = progress >= 30;
          break;

        case AchievementType.onTime10:
          progress = stats['on_time_count'] as int;
          shouldUnlock = progress >= 10;
          break;

        case AchievementType.onTime50:
          progress = stats['on_time_count'] as int;
          shouldUnlock = progress >= 50;
          break;

        case AchievementType.onTime100:
          progress = stats['on_time_count'] as int;
          shouldUnlock = progress >= 100;
          break;

        case AchievementType.earlyBird:
          progress = stats['early_bird_count'] as int;
          shouldUnlock = progress >= 10;
          break;

        case AchievementType.nightOwl:
          progress = stats['night_owl_count'] as int;
          shouldUnlock = progress >= 10;
          break;

        case AchievementType.productive:
          progress = await _getTodayCompletedCount();
          shouldUnlock = progress >= 10;
          break;

        case AchievementType.weekendWarrior:
          progress = stats['weekend_count'] as int;
          shouldUnlock = progress >= 20;
          break;

        case AchievementType.perfectWeek:
          progress = await _getWeekCompletedCount();
          shouldUnlock = progress >= 3;
          break;

        case AchievementType.categoryMaster:
          progress = await _getMaxCategoryCount();
          shouldUnlock = progress >= 50;
          break;

        case AchievementType.sharer:
          progress = await _getSharedRemindersCount();
          shouldUnlock = progress >= 1;
          break;

        case AchievementType.organizer:
          progress = await _getCategoriesCount();
          shouldUnlock = progress >= 5;
          break;
      }

      // Progress güncelle
      await db.update(
        'achievements',
        {'progress': progress},
        where: 'type = ?',
        whereArgs: [achievement.type.name],
      );

      // Rozet kilidi aç
      if (shouldUnlock) {
        await db.update(
          'achievements',
          {
            'is_unlocked': 1,
            'unlocked_at': DateTime.now().toIso8601String(),
          },
          where: 'type = ?',
          whereArgs: [achievement.type.name],
        );

        // Puan ekle
        final currentPoints = stats['total_points'] as int;
        await db.update(
          'user_stats',
          {'total_points': currentPoints + achievement.points},
          where: 'id = 1',
        );

        unlockedAchievements.add(achievement.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        ));
      }
    }

    return unlockedAchievements;
  }

  /// Bugün tamamlanan hatırlatıcı sayısı
  Future<int> _getTodayCompletedCount() async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM completion_history
      WHERE completed_at >= ? AND completed_at < ?
    ''', [startOfDay.toIso8601String(), endOfDay.toIso8601String()]);

    return result.first['count'] as int? ?? 0;
  }

  /// Bu haftaki tamamlanan hatırlatıcı sayısı
  Future<int> _getWeekCompletedCount() async {
    final db = await database;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM completion_history
      WHERE completed_at >= ? AND completed_at < ?
    ''', [weekStart.toIso8601String(), weekEnd.toIso8601String()]);

    return result.first['count'] as int? ?? 0;
  }

  /// En çok hatırlatıcı olan kategori sayısı
  Future<int> _getMaxCategoryCount() async {
    final reminders = await _dbHelper.getReminders();
    final categoryCount = <String, int>{};

    for (final reminder in reminders.where((r) => r.isCompleted)) {
      categoryCount[reminder.category] = (categoryCount[reminder.category] ?? 0) + 1;
    }

    return categoryCount.isEmpty ? 0 : categoryCount.values.reduce((a, b) => a > b ? a : b);
  }

  /// Paylaşılan hatırlatıcı sayısı
  Future<int> _getSharedRemindersCount() async {
    final reminders = await _dbHelper.getSharedReminders();
    return reminders.length;
  }

  /// Kategori sayısı
  Future<int> _getCategoriesCount() async {
    final categories = await _dbHelper.getAllCategories();
    return categories.length;
  }

  /// Kullanıcı istatistiklerini getir
  Future<Map<String, dynamic>> getUserStats() async {
    final db = await database;
    final result = await db.query('user_stats', where: 'id = 1');
    return result.first;
  }

  /// Tüm rozetleri getir
  Future<List<Achievement>> getAllAchievements() async {
    final db = await database;
    final maps = await db.query('achievements', orderBy: 'points ASC');
    return maps.map((map) => Achievement.fromMap(map)).toList();
  }

  /// Kilidi açılmış rozetleri getir
  Future<List<Achievement>> getUnlockedAchievements() async {
    final db = await database;
    final maps = await db.query(
      'achievements',
      where: 'is_unlocked = 1',
      orderBy: 'unlocked_at DESC',
    );
    return maps.map((map) => Achievement.fromMap(map)).toList();
  }

  /// Toplam puan
  Future<int> getTotalPoints() async {
    final stats = await getUserStats();
    return stats['total_points'] as int;
  }

  /// Mevcut streak
  Future<int> getCurrentStreak() async {
    final stats = await getUserStats();
    return stats['current_streak'] as int;
  }

  /// En uzun streak
  Future<int> getLongestStreak() async {
    final stats = await getUserStats();
    return stats['longest_streak'] as int;
  }

  /// Seviye hesapla (her 100 puan = 1 seviye)
  Future<int> getLevel() async {
    final points = await getTotalPoints();
    return (points / 100).floor() + 1;
  }

  /// Sonraki seviye için gereken puan
  Future<int> getPointsToNextLevel() async {
    final points = await getTotalPoints();
    final currentLevel = (points / 100).floor() + 1;
    final nextLevelPoints = currentLevel * 100;
    return nextLevelPoints - points;
  }

  /// Veritabanını temizle
  Future<void> clearData() async {
    final db = await database;
    await db.delete('completion_history');
    await db.update(
      'user_stats',
      {
        'total_points': 0,
        'current_streak': 0,
        'longest_streak': 0,
        'on_time_count': 0,
        'early_bird_count': 0,
        'night_owl_count': 0,
        'weekend_count': 0,
        'last_completion_date': null,
        'total_completed': 0,
      },
      where: 'id = 1',
    );
    await db.update(
      'achievements',
      {
        'is_unlocked': 0,
        'unlocked_at': null,
        'progress': 0,
      },
    );
  }
}


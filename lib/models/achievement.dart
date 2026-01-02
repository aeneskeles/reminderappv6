// Rozet türleri
enum AchievementType {
  firstReminder,      // İlk hatırlatıcı
  streak3,            // 3 gün üst üste
  streak7,            // 7 gün üst üste (Disiplinli)
  streak30,           // 30 gün üst üste (Efsane)
  onTime10,           // 10 hatırlatıcıyı zamanında tamamla
  onTime50,           // 50 hatırlatıcıyı zamanında tamamla
  onTime100,          // 100 hatırlatıcıyı zamanında tamamla
  earlyBird,          // Sabah 6-9 arası 10 hatırlatıcı tamamla
  nightOwl,           // Gece 21-24 arası 10 hatırlatıcı tamamla
  productive,         // Bir günde 10 hatırlatıcı tamamla
  weekendWarrior,     // Hafta sonu 20 hatırlatıcı tamamla
  perfectWeek,        // Bir hafta boyunca tüm hatırlatıcıları tamamla
  categoryMaster,     // Bir kategoride 50 hatırlatıcı tamamla
  sharer,             // İlk hatırlatıcıyı paylaş
  organizer,          // 5 farklı kategori oluştur
}

class Achievement {
  final AchievementType type;
  final String title;
  final String description;
  final String emoji;
  final int points;
  final DateTime? unlockedAt;
  final bool isUnlocked;
  final int progress;
  final int target;

  Achievement({
    required this.type,
    required this.title,
    required this.description,
    required this.emoji,
    required this.points,
    this.unlockedAt,
    this.isUnlocked = false,
    this.progress = 0,
    required this.target,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'title': title,
      'description': description,
      'emoji': emoji,
      'points': points,
      'unlocked_at': unlockedAt?.toIso8601String(),
      'is_unlocked': isUnlocked ? 1 : 0,
      'progress': progress,
      'target': target,
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      type: AchievementType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AchievementType.firstReminder,
      ),
      title: map['title'] as String,
      description: map['description'] as String,
      emoji: map['emoji'] as String,
      points: map['points'] as int,
      unlockedAt: map['unlocked_at'] != null
          ? DateTime.parse(map['unlocked_at'] as String)
          : null,
      isUnlocked: (map['is_unlocked'] as int? ?? 0) == 1,
      progress: map['progress'] as int? ?? 0,
      target: map['target'] as int,
    );
  }

  Achievement copyWith({
    AchievementType? type,
    String? title,
    String? description,
    String? emoji,
    int? points,
    DateTime? unlockedAt,
    bool? isUnlocked,
    int? progress,
    int? target,
  }) {
    return Achievement(
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      points: points ?? this.points,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      progress: progress ?? this.progress,
      target: target ?? this.target,
    );
  }

  double get progressPercentage => target > 0 ? (progress / target) * 100 : 0;
}

// Tüm rozetlerin listesi
class AchievementDefinitions {
  static List<Achievement> getAllAchievements() {
    return [
      Achievement(
        type: AchievementType.firstReminder,
        title: 'İlk Adım',
        description: 'İlk hatırlatıcını oluştur',
        emoji: '🎯',
        points: 10,
        target: 1,
      ),
      Achievement(
        type: AchievementType.streak3,
        title: 'Başlangıç',
        description: '3 gün üst üste hatırlatıcı tamamla',
        emoji: '🔥',
        points: 30,
        target: 3,
      ),
      Achievement(
        type: AchievementType.streak7,
        title: 'Disiplinli',
        description: '7 gün üst üste hatırlatıcı tamamla',
        emoji: '🎖️',
        points: 100,
        target: 7,
      ),
      Achievement(
        type: AchievementType.streak30,
        title: 'Efsane',
        description: '30 gün üst üste hatırlatıcı tamamla',
        emoji: '👑',
        points: 500,
        target: 30,
      ),
      Achievement(
        type: AchievementType.onTime10,
        title: 'Dakik',
        description: '10 hatırlatıcıyı zamanında tamamla',
        emoji: '⏰',
        points: 50,
        target: 10,
      ),
      Achievement(
        type: AchievementType.onTime50,
        title: 'Zamanın Efendisi',
        description: '50 hatırlatıcıyı zamanında tamamla',
        emoji: '⌚',
        points: 200,
        target: 50,
      ),
      Achievement(
        type: AchievementType.onTime100,
        title: 'Zaman Yöneticisi',
        description: '100 hatırlatıcıyı zamanında tamamla',
        emoji: '🕐',
        points: 500,
        target: 100,
      ),
      Achievement(
        type: AchievementType.earlyBird,
        title: 'Erken Kuş',
        description: 'Sabah 6-9 arası 10 hatırlatıcı tamamla',
        emoji: '🌅',
        points: 100,
        target: 10,
      ),
      Achievement(
        type: AchievementType.nightOwl,
        title: 'Gece Kuşu',
        description: 'Gece 21-24 arası 10 hatırlatıcı tamamla',
        emoji: '🦉',
        points: 100,
        target: 10,
      ),
      Achievement(
        type: AchievementType.productive,
        title: 'Üretken',
        description: 'Bir günde 10 hatırlatıcı tamamla',
        emoji: '💪',
        points: 150,
        target: 10,
      ),
      Achievement(
        type: AchievementType.weekendWarrior,
        title: 'Hafta Sonu Savaşçısı',
        description: 'Hafta sonu 20 hatırlatıcı tamamla',
        emoji: '⚔️',
        points: 200,
        target: 20,
      ),
      Achievement(
        type: AchievementType.perfectWeek,
        title: 'Mükemmel Hafta',
        description: 'Bir hafta içinde en az 3 hatırlatıcı tamamla',
        emoji: '✨',
        points: 300,
        target: 3,
      ),
      Achievement(
        type: AchievementType.categoryMaster,
        title: 'Kategori Ustası',
        description: 'Bir kategoride 50 hatırlatıcı tamamla',
        emoji: '🏆',
        points: 250,
        target: 50,
      ),
      Achievement(
        type: AchievementType.sharer,
        title: 'Paylaşımcı',
        description: 'İlk hatırlatıcını paylaş',
        emoji: '🤝',
        points: 50,
        target: 1,
      ),
      Achievement(
        type: AchievementType.organizer,
        title: 'Organizatör',
        description: '5 farklı kategori oluştur',
        emoji: '📋',
        points: 100,
        target: 5,
      ),
    ];
  }
}


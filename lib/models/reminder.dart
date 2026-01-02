enum RecurrenceType { none, hourly, daily, weekly, monthly, yearly }
enum Priority { low, normal, high }

class Reminder {
  final int? id;
  final String title;
  final String description;
  final DateTime dateTime;
  final bool isRecurring;
  final String category;
  final bool isCompleted;
  final bool isAllDay;
  final RecurrenceType recurrenceType;
  final List<int> weeklyDays; // 1-7 (Monday-Sunday)
  final int? monthlyDay; // 1-31
  final int notificationBeforeMinutes; // Bildirim kaç dakika önce
  final Priority priority;
  final int colorTag; // Renk etiketi (0-7)
  final bool isFavorite; // Favori hatırlatıcı
  final List<String> attachments; // Dosya/görsel yolları
  final String? sharedWith; // Paylaşılan kullanıcı ID'leri (virgülle ayrılmış)
  final bool isShared; // Paylaşılan hatırlatıcı mı
  final String? createdBy; // Oluşturan kullanıcı ID
  final DateTime? createdAt; // Oluşturulma zamanı
  final DateTime? updatedAt; // Güncellenme zamanı

  Reminder({
    this.id,
    required this.title,
    this.description = '',
    required this.dateTime,
    this.isRecurring = false,
    this.category = 'Genel',
    this.isCompleted = false,
    this.isAllDay = false,
    this.recurrenceType = RecurrenceType.none,
    this.weeklyDays = const [],
    this.monthlyDay,
    this.notificationBeforeMinutes = 0,
    this.priority = Priority.normal,
    this.colorTag = 0,
    this.isFavorite = false,
    this.attachments = const [],
    this.sharedWith,
    this.isShared = false,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'isRecurring': isRecurring ? 1 : 0,
      'category': category,
      'isCompleted': isCompleted ? 1 : 0,
      'isAllDay': isAllDay ? 1 : 0,
      'recurrenceType': recurrenceType.name,
      'weeklyDays': weeklyDays.join(','),
      'monthlyDay': monthlyDay,
      'notificationBeforeMinutes': notificationBeforeMinutes,
      'priority': priority.name,
      'colorTag': colorTag,
      'isFavorite': isFavorite ? 1 : 0,
      'attachments': attachments.join('|'),
      'sharedWith': sharedWith,
      'isShared': isShared ? 1 : 0,
      'createdBy': createdBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      dateTime: DateTime.parse(map['dateTime'] as String),
      isRecurring: (map['isRecurring'] as int? ?? 0) == 1,
      category: map['category'] as String? ?? 'Genel',
      isCompleted: (map['isCompleted'] as int? ?? 0) == 1,
      isAllDay: (map['isAllDay'] as int? ?? 0) == 1,
      recurrenceType: RecurrenceType.values.firstWhere(
        (e) => e.name == (map['recurrenceType'] as String? ?? 'none'),
        orElse: () => RecurrenceType.none,
      ),
      weeklyDays: (map['weeklyDays'] as String? ?? '').split(',').where((e) => e.isNotEmpty).map((e) => int.parse(e)).toList(),
      monthlyDay: map['monthlyDay'] as int?,
      notificationBeforeMinutes: map['notificationBeforeMinutes'] as int? ?? 0,
      priority: Priority.values.firstWhere(
        (e) => e.name == (map['priority'] as String? ?? 'normal'),
        orElse: () => Priority.normal,
      ),
      colorTag: map['colorTag'] as int? ?? 0,
      isFavorite: (map['isFavorite'] as int? ?? 0) == 1,
      attachments: (map['attachments'] as String? ?? '').split('|').where((e) => e.isNotEmpty).toList(),
      sharedWith: map['sharedWith'] as String?,
      isShared: (map['isShared'] as int? ?? 0) == 1,
      createdBy: map['createdBy'] as String?,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : null,
    );
  }

  Reminder copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dateTime,
    bool? isRecurring,
    String? category,
    bool? isCompleted,
    bool? isAllDay,
    RecurrenceType? recurrenceType,
    List<int>? weeklyDays,
    int? monthlyDay,
    int? notificationBeforeMinutes,
    Priority? priority,
    int? colorTag,
    bool? isFavorite,
    List<String>? attachments,
    String? sharedWith,
    bool? isShared,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      isRecurring: isRecurring ?? this.isRecurring,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      isAllDay: isAllDay ?? this.isAllDay,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      weeklyDays: weeklyDays ?? this.weeklyDays,
      monthlyDay: monthlyDay ?? this.monthlyDay,
      notificationBeforeMinutes: notificationBeforeMinutes ?? this.notificationBeforeMinutes,
      priority: priority ?? this.priority,
      colorTag: colorTag ?? this.colorTag,
      isFavorite: isFavorite ?? this.isFavorite,
      attachments: attachments ?? this.attachments,
      sharedWith: sharedWith ?? this.sharedWith,
      isShared: isShared ?? this.isShared,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}


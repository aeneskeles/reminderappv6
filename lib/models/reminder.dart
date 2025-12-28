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
    );
  }
}


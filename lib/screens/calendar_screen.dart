import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/reminder.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';
import 'add_edit_reminder_screen.dart';
import 'reminder_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService.instance;
  
  List<Reminder> _reminders = [];
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    try {
      final reminders = await _dbHelper.getAllReminders();
      setState(() {
        _reminders = reminders;
      });
    } catch (e) {
      print('Hatırlatıcılar yüklenirken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veriler yüklenirken hata oluştu: $e')),
        );
      }
    }
  }

  // Her gün için hatırlatıcı sayısını hesapla
  Map<DateTime, int> _getRemindersCount() {
    Map<DateTime, int> remindersCount = {};
    for (var reminder in _reminders) {
      final date = DateTime(reminder.dateTime.year, reminder.dateTime.month, reminder.dateTime.day);
      remindersCount[date] = (remindersCount[date] ?? 0) + 1;
    }
    return remindersCount;
  }

  // Seçilen güne ait hatırlatıcıları getir
  List<Reminder> _getRemindersForDay(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = DateTime(day.year, day.month, day.day, 23, 59, 59);
    
    return _reminders.where((r) {
      final reminderDate = DateTime(r.dateTime.year, r.dateTime.month, r.dateTime.day);
      return reminderDate.isAtSameMomentAs(dayStart) ||
          (reminderDate.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
           reminderDate.isBefore(dayEnd.add(const Duration(seconds: 1))));
    }).toList();
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'Genel': Colors.blue,
      'Okul': Colors.green,
      'İş': Colors.orange,
      'Sağlık': Colors.red,
    };
    return colors[category] ?? Colors.grey;
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.low:
        return Colors.green;
      case Priority.normal:
        return Colors.orange;
      case Priority.high:
        return Colors.red;
    }
  }

  IconData _getPriorityIcon(Priority priority) {
    switch (priority) {
      case Priority.low:
        return Icons.arrow_downward;
      case Priority.normal:
        return Icons.remove;
      case Priority.high:
        return Icons.arrow_upward;
    }
  }

  Color _getColorTag(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.amber,
    ];
    return colors[index % colors.length];
  }

  Widget _buildReminderCard(Reminder reminder) {
    final dateFormat = reminder.isAllDay 
        ? DateFormat('dd MMM yyyy')
        : DateFormat('dd MMM yyyy, HH:mm');
    final categoryColor = _getCategoryColor(reminder.category);
    final colorTag = _getColorTag(reminder.colorTag);
    final priorityColor = _getPriorityColor(reminder.priority);
    final priorityIcon = _getPriorityIcon(reminder.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Tıklanabilir alan (detay sayfası için)
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReminderDetailScreen(reminder: reminder),
                  ),
                ).then((_) {
                  _loadReminders();
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Renk etiketi ve öncelik ikonu
                    Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorTag,
                            border: Border.all(
                              color: categoryColor,
                              width: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          priorityIcon,
                          size: 16,
                          color: priorityColor,
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Title and date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reminder.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                              decoration: reminder.isCompleted 
                                  ? TextDecoration.lineThrough 
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateFormat.format(reminder.dateTime),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        reminder.category,
                        style: TextStyle(
                          color: categoryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Three dots menu
          PopupMenuButton(
            icon: Icon(Icons.more_vert, color: Colors.grey[600]),
            padding: EdgeInsets.zero,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'complete',
                child: Row(
                  children: [
                    Icon(
                      reminder.isCompleted ? Icons.undo : Icons.check,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(reminder.isCompleted ? 'Tamamlanmadı olarak işaretle' : 'Tamamlandı olarak işaretle'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Düzenle'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Sil', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'complete') {
                final updated = reminder.copyWith(isCompleted: !reminder.isCompleted);
                await _dbHelper.updateReminder(updated);
                await _notificationService.updateNotification(updated);
                _loadReminders();
              } else if (value == 'edit') {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEditReminderScreen(reminder: reminder),
                  ),
                );
                if (result == true) {
                  _loadReminders();
                }
              } else if (value == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Hatırlatıcıyı Sil'),
                    content: const Text('Bu hatırlatıcıyı silmek istediğinize emin misiniz?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('İptal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Sil'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _dbHelper.deleteReminder(reminder.id!);
                  await _notificationService.cancelNotification(reminder.id!);
                  _loadReminders();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Hatırlatıcı silindi')),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remindersCount = _getRemindersCount();
    final dayReminders = _getRemindersForDay(_selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Takvim'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Takvim
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TableCalendar<dynamic>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: _calendarFormat,
                startingDayOfWeek: StartingDayOfWeek.monday,
                locale: 'tr_TR',
                headerStyle: const HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonShowsNext: false,
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  todayDecoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                eventLoader: (day) {
                  final date = DateTime(day.year, day.month, day.day);
                  final count = remindersCount[date] ?? 0;
                  return count > 0 ? List.generate(count > 3 ? 3 : count, (index) => index) : [];
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                },
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    final dateKey = DateTime(date.year, date.month, date.day);
                    final count = remindersCount[dateKey] ?? 0;
                    if (count == 0) return const SizedBox.shrink();
                    
                    return Positioned(
                      bottom: 1,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          // Seçilen güne ait hatırlatıcılar
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            DateFormat('d MMMM yyyy', 'tr_TR').format(_selectedDay),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        Text(
                          '${dayReminders.length} hatırlatıcı',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: dayReminders.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.event_busy,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Bu güne ait hatırlatıcı yok',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: dayReminders.length,
                            itemBuilder: (context, index) {
                              final reminder = dayReminders[index];
                              return _buildReminderCard(reminder);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


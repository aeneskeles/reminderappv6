import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../models/reminder.dart';
import '../services/theme_service.dart';
import 'add_edit_reminder_screen.dart';

class ReminderDetailScreen extends StatelessWidget {
  final Reminder reminder;

  const ReminderDetailScreen({super.key, required this.reminder});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Color>(
      future: ThemeService.instance.getThemeColor(),
      builder: (context, snapshot) {
        final themeColor = snapshot.data ?? ThemeService.instance.defaultColor;
        final gradientColors = ThemeService.instance.getGradientColors(themeColor);

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // AppBar
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            'Hatırlatıcı Detayı',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddEditReminderScreen(reminder: reminder),
                              ),
                            ).then((_) {
                              Navigator.pop(context, true);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Başlık
                          _buildGlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        reminder.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    // Tamamlandı durumu
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: reminder.isCompleted
                                            ? Colors.green.withOpacity(0.3)
                                            : Colors.orange.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        reminder.isCompleted ? 'Tamamlandı' : 'Beklemede',
                                        style: TextStyle(
                                          color: reminder.isCompleted ? Colors.green[100] : Colors.orange[100],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (reminder.description.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    reminder.description,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Tarih ve Saat
                          _buildGlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, color: Colors.white.withOpacity(0.7), size: 20),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Tarih ve Saat',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  reminder.isAllDay
                                      ? DateFormat('dd MMM yyyy').format(reminder.dateTime)
                                      : DateFormat('dd MMM yyyy, HH:mm').format(reminder.dateTime),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                  ),
                                ),
                                if (reminder.isAllDay) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tam Gün',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Bildirim Zamanı
                          if (reminder.notificationBeforeMinutes > 0)
                            _buildGlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.notifications, color: Colors.white.withOpacity(0.7), size: 20),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Bildirim Zamanı',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _getNotificationTimeText(reminder.notificationBeforeMinutes),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (reminder.notificationBeforeMinutes > 0) const SizedBox(height: 16),
                          // Tekrarlama Bilgisi
                          if (reminder.isRecurring && reminder.recurrenceType != RecurrenceType.none)
                            _buildGlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.repeat, color: Colors.white.withOpacity(0.7), size: 20),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Tekrarlama',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _getRecurrenceText(reminder),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (reminder.isRecurring && reminder.recurrenceType != RecurrenceType.none)
                            const SizedBox(height: 16),
                          // Öncelik
                          _buildGlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(_getPriorityIcon(reminder.priority), color: Colors.white.withOpacity(0.7), size: 20),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Öncelik',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _getPriorityColor(reminder.priority),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _getPriorityText(reminder.priority),
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Kategori ve Renk Etiketi
                          _buildGlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.category, color: Colors.white.withOpacity(0.7), size: 20),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Kategori',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    // Renk etiketi
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _getColorTag(reminder.colorTag),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Kategori
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        reminder.category,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  String _getNotificationTimeText(int minutes) {
    if (minutes == 0) return 'Bildirim yok';
    if (minutes < 60) return '$minutes dakika önce';
    if (minutes < 1440) {
      final hours = minutes ~/ 60;
      return '$hours saat önce';
    }
    final days = minutes ~/ 1440;
    return '$days gün önce';
  }

  String _getRecurrenceText(Reminder reminder) {
    switch (reminder.recurrenceType) {
      case RecurrenceType.hourly:
        return 'Her Saat';
      case RecurrenceType.daily:
        return 'Her Gün';
      case RecurrenceType.weekly:
        if (reminder.weeklyDays.isEmpty) {
          return 'Haftalık';
        }
        final days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
        final selectedDays = reminder.weeklyDays.map((d) => days[d - 1]).join(', ');
        return 'Haftalık ($selectedDays)';
      case RecurrenceType.monthly:
        if (reminder.monthlyDay != null) {
          return 'Aylık (Ayın ${reminder.monthlyDay}. günü)';
        }
        return 'Aylık';
      case RecurrenceType.yearly:
        return 'Yıllık';
      default:
        return 'Tek seferlik';
    }
  }

  String _getPriorityText(Priority priority) {
    switch (priority) {
      case Priority.low:
        return 'Düşük';
      case Priority.normal:
        return 'Normal';
      case Priority.high:
        return 'Yüksek';
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
}


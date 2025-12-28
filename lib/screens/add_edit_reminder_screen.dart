import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';
import '../services/theme_service.dart';
import 'dart:ui';

class AddEditReminderScreen extends StatefulWidget {
  final Reminder? reminder;

  const AddEditReminderScreen({super.key, this.reminder});

  @override
  State<AddEditReminderScreen> createState() => _AddEditReminderScreenState();
}

class _AddEditReminderScreenState extends State<AddEditReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dbHelper = DatabaseHelper.instance;
  final _notificationService = NotificationService.instance;

  DateTime _selectedDateTime = DateTime.now();
  bool _isAllDay = false;
  bool _isRecurring = false;
  RecurrenceType _recurrenceType = RecurrenceType.none;
  List<int> _selectedWeeklyDays = [];
  int? _selectedMonthlyDay;
  int _notificationBeforeMinutes = 0;
  Priority _priority = Priority.normal;
  int _colorTag = 0;
  String _selectedCategory = 'Genel';
  List<String> _categories = ['Genel', 'Okul', 'İş', 'Sağlık', 'Kişisel', 'Alışveriş', 'Spor'];

  // Renk etiketleri
  final List<Color> _colorTags = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.amber,
  ];

  // Haftanın günleri
  final List<String> _weekDays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  @override
  void initState() {
    super.initState();
    if (widget.reminder != null) {
      _titleController.text = widget.reminder!.title;
      _descriptionController.text = widget.reminder!.description;
      _selectedDateTime = widget.reminder!.dateTime;
      _isAllDay = widget.reminder!.isAllDay;
      _isRecurring = widget.reminder!.isRecurring;
      _recurrenceType = widget.reminder!.recurrenceType;
      _selectedWeeklyDays = List.from(widget.reminder!.weeklyDays);
      _selectedMonthlyDay = widget.reminder!.monthlyDay;
      _notificationBeforeMinutes = widget.reminder!.notificationBeforeMinutes;
      _priority = widget.reminder!.priority;
      _colorTag = widget.reminder!.colorTag;
      _selectedCategory = widget.reminder!.category;
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await _dbHelper.getAllCategories();
    setState(() {
      _categories = ['Genel', 'Okul', 'İş', 'Sağlık', 'Kişisel', 'Alışveriş', 'Spor'];
      for (final cat in categories) {
        if (!_categories.contains(cat)) {
          _categories.add(cat);
        }
      }
    });
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (date != null) {
      if (_isAllDay) {
        setState(() {
          _selectedDateTime = DateTime(date.year, date.month, date.day);
        });
      } else {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
        );

        if (time != null) {
          setState(() {
            _selectedDateTime = DateTime(
              date.year,
              date.month,
              date.day,
              time.hour,
              time.minute,
            );
          });
        }
      }
    }
  }

  Future<void> _saveReminder() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Recurrence type'ı isRecurring'e göre ayarla
        final recurrenceType = _isRecurring ? _recurrenceType : RecurrenceType.none;
        
        final reminder = Reminder(
          id: widget.reminder?.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          dateTime: _selectedDateTime,
          isRecurring: _isRecurring,
          category: _selectedCategory,
          isCompleted: widget.reminder?.isCompleted ?? false,
          isAllDay: _isAllDay,
          recurrenceType: recurrenceType,
          weeklyDays: _selectedWeeklyDays,
          monthlyDay: _selectedMonthlyDay,
          notificationBeforeMinutes: _notificationBeforeMinutes,
          priority: _priority,
          colorTag: _colorTag,
        );

        if (widget.reminder == null) {
          final id = await _dbHelper.createReminder(reminder);
          final savedReminder = reminder.copyWith(id: id);
          await _notificationService.scheduleNotification(savedReminder);
        } else {
          await _dbHelper.updateReminder(reminder);
          await _notificationService.updateNotification(reminder);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.reminder == null 
                ? 'Hatırlatıcı oluşturuldu' 
                : 'Hatırlatıcı güncellendi'),
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        print('Hatırlatıcı kaydedilirken hata: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

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
                            widget.reminder == null ? 'Yeni Hatırlatıcı' : 'Hatırlatıcı Düzenle',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.white),
                          onPressed: _saveReminder,
                        ),
                      ],
                    ),
                  ),
                  // Form
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Başlık
                            _buildGlassCard(
                              child: TextFormField(
                                controller: _titleController,
                                style: const TextStyle(color: Colors.white),
                                keyboardType: TextInputType.text,
                                textCapitalization: TextCapitalization.sentences,
                                decoration: InputDecoration(
                                  labelText: 'Başlık *',
                                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                  hintText: 'Hatırlatıcı başlığı',
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.2),
                                  prefixIcon: Icon(Icons.title, color: Colors.white.withOpacity(0.7)),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Başlık gereklidir';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Açıklama
                            _buildGlassCard(
                              child: TextFormField(
                                controller: _descriptionController,
                                style: const TextStyle(color: Colors.white),
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.newline,
                                textCapitalization: TextCapitalization.sentences,
                                decoration: InputDecoration(
                                  labelText: 'Açıklama / Notlar',
                                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                  hintText: 'Hatırlatıcı açıklaması (opsiyonel)',
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.2),
                                  prefixIcon: Icon(Icons.description, color: Colors.white.withOpacity(0.7)),
                                ),
                                maxLines: 3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Tam Gün
                            _buildGlassCard(
                              child: SwitchListTile(
                                title: const Text('Tam Gün', style: TextStyle(color: Colors.white)),
                                subtitle: const Text('Belirli saat olmadan', style: TextStyle(color: Colors.white70)),
                                value: _isAllDay,
                                onChanged: (value) {
                                  setState(() {
                                    _isAllDay = value;
                                    if (value) {
                                      _selectedDateTime = DateTime(
                                        _selectedDateTime.year,
                                        _selectedDateTime.month,
                                        _selectedDateTime.day,
                                      );
                                    }
                                  });
                                },
                                activeColor: themeColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Tarih ve Saat
                            _buildGlassCard(
                              child: InkWell(
                                onTap: _selectDateTime,
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: _isAllDay ? 'Tarih' : 'Tarih ve Saat',
                                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.2),
                                    prefixIcon: Icon(Icons.calendar_today, color: Colors.white.withOpacity(0.7)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _isAllDay
                                            ? DateFormat('dd MMM yyyy').format(_selectedDateTime)
                                            : DateFormat('dd MMM yyyy, HH:mm').format(_selectedDateTime),
                                        style: const TextStyle(color: Colors.white, fontSize: 16),
                                      ),
                                      const Icon(Icons.arrow_drop_down, color: Colors.white),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Tekrar Eden
                            _buildGlassCard(
                              child: SwitchListTile(
                                title: const Text('Tekrar Eden', style: TextStyle(color: Colors.white)),
                                subtitle: const Text('Bu hatırlatıcı tekrar etsin mi?', style: TextStyle(color: Colors.white70)),
                                value: _isRecurring,
                                onChanged: (value) {
                                  setState(() {
                                    _isRecurring = value;
                                    if (!value) {
                                      _recurrenceType = RecurrenceType.none;
                                    }
                                  });
                                },
                                activeColor: themeColor,
                              ),
                            ),
                            // Tekrar Tipi
                            if (_isRecurring) ...[
                              const SizedBox(height: 16),
                              _buildGlassCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text('Tekrar Tipi', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                    ),
                                    ...RecurrenceType.values.where((e) => e != RecurrenceType.none).map((type) {
                                      return RadioListTile<RecurrenceType>(
                                        title: Text(_getRecurrenceTypeName(type), style: const TextStyle(color: Colors.white)),
                                        value: type,
                                        groupValue: _recurrenceType,
                                        onChanged: (value) {
                                          setState(() {
                                            _recurrenceType = value!;
                                            if (value != RecurrenceType.weekly) {
                                              _selectedWeeklyDays = [];
                                            }
                                            if (value != RecurrenceType.monthly) {
                                              _selectedMonthlyDay = null;
                                            }
                                          });
                                        },
                                        activeColor: themeColor,
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                              // Haftalık günler
                              if (_recurrenceType == RecurrenceType.weekly) ...[
                                const SizedBox(height: 16),
                                _buildGlassCard(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text('Haftanın Günleri', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: List.generate(7, (index) {
                                            final day = index + 1;
                                            final isSelected = _selectedWeeklyDays.contains(day);
                                            return FilterChip(
                                              label: Text(_weekDays[index], style: TextStyle(color: isSelected ? Colors.white : Colors.white70)),
                                              selected: isSelected,
                                              onSelected: (selected) {
                                                setState(() {
                                                  if (selected) {
                                                    _selectedWeeklyDays.add(day);
                                                  } else {
                                                    _selectedWeeklyDays.remove(day);
                                                  }
                                                });
                                              },
                                              selectedColor: themeColor,
                                              checkmarkColor: Colors.white,
                                              backgroundColor: Colors.white.withOpacity(0.2),
                                            );
                                          }),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              // Aylık gün
                              if (_recurrenceType == RecurrenceType.monthly) ...[
                                const SizedBox(height: 16),
                                _buildGlassCard(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text('Ayın Kaçıncı Günü', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: DropdownButtonFormField<int>(
                                          value: _selectedMonthlyDay ?? _selectedDateTime.day,
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.white.withOpacity(0.2),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(15),
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                          dropdownColor: gradientColors[0],
                                          style: const TextStyle(color: Colors.white),
                                          items: List.generate(31, (index) {
                                            final day = index + 1;
                                            return DropdownMenuItem(
                                              value: day,
                                              child: Text('$day'),
                                            );
                                          }),
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedMonthlyDay = value;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                            const SizedBox(height: 16),
                            // Önceden Bildirim
                            _buildGlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text('Önceden Bildirim', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: DropdownButtonFormField<int>(
                                      value: _notificationBeforeMinutes,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(0.2),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(15),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      dropdownColor: gradientColors[0],
                                      style: const TextStyle(color: Colors.white),
                                      items: const [
                                        DropdownMenuItem(value: 0, child: Text('Bildirim yok')),
                                        DropdownMenuItem(value: 5, child: Text('5 dakika önce')),
                                        DropdownMenuItem(value: 15, child: Text('15 dakika önce')),
                                        DropdownMenuItem(value: 30, child: Text('30 dakika önce')),
                                        DropdownMenuItem(value: 60, child: Text('1 saat önce')),
                                        DropdownMenuItem(value: 1440, child: Text('1 gün önce')),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _notificationBeforeMinutes = value ?? 0;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Öncelik
                            _buildGlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text('Öncelik Seviyesi', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                                  ...Priority.values.map((priority) {
                                    return RadioListTile<Priority>(
                                      title: Text(_getPriorityName(priority), style: const TextStyle(color: Colors.white)),
                                      value: priority,
                                      groupValue: _priority,
                                      onChanged: (value) {
                                        setState(() {
                                          _priority = value!;
                                        });
                                      },
                                      activeColor: themeColor,
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Kategori
                            _buildGlassCard(
                              child: DropdownButtonFormField<String>(
                                value: _selectedCategory,
                                decoration: InputDecoration(
                                  labelText: 'Kategori',
                                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.2),
                                  prefixIcon: Icon(Icons.category, color: Colors.white.withOpacity(0.7)),
                                ),
                                dropdownColor: gradientColors[0],
                                style: const TextStyle(color: Colors.white),
                                items: _categories.map((category) {
                                  return DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedCategory = value;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Renk Etiketi
                            _buildGlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text('Renk Etiketi', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: List.generate(_colorTags.length, (index) {
                                        final isSelected = _colorTag == index;
                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _colorTag = index;
                                            });
                                          },
                                          child: Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: _colorTags[index],
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isSelected ? Colors.white : Colors.transparent,
                                                width: 3,
                                              ),
                                            ),
                                            child: isSelected
                                                ? const Icon(Icons.check, color: Colors.white, size: 20)
                                                : null,
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
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

  String _getRecurrenceTypeName(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.hourly:
        return 'Her Saat';
      case RecurrenceType.daily:
        return 'Her Gün';
      case RecurrenceType.weekly:
        return 'Haftalık';
      case RecurrenceType.monthly:
        return 'Aylık';
      case RecurrenceType.yearly:
        return 'Yıllık';
      default:
        return '';
    }
  }

  String _getPriorityName(Priority priority) {
    switch (priority) {
      case Priority.low:
        return 'Düşük';
      case Priority.normal:
        return 'Normal';
      case Priority.high:
        return 'Yüksek';
    }
  }
}

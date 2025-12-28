import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';

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
  bool _isRecurring = false;
  String _selectedCategory = 'Genel';
  List<String> _categories = ['Genel', 'Okul', 'İş', 'Sağlık'];

  @override
  void initState() {
    super.initState();
    if (widget.reminder != null) {
      _titleController.text = widget.reminder!.title;
      _descriptionController.text = widget.reminder!.description;
      _selectedDateTime = widget.reminder!.dateTime;
      _isRecurring = widget.reminder!.isRecurring;
      _selectedCategory = widget.reminder!.category;
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await _dbHelper.getAllCategories();
    setState(() {
      _categories = ['Genel', 'Okul', 'İş', 'Sağlık'];
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

  Future<void> _saveReminder() async {
    if (_formKey.currentState!.validate()) {
      try {
        final reminder = Reminder(
          id: widget.reminder?.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          dateTime: _selectedDateTime,
          isRecurring: _isRecurring,
          category: _selectedCategory,
          isCompleted: widget.reminder?.isCompleted ?? false,
        );

        if (widget.reminder == null) {
          print('Yeni hatırlatıcı oluşturuluyor: ${reminder.title}');
          final id = await _dbHelper.createReminder(reminder);
          print('Hatırlatıcı oluşturuldu, ID: $id');
          final savedReminder = reminder.copyWith(id: id);
          await _notificationService.scheduleNotification(savedReminder);
        } else {
          print('Hatırlatıcı güncelleniyor: ${reminder.id}');
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reminder == null ? 'Yeni Hatırlatıcı' : 'Hatırlatıcı Düzenle'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Başlık
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Başlık',
                hintText: 'Hatırlatıcı başlığı',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Başlık gereklidir';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Açıklama
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Açıklama',
                hintText: 'Hatırlatıcı açıklaması',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Açıklama gereklidir';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Tarih ve Saat
            InkWell(
              onTap: _selectDateTime,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tarih ve Saat',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm').format(_selectedDateTime),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Tekrar eden
            SwitchListTile(
              title: const Text('Tekrar Eden'),
              subtitle: const Text('Bu hatırlatıcı tekrar etsin mi?'),
              value: _isRecurring,
              onChanged: (value) {
                setState(() {
                  _isRecurring = value;
                });
              },
              secondary: const Icon(Icons.repeat),
            ),
            const SizedBox(height: 16),
            // Kategori
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
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
            const SizedBox(height: 24),
            // Kaydet butonu
            ElevatedButton(
              onPressed: _saveReminder,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Kaydet',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import 'add_edit_reminder_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService.instance;
  final AuthService _authService = AuthService();
  List<Reminder> _reminders = [];
  List<Reminder> _filteredReminders = [];
  String _searchQuery = '';
  String _filterStatus = 'Tümü'; // Tümü, Aktif, Tamamlanan
  String? _selectedCategory;
  List<String> _categories = [];
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReminders();
      _loadCategories();
      _loadUserProfile();
    });
  }

  Future<void> _loadUserProfile() async {
    final profile = await _authService.getUserProfile();
    setState(() {
      _userProfile = profile;
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _loadReminders() async {
    try {
      final reminders = await _dbHelper.getAllReminders();
      print('Yüklenen hatırlatıcı sayısı: ${reminders.length}');
      setState(() {
        _reminders = reminders;
        _applyFilters();
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

  Future<void> _loadCategories() async {
    final categories = await _dbHelper.getAllCategories();
    setState(() {
      _categories = categories;
    });
  }

  void _applyFilters() {
    List<Reminder> filtered = List.from(_reminders);

    // Durum filtresi
    if (_filterStatus == 'Aktif') {
      filtered = filtered.where((r) => !r.isCompleted).toList();
    } else if (_filterStatus == 'Tamamlanan') {
      filtered = filtered.where((r) => r.isCompleted).toList();
    }

    // Kategori filtresi
    if (_selectedCategory != null) {
      filtered = filtered.where((r) => r.category == _selectedCategory).toList();
    }

    // Arama filtresi
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((r) {
        return r.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            r.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            r.category.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    setState(() {
      _filteredReminders = filtered;
    });
  }

  Future<void> _toggleComplete(Reminder reminder) async {
    final updated = reminder.copyWith(isCompleted: !reminder.isCompleted);
    await _dbHelper.updateReminder(updated);
    await _notificationService.updateNotification(updated);
    _loadReminders();
  }

  Future<void> _deleteReminder(Reminder reminder) async {
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

  Future<void> _navigateToAddEdit(Reminder? reminder) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditReminderScreen(reminder: reminder),
      ),
    );

    // Ekran geri döndüğünde her zaman listeyi yenile
    _loadReminders();
    _loadCategories();
    if (result == true) {
      await _notificationService.rescheduleAllNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hatırlatıcılar'),
            if (_userProfile != null)
              Text(
                'Merhaba, ${_userProfile!['first_name'] ?? ''}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Çıkış Yap butonu
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
            onPressed: _logout,
          ),
          // Filtre menüsü
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _filterStatus = value;
                _applyFilters();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Tümü', child: Text('Tümü')),
              const PopupMenuItem(value: 'Aktif', child: Text('Aktif')),
              const PopupMenuItem(value: 'Tamamlanan', child: Text('Tamamlanan')),
            ],
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Icon(Icons.filter_list),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama çubuğu
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Ara...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _applyFilters();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFilters();
                });
              },
            ),
          ),
          // Kategori filtresi
          if (_categories.isNotEmpty)
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildCategoryChip(null, 'Tümü'),
                  ..._categories.map((cat) => _buildCategoryChip(cat, cat)),
                ],
              ),
            ),
          // Hatırlatıcı listesi
          Expanded(
            child: _filteredReminders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty || _selectedCategory != null
                              ? 'Sonuç bulunamadı'
                              : 'Henüz hatırlatıcı yok',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _filteredReminders.length,
                    itemBuilder: (context, index) {
                      final reminder = _filteredReminders[index];
                      return _buildReminderCard(reminder);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEdit(null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryChip(String? category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : null;
            _applyFilters();
          });
        },
      ),
    );
  }

  Widget _buildReminderCard(Reminder reminder) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final isPast = reminder.dateTime.isBefore(DateTime.now()) && !reminder.isCompleted;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(reminder.category),
          child: Text(
            reminder.category[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          reminder.title,
          style: TextStyle(
            decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reminder.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(reminder.dateTime),
                  style: TextStyle(
                    color: isPast ? Colors.red : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (reminder.isRecurring) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.repeat, size: 14, color: Colors.blue),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getCategoryColor(reminder.category).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                reminder.category,
                style: TextStyle(
                  color: _getCategoryColor(reminder.category),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: reminder.isCompleted,
              onChanged: (value) => _toggleComplete(reminder),
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
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
              onSelected: (value) {
                if (value == 'edit') {
                  _navigateToAddEdit(reminder);
                } else if (value == 'delete') {
                  _deleteReminder(reminder);
                }
              },
            ),
          ],
        ),
      ),
    );
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
}


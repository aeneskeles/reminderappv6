import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../models/reminder.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../utils/turkish_char_utils.dart';
import 'add_edit_reminder_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import 'reminder_detail_screen.dart';
import 'calendar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService.instance;
  final AuthService _authService = AuthService();
  List<Reminder> _reminders = [];
  List<Reminder> _filteredReminders = [];
  String _searchQuery = '';
  String _filterStatus = 'Tümü'; // Tümü, Aktif, Tamamlanan
  String? _selectedCategory;
  Priority? _selectedPriority; // Öncelik filtresi
  String _dateFilter = 'Tümü'; // Tümü, Bugün, Yarın, Bu Hafta, Bu Ay
  String _sortBy = 'Tarih'; // Tarih, Öncelik
  List<String> _categories = [];
  Map<String, dynamic>? _userProfile;
  int _selectedTabIndex = 0; // 0: Bugün, 1: Yaklaşanlar, 2: Tümü, 3: Tamamlananlar
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = _selectedTabIndex.clamp(0, 3);
    _tabController?.dispose();
    _tabController = TabController(length: 4, vsync: this, initialIndex: _selectedTabIndex);
    _tabController!.addListener(() {
      if (!_tabController!.indexIsChanging && _tabController != null) {
        final newIndex = _tabController!.index;
        if (newIndex >= 0 && newIndex < 4 && _selectedTabIndex != newIndex) {
          setState(() {
            _selectedTabIndex = newIndex;
            _applyFilters();
          });
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReminders();
      _loadCategories();
      _loadUserProfile();
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
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
      final completedCount = reminders.where((r) => r.isCompleted).length;
      print('Yüklenen hatırlatıcı sayısı: ${reminders.length} (Tamamlanan: $completedCount)');
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
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final weekEnd = now.add(const Duration(days: 7));

    // Tab-based filtering
    if (_selectedTabIndex == 0) {
      // Bugün
      filtered = filtered.where((r) {
        return !r.isCompleted &&
            r.dateTime.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
            r.dateTime.isBefore(todayEnd.add(const Duration(seconds: 1)));
      }).toList();
    } else if (_selectedTabIndex == 1) {
      // Yaklaşanlar (next 7 days)
      filtered = filtered.where((r) {
        return !r.isCompleted &&
            r.dateTime.isAfter(now.subtract(const Duration(seconds: 1))) &&
            r.dateTime.isBefore(weekEnd);
      }).toList();
    } else if (_selectedTabIndex == 2) {
      // Tümü (all uncompleted)
      filtered = filtered.where((r) => !r.isCompleted).toList();
    } else if (_selectedTabIndex == 3) {
      // Tamamlananlar
      filtered = filtered.where((r) => r.isCompleted).toList();
    }

    // Date filter
    if (_dateFilter == 'Bugün') {
      filtered = filtered.where((r) {
        return r.dateTime.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
            r.dateTime.isBefore(todayEnd.add(const Duration(seconds: 1)));
      }).toList();
    } else if (_dateFilter == 'Yarın') {
      final tomorrowStart = todayStart.add(const Duration(days: 1));
      final tomorrowEnd = todayEnd.add(const Duration(days: 1));
      filtered = filtered.where((r) {
        return r.dateTime.isAfter(tomorrowStart.subtract(const Duration(seconds: 1))) &&
            r.dateTime.isBefore(tomorrowEnd.add(const Duration(seconds: 1)));
      }).toList();
    } else if (_dateFilter == 'Bu Hafta') {
      filtered = filtered.where((r) {
        return r.dateTime.isAfter(now.subtract(const Duration(seconds: 1))) &&
            r.dateTime.isBefore(weekEnd);
      }).toList();
    } else if (_dateFilter == 'Bu Ay') {
      final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      filtered = filtered.where((r) {
        return r.dateTime.isAfter(now.subtract(const Duration(seconds: 1))) &&
            r.dateTime.isBefore(monthEnd.add(const Duration(seconds: 1)));
      }).toList();
    }

    // Category filter
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filtered = filtered.where((r) => r.category == _selectedCategory).toList();
    }

    // Priority filter
    if (_selectedPriority != null) {
      filtered = filtered.where((r) => r.priority == _selectedPriority).toList();
    }

    // Search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((r) {
        return TurkishCharUtils.containsTurkish(r.title.toLowerCase(), _searchQuery.toLowerCase());
      }).toList();
    }

    // Sorting
    if (_sortBy == 'Tarih') {
      if (_selectedTabIndex == 3) {
        // Tamamlananlar: reverse chronological
        filtered.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      } else {
        filtered.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      }
    } else if (_sortBy == 'Öncelik') {
      filtered.sort((a, b) {
        final priorityOrder = {Priority.high: 0, Priority.normal: 1, Priority.low: 2};
        return (priorityOrder[a.priority] ?? 1).compareTo(priorityOrder[b.priority] ?? 1);
      });
    }

    setState(() {
      _filteredReminders = filtered;
    });
  }

  Future<void> _toggleComplete(Reminder reminder) async {
    try {
      final updated = reminder.copyWith(isCompleted: !reminder.isCompleted);
      await _dbHelper.updateReminder(updated);
      if (updated.isCompleted) {
        await _notificationService.cancelNotification(updated.id!);
      } else {
        await _notificationService.scheduleNotification(updated);
      }
      await _loadReminders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
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
      try {
        await _dbHelper.deleteReminder(reminder.id!);
        await _notificationService.cancelNotification(reminder.id!);
        await _loadReminders();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e')),
          );
        }
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
    if (result == true) {
      await _loadReminders();
    }
  }


  void _buildFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filtrele ve Sırala'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tarih Filtresi:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['Tümü', 'Bugün', 'Yarın', 'Bu Hafta', 'Bu Ay'].map((filter) {
                    return FilterChip(
                      label: Text(filter),
                      selected: _dateFilter == filter,
                      onSelected: (selected) {
                        setDialogState(() {
                          _dateFilter = filter;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Öncelik:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Tümü'),
                      selected: _selectedPriority == null,
                      onSelected: (selected) {
                        setDialogState(() {
                          _selectedPriority = null;
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('Düşük'),
                      selected: _selectedPriority == Priority.low,
                      onSelected: (selected) {
                        setDialogState(() {
                          _selectedPriority = selected ? Priority.low : null;
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('Normal'),
                      selected: _selectedPriority == Priority.normal,
                      onSelected: (selected) {
                        setDialogState(() {
                          _selectedPriority = selected ? Priority.normal : null;
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('Yüksek'),
                      selected: _selectedPriority == Priority.high,
                      onSelected: (selected) {
                        setDialogState(() {
                          _selectedPriority = selected ? Priority.high : null;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Kategori:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Tümü'),
                      selected: _selectedCategory == null,
                      onSelected: (selected) {
                        setDialogState(() {
                          _selectedCategory = null;
                        });
                      },
                    ),
                    ..._categories.map((cat) {
                      return FilterChip(
                        label: Text(cat),
                        selected: _selectedCategory == cat,
                        onSelected: (selected) {
                          setDialogState(() {
                            _selectedCategory = selected ? cat : null;
                          });
                        },
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Sıralama:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['Tarih', 'Öncelik'].map((sort) {
                    return FilterChip(
                      label: Text(sort),
                      selected: _sortBy == sort,
                      onSelected: (selected) {
                        setDialogState(() {
                          _sortBy = sort;
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _applyFilters();
                });
                Navigator.pop(context);
              },
              child: const Text('Uygula'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernReminderCard(Reminder reminder) {
    final colorTag = _getColorTag(reminder.colorTag);
    final priorityColor = _getPriorityColor(reminder.priority);
    final priorityIcon = _getPriorityIcon(reminder.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // Color tag
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: colorTag,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                // Content - wrapped in Expanded and GestureDetector
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReminderDetailScreen(reminder: reminder),
                        ),
                      ).then((_) => _loadReminders());
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                reminder.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  decoration: reminder.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            Icon(
                              priorityIcon,
                              color: priorityColor,
                              size: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd MMM yyyy, HH:mm', 'tr_TR').format(reminder.dateTime),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (reminder.category.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildCategoryChip(reminder.category),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Actions - PopupMenuButton outside GestureDetector
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                  onSelected: (value) {
                    if (value == 'complete') {
                      _toggleComplete(reminder);
                    } else if (value == 'edit') {
                      _navigateToAddEdit(reminder);
                    } else if (value == 'delete') {
                      _deleteReminder(reminder);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'complete',
                      child: Row(
                        children: [
                          Icon(
                            reminder.isCompleted
                                ? Icons.radio_button_unchecked
                                : Icons.check_circle,
                            color: reminder.isCompleted ? Colors.grey : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(reminder.isCompleted ? 'Tamamlanmadı' : 'Tamamlandı'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Düzenle'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Sil'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getCategoryColor(category).withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getCategoryColor(category).withOpacity(0.5),
        ),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontSize: 12,
          color: _getCategoryColor(category),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getColorTag(int colorTag) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];
    return colors[colorTag % colors.length];
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Colors.red;
      case Priority.normal:
        return Colors.orange;
      case Priority.low:
        return Colors.green;
    }
  }

  IconData _getPriorityIcon(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Icons.priority_high;
      case Priority.normal:
        return Icons.remove;
      case Priority.low:
        return Icons.arrow_downward;
    }
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'İş': Colors.blue,
      'Okul': Colors.purple,
      'Sağlık': Colors.red,
      'Kişisel': Colors.green,
      'Alışveriş': Colors.orange,
      'Spor': Colors.teal,
    };
    return colors[category] ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final userName = _userProfile != null
        ? '${_userProfile!['first_name'] ?? ''} ${_userProfile!['last_name'] ?? ''}'
        : 'Kullanıcı';

    return FutureBuilder<Color>(
      future: ThemeService.instance.getThemeColor(),
      builder: (context, snapshot) {
        final themeColor = snapshot.data ?? ThemeService.instance.defaultColor;
        final gradientColors = ThemeService.instance.getGradientColors(themeColor);

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // Blurred background shapes
                  Positioned(
                    top: -100,
                    left: -100,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -150,
                    right: -100,
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  // Main content
                  Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Merhaba,',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                // Sync status indicator
                                FutureBuilder<bool>(
                                  future: _dbHelper.isOnline(),
                                  builder: (context, snapshot) {
                                    final isOnline = snapshot.data ?? false;
                                    return IconButton(
                                      icon: Icon(
                                        isOnline ? Icons.cloud_done : Icons.cloud_off,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      onPressed: () async {
                                        if (isOnline) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Senkronizasyon başlatılıyor...'),
                                              duration: Duration(seconds: 1),
                                            ),
                                          );
                                          final success = await _dbHelper.syncWithServer();
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  success 
                                                      ? '✅ Senkronizasyon tamamlandı' 
                                                      : '❌ Senkronizasyon başarısız',
                                                ),
                                                duration: const Duration(seconds: 2),
                                              ),
                                            );
                                            await _loadReminders();
                                          }
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('📴 Offline moddasınız'),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      },
                                      tooltip: isOnline ? 'Online - Senkronize et' : 'Offline',
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.calendar_today, color: Colors.white),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const CalendarScreen(),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.settings, color: Colors.white),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const SettingsScreen(),
                                      ),
                                    );
                                  },
                                  tooltip: 'Ayarlar',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.logout, color: Colors.white),
                                  onPressed: _logout,
                                  tooltip: 'Çıkış Yap',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Tab Bar
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  _tabController?.animateTo(0);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _selectedTabIndex == 0 
                                        ? Colors.white.withOpacity(0.3) 
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Bugün',
                                    style: TextStyle(
                                      color: _selectedTabIndex == 0 
                                          ? Colors.white 
                                          : Colors.white.withOpacity(0.7),
                                      fontWeight: _selectedTabIndex == 0 
                                          ? FontWeight.bold 
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  _tabController?.animateTo(1);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _selectedTabIndex == 1 
                                        ? Colors.white.withOpacity(0.3) 
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Yaklaşanlar',
                                    style: TextStyle(
                                      color: _selectedTabIndex == 1 
                                          ? Colors.white 
                                          : Colors.white.withOpacity(0.7),
                                      fontWeight: _selectedTabIndex == 1 
                                          ? FontWeight.bold 
                                          : FontWeight.normal,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  _tabController?.animateTo(2);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _selectedTabIndex == 2 
                                        ? Colors.white.withOpacity(0.3) 
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Tümü',
                                    style: TextStyle(
                                      color: _selectedTabIndex == 2 
                                          ? Colors.white 
                                          : Colors.white.withOpacity(0.7),
                                      fontWeight: _selectedTabIndex == 2 
                                          ? FontWeight.bold 
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  _tabController?.animateTo(3);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _selectedTabIndex == 3 
                                        ? Colors.white.withOpacity(0.3) 
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Tamamlananlar',
                                    style: TextStyle(
                                      color: _selectedTabIndex == 3 
                                          ? Colors.white 
                                          : Colors.white.withOpacity(0.7),
                                      fontWeight: _selectedTabIndex == 3 
                                          ? FontWeight.bold 
                                          : FontWeight.normal,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Search and Filter
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: TextField(
                                  onChanged: (value) {
                                    setState(() {
                                      _searchQuery = value;
                                      _applyFilters();
                                    });
                                  },
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Ara...',
                                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                    prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.filter_list, color: Colors.white),
                                onPressed: _buildFilterDialog,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Reminder List
                      Expanded(
                        child: _filteredReminders.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inbox_outlined,
                                      size: 80,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Henüz hatırlatıcı yok',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: _filteredReminders.length,
                                itemBuilder: (context, index) {
                                  return _buildModernReminderCard(_filteredReminders[index]);
                                },
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FutureBuilder<Color>(
            future: ThemeService.instance.getThemeColor(),
            builder: (context, snapshot) {
              final fabThemeColor = snapshot.data ?? ThemeService.instance.defaultColor;
              final fabGradientColors = ThemeService.instance.getGradientColors(fabThemeColor);
              return Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      fabGradientColors[0],
                      fabGradientColors[1],
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: fabGradientColors[0].withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _navigateToAddEdit(null),
                    borderRadius: BorderRadius.circular(32),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

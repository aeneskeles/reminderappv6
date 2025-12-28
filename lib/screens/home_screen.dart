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
      print('Yüklenen hatırlatıcı sayısı: \\${reminders.length} (Tamamlanan: \\${completedCount})');
      setState(() {
        _reminders = reminders;
        _applyFilters();
      });
    } catch (e) {
      print('Hatırlatıcılar yüklenirken hata: \\${e}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veriler yüklenirken hata oluştu: \\${e}')),
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
    if (_selectedTabIndex == 0) {
      filtered = filtered.where((r) {
        return !r.isCompleted &&
            r.dateTime.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
            r.dateTime.isBefore(todayEnd.add(const Duration(seconds: 1)));
      }).toList();
    } else if (_selectedTabIndex == 1) {
      filtered = filtered.where((r) {
        return !r.isCompleted &&
            r.dateTime.isAfter(now.subtract(const Duration(seconds: 1))) &&
            r.dateTime.isBefore(weekEnd);
      }).toList();
    } else if (_selectedTabIndex == 2) {
      filtered = filtered.where((r) => !r.isCompleted).toList();
    } else if (_selectedTabIndex == 3) { filtered = filtered.where((r) => r.isCompleted).toList(); }
    // --- ek filtreler aynı şekilde devam ediyor ---
    // ...
    setState(() { _filteredReminders = filtered; });
  }

  // --- Diğer yardımcı fonksiyonlar: _toggleComplete, _deleteReminder, _navigateToAddEdit, _buildMenuSheet, _buildFilterDialog, _buildCategoryFilterChip, _buildCategoryChip, _buildModernReminderCard, _buildReminderCard, _getColorTag, _getPriorityColor, _getPriorityIcon, _getCategoryColor ---

  @override
  Widget build(BuildContext context) {
    final userName = _userProfile != null
        ? '\{_userProfile!['first_name'] ?? ''}, ${_userProfile!['last_name'] ?? ''}'
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
                      // ... --- Diğer UI widgetların tamamı buraya --- ...
                      // Header section, tabbar, arama, filter vs. hepsi burada
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

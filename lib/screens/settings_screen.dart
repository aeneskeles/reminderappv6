import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/settings_service.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import 'login_screen.dart';
import 'statistics_screen.dart';
import 'notification_history_screen.dart';
import 'app_lock_settings_screen.dart';
import 'accessibility_settings_screen.dart';
import 'achievements_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService.instance;
  final AuthService _authService = AuthService();
  
  // Settings values
  int _defaultSnoozeMinutes = 10;
  int _defaultNotificationMinutes = 15;
  bool _notificationSound = true;
  bool _notificationVibration = true;
  String _themeMode = 'system';
  String _language = 'tr';
  
  // User profile
  Map<String, dynamic>? _userProfile;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadUserProfile();
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsService.getAllSettings();
    setState(() {
      _defaultSnoozeMinutes = settings['defaultSnoozeMinutes'];
      _defaultNotificationMinutes = settings['defaultNotificationMinutes'];
      _notificationSound = settings['notificationSound'];
      _notificationVibration = settings['notificationVibration'];
      _themeMode = settings['themeMode'];
      _language = settings['language'];
      _isLoading = false;
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

  Widget _buildGlassContainer({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white.withOpacity(0.9),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Ayarlar',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Settings List
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            children: [
                              // Account Section
                              _buildSectionTitle('HESAP'),
                              _buildGlassContainer(
                                child: Column(
                                  children: [
                                    ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: themeColor.withOpacity(0.2),
                                        child: Icon(Icons.person, color: themeColor),
                                      ),
                                      title: Text(
                                        _userProfile != null
                                            ? '${_userProfile!['first_name'] ?? ''} ${_userProfile!['last_name'] ?? ''}'
                                            : 'Kullanıcı',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      subtitle: Text(
                                        _userProfile?['email'] ?? _authService.currentUser?.email ?? '',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ),
                                    const Divider(height: 1),
                                    ListTile(
                                      leading: const Icon(Icons.logout, color: Colors.red),
                                      title: const Text(
                                        'Çıkış Yap',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                      onTap: _logout,
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Notification Settings
                              _buildSectionTitle('BİLDİRİM AYARLARI'),
                              _buildGlassContainer(
                                child: Column(
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.snooze, color: Colors.blue),
                                      title: const Text(
                                        'Varsayılan Erteleme Süresi',
                                        style: TextStyle(color: Colors.black87),
                                      ),
                                      subtitle: Text(
                                        '$_defaultSnoozeMinutes dakika',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                      onTap: () => _showSnoozeDialog(),
                                    ),
                                    const Divider(height: 1),
                                    ListTile(
                                      leading: const Icon(Icons.notifications_active, color: Colors.orange),
                                      title: const Text(
                                        'Varsayılan Önceden Hatırlatma',
                                        style: TextStyle(color: Colors.black87),
                                      ),
                                      subtitle: Text(
                                        '$_defaultNotificationMinutes dakika önce',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                      onTap: () => _showNotificationTimeDialog(),
                                    ),
                                    const Divider(height: 1),
                                    SwitchListTile(
                                      secondary: const Icon(Icons.volume_up, color: Colors.purple),
                                      title: const Text(
                                        'Bildirim Sesi',
                                        style: TextStyle(color: Colors.black87),
                                      ),
                                      value: _notificationSound,
                                      onChanged: (value) async {
                                        await _settingsService.setNotificationSound(value);
                                        setState(() {
                                          _notificationSound = value;
                                        });
                                      },
                                    ),
                                    const Divider(height: 1),
                                    SwitchListTile(
                                      secondary: const Icon(Icons.vibration, color: Colors.teal),
                                      title: const Text(
                                        'Titreşim',
                                        style: TextStyle(color: Colors.black87),
                                      ),
                                      value: _notificationVibration,
                                      onChanged: (value) async {
                                        await _settingsService.setNotificationVibration(value);
                                        setState(() {
                                          _notificationVibration = value;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Appearance Settings
                              _buildSectionTitle('GÖRÜNÜM AYARLARI'),
                              _buildGlassContainer(
                                child: Column(
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.palette, color: Colors.indigo),
                                      title: const Text(
                                        'Tema',
                                        style: TextStyle(color: Colors.black87),
                                      ),
                                      subtitle: Text(
                                        _getThemeModeText(_themeMode),
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                      onTap: () => _showThemeDialog(),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Language Settings
                              _buildSectionTitle('DİL AYARLARI'),
                              _buildGlassContainer(
                                child: ListTile(
                                  leading: const Icon(Icons.language, color: Colors.deepOrange),
                                  title: const Text(
                                    'Dil',
                                    style: TextStyle(color: Colors.black87),
                                  ),
                                  subtitle: Text(
                                    _getLanguageText(_language),
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  onTap: () => _showLanguageDialog(),
                                ),
                              ),
                              
                              // Advanced Features
                              _buildSectionTitle('GELİŞMİŞ ÖZELLİKLER'),
                              _buildGlassContainer(
                                child: Column(
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.emoji_events, color: Colors.amber),
                                      title: const Text(
                                        'Rozetler ve Puanlar',
                                        style: TextStyle(color: Colors.black87),
                                      ),
                                      subtitle: Text(
                                        'Kazandığın rozetleri ve puanları gör',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const AchievementsScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                    const Divider(height: 1),
                                    ListTile(
                                      leading: const Icon(Icons.history, color: Colors.amber),
                                      title: const Text(
                                        'Bildirim Geçmişi',
                                        style: TextStyle(color: Colors.black87),
                                      ),
                                      subtitle: Text(
                                        'Geçmiş bildirimleri görüntüle',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const NotificationHistoryScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                    const Divider(height: 1),
                                    ListTile(
                                      leading: const Icon(Icons.lock, color: Colors.red),
                                      title: const Text(
                                        'Uygulama Kilidi',
                                        style: TextStyle(color: Colors.black87),
                                      ),
                                      subtitle: Text(
                                        'PIN veya biyometrik kilit',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const AppLockSettingsScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                    const Divider(height: 1),
                                    ListTile(
                                      leading: const Icon(Icons.accessibility, color: Colors.purple),
                                      title: const Text(
                                        'Erişilebilirlik',
                                        style: TextStyle(color: Colors.black87),
                                      ),
                                      subtitle: Text(
                                        'Yazı boyutu, kontrast ve daha fazlası',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const AccessibilitySettingsScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              
                              // App Info
                              _buildSectionTitle('UYGULAMA BİLGİSİ'),
                              _buildGlassContainer(
                                child: Column(
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.info_outline, color: Colors.grey),
                                      title: const Text(
                                        'Versiyon',
                                        style: TextStyle(color: Colors.black87),
                                      ),
                                      subtitle: Text(
                                        '1.0.0',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                            ],
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

  void _showSnoozeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erteleme Süresi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [5, 10, 15, 30].map((minutes) {
            return RadioListTile<int>(
              title: Text('$minutes dakika'),
              value: minutes,
              groupValue: _defaultSnoozeMinutes,
              onChanged: (value) async {
                if (value != null) {
                  await _settingsService.setDefaultSnoozeMinutes(value);
                  setState(() {
                    _defaultSnoozeMinutes = value;
                  });
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showNotificationTimeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Önceden Hatırlatma'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [0, 5, 10, 15, 30, 60, 120, 1440].map((minutes) {
              String label;
              if (minutes == 0) {
                label = 'Hatırlatma yok';
              } else if (minutes < 60) {
                label = '$minutes dakika önce';
              } else if (minutes == 60) {
                label = '1 saat önce';
              } else if (minutes < 1440) {
                label = '${minutes ~/ 60} saat önce';
              } else {
                label = '1 gün önce';
              }
              
              return RadioListTile<int>(
                title: Text(label),
                value: minutes,
                groupValue: _defaultNotificationMinutes,
                onChanged: (value) async {
                  if (value != null) {
                    await _settingsService.setDefaultNotificationMinutes(value);
                    setState(() {
                      _defaultNotificationMinutes = value;
                    });
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tema Seçin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Açık Tema'),
              value: 'light',
              groupValue: _themeMode,
              onChanged: (value) async {
                if (value != null) {
                  await _settingsService.setThemeMode(value);
                  setState(() {
                    _themeMode = value;
                  });
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tema değişikliği uygulandı'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Koyu Tema'),
              value: 'dark',
              groupValue: _themeMode,
              onChanged: (value) async {
                if (value != null) {
                  await _settingsService.setThemeMode(value);
                  setState(() {
                    _themeMode = value;
                  });
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tema değişikliği uygulandı'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Sistem Teması'),
              value: 'system',
              groupValue: _themeMode,
              onChanged: (value) async {
                if (value != null) {
                  await _settingsService.setThemeMode(value);
                  setState(() {
                    _themeMode = value;
                  });
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tema değişikliği uygulandı'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dil Seçin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Türkçe'),
              value: 'tr',
              groupValue: _language,
              onChanged: (value) async {
                if (value != null) {
                  await _settingsService.setLanguage(value);
                  setState(() {
                    _language = value;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dil değişikliği için uygulamayı yeniden başlatın'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: _language,
              onChanged: (value) async {
                if (value != null) {
                  await _settingsService.setLanguage(value);
                  setState(() {
                    _language = value;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Restart the app to apply language change'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeModeText(String mode) {
    switch (mode) {
      case 'light':
        return 'Açık Tema';
      case 'dark':
        return 'Koyu Tema';
      case 'system':
        return 'Sistem Teması';
      default:
        return 'Sistem Teması';
    }
  }

  String _getLanguageText(String lang) {
    switch (lang) {
      case 'tr':
        return 'Türkçe';
      case 'en':
        return 'English';
      default:
        return 'Türkçe';
    }
  }
}

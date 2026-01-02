import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reminder.dart';
import 'local_database_helper.dart';
import 'auth_service.dart';

class SyncService {
  static final SyncService instance = SyncService._init();
  
  final LocalDatabaseHelper _localDb = LocalDatabaseHelper.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();
  final Connectivity _connectivity = Connectivity();
  
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  SyncService._init();

  String? get _userId => _authService.currentUser?.id;

  // Initialize sync service
  Future<void> initialize() async {
    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      _onConnectivityChanged(results);
    });

    // Check initial connectivity and sync
    final connectivityResult = await _connectivity.checkConnectivity();
    if (_isConnected(connectivityResult)) {
      await syncAll();
    }
  }

  // Dispose
  void dispose() {
    _connectivitySubscription?.cancel();
  }

  // Check if connected to internet
  bool _isConnected(List<ConnectivityResult> results) {
    return results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet);
  }

  // Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    if (_isConnected(results) && !_isSyncing) {
      print('📡 İnternet bağlantısı tespit edildi, senkronizasyon başlatılıyor...');
      syncAll();
    }
  }

  // Check if online
  Future<bool> isOnline() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return _isConnected(connectivityResult);
  }

  // Sync all data
  Future<bool> syncAll() async {
    if (_userId == null) {
      print('❌ Kullanıcı giriş yapmamış, senkronizasyon yapılamıyor');
      return false;
    }

    if (_isSyncing) {
      print('⏳ Senkronizasyon zaten devam ediyor');
      return false;
    }

    _isSyncing = true;
    print('🔄 Senkronizasyon başladı...');

    try {
      // 1. Push local changes to server
      await _pushLocalChanges();

      // 2. Pull server changes to local
      await _pullServerChanges();

      _lastSyncTime = DateTime.now();
      print('✅ Senkronizasyon tamamlandı: ${_lastSyncTime}');
      return true;
    } catch (e) {
      print('❌ Senkronizasyon hatası: $e');
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  // Push local changes to server
  Future<void> _pushLocalChanges() async {
    if (_userId == null) return;

    try {
      final unsyncedReminders = await _localDb.getUnsyncedReminders(_userId!);
      print('📤 ${unsyncedReminders.length} yerel değişiklik sunucuya gönderiliyor...');

      for (final map in unsyncedReminders) {
        try {
          final isDeleted = (map['is_deleted'] as int) == 1;
          final serverId = map['server_id'] as int?;
          final localId = map['id'] as int;

          if (isDeleted && serverId != null) {
            // Delete from server
            await _supabase
                .from('reminders')
                .delete()
                .eq('id', serverId)
                .eq('user_id', _userId!);
            
            print('🗑️ Sunucudan silindi: $serverId');
            
            // Remove from local db completely
            final db = await _localDb.database;
            await db.delete('reminders', where: 'id = ?', whereArgs: [localId]);
          } else if (!isDeleted) {
            final reminder = _localDb.reminderFromMap(map);
            
            if (serverId != null) {
              // Update existing on server
              final data = _reminderToSupabaseMap(reminder);
              await _supabase
                  .from('reminders')
                  .update(data)
                  .eq('id', serverId)
                  .eq('user_id', _userId!);
              
              print('📝 Sunucuda güncellendi: $serverId');
              await _localDb.markAsSynced(localId, serverId);
            } else {
              // Create new on server
              final data = _reminderToSupabaseMap(reminder);
              data['user_id'] = _userId;
              
              final response = await _supabase
                  .from('reminders')
                  .insert(data)
                  .select('id')
                  .single();
              
              final newServerId = response['id'] as int;
              print('➕ Sunucuda oluşturuldu: $newServerId');
              await _localDb.markAsSynced(localId, newServerId);
            }
          }
        } catch (e) {
          print('❌ Hatırlatıcı senkronize edilemedi: $e');
          // Continue with next reminder
        }
      }
    } catch (e) {
      print('❌ Yerel değişiklikler gönderilirken hata: $e');
      rethrow;
    }
  }

  // Pull server changes to local
  Future<void> _pullServerChanges() async {
    if (_userId == null) return;

    try {
      print('📥 Sunucudan veriler çekiliyor...');
      
      final response = await _supabase
          .from('reminders')
          .select()
          .eq('user_id', _userId!)
          .order('date_time', ascending: true);

      final serverReminders = (response as List)
          .map((map) => _reminderFromSupabaseMap(map as Map<String, dynamic>))
          .toList();

      print('📥 ${serverReminders.length} hatırlatıcı sunucudan alındı');

      // Upsert each reminder to local database
      for (final reminder in serverReminders) {
        await _localDb.upsertFromServer(reminder, _userId!);
      }

      print('✅ Sunucu verileri yerel veritabanına kaydedildi');
    } catch (e) {
      print('❌ Sunucu değişiklikleri çekilirken hata: $e');
      rethrow;
    }
  }

  // Create reminder (with sync)
  Future<int> createReminder(Reminder reminder) async {
    if (_userId == null) {
      throw Exception('Kullanıcı giriş yapmamış');
    }

    try {
      // Save to local database first
      final localId = await _localDb.createReminder(reminder, _userId!);
      print('💾 Yerel veritabanına kaydedildi: $localId');

      // Try to sync immediately if online
      if (await isOnline()) {
        try {
          final data = _reminderToSupabaseMap(reminder);
          data['user_id'] = _userId;

          final response = await _supabase
              .from('reminders')
              .insert(data)
              .select('id')
              .single();

          final serverId = response['id'] as int;
          await _localDb.markAsSynced(localId, serverId);
          print('☁️ Sunucuya kaydedildi: $serverId');
          
          return serverId;
        } catch (e) {
          print('⚠️ Sunucuya kaydedilemedi, offline modda çalışılıyor: $e');
          return localId;
        }
      } else {
        print('📴 Offline modda çalışılıyor');
        return localId;
      }
    } catch (e) {
      print('❌ Hatırlatıcı oluşturulurken hata: $e');
      rethrow;
    }
  }

  // Update reminder (with sync)
  Future<void> updateReminder(Reminder reminder) async {
    if (_userId == null || reminder.id == null) {
      throw Exception('Geçersiz kullanıcı veya hatırlatıcı');
    }

    try {
      // Update local database first
      await _localDb.updateReminder(reminder, _userId!);
      print('💾 Yerel veritabanında güncellendi: ${reminder.id}');

      // Try to sync immediately if online
      if (await isOnline()) {
        try {
          // Get server_id from local database
          final localReminder = await _localDb.getReminder(reminder.id!);
          if (localReminder != null) {
            final db = await _localDb.database;
            final maps = await db.query(
              'reminders',
              columns: ['server_id'],
              where: 'id = ?',
              whereArgs: [reminder.id],
              limit: 1,
            );
            
            if (maps.isNotEmpty && maps.first['server_id'] != null) {
              final serverId = maps.first['server_id'] as int;
              final data = _reminderToSupabaseMap(reminder);
              
              await _supabase
                  .from('reminders')
                  .update(data)
                  .eq('id', serverId)
                  .eq('user_id', _userId!);
              
              await _localDb.markAsSynced(reminder.id!, serverId);
              print('☁️ Sunucuda güncellendi: $serverId');
            }
          }
        } catch (e) {
          print('⚠️ Sunucuda güncellenemedi, offline modda çalışılıyor: $e');
        }
      } else {
        print('📴 Offline modda çalışılıyor');
      }
    } catch (e) {
      print('❌ Hatırlatıcı güncellenirken hata: $e');
      rethrow;
    }
  }

  // Delete reminder (with sync)
  Future<void> deleteReminder(int localId) async {
    if (_userId == null) {
      throw Exception('Kullanıcı giriş yapmamış');
    }

    try {
      // Soft delete in local database
      await _localDb.deleteReminder(localId, _userId!);
      print('💾 Yerel veritabanında silindi: $localId');

      // Try to sync immediately if online
      if (await isOnline()) {
        try {
          // Get server_id from local database
          final db = await _localDb.database;
          final maps = await db.query(
            'reminders',
            columns: ['server_id'],
            where: 'id = ?',
            whereArgs: [localId],
            limit: 1,
          );
          
          if (maps.isNotEmpty && maps.first['server_id'] != null) {
            final serverId = maps.first['server_id'] as int;
            
            await _supabase
                .from('reminders')
                .delete()
                .eq('id', serverId)
                .eq('user_id', _userId!);
            
            print('☁️ Sunucudan silindi: $serverId');
            
            // Remove from local db completely
            await db.delete('reminders', where: 'id = ?', whereArgs: [localId]);
          }
        } catch (e) {
          print('⚠️ Sunucudan silinemedi, offline modda çalışılıyor: $e');
        }
      } else {
        print('📴 Offline modda çalışılıyor');
      }
    } catch (e) {
      print('❌ Hatırlatıcı silinirken hata: $e');
      rethrow;
    }
  }

  // Get all reminders (from local database)
  Future<List<Reminder>> getAllReminders() async {
    if (_userId == null) {
      return [];
    }

    try {
      return await _localDb.getAllReminders(_userId!);
    } catch (e) {
      print('❌ Hatırlatıcılar alınırken hata: $e');
      return [];
    }
  }

  // Clear local data (on logout)
  Future<void> clearLocalData() async {
    await _localDb.clearAllData();
    _lastSyncTime = null;
    print('🗑️ Yerel veriler temizlendi');
  }

  // Force sync
  Future<bool> forceSync() async {
    return await syncAll();
  }

  // Get last sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  // Check if syncing
  bool get isSyncing => _isSyncing;

  // Convert Reminder to Supabase map
  Map<String, dynamic> _reminderToSupabaseMap(Reminder reminder) {
    return {
      'title': reminder.title,
      'description': reminder.description,
      'date_time': reminder.dateTime.toIso8601String(),
      'is_recurring': reminder.isRecurring,
      'category': reminder.category,
      'is_completed': reminder.isCompleted,
      'is_all_day': reminder.isAllDay,
      'recurrence_type': reminder.recurrenceType.name,
      'weekly_days': reminder.weeklyDays.isEmpty ? null : reminder.weeklyDays.join(','),
      'monthly_day': reminder.monthlyDay,
      'notification_before_minutes': reminder.notificationBeforeMinutes,
      'priority': reminder.priority.name,
      'color_tag': reminder.colorTag,
    };
  }

  // Convert Supabase map to Reminder
  Reminder _reminderFromSupabaseMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      dateTime: DateTime.parse(map['date_time'] as String),
      isRecurring: map['is_recurring'] as bool? ?? false,
      category: map['category'] as String? ?? 'Genel',
      isCompleted: map['is_completed'] as bool? ?? false,
      isAllDay: map['is_all_day'] as bool? ?? false,
      recurrenceType: RecurrenceType.values.firstWhere(
        (e) => e.name == (map['recurrence_type'] as String? ?? 'none'),
        orElse: () => RecurrenceType.none,
      ),
      weeklyDays: (map['weekly_days'] as String? ?? '')
          .split(',')
          .where((e) => e.isNotEmpty)
          .map((e) => int.parse(e))
          .toList(),
      monthlyDay: map['monthly_day'] as int?,
      notificationBeforeMinutes: map['notification_before_minutes'] as int? ?? 0,
      priority: Priority.values.firstWhere(
        (e) => e.name == (map['priority'] as String? ?? 'normal'),
        orElse: () => Priority.normal,
      ),
      colorTag: map['color_tag'] as int? ?? 0,
    );
  }
}


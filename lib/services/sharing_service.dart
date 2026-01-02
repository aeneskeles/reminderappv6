import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reminder.dart';

class SharingService {
  static final SharingService _instance = SharingService._internal();
  factory SharingService() => _instance;
  SharingService._internal();

  final _supabase = Supabase.instance.client;

  /// Hatırlatıcıyı kullanıcılarla paylaş
  Future<bool> shareReminder(int reminderId, List<String> userEmails) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return false;

      // Kullanıcı ID'lerini email'lerden bul
      final usersResponse = await _supabase
          .from('profiles')
          .select('id')
          .inFilter('email', userEmails);

      if (usersResponse.isEmpty) {
        throw Exception('Kullanıcılar bulunamadı');
      }

      final userIds = (usersResponse as List).map((u) => u['id'] as String).toList();

      // Paylaşım kayıtlarını oluştur
      final shares = userIds.map((userId) => {
        'reminder_id': reminderId,
        'shared_with_user_id': userId,
        'shared_by_user_id': currentUser.id,
        'can_edit': true,
        'created_at': DateTime.now().toIso8601String(),
      }).toList();

      await _supabase.from('reminder_shares').insert(shares);

      // Hatırlatıcıyı paylaşımlı olarak işaretle
      await _supabase
          .from('reminders')
          .update({'is_shared': true})
          .eq('id', reminderId);

      return true;
    } catch (e) {
      print('Hatırlatıcı paylaşma hatası: $e');
      return false;
    }
  }

  /// Hatırlatıcı paylaşımını kaldır
  Future<bool> unshareReminder(int reminderId, String userId) async {
    try {
      await _supabase
          .from('reminder_shares')
          .delete()
          .eq('reminder_id', reminderId)
          .eq('shared_with_user_id', userId);

      // Eğer başka paylaşım yoksa, hatırlatıcıyı paylaşımsız yap
      final remainingShares = await _supabase
          .from('reminder_shares')
          .select()
          .eq('reminder_id', reminderId);

      if (remainingShares.isEmpty) {
        await _supabase
            .from('reminders')
            .update({'is_shared': false})
            .eq('id', reminderId);
      }

      return true;
    } catch (e) {
      print('Paylaşım kaldırma hatası: $e');
      return false;
    }
  }

  /// Paylaşılan hatırlatıcıları getir
  Future<List<Reminder>> getSharedReminders() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return [];

      // Benimle paylaşılan hatırlatıcıları getir
      final response = await _supabase
          .from('reminder_shares')
          .select('reminder_id')
          .eq('shared_with_user_id', currentUser.id);

      if (response.isEmpty) return [];

      final reminderIds = (response as List).map((s) => s['reminder_id'] as int).toList();

      // Hatırlatıcı detaylarını getir
      final remindersResponse = await _supabase
          .from('reminders')
          .select()
          .inFilter('id', reminderIds);

      return (remindersResponse as List)
          .map((data) => Reminder.fromMap(data))
          .toList();
    } catch (e) {
      print('Paylaşılan hatırlatıcıları getirme hatası: $e');
      return [];
    }
  }

  /// Hatırlatıcının paylaşıldığı kullanıcıları getir
  Future<List<Map<String, dynamic>>> getSharedUsers(int reminderId) async {
    try {
      final response = await _supabase
          .from('reminder_shares')
          .select('shared_with_user_id, can_edit, profiles!inner(email, full_name)')
          .eq('reminder_id', reminderId);

      return (response as List).map((share) {
        final profile = share['profiles'];
        return {
          'user_id': share['shared_with_user_id'],
          'email': profile['email'],
          'full_name': profile['full_name'],
          'can_edit': share['can_edit'],
        };
      }).toList();
    } catch (e) {
      print('Paylaşılan kullanıcıları getirme hatası: $e');
      return [];
    }
  }

  /// Kullanıcının düzenleme iznini güncelle
  Future<bool> updateEditPermission(int reminderId, String userId, bool canEdit) async {
    try {
      await _supabase
          .from('reminder_shares')
          .update({'can_edit': canEdit})
          .eq('reminder_id', reminderId)
          .eq('shared_with_user_id', userId);

      return true;
    } catch (e) {
      print('Düzenleme izni güncelleme hatası: $e');
      return false;
    }
  }

  /// Kullanıcının hatırlatıcıyı düzenleme iznini kontrol et
  Future<bool> canEditReminder(int reminderId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return false;

      // Hatırlatıcının sahibi mi kontrol et
      final reminder = await _supabase
          .from('reminders')
          .select('created_by')
          .eq('id', reminderId)
          .single();

      if (reminder['created_by'] == currentUser.id) {
        return true;
      }

      // Paylaşım izni kontrol et
      final share = await _supabase
          .from('reminder_shares')
          .select('can_edit')
          .eq('reminder_id', reminderId)
          .eq('shared_with_user_id', currentUser.id)
          .maybeSingle();

      return share?['can_edit'] ?? false;
    } catch (e) {
      print('Düzenleme izni kontrol hatası: $e');
      return false;
    }
  }

  /// Email ile kullanıcı ara
  Future<List<Map<String, dynamic>>> searchUsersByEmail(String query) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return [];

      final response = await _supabase
          .from('profiles')
          .select('id, email, full_name')
          .ilike('email', '%$query%')
          .neq('id', currentUser.id)
          .limit(10);

      return (response as List).map((user) => {
        'id': user['id'],
        'email': user['email'],
        'full_name': user['full_name'],
      }).toList();
    } catch (e) {
      print('Kullanıcı arama hatası: $e');
      return [];
    }
  }

  /// Paylaşım davetini kabul et
  Future<bool> acceptShareInvitation(int reminderId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return false;

      await _supabase
          .from('reminder_shares')
          .update({'accepted': true})
          .eq('reminder_id', reminderId)
          .eq('shared_with_user_id', currentUser.id);

      return true;
    } catch (e) {
      print('Davet kabul etme hatası: $e');
      return false;
    }
  }

  /// Paylaşım davetini reddet
  Future<bool> rejectShareInvitation(int reminderId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return false;

      await _supabase
          .from('reminder_shares')
          .delete()
          .eq('reminder_id', reminderId)
          .eq('shared_with_user_id', currentUser.id);

      return true;
    } catch (e) {
      print('Davet reddetme hatası: $e');
      return false;
    }
  }

  /// Bekleyen paylaşım davetlerini getir
  Future<List<Map<String, dynamic>>> getPendingInvitations() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return [];

      final response = await _supabase
          .from('reminder_shares')
          .select('reminder_id, shared_by_user_id, created_at, reminders!inner(title, description), profiles!inner(full_name, email)')
          .eq('shared_with_user_id', currentUser.id)
          .eq('accepted', false);

      return (response as List).map((invite) {
        final reminder = invite['reminders'];
        final profile = invite['profiles'];
        return {
          'reminder_id': invite['reminder_id'],
          'reminder_title': reminder['title'],
          'reminder_description': reminder['description'],
          'shared_by_name': profile['full_name'],
          'shared_by_email': profile['email'],
          'created_at': invite['created_at'],
        };
      }).toList();
    } catch (e) {
      print('Bekleyen davetleri getirme hatası: $e');
      return [];
    }
  }
}


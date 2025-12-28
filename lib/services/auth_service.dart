import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Kullanıcı giriş yapmış mı kontrol et
  User? get currentUser => _supabase.auth.currentUser;
  
  bool get isAuthenticated => currentUser != null;

  // Email ve şifre ile giriş
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    try {
      // Önce kullanıcının Google ile kayıt olup olmadığını kontrol et
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      // AuthException'ı daha detaylı hata mesajı ile fırlat
      if (e.message.contains('Invalid login credentials') || 
          e.message.contains('invalid_credentials')) {
        throw Exception('Bu e-posta adresi ile Google ile giriş yapılmış olabilir. Lütfen "Google ile Giriş Yap" butonunu kullanın.');
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // Google ile giriş
  Future<bool> signInWithGoogle() async {
    try {
      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.reminderappv6://login-callback/',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      return response;
    } catch (e) {
      print('Google ile giriş hatası: $e');
      rethrow;
    }
  }


  // Kayıt ol (ad, soyad, email, şifre)
  Future<AuthResponse> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'full_name': '$firstName $lastName',
        },
      );

      // Kullanıcı profil bilgilerini profiles tablosuna kaydet
      // Email confirmation açıksa user null olabilir, bu durumda database trigger ile otomatik oluşturulabilir
      // Ya da email confirmation kapalıysa direkt ekleyebiliriz
      if (response.user != null) {
        try {
          await _supabase.from('profiles').insert({
            'id': response.user!.id,
            'first_name': firstName,
            'last_name': lastName,
            'email': email,
            'full_name': '$firstName $lastName',
          });
        } catch (e) {
          // Profil zaten varsa veya başka bir hata varsa logla ama devam et
          print('Profil oluşturulurken hata (normal olabilir): $e');
        }
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Kullanıcı profil bilgilerini al
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (currentUser == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', currentUser!.id)
          .single();

      return response as Map<String, dynamic>?;
    } catch (e) {
      print('Profil bilgileri alınırken hata: $e');
      return null;
    }
  }

  // Kullanıcı profil bilgilerini güncelle
  Future<void> updateUserProfile({
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    try {
      if (currentUser == null) return;

      final updateData = <String, dynamic>{};
      if (firstName != null) updateData['first_name'] = firstName;
      if (lastName != null) updateData['last_name'] = lastName;
      if (email != null) updateData['email'] = email;
      
      if (firstName != null && lastName != null) {
        updateData['full_name'] = '$firstName $lastName';
      }

      await _supabase
          .from('profiles')
          .update(updateData)
          .eq('id', currentUser!.id);
    } catch (e) {
      print('Profil güncellenirken hata: $e');
      rethrow;
    }
  }

  // Şifre sıfırlama e-postası gönder
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.reminderappv6://reset-password/',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Yeni şifre ile şifreyi güncelle
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Auth state değişikliklerini dinle
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}


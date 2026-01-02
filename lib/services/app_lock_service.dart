import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AppLockService {
  static final AppLockService _instance = AppLockService._internal();
  factory AppLockService() => _instance;
  AppLockService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _pinKey = 'app_lock_pin';
  static const String _lockEnabledKey = 'app_lock_enabled';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _lockTimeoutKey = 'lock_timeout';

  /// Biyometrik donanım var mı kontrol et
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      print('Biyometrik kontrol hatası: $e');
      return false;
    }
  }

  /// Kullanılabilir biyometrik türleri getir
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Biyometrik türleri getirme hatası: $e');
      return [];
    }
  }

  /// Biyometrik kimlik doğrulama yap
  Future<bool> authenticateWithBiometrics() async {
    try {
      final canCheck = await canCheckBiometrics();
      if (!canCheck) return false;

      return await _localAuth.authenticate(
        localizedReason: 'Uygulamaya erişmek için kimliğinizi doğrulayın',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      print('Biyometrik kimlik doğrulama hatası: $e');
      return false;
    }
  }

  /// PIN kodu ayarla
  Future<bool> setPin(String pin) async {
    try {
      if (pin.length < 4) {
        throw Exception('PIN en az 4 karakter olmalıdır');
      }

      // PIN'i hash'le ve sakla
      final hashedPin = _hashPin(pin);
      await _secureStorage.write(key: _pinKey, value: hashedPin);
      return true;
    } catch (e) {
      print('PIN ayarlama hatası: $e');
      return false;
    }
  }

  /// PIN kodunu doğrula
  Future<bool> verifyPin(String pin) async {
    try {
      final storedPin = await _secureStorage.read(key: _pinKey);
      if (storedPin == null) return false;

      final hashedPin = _hashPin(pin);
      return storedPin == hashedPin;
    } catch (e) {
      print('PIN doğrulama hatası: $e');
      return false;
    }
  }

  /// PIN kodunu sil
  Future<bool> deletePin() async {
    try {
      await _secureStorage.delete(key: _pinKey);
      return true;
    } catch (e) {
      print('PIN silme hatası: $e');
      return false;
    }
  }

  /// PIN var mı kontrol et
  Future<bool> hasPin() async {
    try {
      final pin = await _secureStorage.read(key: _pinKey);
      return pin != null;
    } catch (e) {
      print('PIN kontrol hatası: $e');
      return false;
    }
  }

  /// Uygulama kilidi aktif mi
  Future<bool> isLockEnabled() async {
    try {
      final enabled = await _secureStorage.read(key: _lockEnabledKey);
      return enabled == 'true';
    } catch (e) {
      print('Kilit durumu kontrol hatası: $e');
      return false;
    }
  }

  /// Uygulama kilidini aç/kapat
  Future<bool> setLockEnabled(bool enabled) async {
    try {
      await _secureStorage.write(
        key: _lockEnabledKey,
        value: enabled.toString(),
      );
      return true;
    } catch (e) {
      print('Kilit durumu ayarlama hatası: $e');
      return false;
    }
  }

  /// Biyometrik kilit aktif mi
  Future<bool> isBiometricEnabled() async {
    try {
      final enabled = await _secureStorage.read(key: _biometricEnabledKey);
      return enabled == 'true';
    } catch (e) {
      print('Biyometrik durum kontrol hatası: $e');
      return false;
    }
  }

  /// Biyometrik kilidi aç/kapat
  Future<bool> setBiometricEnabled(bool enabled) async {
    try {
      // Biyometrik donanım var mı kontrol et
      if (enabled) {
        final canCheck = await canCheckBiometrics();
        if (!canCheck) {
          throw Exception('Biyometrik donanım bulunamadı');
        }
      }

      await _secureStorage.write(
        key: _biometricEnabledKey,
        value: enabled.toString(),
      );
      return true;
    } catch (e) {
      print('Biyometrik durum ayarlama hatası: $e');
      return false;
    }
  }

  /// Kilit zaman aşımını ayarla (dakika)
  Future<bool> setLockTimeout(int minutes) async {
    try {
      await _secureStorage.write(
        key: _lockTimeoutKey,
        value: minutes.toString(),
      );
      return true;
    } catch (e) {
      print('Kilit zaman aşımı ayarlama hatası: $e');
      return false;
    }
  }

  /// Kilit zaman aşımını getir (dakika)
  Future<int> getLockTimeout() async {
    try {
      final timeout = await _secureStorage.read(key: _lockTimeoutKey);
      return int.tryParse(timeout ?? '5') ?? 5;
    } catch (e) {
      print('Kilit zaman aşımı getirme hatası: $e');
      return 5;
    }
  }

  /// PIN'i hash'le
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Kimlik doğrulama yap (PIN veya Biyometrik)
  Future<bool> authenticate() async {
    try {
      final lockEnabled = await isLockEnabled();
      if (!lockEnabled) return true;

      // Önce biyometrik dene
      final biometricEnabled = await isBiometricEnabled();
      if (biometricEnabled) {
        final authenticated = await authenticateWithBiometrics();
        if (authenticated) return true;
      }

      // Biyometrik başarısız olursa PIN'e dön
      return false; // UI'da PIN ekranı gösterilecek
    } catch (e) {
      print('Kimlik doğrulama hatası: $e');
      return false;
    }
  }

  /// Tüm kilit ayarlarını sıfırla
  Future<bool> resetLock() async {
    try {
      await _secureStorage.delete(key: _pinKey);
      await _secureStorage.delete(key: _lockEnabledKey);
      await _secureStorage.delete(key: _biometricEnabledKey);
      await _secureStorage.delete(key: _lockTimeoutKey);
      return true;
    } catch (e) {
      print('Kilit sıfırlama hatası: $e');
      return false;
    }
  }

  /// Son aktiflik zamanını kaydet
  Future<void> updateLastActiveTime() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch.toString();
      await _secureStorage.write(key: 'last_active_time', value: now);
    } catch (e) {
      print('Son aktiflik zamanı güncelleme hatası: $e');
    }
  }

  /// Kilitleme gerekli mi kontrol et
  Future<bool> shouldLock() async {
    try {
      final lockEnabled = await isLockEnabled();
      if (!lockEnabled) return false;

      final lastActiveStr = await _secureStorage.read(key: 'last_active_time');
      if (lastActiveStr == null) return true;

      final lastActive = int.tryParse(lastActiveStr);
      if (lastActive == null) return true;

      final timeout = await getLockTimeout();
      final now = DateTime.now().millisecondsSinceEpoch;
      final diff = now - lastActive;
      final diffMinutes = diff / (1000 * 60);

      return diffMinutes >= timeout;
    } catch (e) {
      print('Kilitleme kontrolü hatası: $e');
      return false;
    }
  }
}


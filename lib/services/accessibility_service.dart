import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FontSizeOption { small, normal, large, extraLarge }
enum ContrastMode { normal, high }

class AccessibilityService {
  static final AccessibilityService _instance = AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  static const String _fontSizeKey = 'accessibility_font_size';
  static const String _contrastModeKey = 'accessibility_contrast_mode';
  static const String _voiceOverEnabledKey = 'accessibility_voice_over';
  static const String _reduceAnimationsKey = 'accessibility_reduce_animations';
  static const String _boldTextKey = 'accessibility_bold_text';

  /// Font boyutunu ayarla
  Future<bool> setFontSize(FontSizeOption size) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fontSizeKey, size.name);
      return true;
    } catch (e) {
      print('Font boyutu ayarlama hatası: $e');
      return false;
    }
  }

  /// Font boyutunu getir
  Future<FontSizeOption> getFontSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sizeStr = prefs.getString(_fontSizeKey);
      return FontSizeOption.values.firstWhere(
        (e) => e.name == sizeStr,
        orElse: () => FontSizeOption.normal,
      );
    } catch (e) {
      print('Font boyutu getirme hatası: $e');
      return FontSizeOption.normal;
    }
  }

  /// Font boyutu çarpanını getir
  double getFontSizeMultiplier(FontSizeOption size) {
    switch (size) {
      case FontSizeOption.small:
        return 0.85;
      case FontSizeOption.normal:
        return 1.0;
      case FontSizeOption.large:
        return 1.15;
      case FontSizeOption.extraLarge:
        return 1.3;
    }
  }

  /// Kontrast modunu ayarla
  Future<bool> setContrastMode(ContrastMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_contrastModeKey, mode.name);
      return true;
    } catch (e) {
      print('Kontrast modu ayarlama hatası: $e');
      return false;
    }
  }

  /// Kontrast modunu getir
  Future<ContrastMode> getContrastMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = prefs.getString(_contrastModeKey);
      return ContrastMode.values.firstWhere(
        (e) => e.name == modeStr,
        orElse: () => ContrastMode.normal,
      );
    } catch (e) {
      print('Kontrast modu getirme hatası: $e');
      return ContrastMode.normal;
    }
  }

  /// Voice Over'ı aç/kapat
  Future<bool> setVoiceOverEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_voiceOverEnabledKey, enabled);
      return true;
    } catch (e) {
      print('Voice Over ayarlama hatası: $e');
      return false;
    }
  }

  /// Voice Over aktif mi
  Future<bool> isVoiceOverEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_voiceOverEnabledKey) ?? false;
    } catch (e) {
      print('Voice Over kontrol hatası: $e');
      return false;
    }
  }

  /// Animasyonları azalt
  Future<bool> setReduceAnimations(bool reduce) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_reduceAnimationsKey, reduce);
      return true;
    } catch (e) {
      print('Animasyon azaltma ayarlama hatası: $e');
      return false;
    }
  }

  /// Animasyonlar azaltılmış mı
  Future<bool> shouldReduceAnimations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_reduceAnimationsKey) ?? false;
    } catch (e) {
      print('Animasyon azaltma kontrol hatası: $e');
      return false;
    }
  }

  /// Kalın yazı tipi
  Future<bool> setBoldText(bool bold) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_boldTextKey, bold);
      return true;
    } catch (e) {
      print('Kalın yazı ayarlama hatası: $e');
      return false;
    }
  }

  /// Kalın yazı aktif mi
  Future<bool> isBoldTextEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_boldTextKey) ?? false;
    } catch (e) {
      print('Kalın yazı kontrol hatası: $e');
      return false;
    }
  }

  /// Yüksek kontrast renk şeması
  ColorScheme getHighContrastColorScheme(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const ColorScheme.light(
        primary: Colors.black,
        onPrimary: Colors.white,
        secondary: Colors.black87,
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black,
        error: Colors.red,
        onError: Colors.white,
      );
    } else {
      return const ColorScheme.dark(
        primary: Colors.white,
        onPrimary: Colors.black,
        secondary: Colors.white70,
        onSecondary: Colors.black,
        surface: Colors.black,
        onSurface: Colors.white,
        error: Colors.redAccent,
        onError: Colors.black,
      );
    }
  }

  /// Erişilebilir tema oluştur
  Future<ThemeData> buildAccessibleTheme({
    required Brightness brightness,
    required ColorScheme baseColorScheme,
  }) async {
    final fontSize = await getFontSize();
    final fontMultiplier = getFontSizeMultiplier(fontSize);
    final contrastMode = await getContrastMode();
    final boldText = await isBoldTextEnabled();

    final colorScheme = contrastMode == ContrastMode.high
        ? getHighContrastColorScheme(brightness)
        : baseColorScheme;

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 57 * fontMultiplier,
          fontWeight: boldText ? FontWeight.bold : FontWeight.normal,
        ),
        displayMedium: TextStyle(
          fontSize: 45 * fontMultiplier,
          fontWeight: boldText ? FontWeight.bold : FontWeight.normal,
        ),
        displaySmall: TextStyle(
          fontSize: 36 * fontMultiplier,
          fontWeight: boldText ? FontWeight.bold : FontWeight.normal,
        ),
        headlineLarge: TextStyle(
          fontSize: 32 * fontMultiplier,
          fontWeight: boldText ? FontWeight.bold : FontWeight.normal,
        ),
        headlineMedium: TextStyle(
          fontSize: 28 * fontMultiplier,
          fontWeight: boldText ? FontWeight.bold : FontWeight.normal,
        ),
        headlineSmall: TextStyle(
          fontSize: 24 * fontMultiplier,
          fontWeight: boldText ? FontWeight.bold : FontWeight.normal,
        ),
        titleLarge: TextStyle(
          fontSize: 22 * fontMultiplier,
          fontWeight: boldText ? FontWeight.bold : FontWeight.w500,
        ),
        titleMedium: TextStyle(
          fontSize: 16 * fontMultiplier,
          fontWeight: boldText ? FontWeight.bold : FontWeight.w500,
        ),
        titleSmall: TextStyle(
          fontSize: 14 * fontMultiplier,
          fontWeight: boldText ? FontWeight.bold : FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          fontSize: 16 * fontMultiplier,
          fontWeight: boldText ? FontWeight.w600 : FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          fontSize: 14 * fontMultiplier,
          fontWeight: boldText ? FontWeight.w600 : FontWeight.normal,
        ),
        bodySmall: TextStyle(
          fontSize: 12 * fontMultiplier,
          fontWeight: boldText ? FontWeight.w600 : FontWeight.normal,
        ),
        labelLarge: TextStyle(
          fontSize: 14 * fontMultiplier,
          fontWeight: boldText ? FontWeight.bold : FontWeight.w500,
        ),
        labelMedium: TextStyle(
          fontSize: 12 * fontMultiplier,
          fontWeight: boldText ? FontWeight.bold : FontWeight.w500,
        ),
        labelSmall: TextStyle(
          fontSize: 11 * fontMultiplier,
          fontWeight: boldText ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }

  /// Animasyon süresi
  Future<Duration> getAnimationDuration(Duration defaultDuration) async {
    final reduce = await shouldReduceAnimations();
    return reduce ? Duration.zero : defaultDuration;
  }

  /// Semantik etiket oluştur
  String buildSemanticLabel({
    required String text,
    String? hint,
    bool isButton = false,
    bool isSelected = false,
  }) {
    final buffer = StringBuffer(text);
    
    if (isButton) {
      buffer.write(', düğme');
    }
    
    if (isSelected) {
      buffer.write(', seçili');
    }
    
    if (hint != null && hint.isNotEmpty) {
      buffer.write(', $hint');
    }
    
    return buffer.toString();
  }

  /// Tüm erişilebilirlik ayarlarını sıfırla
  Future<bool> resetAllSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_fontSizeKey);
      await prefs.remove(_contrastModeKey);
      await prefs.remove(_voiceOverEnabledKey);
      await prefs.remove(_reduceAnimationsKey);
      await prefs.remove(_boldTextKey);
      return true;
    } catch (e) {
      print('Erişilebilirlik ayarları sıfırlama hatası: $e');
      return false;
    }
  }

  /// Erişilebilirlik ayarlarını dışa aktar
  Future<Map<String, dynamic>> exportSettings() async {
    try {
      final fontSize = await getFontSize();
      final contrastMode = await getContrastMode();
      final voiceOver = await isVoiceOverEnabled();
      final reduceAnimations = await shouldReduceAnimations();
      final boldText = await isBoldTextEnabled();

      return {
        'fontSize': fontSize.name,
        'contrastMode': contrastMode.name,
        'voiceOver': voiceOver,
        'reduceAnimations': reduceAnimations,
        'boldText': boldText,
      };
    } catch (e) {
      print('Erişilebilirlik ayarları dışa aktarma hatası: $e');
      return {};
    }
  }

  /// Erişilebilirlik ayarlarını içe aktar
  Future<bool> importSettings(Map<String, dynamic> settings) async {
    try {
      if (settings.containsKey('fontSize')) {
        final fontSize = FontSizeOption.values.firstWhere(
          (e) => e.name == settings['fontSize'],
          orElse: () => FontSizeOption.normal,
        );
        await setFontSize(fontSize);
      }

      if (settings.containsKey('contrastMode')) {
        final contrastMode = ContrastMode.values.firstWhere(
          (e) => e.name == settings['contrastMode'],
          orElse: () => ContrastMode.normal,
        );
        await setContrastMode(contrastMode);
      }

      if (settings.containsKey('voiceOver')) {
        await setVoiceOverEnabled(settings['voiceOver'] as bool);
      }

      if (settings.containsKey('reduceAnimations')) {
        await setReduceAnimations(settings['reduceAnimations'] as bool);
      }

      if (settings.containsKey('boldText')) {
        await setBoldText(settings['boldText'] as bool);
      }

      return true;
    } catch (e) {
      print('Erişilebilirlik ayarları içe aktarma hatası: $e');
      return false;
    }
  }
}


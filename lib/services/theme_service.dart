import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static final ThemeService instance = ThemeService._init();
  static const String _themeColorKey = 'theme_color';
  
  ThemeService._init();

  // Tema renkleri
  static const Map<String, Color> themeColors = {
    'Purple': Color(0xFF6C5CE7),
    'Blue': Color(0xFF4C63D2),
    'Teal': Color(0xFF00B8D4),
    'Green': Color(0xFF00C853),
    'Orange': Color(0xFFFF6B35),
    'Pink': Color(0xFFE91E63),
    'Red': Color(0xFFD32F2F),
    'Indigo': Color(0xFF3F51B5),
  };

  // Varsayılan renk
  Color get defaultColor => themeColors['Purple']!;

  // Mevcut tema rengini al
  Future<Color> getThemeColor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final colorName = prefs.getString(_themeColorKey) ?? 'Purple';
      return themeColors[colorName] ?? defaultColor;
    } catch (e) {
      return defaultColor;
    }
  }

  // Tema rengini kaydet
  Future<void> setThemeColor(String colorName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeColorKey, colorName);
    } catch (e) {
      print('Tema rengi kaydedilirken hata: $e');
    }
  }

  // Gradient renkleri oluştur
  List<Color> getGradientColors(Color primaryColor) {
    // Primary color'a göre gradient oluştur
    if (primaryColor == themeColors['Purple']) {
      return [
        const Color(0xFF6C5CE7),
        const Color(0xFF5F3DC4),
        const Color(0xFF4C63D2),
        const Color(0xFF00B8D4),
      ];
    } else if (primaryColor == themeColors['Blue']) {
      return [
        const Color(0xFF4C63D2),
        const Color(0xFF3F51B5),
        const Color(0xFF5C6BC0),
        const Color(0xFF00B8D4),
      ];
    } else if (primaryColor == themeColors['Teal']) {
      return [
        const Color(0xFF00B8D4),
        const Color(0xFF00ACC1),
        const Color(0xFF0097A7),
        const Color(0xFF00838F),
      ];
    } else if (primaryColor == themeColors['Green']) {
      return [
        const Color(0xFF00C853),
        const Color(0xFF00B248),
        const Color(0xFF009624),
        const Color(0xFF00B8D4),
      ];
    } else if (primaryColor == themeColors['Orange']) {
      return [
        const Color(0xFFFF6B35),
        const Color(0xFFFF5722),
        const Color(0xFFE64A19),
        const Color(0xFFFF9800),
      ];
    } else if (primaryColor == themeColors['Pink']) {
      return [
        const Color(0xFFE91E63),
        const Color(0xFFC2185B),
        const Color(0xFFAD1457),
        const Color(0xFFF06292),
      ];
    } else if (primaryColor == themeColors['Red']) {
      return [
        const Color(0xFFD32F2F),
        const Color(0xFFC62828),
        const Color(0xFFB71C1C),
        const Color(0xFFE53935),
      ];
    } else if (primaryColor == themeColors['Indigo']) {
      return [
        const Color(0xFF3F51B5),
        const Color(0xFF303F9F),
        const Color(0xFF283593),
        const Color(0xFF5C6BC0),
      ];
    }
    
    // Varsayılan gradient
    return [
      primaryColor,
      primaryColor.withOpacity(0.8),
      primaryColor.withOpacity(0.6),
      primaryColor.withOpacity(0.4),
    ];
  }
}


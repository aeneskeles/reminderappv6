/// Türkçe karakter desteği için yardımcı fonksiyonlar
class TurkishCharUtils {
  /// Türkçe karakterleri normalize eder (büyük/küçük harf duyarsız arama için)
  static String normalizeTurkish(String text) {
    return text
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .replaceAll('Ğ', 'ğ')
        .replaceAll('Ü', 'ü')
        .replaceAll('Ş', 'ş')
        .replaceAll('Ö', 'ö')
        .replaceAll('Ç', 'ç')
        .toLowerCase();
  }

  /// Türkçe karakterleri içeren metinleri karşılaştırır
  static bool containsTurkish(String text, String query) {
    final normalizedText = normalizeTurkish(text);
    final normalizedQuery = normalizeTurkish(query);
    return normalizedText.contains(normalizedQuery);
  }

  /// Türkçe karakterleri içeren metinleri eşitlik kontrolü yapar
  static bool equalsTurkish(String text1, String text2) {
    return normalizeTurkish(text1) == normalizeTurkish(text2);
  }
}


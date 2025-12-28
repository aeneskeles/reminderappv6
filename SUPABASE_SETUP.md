# Supabase Kurulum Rehberi

## 1. Supabase Projesi Oluşturma

1. [Supabase](https://supabase.com) sitesine gidin
2. Yeni bir proje oluşturun
3. Proje URL'sini ve anon key'i kopyalayın

## 2. Yapılandırma

`lib/config/supabase_config.dart` dosyasını açın ve kendi bilgilerinizi girin:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key-here';
}
```

## 3. Veritabanı Tablosu Oluşturma

1. Supabase Dashboard'a gidin
2. SQL Editor'ü açın
3. `supabase_setup.sql` dosyasındaki SQL kodunu çalıştırın

Bu SQL kodu:
- `profiles` tablosunu oluşturur
- Row Level Security (RLS) politikalarını ayarlar
- Kullanıcıların sadece kendi bilgilerini görmesini sağlar

## 4. Authentication Ayarları

Supabase Dashboard > Authentication > Settings'den:

1. **Email Auth**'u etkinleştirin
2. **Confirm email** ayarını isteğinize göre yapın (geliştirme için kapatabilirsiniz)
3. **Site URL**'i ayarlayın

## 5. Paketleri Yükleme

```bash
flutter pub get
```

## 6. Uygulamayı Çalıştırma

```bash
flutter run
```

## Önemli Notlar

- Supabase URL ve anon key bilgilerinizi asla public repository'lere commit etmeyin
- Production için environment variables kullanın
- Email confirmation'ı production'da mutlaka açın


# Hatırlatıcı Uygulaması (Reminder App)

Flutter ile geliştirilmiş kapsamlı hatırlatıcı uygulaması. Supabase ile authentication ve veri saklama özellikleri içerir.

## Özellikler

### 📌 Hatırlatıcı Yönetimi
- ✅ Hatırlatıcı oluşturma (Başlık, Açıklama, Tarih & Saat)
- ✅ Tek seferlik / Tekrar eden hatırlatıcılar
- ✅ Kategori/Etiket sistemi (Genel, Okul, İş, Sağlık)
- ✅ CRUD işlemleri (Oluştur, Oku, Güncelle, Sil)
- ✅ Tamamlanma durumu takibi

### 🔔 Bildirim Sistemi
- ✅ Zamanında push notification
- ✅ Gecikme / yeniden dene mantığı
- ✅ Android ve iOS desteği

### 🔍 Arama ve Filtreleme
- ✅ Metin araması (Başlık, Açıklama, Kategori)
- ✅ Durum filtresi (Tümü, Aktif, Tamamlanan)
- ✅ Kategori filtresi
- ✅ Tarih gösterimi ve sıralama

### 🔐 Authentication
- ✅ Email/Şifre ile giriş
- ✅ Google OAuth ile giriş
- ✅ Kayıt ol (Ad, Soyad, Email, Şifre)
- ✅ Kullanıcı profil yönetimi
- ✅ Güvenli çıkış

## Kurulum

### Gereksinimler
- Flutter SDK (3.10.1 veya üzeri)
- Dart SDK
- Android Studio / VS Code
- Supabase hesabı

### Adımlar

1. **Repository'yi klonlayın**
```bash
git clone https://github.com/kullaniciadi/reminderappv6.git
cd reminderappv6
```

2. **Bağımlılıkları yükleyin**
```bash
flutter pub get
```

3. **Supabase Yapılandırması**
   - `lib/config/supabase_config.dart` dosyasını oluşturun
   - Supabase URL ve anon key'inizi ekleyin
   - Detaylı kurulum için `SUPABASE_SETUP.md` dosyasına bakın

4. **Veritabanı Kurulumu**
   - Supabase Dashboard > SQL Editor
   - `supabase_setup.sql` dosyasındaki SQL'i çalıştırın

5. **Google OAuth Kurulumu** (Opsiyonel)
   - Detaylı kurulum için `GOOGLE_OAUTH_SETUP.md` dosyasına bakın

6. **Uygulamayı çalıştırın**
```bash
flutter run
```

## Kullanılan Teknolojiler

- **Flutter** - UI Framework
- **Supabase** - Backend (Authentication & Database)
- **sqflite** - Yerel veritabanı (mobil)
- **shared_preferences** - Yerel veri saklama (web)
- **flutter_local_notifications** - Bildirimler
- **intl** - Tarih formatlama

## Proje Yapısı

```
lib/
├── config/
│   └── supabase_config.dart      # Supabase yapılandırması
├── models/
│   └── reminder.dart             # Hatırlatıcı modeli
├── screens/
│   ├── login_screen.dart         # Giriş ekranı
│   ├── register_screen.dart      # Kayıt ekranı
│   ├── home_screen.dart          # Ana ekran
│   └── add_edit_reminder_screen.dart  # Hatırlatıcı ekleme/düzenleme
└── services/
    ├── auth_service.dart         # Authentication servisi
    ├── database_helper.dart      # Veritabanı helper
    └── notification_service.dart # Bildirim servisi
```

## Önemli Notlar

⚠️ **Güvenlik**: `lib/config/supabase_config.dart` dosyası `.gitignore`'a eklenmiştir. Bu dosya hassas bilgiler içerir ve asla commit edilmemelidir.

📝 **Yapılandırma**: Projeyi kullanmadan önce mutlaka Supabase yapılandırmasını tamamlayın.

## Lisans

Bu proje eğitim amaçlı geliştirilmiştir.

## Katkıda Bulunma

Pull request'ler memnuniyetle karşılanır. Büyük değişiklikler için önce bir issue açarak neyi değiştirmek istediğinizi tartışın.

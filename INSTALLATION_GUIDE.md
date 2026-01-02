# Kurulum Rehberi - İleri Seviye Özellikler

Bu rehber, uygulamaya eklenen ileri seviye özelliklerin kurulumu için gerekli adımları içerir.

## 📋 Gereksinimler

- Flutter SDK 3.10.1 veya üzeri
- Dart SDK 3.10.1 veya üzeri
- Android Studio / Xcode
- Supabase hesabı
- Firebase hesabı (opsiyonel - push notification için)

## 🚀 Kurulum Adımları

### 1. Paketleri Yükle

```bash
flutter pub get
```

### 2. Supabase Veritabanı Yapılandırması

Supabase Dashboard'unuzda SQL Editor'ü açın ve aşağıdaki dosyayı çalıştırın:

```bash
supabase_advanced_features_migration.sql
```

Bu dosya şunları oluşturacak:
- Yeni tablo: `reminder_shares`
- Yeni alanlar: `is_favorite`, `attachments`, `shared_with`, `is_shared`, `created_by`
- Fonksiyonlar: `share_reminder`, `unshare_reminder`, `get_favorite_reminders`, vb.
- View'lar: `reminder_share_details`
- Index'ler ve RLS politikaları

### 3. Android Yapılandırması

#### 3.1. İzinler (Otomatik Eklendi)
`android/app/src/main/AndroidManifest.xml` dosyasına aşağıdaki izinler eklendi:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<uses-permission android:name="android.permission.USE_FINGERPRINT"/>
```

#### 3.2. Minimum SDK Versiyonu
`android/app/build.gradle.kts` dosyasında minimum SDK versiyonunu kontrol edin:

```kotlin
minSdk = 21  // En az 21 olmalı
```

#### 3.3. ProGuard Kuralları (Release için)
`android/app/proguard-rules.pro` dosyası oluşturun:

```proguard
# Speech to Text
-keep class com.google.android.gms.** { *; }

# Local Auth
-keep class androidx.biometric.** { *; }

# Image Picker
-keep class io.flutter.plugins.imagepicker.** { *; }
```

### 4. iOS Yapılandırması

#### 4.1. İzinler (Otomatik Eklendi)
`ios/Runner/Info.plist` dosyasına aşağıdaki izinler eklendi:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Sesli hatırlatıcı eklemek için mikrofon erişimi gerekli</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>Sesli komutları tanımak için konuşma tanıma erişimi gerekli</string>

<key>NSCameraUsageDescription</key>
<string>Hatırlatıcılara fotoğraf eklemek için kamera erişimi gerekli</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Hatırlatıcılara fotoğraf eklemek için galeri erişimi gerekli</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>Fotoğrafları kaydetmek için galeri erişimi gerekli</string>

<key>NSFaceIDUsageDescription</key>
<string>Uygulamayı güvenli bir şekilde açmak için Face ID kullanılacak</string>
```

#### 4.2. Minimum iOS Versiyonu
`ios/Podfile` dosyasında minimum iOS versiyonunu kontrol edin:

```ruby
platform :ios, '12.0'  # En az 12.0 olmalı
```

#### 4.3. Pod Kurulumu
```bash
cd ios
pod install
cd ..
```

### 5. Eklenen Paketler

Aşağıdaki paketler `pubspec.yaml` dosyasına eklendi:

```yaml
dependencies:
  # Speech to Text
  speech_to_text: ^7.0.0
  permission_handler: ^11.3.1
  
  # Image & File Picker
  image_picker: ^1.1.2
  file_picker: ^8.1.4
  
  # Charts & Statistics
  fl_chart: ^0.69.2
  
  # Security (Biometric & PIN)
  local_auth: ^2.3.0
  flutter_secure_storage: ^9.2.2
  
  # Home Screen Widget
  home_widget: ^0.7.0
  
  # Share functionality
  share_plus: ^10.1.2
  
  # Image handling
  cached_network_image: ^3.4.1
  image: ^4.3.0
  
  # Crypto for PIN hashing
  crypto: ^3.0.5
```

### 6. Oluşturulan Servisler

Aşağıdaki servisler `lib/services/` klasörüne eklendi:

1. **speech_service.dart** - Sesli hatırlatıcı ekleme
2. **attachment_service.dart** - Dosya ve görsel ekleme
3. **sharing_service.dart** - Hatırlatıcı paylaşımı
4. **statistics_service.dart** - İstatistik hesaplamaları
5. **app_lock_service.dart** - Uygulama kilidi (PIN/Biometric)
6. **notification_history_service.dart** - Bildirim geçmişi
7. **widget_service.dart** - Ana sayfa widget'ı
8. **accessibility_service.dart** - Erişilebilirlik özellikleri

### 7. Oluşturulan Ekranlar

Aşağıdaki ekranlar `lib/screens/` klasörüne eklendi:

1. **statistics_screen.dart** - İstatistik ve grafikler
2. **notification_history_screen.dart** - Bildirim geçmişi
3. **app_lock_screen.dart** - Kilit ekranı
4. **app_lock_settings_screen.dart** - Kilit ayarları
5. **accessibility_settings_screen.dart** - Erişilebilirlik ayarları

### 8. Veritabanı Güncellemeleri

#### Local Database (SQLite)
`lib/services/local_database_helper.dart` dosyası güncellendi:
- Veritabanı versiyonu 1'den 2'ye yükseltildi
- Yeni alanlar eklendi: `is_favorite`, `attachments`, `shared_with`, `is_shared`, `created_by`
- Migration fonksiyonu eklendi

#### Supabase Database
Yukarıda belirtilen SQL migration dosyasını çalıştırın.

## 🧪 Test Etme

### 1. Uygulamayı Çalıştır

```bash
flutter run
```

### 2. Özellikleri Test Et

#### Sesli Hatırlatıcı:
1. Hatırlatıcı ekleme ekranında mikrofon butonuna tıklayın
2. "Yarın saat 10'da toplantı" gibi bir komut verin
3. Sistemin metni tanıdığını kontrol edin

#### Dosya Ekleme:
1. Hatırlatıcı ekleme/düzenleme ekranında ek butonuna tıklayın
2. Kamera veya galeri seçin
3. Fotoğraf eklendiğini kontrol edin

#### Hatırlatıcı Paylaşma:
1. Bir hatırlatıcıyı açın
2. Paylaş butonuna tıklayın
3. Email adresi girin ve paylaşın
4. Diğer kullanıcının hesabında hatırlatıcının göründüğünü kontrol edin

#### İstatistikler:
1. Ayarlar > İstatistikler'e gidin
2. Grafiklerin yüklendiğini kontrol edin

#### Uygulama Kilidi:
1. Ayarlar > Uygulama Kilidi'ne gidin
2. PIN oluşturun
3. Uygulamayı kapatıp açın
4. Kilit ekranının göründüğünü kontrol edin

#### Erişilebilirlik:
1. Ayarlar > Erişilebilirlik'e gidin
2. Yazı boyutunu değiştirin
3. Uygulamanın yeniden başlatılmasını bekleyin
4. Değişikliklerin uygulandığını kontrol edin

## 🐛 Sorun Giderme

### Paket Yükleme Hataları

```bash
flutter clean
flutter pub get
```

### iOS Pod Hataları

```bash
cd ios
pod deintegrate
pod install
cd ..
```

### Android Build Hataları

```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter build apk
```

### İzin Hataları

Eğer izinler çalışmıyorsa:
1. Uygulamayı tamamen silin
2. Yeniden yükleyin
3. İzinleri manuel olarak verin (Ayarlar > Uygulamalar > İzinler)

### Veritabanı Migration Hataları

Eğer migration başarısız olursa:
1. Supabase Dashboard'da SQL Editor'ü açın
2. Migration dosyasını satır satır çalıştırın
3. Hata mesajlarını kontrol edin
4. Gerekirse tabloları manuel olarak oluşturun

## 📱 Platform Özgü Notlar

### Android

- **Minimum SDK:** 21 (Android 5.0)
- **Target SDK:** 34 (Android 14)
- **Speech Recognition:** Google Play Services gerektirir
- **Biometric:** Android 6.0+ için parmak izi, Android 10+ için yüz tanıma

### iOS

- **Minimum iOS:** 12.0
- **Speech Recognition:** iOS 13+ için en iyi çalışır
- **Biometric:** Touch ID (iPhone 5s+), Face ID (iPhone X+)
- **Widget:** iOS 14+ gerektirir

## 🔐 Güvenlik Notları

1. **PIN Saklama:** PIN'ler SHA-256 ile hash'lenerek `flutter_secure_storage` ile saklanır
2. **Biyometrik:** Sistem biyometrik API'leri kullanılır, veri saklanmaz
3. **Dosyalar:** Dosyalar uygulama dizininde saklanır, şifrelenmez
4. **Paylaşım:** RLS politikaları ile korunur

## 📊 Performans Optimizasyonu

1. **Büyük Dosyalar:** 10MB'dan büyük dosyalar yüklenemez
2. **Görsel Önbellek:** `cached_network_image` kullanılır
3. **Veritabanı:** Index'ler eklendi
4. **Widget:** Sadece gerekli veriler güncellenir

## 🔄 Güncelleme Notları

Mevcut bir uygulamayı güncelliyorsanız:

1. **Veritabanı:** Migration otomatik çalışır (local)
2. **Supabase:** Migration dosyasını manuel çalıştırın
3. **Kullanıcı Verileri:** Korunur
4. **Ayarlar:** Sıfırlanmaz

## 📞 Destek

Sorun yaşarsanız:
1. Loglara bakın: `flutter logs`
2. Hata mesajlarını kontrol edin
3. GitHub Issues'da arayın
4. Yeni issue açın

## ✅ Kontrol Listesi

Kurulum tamamlandıktan sonra:

- [ ] `flutter pub get` çalıştırıldı
- [ ] Supabase migration çalıştırıldı
- [ ] Android izinleri eklendi
- [ ] iOS izinleri eklendi
- [ ] Uygulama başarıyla derlendi
- [ ] Tüm özellikler test edildi
- [ ] İzinler doğru çalışıyor
- [ ] Veritabanı migration başarılı

## 🎉 Tamamlandı!

Artık tüm ileri seviye özellikler kullanıma hazır!

Detaylı kullanım için `ADVANCED_FEATURES.md` dosyasına bakın.


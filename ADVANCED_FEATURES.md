# İleri Seviye Özellikler Dokümantasyonu

Bu dokümantasyon, Hatırlatıcı Uygulamasına eklenen ileri seviye özellikleri açıklar.

## 🎤 Sesli Hatırlatıcı Ekleme (Speech to Text)

### Özellikler:
- Mikrofon ile sesli komut verme
- Türkçe dil desteği
- Gerçek zamanlı ses tanıma
- Otomatik izin yönetimi

### Kullanım:
```dart
import '../services/speech_service.dart';

final speechService = SpeechService();

// Dinlemeyi başlat
await speechService.startListening(
  onResult: (text) {
    print('Tanınan metin: $text');
  },
  localeId: 'tr_TR',
);

// Dinlemeyi durdur
await speechService.stopListening();
```

### Gerekli İzinler:
- Android: `android.permission.RECORD_AUDIO`
- iOS: `NSMicrophoneUsageDescription` (Info.plist)

---

## ⭐ Favori Hatırlatıcılar

### Özellikler:
- Hatırlatıcıları favori olarak işaretleme
- Favori hatırlatıcıları filtreleme
- Hızlı erişim için favori listesi

### Kullanım:
```dart
// Favori durumunu değiştir
await _dbHelper.toggleFavorite(reminderId);

// Favori hatırlatıcıları getir
final favorites = await _dbHelper.getFavoriteReminders();
```

---

## 📎 Hatırlatıcıya Görsel/Dosya Ekleme

### Özellikler:
- Kameradan fotoğraf çekme
- Galeriden fotoğraf seçme
- Dosya ekleme (PDF, DOC, vb.)
- Çoklu dosya desteği
- Otomatik dosya boyutu kontrolü (max 10MB)

### Kullanım:
```dart
import '../services/attachment_service.dart';

final attachmentService = AttachmentService();

// Kameradan fotoğraf çek
final photoPath = await attachmentService.takePhoto();

// Galeriden fotoğraf seç
final imagePath = await attachmentService.pickImage();

// Dosya seç
final filePath = await attachmentService.pickFile();

// Çoklu fotoğraf seç
final imagePaths = await attachmentService.pickMultipleImages();

// Dosyayı sil
await attachmentService.deleteFile(filePath);
```

### Gerekli İzinler:
- Android: `CAMERA`, `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`
- iOS: `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`

---

## 👥 Paylaşılabilir / Ortak Hatırlatıcılar

### Özellikler:
- Hatırlatıcıları diğer kullanıcılarla paylaşma
- Düzenleme izni yönetimi
- Paylaşım davetleri
- Paylaşılan hatırlatıcıları görüntüleme

### Kullanım:
```dart
import '../services/sharing_service.dart';

final sharingService = SharingService();

// Hatırlatıcıyı paylaş
await sharingService.shareReminder(
  reminderId,
  ['user1@example.com', 'user2@example.com'],
);

// Paylaşılan hatırlatıcıları getir
final sharedReminders = await sharingService.getSharedReminders();

// Paylaşılan kullanıcıları getir
final users = await sharingService.getSharedUsers(reminderId);

// Düzenleme iznini güncelle
await sharingService.updateEditPermission(reminderId, userId, true);

// Paylaşımı kaldır
await sharingService.unshareReminder(reminderId, userId);
```

### Veritabanı Tablosu:
```sql
CREATE TABLE reminder_shares (
  id SERIAL PRIMARY KEY,
  reminder_id INTEGER REFERENCES reminders(id),
  shared_with_user_id UUID REFERENCES profiles(id),
  shared_by_user_id UUID REFERENCES profiles(id),
  can_edit BOOLEAN DEFAULT true,
  accepted BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 📊 İstatistik ve Grafik Ekranı

### Özellikler:
- Toplam/Tamamlanan/Aktif hatırlatıcı sayısı
- Kategoriye göre dağılım (Pasta grafik)
- Önceliğe göre dağılım (Bar grafik)
- Haftalık tamamlanma oranı (Çizgi grafik)
- Aylık hatırlatıcı sayısı (Bar grafik)
- Ortalama tamamlanma süresi
- En çok kullanılan kategori

### Kullanım:
```dart
import '../services/statistics_service.dart';

final statsService = StatisticsService();

// Tüm istatistikleri getir
final stats = await statsService.getAllStatistics();

// Belirli istatistikleri getir
final totalCount = await statsService.getTotalRemindersCount();
final completionRate = await statsService.getOverallCompletionRate();
final categoryStats = await statsService.getRemindersByCategory();
```

### Ekran:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const StatisticsScreen(),
  ),
);
```

---

## 🔒 Uygulama Kilidi (PIN / Biyometrik)

### Özellikler:
- PIN kodu ile kilitleme (4-6 rakam)
- Biyometrik kimlik doğrulama (Parmak izi / Yüz tanıma)
- Otomatik kilitleme (zaman aşımı)
- Güvenli şifre saklama (Encrypted)

### Kullanım:
```dart
import '../services/app_lock_service.dart';

final appLockService = AppLockService();

// PIN ayarla
await appLockService.setPin('1234');

// PIN doğrula
final verified = await appLockService.verifyPin('1234');

// Biyometrik kimlik doğrulama
final authenticated = await appLockService.authenticateWithBiometrics();

// Kilit durumunu kontrol et
final shouldLock = await appLockService.shouldLock();

// Kilidi aç/kapat
await appLockService.setLockEnabled(true);
await appLockService.setBiometricEnabled(true);

// Kilit zaman aşımını ayarla (dakika)
await appLockService.setLockTimeout(5);
```

### Ekran:
```dart
// Ayarlar ekranı
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const AppLockSettingsScreen(),
  ),
);

// Kilit ekranı
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => AppLockScreen(
      onUnlocked: () {
        Navigator.pop(context);
      },
    ),
  ),
);
```

---

## 📜 Bildirim Geçmişi ve Kaçırılan Hatırlatıcı Listesi

### Özellikler:
- Tüm bildirimlerin geçmişi
- Bildirim durumu takibi (Gönderildi, Açıldı, Kapatıldı, Ertelendi, Kaçırıldı)
- Kaçırılan bildirimleri filtreleme
- Bildirim istatistikleri

### Kullanım:
```dart
import '../services/notification_history_service.dart';

final historyService = NotificationHistoryService();

// Bildirim geçmişi ekle
await historyService.addHistory(
  NotificationHistoryItem(
    reminderId: 1,
    reminderTitle: 'Toplantı',
    notificationTime: DateTime.now(),
    status: NotificationStatus.sent,
  ),
);

// Tüm geçmişi getir
final history = await historyService.getAllHistory();

// Kaçırılan bildirimleri getir
final missed = await historyService.getMissedNotifications();

// Durumu güncelle
await historyService.updateStatus(
  historyId,
  NotificationStatus.opened,
  note: 'Kullanıcı bildirimi açtı',
);

// Geçmişi temizle
await historyService.clearAllHistory();
```

### Ekran:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const NotificationHistoryScreen(),
  ),
);
```

---

## 🏠 Anasayfa Widget Desteği

### Özellikler:
- Bugünkü hatırlatıcıları gösterme
- Yaklaşan hatırlatıcıları gösterme
- Widget'tan doğrudan hatırlatıcı tamamlama
- Otomatik güncelleme

### Kullanım:
```dart
import '../services/widget_service.dart';

final widgetService = WidgetService();

// Widget'ı başlat
await widgetService.initialize();

// Widget'ı güncelle
await widgetService.updateWidget();

// Yaklaşan hatırlatıcıları göster
await widgetService.updateUpcomingReminders();

// Widget tıklamalarını işle
await widgetService.handleWidgetClick(uri);
```

### Android Kurulumu:
1. `android/app/src/main/res/xml/widget_info.xml` oluştur
2. `AndroidManifest.xml`'e widget receiver ekle
3. Widget layout dosyalarını oluştur

### iOS Kurulumu:
1. Widget Extension oluştur
2. App Group yapılandır
3. Widget Timeline Provider oluştur

---

## ♿ Erişilebilirlik Özellikleri

### Özellikler:
- Yazı boyutu ayarlama (Küçük, Normal, Büyük, Çok Büyük)
- Yüksek kontrast modu
- Kalın yazı tipi
- Animasyonları azaltma
- Ekran okuyucu desteği (Voice Over)

### Kullanım:
```dart
import '../services/accessibility_service.dart';

final accessibilityService = AccessibilityService();

// Yazı boyutunu ayarla
await accessibilityService.setFontSize(FontSizeOption.large);

// Kontrast modunu ayarla
await accessibilityService.setContrastMode(ContrastMode.high);

// Kalın yazı
await accessibilityService.setBoldText(true);

// Animasyonları azalt
await accessibilityService.setReduceAnimations(true);

// Ekran okuyucu
await accessibilityService.setVoiceOverEnabled(true);

// Erişilebilir tema oluştur
final theme = await accessibilityService.buildAccessibleTheme(
  brightness: Brightness.light,
  baseColorScheme: ColorScheme.light(),
);
```

### Ekran:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const AccessibilitySettingsScreen(),
  ),
);
```

---

## 📦 Yükleme ve Kurulum

### 1. Paketleri Yükle:
```bash
flutter pub get
```

### 2. İzinleri Yapılandır:

#### Android (android/app/src/main/AndroidManifest.xml):
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
```

#### iOS (ios/Runner/Info.plist):
```xml
<key>NSMicrophoneUsageDescription</key>
<string>Sesli hatırlatıcı eklemek için mikrofon erişimi gerekli</string>
<key>NSCameraUsageDescription</key>
<string>Fotoğraf eklemek için kamera erişimi gerekli</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Fotoğraf seçmek için galeri erişimi gerekli</string>
<key>NSFaceIDUsageDescription</key>
<string>Uygulamayı açmak için Face ID kullanılacak</string>
```

### 3. Supabase Tablolarını Oluştur:
```sql
-- reminder_shares tablosu
CREATE TABLE reminder_shares (
  id SERIAL PRIMARY KEY,
  reminder_id INTEGER REFERENCES reminders(id) ON DELETE CASCADE,
  shared_with_user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  shared_by_user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  can_edit BOOLEAN DEFAULT true,
  accepted BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Reminders tablosuna yeni alanlar ekle
ALTER TABLE reminders ADD COLUMN is_favorite BOOLEAN DEFAULT false;
ALTER TABLE reminders ADD COLUMN attachments TEXT[];
ALTER TABLE reminders ADD COLUMN shared_with TEXT;
ALTER TABLE reminders ADD COLUMN is_shared BOOLEAN DEFAULT false;
ALTER TABLE reminders ADD COLUMN created_by UUID REFERENCES profiles(id);

-- Index'ler
CREATE INDEX idx_reminder_shares_reminder ON reminder_shares(reminder_id);
CREATE INDEX idx_reminder_shares_shared_with ON reminder_shares(shared_with_user_id);
CREATE INDEX idx_reminders_favorite ON reminders(is_favorite);
CREATE INDEX idx_reminders_shared ON reminders(is_shared);
```

### 4. Uygulamayı Çalıştır:
```bash
flutter run
```

---

## 🎯 Kullanım Örnekleri

### Sesli Hatırlatıcı Ekleme:
1. Hatırlatıcı ekleme ekranında mikrofon butonuna tıklayın
2. "Yarın saat 10'da toplantı" gibi bir komut verin
3. Sistem otomatik olarak başlık ve zamanı algılayacak

### Hatırlatıcı Paylaşma:
1. Bir hatırlatıcıyı açın
2. Paylaş butonuna tıklayın
3. Email adresi girerek kullanıcı arayın
4. Paylaşmak istediğiniz kullanıcıları seçin
5. Düzenleme iznini ayarlayın

### İstatistikleri Görüntüleme:
1. Ayarlar > İstatistikler'e gidin
2. Grafikler ve sayılar otomatik olarak yüklenecek
3. Yenilemek için aşağı çekin

### Uygulama Kilidi Kurma:
1. Ayarlar > Uygulama Kilidi'ne gidin
2. Kilidi aktif edin ve PIN oluşturun
3. İsterseniz biyometrik kimlik doğrulamayı aktif edin
4. Zaman aşımı süresini ayarlayın

---

## 🐛 Sorun Giderme

### Speech-to-Text Çalışmıyor:
- Mikrofon izninin verildiğinden emin olun
- Cihazınızın mikrofonu desteklediğini kontrol edin
- İnternet bağlantınızı kontrol edin (bazı cihazlarda gerekli)

### Biyometrik Kimlik Doğrulama Çalışmıyor:
- Cihazınızda biyometrik donanım olduğundan emin olun
- Sistem ayarlarından biyometrik kimlik doğrulamanın aktif olduğunu kontrol edin
- En az bir parmak izi veya yüz kaydı olmalı

### Dosya Ekleme Çalışmıyor:
- Depolama izinlerinin verildiğinden emin olun
- Dosya boyutunun 10MB'dan küçük olduğunu kontrol edin

### Widget Görünmüyor:
- App Group yapılandırmasının doğru olduğundan emin olun (iOS)
- Widget receiver'ın AndroidManifest.xml'de tanımlı olduğunu kontrol edin (Android)

---

## 📝 Notlar

- Tüm özellikler offline çalışabilir (paylaşım hariç)
- Veriler otomatik olarak senkronize edilir
- Güvenlik için hassas veriler şifreli saklanır
- Erişilebilirlik özellikleri tüm ekranlarda çalışır

---

## 🔄 Güncellemeler

### Versiyon 2.0.0
- ✅ Sesli hatırlatıcı ekleme
- ✅ Favori hatırlatıcılar
- ✅ Dosya ve görsel ekleme
- ✅ Hatırlatıcı paylaşımı
- ✅ İstatistik ve grafikler
- ✅ Uygulama kilidi
- ✅ Bildirim geçmişi
- ✅ Widget desteği
- ✅ Erişilebilirlik özellikleri

---

## 📞 Destek

Herhangi bir sorun veya öneriniz için lütfen iletişime geçin.


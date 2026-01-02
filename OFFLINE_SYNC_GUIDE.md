# Offline Çalışma ve Senkronizasyon Rehberi

## 🎯 Özellikler

### 1. **Offline Çalışma**
- Uygulama internet bağlantısı olmadan da çalışır
- Tüm hatırlatıcılar yerel veritabanında (SQLite) saklanır
- İnternet yokken yapılan tüm değişiklikler yerel olarak kaydedilir

### 2. **Otomatik Senkronizasyon**
- İnternet bağlantısı tespit edildiğinde otomatik olarak senkronizasyon başlar
- Yerel değişiklikler sunucuya gönderilir
- Sunucudaki değişiklikler yerel veritabanına indirilir

### 3. **Çoklu Cihaz Desteği**
- Aynı hesapla farklı cihazlardan giriş yapabilirsiniz
- Tüm hatırlatıcılarınız tüm cihazlarda senkronize olur
- Bir cihazda yapılan değişiklik diğer cihazlara yansır

## 🔧 Teknik Detaylar

### Kullanılan Teknolojiler
- **SQLite (sqflite)**: Yerel veritabanı
- **Supabase**: Bulut veritabanı
- **connectivity_plus**: İnternet bağlantısı kontrolü

### Senkronizasyon Mantığı

#### 1. **Veri Oluşturma**
```
1. Hatırlatıcı yerel veritabanına kaydedilir
2. İnternet varsa → Supabase'e gönderilir
3. İnternet yoksa → "needs_sync" olarak işaretlenir
```

#### 2. **Veri Güncelleme**
```
1. Değişiklik yerel veritabanına kaydedilir
2. İnternet varsa → Supabase'de güncellenir
3. İnternet yoksa → "needs_sync" olarak işaretlenir
```

#### 3. **Veri Silme**
```
1. Yerel veritabanında "soft delete" yapılır (is_deleted=1)
2. İnternet varsa → Supabase'den silinir
3. İnternet yoksa → "needs_sync" olarak işaretlenir
```

#### 4. **Otomatik Senkronizasyon**
```
1. İnternet bağlantısı tespit edilir
2. Yerel değişiklikler (needs_sync=1) sunucuya gönderilir
3. Sunucudaki tüm veriler yerel veritabanına indirilir
4. Çakışmalar sunucu verisine göre çözülür
```

## 📱 Kullanım

### Senkronizasyon Durumu
Ana ekranın sağ üst köşesinde senkronizasyon durumu gösterilir:
- ☁️ **Bulut ikonu (dolu)**: Online - Veriler senkronize
- ☁️ **Bulut ikonu (boş)**: Offline - Yerel modda çalışıyor

### Manuel Senkronizasyon
Bulut ikonuna tıklayarak manuel senkronizasyon başlatabilirsiniz:
- Online ise: Senkronizasyon başlar
- Offline ise: "Offline moddasınız" mesajı gösterilir

### Offline Modda Çalışma
1. İnternet bağlantınız kesildiğinde uygulama otomatik olarak offline moda geçer
2. Tüm işlemleriniz yerel veritabanında saklanır
3. İnternet bağlantısı geldiğinde otomatik olarak senkronize edilir

## 🔐 Güvenlik

### Veri Güvenliği
- Tüm veriler kullanıcı ID'sine göre filtrelenir
- Yerel veritabanı cihazda şifrelenmiş olarak saklanır
- Supabase Row Level Security (RLS) ile korunur

### Çıkış Yapma
Çıkış yaptığınızda:
- Yerel veritabanındaki tüm veriler temizlenir
- Supabase'deki veriler korunur
- Tekrar giriş yaptığınızda veriler indirilir

## 🐛 Sorun Giderme

### Senkronizasyon Çalışmıyor
1. İnternet bağlantınızı kontrol edin
2. Uygulamayı yeniden başlatın
3. Manuel senkronizasyon deneyin (bulut ikonuna tıklayın)

### Veriler Görünmüyor
1. Senkronizasyon tamamlanana kadar bekleyin
2. Çıkış yapıp tekrar giriş yapın
3. İnternet bağlantınızı kontrol edin

### Çakışan Veriler
- Sistem otomatik olarak sunucu verisini önceliklendirir
- Yerel değişiklikler sunucuya gönderilir
- Çakışma durumunda en son güncelleme geçerli olur

## 📊 Senkronizasyon Logları

Uygulama konsolunda senkronizasyon durumunu takip edebilirsiniz:
- 🔄 Senkronizasyon başladı
- 📤 Yerel değişiklikler gönderiliyor
- 📥 Sunucu verileri indiriliyor
- ✅ Senkronizasyon tamamlandı
- ❌ Hata oluştu

## 🚀 Performans

### Optimizasyonlar
- Sadece değişen veriler senkronize edilir
- Toplu işlemler kullanılır
- İndexler ile hızlı sorgulama
- Arka planda çalışır

### Veri Kullanımı
- İlk senkronizasyon: Tüm veriler indirilir
- Sonraki senkronizasyonlar: Sadece değişiklikler
- Ortalama veri kullanımı: Çok düşük (<1KB per hatırlatıcı)

## 💡 İpuçları

1. **Düzenli Senkronizasyon**: Uygulamayı açtığınızda otomatik senkronize olur
2. **Offline Çalışma**: İnternet olmadan da tüm özellikler çalışır
3. **Çoklu Cihaz**: Farklı cihazlarda aynı anda kullanabilirsiniz
4. **Veri Güvenliği**: Çıkış yapınca yerel veriler silinir
5. **Otomatik Yedekleme**: Tüm veriler bulutta güvende

## 📝 Notlar

- Senkronizasyon arka planda otomatik çalışır
- İnternet bağlantısı geldiğinde hemen başlar
- Başarısız senkronizasyonlar otomatik olarak tekrar denenir
- Tüm işlemler loglarda izlenebilir


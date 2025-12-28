# Google OAuth Kurulum Rehberi

## 1. Google Cloud Console'da OAuth 2.0 Client ID Oluşturma

1. [Google Cloud Console](https://console.cloud.google.com/) adresine gidin
2. Yeni bir proje oluşturun veya mevcut bir projeyi seçin
3. **APIs & Services** > **Credentials** bölümüne gidin
4. **Create Credentials** > **OAuth client ID** seçin
5. **Application type** olarak **Web application** seçin
6. **Name** alanına bir isim verin (örn: "Reminder App")
7. **Authorized redirect URIs** bölümüne şunu ekleyin:
   ```
   https://sracxiryfylnnbxqzaag.supabase.co/auth/v1/callback
   ```
   (Kendi Supabase URL'nizi kullanın)
8. **Create** butonuna tıklayın
9. **Client ID** ve **Client Secret** değerlerini kopyalayın

## 2. Supabase'de Google Provider'ı Etkinleştirme

1. [Supabase Dashboard](https://app.supabase.com) adresine gidin
2. Projenizi seçin
3. **Authentication** > **Providers** bölümüne gidin
4. **Google** provider'ını bulun ve **Enable** butonuna tıklayın
5. Google Cloud Console'dan kopyaladığınız bilgileri girin:
   - **Client ID (for OAuth)**: Google Cloud'dan aldığınız Client ID
   - **Client Secret (for OAuth)**: Google Cloud'dan aldığınız Client Secret
6. **Save** butonuna tıklayın

## 3. Redirect URL Yapılandırması

Supabase Dashboard > **Authentication** > **URL Configuration** bölümünde:

**Redirect URLs** listesine şunu ekleyin:
```
io.supabase.reminderappv6://login-callback/
```

## 4. Test Etme

1. Uygulamayı çalıştırın
2. Login ekranında **"Google ile Giriş Yap"** butonuna tıklayın
3. Google hesabınızı seçin ve izin verin
4. Uygulamaya geri dönüp otomatik giriş yapıldığını kontrol edin

## Notlar

- İlk Google girişinde kullanıcı profil bilgileri otomatik olarak oluşturulur
- Google hesabındaki ad ve email bilgileri otomatik olarak alınır
- Production için mutlaka Google Cloud Console'da doğru redirect URI'ları ekleyin


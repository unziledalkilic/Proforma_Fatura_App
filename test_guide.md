# Proforma Fatura App - Test Rehberi

## 🔧 Firebase Kurulumu (Zorunlu)

Firebase projesini kurmak için aşağıdaki adımları takip edin:

### 1. Firebase Console'da Proje Oluşturun
1. https://console.firebase.google.com adresine gidin
2. "Create a project" butonuna tıklayın
3. Proje adını girin ve ayarları tamamlayın

### 2. Android Uygulamasını Ekleyin
1. Firebase projesinde "Add app" > Android seçin
2. Package name: com.example.proforma_fatura_app
3. google-services.json dosyasını indirin ve android/app/ klasörüne yerleştirin

## 📱 Uygulamayı Test Etme

### 1. Emülatörde Çalıştırma
```bash
cd proforma_fatura_app
flutter run -d emulator-5554
```

### 2. Test Senaryoları

#### A. Yeni Kullanıcı Kaydı
1. Uygulama açıldığında "Kayıt Ol" butonuna tıklayın
2. Aşağıdaki bilgileri girin:
   - **Ad Soyad**: Test Kullanıcı
   - **E-posta**: test@example.com
   - **Şifre**: 12345678 (en az 8 karakter)
   - **Telefon**: 0555 123 45 67
3. "Kayıt Ol" butonuna tıklayın
4. Başarılı kayıt sonrası ana sayfaya yönlendirileceksiniz

#### B. Mevcut Kullanıcı ile Giriş
1. Ana sayfada "Giriş Yap" butonuna tıklayın
2. Aşağıdaki bilgileri girin:
   - **E-posta**: test@example.com
   - **Şifre**: 12345678
3. "Giriş Yap" butonuna tıklayın
4. Başarılı giriş sonrası ana sayfaya yönlendirileceksiniz

### 3. Hata Durumları

#### A. Firebase Bağlantı Hatası
- **Belirti**: "Firebase bağlantısı kurulamadı" mesajı
- **Çözüm**: google-services.json dosyasının doğru yerde olduğundan emin olun

#### B. Kullanıcı Bulunamadı
- **Belirti**: "Kullanıcı bulunamadı" mesajı
- **Çözüm**: E-posta adresini kontrol edin

#### C. Hatalı Şifre
- **Belirti**: "Hatalı şifre" mesajı
- **Çözüm**: Şifreyi kontrol edin

## 🔍 Debug Logları

Uygulama çalışırken aşağıdaki logları göreceksiniz:

### Başarılı Bağlantı
```
✅ Firebase bağlantısı başarılı!
```

### Başarılı Kayıt
```
✅ Kullanıcı kaydı başarılı
```

### Başarılı Giriş
```
✅ Kullanıcı girişi başarılı
```

## 🚀 Test Sonrası Kontroller

### 1. Ana Sayfa Özellikleri
- [ ] Döviz kurları görüntüleniyor
- [ ] Hızlı işlemler çalışıyor
- [ ] Müşteri, ürün, fatura sayıları doğru

### 2. Navigasyon
- [ ] Alt menü çalışıyor
- [ ] Sayfalar arası geçiş sorunsuz
- [ ] Geri butonu çalışıyor

### 3. Veri İşlemleri
- [ ] Yeni müşteri eklenebiliyor
- [ ] Yeni ürün eklenebiliyor
- [ ] Yeni fatura oluşturulabiliyor

## 🛠️ Sorun Giderme

### Firebase Bağlantı Sorunu
```bash
# google-services.json dosyasının varlığını kontrol edin
# android/app/google-services.json dosyasının olduğundan emin olun
```

### Flutter Bağlantı Sorunu
```bash
# Flutter doctor ile sistem durumunu kontrol edin
flutter doctor

# Bağımlılıkları yeniden yükleyin
flutter pub get
```

### Emülatör Sorunu
```bash
# Mevcut emülatörleri listele
flutter emulators

# Yeni emülatör başlat
flutter emulators --launch <emulator_id>
```

## 📞 Destek

Eğer sorun yaşarsanız:
1. Debug loglarını paylaşın
2. Hangi adımda takıldığınızı belirtin
3. Ekran görüntüsü ekleyin 
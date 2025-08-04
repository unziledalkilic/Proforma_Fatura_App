# Proforma Fatura App - Test Rehberi

## 🔧 Veritabanı Güncellemesi (Zorunlu)

PostgreSQL'de aşağıdaki komutları sırasıyla çalıştırın:

### 1. Migration Script'ini Çalıştırın
```sql
-- postgres_migration.sql dosyasındaki tüm komutları çalıştırın
-- Bu komut user_id sütunlarını ekleyecek ve mevcut verileri düzenleyecek
```

### 2. Veritabanı Durumunu Kontrol Edin
```sql
-- Kullanıcıları kontrol edin
SELECT id, username, email FROM users ORDER BY id;

-- Tabloların user_id sütunlarını kontrol edin
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name IN ('customers', 'products', 'invoices', 'product_categories')
    AND column_name = 'user_id'
ORDER BY table_name;
```

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

#### A. Veritabanı Bağlantı Hatası
- **Belirti**: "PostgreSQL bağlantısı kurulamadı" mesajı
- **Çözüm**: PostgreSQL servisinin çalıştığından emin olun

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
✅ PostgreSQL bağlantısı başarılı!
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

### PostgreSQL Bağlantı Sorunu
```bash
# PostgreSQL servisinin durumunu kontrol edin
# Windows: Hizmetler (Services) uygulamasından "postgresql-x64-15" servisini kontrol edin
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
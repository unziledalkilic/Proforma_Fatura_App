# Proforma Fatura Uygulaması

Flutter ile geliştirilmiş, PostgreSQL veritabanı kullanan profesyonel proforma fatura yönetim uygulaması.

## 🚀 Özellikler

- **Kullanıcı Yönetimi**: Kayıt, giriş ve profil yönetimi
- **Müşteri Yönetimi**: Müşteri ekleme, düzenleme ve listeleme
- **Ürün Yönetimi**: Ürün ekleme, düzenleme, kategorilendirme
- **Fatura Yönetimi**: Proforma fatura oluşturma ve yönetimi
- **Döviz Kurları**: Canlı döviz kuru takibi
- **Hesap Makinesi**: Hızlı hesaplama aracı
- **Kategori Sistemi**: Ürün kategorileri ve filtreleme
- **Çoklu Para Birimi**: TL, USD, EUR, GBP desteği

## 🛠️ Teknolojiler

- **Frontend**: Flutter (Dart)
- **Backend**: PostgreSQL
- **State Management**: Provider
- **API**: HTTP (Döviz kurları için)
- **Navigation**: Flutter Navigator

## 📋 Gereksinimler

- Flutter SDK (3.0+)
- Dart SDK (3.0+)
- PostgreSQL Server
- Android Studio / VS Code / Cursor

## 🔧 Kurulum

### 1. Projeyi Klonlayın
```bash
git clone https://github.com/kullaniciadi/proforma-fatura-app.git
cd proforma-fatura-app
```

### 2. Bağımlılıkları Yükleyin
```bash
flutter pub get
```

### 3. PostgreSQL Veritabanını Kurun
```bash
# PostgreSQL sunucusunu başlatın
# database_setup.sql dosyasını çalıştırın
psql -U postgres -d postgres -f database_setup.sql
```

### 4. Veritabanı Bağlantısını Yapılandırın
`lib/services/postgres_service.dart` dosyasında veritabanı bağlantı bilgilerini güncelleyin:

```dart
static const String _host = 'localhost';
static const int _port = 5432;
static const String _database = 'proforma_fatura';
static const String _username = 'your_username';
static const String _password = 'your_password';
```

### 5. Uygulamayı Çalıştırın
```bash
flutter run
```

## 📱 Ekran Görüntüleri

### Ana Sayfa
- Hoş geldin mesajı
- Canlı döviz kurları
- Hızlı işlemler (Hesap Makinesi, Ürün Ekle)

### Ürünler
- Ürün listesi
- Kategori filtreleme
- Arama fonksiyonu
- Ekleme/Düzenleme/Silme

### Müşteriler
- Müşteri listesi
- Müşteri ekleme/düzenleme

### Faturalar
- Proforma fatura oluşturma
- Fatura listesi

## 🗄️ Veritabanı Şeması

### Tablolar
- `users` - Kullanıcı bilgileri
- `customers` - Müşteri bilgileri
- `products` - Ürün bilgileri
- `product_categories` - Ürün kategorileri
- `invoices` - Fatura bilgileri
- `invoice_items` - Fatura kalemleri

## 🔄 Güncellemeler

### v1.0.0
- Temel kullanıcı yönetimi
- Müşteri yönetimi
- Ürün yönetimi
- Fatura yönetimi
- Döviz kuru entegrasyonu
- Kategori sistemi

## 🐛 Bilinen Sorunlar

- [x] FlutterError (Looking up a deactivated widget's ancestor is unsafe.) - Çözüldü
- [x] PostgreSQL bağlantı sorunları - Çözüldü
- [x] Kategori filtreleme sorunları - Çözüldü

## 🤝 Katkıda Bulunma

1. Bu repository'yi fork edin
2. Feature branch oluşturun (`git checkout -b feature/AmazingFeature`)
3. Değişikliklerinizi commit edin (`git commit -m 'Add some AmazingFeature'`)
4. Branch'inizi push edin (`git push origin feature/AmazingFeature`)
5. Pull Request oluşturun


## 🙏 Teşekkürler

- Flutter ekibine
- PostgreSQL topluluğuna
- Tüm katkıda bulunanlara

---

⭐ Bu projeyi beğendiyseniz yıldız vermeyi unutmayın! 

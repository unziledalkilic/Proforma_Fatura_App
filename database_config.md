# 🗄️ PostgreSQL Veritabanı Kurulum Rehberi

## 📥 Adım 1: PostgreSQL Kurulumu

### Windows için:
1. [PostgreSQL İndirme Sayfası](https://www.postgresql.org/download/windows/) adresine gidin
2. **Download the installer** butonuna tıklayın
3. En son sürümü indirin (örn: PostgreSQL 15.x)
4. İndirilen dosyayı çalıştırın

### Kurulum Ayarları:
- **Port:** 5432 (varsayılan)
- **Şifre:** Güvenli bir şifre belirleyin (unutmayın!)
- **Locale:** Default locale
- **Stack Builder:** İsteğe bağlı (şimdilik işaretlemeyin)

## 🗂️ Adım 2: Veritabanı Oluşturma

### pgAdmin ile:
1. **pgAdmin** açın (PostgreSQL ile birlikte gelir)
2. **Servers** → **PostgreSQL** → **Databases** → **Create** → **Database**
3. Veritabanı adı: `proforma_fatura_db`
4. **Save** butonuna tıklayın

### Komut Satırı ile:
```sql
CREATE DATABASE proforma_fatura_db;
```

## 📋 Adım 3: Tabloları Oluşturma

### Yöntem 1: pgAdmin Query Tool
1. pgAdmin'de `proforma_fatura_db` veritabanına sağ tıklayın
2. **Query Tool** seçin
3. `database_setup.sql` dosyasının içeriğini kopyalayın
4. **Execute** butonuna tıklayın

### Yöntem 2: Komut Satırı
```bash
# PostgreSQL'e bağlanın
psql -U postgres -d proforma_fatura_db

# SQL dosyasını çalıştırın
\i database_setup.sql
```

## 🔧 Adım 4: Bağlantı Bilgileri

### Veritabanı Bağlantı Parametreleri:
```yaml
Host: localhost
Port: 5432
Database: proforma_fatura_db
Username: postgres
Password: [Kurulum sırasında belirlediğiniz şifre]
```

### Test Bağlantısı:
```bash
psql -h localhost -p 5432 -U postgres -d proforma_fatura_db
```

## 📊 Oluşturulan Tablolar

### 1. users (Kullanıcılar)
- id, username, email, password_hash
- full_name, company_name, phone
- address, tax_number, tax_office
- is_active, created_at, updated_at

### 2. customers (Müşteriler)
- id, name, email, phone
- address, tax_number, tax_office
- created_at, updated_at

### 3. products (Ürünler)
- id, name, description, price
- unit, barcode, tax_rate
- created_at, updated_at

### 4. invoices (Faturalar)
- id, invoice_number, customer_id
- invoice_date, due_date, notes, terms
- discount_rate, status
- created_at, updated_at

### 5. invoice_items (Fatura Kalemleri)
- id, invoice_id, product_id
- quantity, unit_price, discount_rate
- tax_rate, notes

## 🔍 Tablo Kontrolü

### Tabloları Listele:
```sql
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
```

### Tablo Yapısını Görüntüle:
```sql
\d users;
\d customers;
\d products;
\d invoices;
\d invoice_items;
```

## 📝 Örnek Veriler

SQL dosyasında aşağıdaki örnek veriler bulunmaktadır:

### Test Kullanıcısı:
- **Email:** admin@example.com
- **Şifre:** 12345678

### Örnek Müşteriler:
- ABC Şirketi A.Ş.
- XYZ Ltd. Şti.
- DEF Ticaret

### Örnek Ürünler:
- Laptop (15.000 TL)
- Mouse (150 TL)
- Klavye (500 TL)
- Monitör (2.000 TL)
- Yazıcı (3.000 TL)

## ⚠️ Önemli Notlar

1. **Şifre Güvenliği:** Kurulum sırasında belirlediğiniz şifreyi not alın
2. **Port:** 5432 portunu başka uygulamalar kullanmıyorsa değiştirmeyin
3. **Yedekleme:** Düzenli olarak veritabanınızı yedekleyin
4. **Güvenlik:** Üretim ortamında güçlü şifreler kullanın

## 🚀 Sonraki Adımlar

Veritabanı kurulumu tamamlandıktan sonra:
1. Flutter uygulamasında PostgreSQL bağlantısını yapılandırın
2. API servislerini geliştirin
3. Veri senkronizasyonunu sağlayın 
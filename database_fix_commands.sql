-- Veritabanındaki yanlış verileri düzeltme scripti
-- Bu scripti pgAdmin'de çalıştırın

-- 1. Önce mevcut durumu kontrol edelim
SELECT 'Mevcut durum kontrolü' as islem;
SELECT 'customers' as tablo, COUNT(*) as kayit_sayisi FROM customers;
SELECT 'invoices' as tablo, COUNT(*) as kayit_sayisi FROM invoices;

-- 2. Customers tablosuna user_id sütunu ekle (eğer yoksa)
ALTER TABLE customers ADD COLUMN IF NOT EXISTS user_id INTEGER REFERENCES users(id) ON DELETE CASCADE;

-- 3. Mevcut müşterileri varsayılan kullanıcıya ata (ilk kullanıcı)
UPDATE customers SET user_id = (SELECT id FROM users LIMIT 1) WHERE user_id IS NULL;

-- 4. user_id sütununu NOT NULL yap
ALTER TABLE customers ALTER COLUMN user_id SET NOT NULL;

-- 5. Customers için user_id indeksi oluştur (performans için)
CREATE INDEX IF NOT EXISTS idx_customers_user_id ON customers(user_id);

-- 6. Invoices tablosuna user_id sütunu ekle (eğer yoksa)
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS user_id INTEGER REFERENCES users(id) ON DELETE CASCADE;

-- 7. Mevcut faturaları varsayılan kullanıcıya ata
UPDATE invoices SET user_id = (SELECT id FROM users LIMIT 1) WHERE user_id IS NULL;

-- 8. Invoices için user_id sütununu NOT NULL yap
ALTER TABLE invoices ALTER COLUMN user_id SET NOT NULL;

-- 9. Invoices için user_id indeksi oluştur
CREATE INDEX IF NOT EXISTS idx_invoices_user_id ON invoices(user_id);

-- 10. Yanlış verileri kontrol edelim
SELECT 'Yanlış tarih verileri kontrolü' as islem;
SELECT id, created_at, updated_at FROM customers WHERE created_at IS NULL OR updated_at IS NULL;
SELECT id, created_at, updated_at FROM invoices WHERE created_at IS NULL OR updated_at IS NULL;

-- 11. Status alanlarında yanlış verileri kontrol edelim
SELECT 'Yanlış status verileri kontrolü' as islem;
SELECT id, status FROM invoices WHERE status NOT IN ('draft', 'sent', 'accepted', 'rejected', 'expired');

-- 12. NULL tarih değerlerini düzeltelim
UPDATE customers SET 
  created_at = CURRENT_TIMESTAMP 
WHERE created_at IS NULL;

UPDATE customers SET 
  updated_at = CURRENT_TIMESTAMP 
WHERE updated_at IS NULL;

UPDATE invoices SET 
  created_at = CURRENT_TIMESTAMP 
WHERE created_at IS NULL;

UPDATE invoices SET 
  updated_at = CURRENT_TIMESTAMP 
WHERE updated_at IS NULL;

-- 13. Status alanlarını düzeltelim (eğer yanlış veriler varsa)
UPDATE invoices SET 
  status = 'draft' 
WHERE status NOT IN ('draft', 'sent', 'accepted', 'rejected', 'expired');

-- 14. Son durumu kontrol edelim
SELECT 'Düzeltme sonrası kontrol' as islem;
SELECT 'customers' as tablo, COUNT(*) as kayit_sayisi FROM customers;
SELECT 'invoices' as tablo, COUNT(*) as kayit_sayisi FROM invoices;

-- 15. Örnek verileri kontrol edelim
SELECT 'Örnek müşteri verileri' as islem;
SELECT id, name, email, user_id, created_at, updated_at FROM customers LIMIT 5;

SELECT 'Örnek fatura verileri' as islem;
SELECT id, invoice_number, user_id, status, created_at, updated_at FROM invoices LIMIT 5;

-- 16. Tüm faturaları listele
SELECT 'Tüm faturalar' as islem;
SELECT 
  i.id,
  i.invoice_number,
  c.name as musteri_adi,
  i.user_id,
  i.status,
  i.created_at,
  i.updated_at
FROM invoices i 
JOIN customers c ON i.customer_id = c.id 
ORDER BY i.created_at DESC;

-- 17. Tablo yapılarını kontrol et
SELECT 'customers' as table_name, column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'customers' 
ORDER BY ordinal_position;

SELECT 'invoices' as table_name, column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'invoices' 
ORDER BY ordinal_position; 
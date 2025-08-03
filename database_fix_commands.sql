-- Veritabanındaki yanlış verileri düzeltme scripti
-- Bu scripti pgAdmin'de çalıştırın

-- 1. Önce mevcut durumu kontrol edelim
SELECT 'Mevcut durum kontrolü' as islem;
SELECT 'customers' as tablo, COUNT(*) as kayit_sayisi FROM customers;
SELECT 'invoices' as tablo, COUNT(*) as kayit_sayisi FROM invoices;

-- 2. Yanlış verileri kontrol edelim
SELECT 'Yanlış tarih verileri kontrolü' as islem;
SELECT id, created_at, updated_at FROM customers WHERE created_at IS NULL OR updated_at IS NULL;
SELECT id, created_at, updated_at FROM invoices WHERE created_at IS NULL OR updated_at IS NULL;

-- 3. Status alanlarında yanlış verileri kontrol edelim
SELECT 'Yanlış status verileri kontrolü' as islem;
SELECT id, status FROM invoices WHERE status NOT IN ('draft', 'sent', 'accepted', 'rejected', 'expired');

-- 4. NULL tarih değerlerini düzeltelim
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

-- 5. Status alanlarını düzeltelim (eğer yanlış veriler varsa)
UPDATE invoices SET 
  status = 'draft' 
WHERE status NOT IN ('draft', 'sent', 'accepted', 'rejected', 'expired');

-- 6. Son durumu kontrol edelim
SELECT 'Düzeltme sonrası kontrol' as islem;
SELECT 'customers' as tablo, COUNT(*) as kayit_sayisi FROM customers;
SELECT 'invoices' as tablo, COUNT(*) as kayit_sayisi FROM invoices;

-- 7. Örnek verileri kontrol edelim
SELECT 'Örnek müşteri verileri' as islem;
SELECT id, name, email, created_at, updated_at FROM customers LIMIT 5;

SELECT 'Örnek fatura verileri' as islem;
SELECT id, invoice_number, status, created_at, updated_at FROM invoices LIMIT 5;

-- 8. Tüm faturaları listele
SELECT 'Tüm faturalar' as islem;
SELECT 
  i.id,
  i.invoice_number,
  c.name as musteri_adi,
  i.status,
  i.created_at,
  i.updated_at
FROM invoices i 
JOIN customers c ON i.customer_id = c.id 
ORDER BY i.created_at DESC; 
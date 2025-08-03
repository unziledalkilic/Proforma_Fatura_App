-- =====================================================
-- VERİTABANI DURUM KONTROLÜ VE DÜZELTME KOMUTLARI
-- =====================================================

-- 1. Mevcut tablo yapısını kontrol et
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name IN ('customers', 'invoices', 'invoice_items')
ORDER BY table_name, ordinal_position;

-- 2. Eksik sütunları ekle (eğer yoksa)
ALTER TABLE customers ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE invoices ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE invoice_items ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE invoice_items ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- 3. tax_office sütununu sil (eğer varsa)
ALTER TABLE customers DROP COLUMN IF EXISTS tax_office;
DROP INDEX IF EXISTS idx_customers_tax_office;

-- 4. Mevcut verileri kontrol et
SELECT 'customers' as tablo, COUNT(*) as kayit_sayisi FROM customers
UNION ALL
SELECT 'invoices' as tablo, COUNT(*) as kayit_sayisi FROM invoices
UNION ALL
SELECT 'invoice_items' as tablo, COUNT(*) as kayit_sayisi FROM invoice_items;

-- 5. Örnek müşteri verilerini ekle (eğer yoksa)
INSERT INTO customers (name, email, phone, address, tax_number) VALUES
('ABC Şirketi A.Ş.', 'info@abc.com', '0212 555 01 01', 'İstanbul, Türkiye', '1234567890'),
('XYZ Ltd. Şti.', 'contact@xyz.com', '0312 555 02 02', 'Ankara, Türkiye', '0987654321'),
('DEF Ticaret', 'info@def.com', '0232 555 03 03', 'İzmir, Türkiye', '1122334455')
ON CONFLICT DO NOTHING;

-- 6. Test faturaları ekle (eğer yoksa)
INSERT INTO invoices (user_id, invoice_number, customer_id, invoice_date, due_date, status, notes) 
SELECT 
    1,
    'PF-20241201-0001',
    c.id,
    CURRENT_DATE - INTERVAL '5 days',
    CURRENT_DATE + INTERVAL '25 days',
    'draft',
    'Test fatura 1'
FROM customers c 
WHERE c.name = 'ABC Şirketi A.Ş.'
LIMIT 1
ON CONFLICT (invoice_number) DO NOTHING;

INSERT INTO invoices (user_id, invoice_number, customer_id, invoice_date, due_date, status, notes) 
SELECT 
    1,
    'PF-20241201-0002',
    c.id,
    CURRENT_DATE - INTERVAL '3 days',
    CURRENT_DATE + INTERVAL '27 days',
    'sent',
    'Test fatura 2'
FROM customers c 
WHERE c.name = 'XYZ Ltd. Şti.'
LIMIT 1
ON CONFLICT (invoice_number) DO NOTHING;

-- 7. Son durumu kontrol et
SELECT 
    i.id,
    i.invoice_number,
    i.invoice_date,
    i.status,
    i.created_at,
    c.name as musteri_adi,
    c.email as musteri_email
FROM invoices i
LEFT JOIN customers c ON i.customer_id = c.id
ORDER BY i.created_at DESC;

-- 8. Hata kontrolü - NULL değerleri kontrol et
SELECT 
    'customers' as tablo,
    COUNT(*) as toplam_kayit,
    COUNT(CASE WHEN name IS NULL THEN 1 END) as null_name,
    COUNT(CASE WHEN created_at IS NULL THEN 1 END) as null_created_at,
    COUNT(CASE WHEN updated_at IS NULL THEN 1 END) as null_updated_at
FROM customers
UNION ALL
SELECT 
    'invoices' as tablo,
    COUNT(*) as toplam_kayit,
    COUNT(CASE WHEN invoice_number IS NULL THEN 1 END) as null_invoice_number,
    COUNT(CASE WHEN created_at IS NULL THEN 1 END) as null_created_at,
    COUNT(CASE WHEN updated_at IS NULL THEN 1 END) as null_updated_at
FROM invoices;

-- 9. Eksik tarihleri düzelt
UPDATE customers SET created_at = CURRENT_TIMESTAMP WHERE created_at IS NULL;
UPDATE customers SET updated_at = CURRENT_TIMESTAMP WHERE updated_at IS NULL;

UPDATE invoices SET created_at = CURRENT_TIMESTAMP WHERE created_at IS NULL;
UPDATE invoices SET updated_at = CURRENT_TIMESTAMP WHERE updated_at IS NULL;

-- 10. Final kontrol
SELECT 
    'Son Durum' as bilgi,
    COUNT(*) as fatura_sayisi
FROM invoices
UNION ALL
SELECT 
    'Müşteri Sayısı' as bilgi,
    COUNT(*) as musteri_sayisi
FROM customers; 
-- =====================================================
-- POSTGRESQL MIGRATION SCRIPT - KULLANICIYA ÖZEL VERİ YAPISI
-- =====================================================

-- 1. Mevcut durumu kontrol et
-- =====================================================
SELECT 'Mevcut tablo durumu kontrol ediliyor...' as islem;

-- Hangi tabloların user_id sütunu var?
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name IN ('customers', 'products', 'invoices', 'product_categories')
    AND column_name = 'user_id'
ORDER BY table_name;

-- =====================================================
-- 2. user_id sütunlarını ekle (eğer yoksa)
-- =====================================================

-- Customers tablosuna user_id sütunu ekle
ALTER TABLE customers ADD COLUMN IF NOT EXISTS user_id INTEGER;

-- Products tablosuna user_id sütunu ekle
ALTER TABLE products ADD COLUMN IF NOT EXISTS user_id INTEGER;

-- Invoices tablosuna user_id sütunu ekle
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS user_id INTEGER;

-- Product categories tablosuna user_id sütunu ekle
ALTER TABLE product_categories ADD COLUMN IF NOT EXISTS user_id INTEGER;

-- =====================================================
-- 3. Mevcut verileri güncelle
-- =====================================================

-- Hangi kullanıcılar var?
SELECT 'Mevcut kullanıcılar:' as islem;
SELECT id, username, email FROM users ORDER BY id;

-- Mevcut verileri varsayılan kullanıcıya ata (ilk kullanıcı)
UPDATE customers SET user_id = (SELECT id FROM users ORDER BY id LIMIT 1) WHERE user_id IS NULL;
UPDATE products SET user_id = (SELECT id FROM users ORDER BY id LIMIT 1) WHERE user_id IS NULL;
UPDATE invoices SET user_id = (SELECT id FROM users ORDER BY id LIMIT 1) WHERE user_id IS NULL;
UPDATE product_categories SET user_id = (SELECT id FROM users ORDER BY id LIMIT 1) WHERE user_id IS NULL;

-- =====================================================
-- 4. NOT NULL kısıtlamaları ekle
-- =====================================================

ALTER TABLE customers ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE products ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE invoices ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE product_categories ALTER COLUMN user_id SET NOT NULL;

-- =====================================================
-- 5. Foreign key kısıtlamaları ekle
-- =====================================================

-- Mevcut foreign key'leri kontrol et
SELECT 'Mevcut foreign key kısıtlamaları:' as islem;
SELECT 
    tc.table_name, 
    tc.constraint_name, 
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name IN ('customers', 'products', 'invoices', 'product_categories')
    AND tc.constraint_type = 'FOREIGN KEY'
    AND kcu.column_name = 'user_id';

-- Foreign key'leri ekle (eğer yoksa)
DO $$
BEGIN
    -- Customers için
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_customers_user'
    ) THEN
        ALTER TABLE customers 
        ADD CONSTRAINT fk_customers_user 
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
    
    -- Products için
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_products_user'
    ) THEN
        ALTER TABLE products 
        ADD CONSTRAINT fk_products_user 
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
    
    -- Invoices için
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_invoices_user'
    ) THEN
        ALTER TABLE invoices 
        ADD CONSTRAINT fk_invoices_user 
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
    
    -- Product categories için
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_product_categories_user'
    ) THEN
        ALTER TABLE product_categories 
        ADD CONSTRAINT fk_product_categories_user 
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
END $$;

-- =====================================================
-- 6. İndeksler oluştur
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_customers_user_id ON customers(user_id);
CREATE INDEX IF NOT EXISTS idx_products_user_id ON products(user_id);
CREATE INDEX IF NOT EXISTS idx_invoices_user_id ON invoices(user_id);
CREATE INDEX IF NOT EXISTS idx_product_categories_user_id ON product_categories(user_id);

-- =====================================================
-- 7. Sonuçları kontrol et
-- =====================================================

SELECT 'Migration tamamlandı! Sonuçlar:' as islem;

-- Kullanıcı başına veri sayısı
SELECT 
    'customers' as table_name,
    user_id,
    COUNT(*) as record_count
FROM customers 
GROUP BY user_id
UNION ALL
SELECT 
    'products' as table_name,
    user_id,
    COUNT(*) as record_count
FROM products 
GROUP BY user_id
UNION ALL
SELECT 
    'invoices' as table_name,
    user_id,
    COUNT(*) as record_count
FROM invoices 
GROUP BY user_id
UNION ALL
SELECT 
    'product_categories' as table_name,
    user_id,
    COUNT(*) as record_count
FROM product_categories 
GROUP BY user_id
ORDER BY table_name, user_id;

-- Örnek veriler
SELECT 'Örnek müşteriler:' as islem;
SELECT id, name, email, user_id FROM customers LIMIT 5;

SELECT 'Örnek faturalar:' as islem;
SELECT id, invoice_number, user_id, status FROM invoices LIMIT 5;

SELECT 'Örnek ürünler:' as islem;
SELECT id, name, price, user_id FROM products LIMIT 5;

-- =====================================================
-- MIGRATION TAMAMLANDI
-- ===================================================== 
-- =====================================================
-- KULLANICIYA ÖZEL VERİ YAPISI MIGRATION SCRIPT
-- =====================================================

-- 1. Önce mevcut tablolara user_id sütunu ekle
-- =====================================================

-- Customers tablosuna user_id sütunu ekle
ALTER TABLE customers ADD COLUMN IF NOT EXISTS user_id INTEGER;

-- Products tablosuna user_id sütunu ekle (eğer yoksa)
ALTER TABLE products ADD COLUMN IF NOT EXISTS user_id INTEGER;

-- Invoices tablosuna user_id sütunu ekle (eğer yoksa)
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS user_id INTEGER;

-- Product categories tablosuna user_id sütunu ekle (eğer yoksa)
ALTER TABLE product_categories ADD COLUMN IF NOT EXISTS user_id INTEGER;

-- =====================================================
-- 2. Mevcut verileri güncelle (varsayılan kullanıcıya ata)
-- =====================================================

-- Mevcut müşterileri varsayılan kullanıcıya ata (user_id = 1)
UPDATE customers SET user_id = 1 WHERE user_id IS NULL;

-- Mevcut ürünleri varsayılan kullanıcıya ata (user_id = 1)
UPDATE products SET user_id = 1 WHERE user_id IS NULL;

-- Mevcut faturaları varsayılan kullanıcıya ata (user_id = 1)
UPDATE invoices SET user_id = 1 WHERE user_id IS NULL;

-- Mevcut ürün kategorilerini varsayılan kullanıcıya ata (user_id = 1)
UPDATE product_categories SET user_id = 1 WHERE user_id IS NULL;

-- =====================================================
-- 3. NOT NULL kısıtlamaları ekle
-- =====================================================

-- user_id sütunlarını NOT NULL yap
ALTER TABLE customers ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE products ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE invoices ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE product_categories ALTER COLUMN user_id SET NOT NULL;

-- =====================================================
-- 4. Foreign key kısıtlamaları ekle
-- =====================================================

-- Customers tablosu için foreign key
ALTER TABLE customers 
ADD CONSTRAINT fk_customers_user 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- Products tablosu için foreign key
ALTER TABLE products 
ADD CONSTRAINT fk_products_user 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- Invoices tablosu için foreign key
ALTER TABLE invoices 
ADD CONSTRAINT fk_invoices_user 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- Product categories tablosu için foreign key
ALTER TABLE product_categories 
ADD CONSTRAINT fk_product_categories_user 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- =====================================================
-- 5. İndeksler oluştur (performans için)
-- =====================================================

-- user_id sütunları için indeksler
CREATE INDEX IF NOT EXISTS idx_customers_user_id ON customers(user_id);
CREATE INDEX IF NOT EXISTS idx_products_user_id ON products(user_id);
CREATE INDEX IF NOT EXISTS idx_invoices_user_id ON invoices(user_id);
CREATE INDEX IF NOT EXISTS idx_product_categories_user_id ON product_categories(user_id);

-- =====================================================
-- 6. Mevcut verileri kontrol et
-- =====================================================

-- Kullanıcı başına veri sayısını göster
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

-- =====================================================
-- 7. Test sorguları
-- =====================================================

-- Kullanıcı ID'si 8 olan kullanıcının verilerini kontrol et
SELECT 'customers' as table_name, COUNT(*) as count FROM customers WHERE user_id = 8
UNION ALL
SELECT 'products' as table_name, COUNT(*) as count FROM products WHERE user_id = 8
UNION ALL
SELECT 'invoices' as table_name, COUNT(*) as count FROM invoices WHERE user_id = 8
UNION ALL
SELECT 'product_categories' as table_name, COUNT(*) as count FROM product_categories WHERE user_id = 8;

-- =====================================================
-- MIGRATION TAMAMLANDI
-- ===================================================== 
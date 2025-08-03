-- =====================================================
-- POSTGRESQL MIGRATION - CURRENCY SÜTUNU EKLEME
-- =====================================================

-- Mevcut products tablosuna currency sütunu ekle
ALTER TABLE products ADD COLUMN IF NOT EXISTS currency VARCHAR(3) NOT NULL DEFAULT 'TRY';

-- Mevcut products tablosunda unit sütununu NOT NULL yap
ALTER TABLE products ALTER COLUMN unit SET NOT NULL;
ALTER TABLE products ALTER COLUMN unit SET DEFAULT 'Adet';

-- Mevcut kayıtları güncelle (eğer unit NULL ise)
UPDATE products SET unit = 'Adet' WHERE unit IS NULL;

-- Mevcut kayıtları güncelle (eğer currency NULL ise)
UPDATE products SET currency = 'TRY' WHERE currency IS NULL;

-- Users tablosundan tax_office sütununu kaldır (eğer varsa)
ALTER TABLE users DROP COLUMN IF EXISTS tax_office;

-- Ürün kategorileri tablosu oluştur
CREATE TABLE IF NOT EXISTS product_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    color VARCHAR(7) DEFAULT '#2196F3', -- Hex renk kodu
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Varsayılan kategorileri ekle
INSERT INTO product_categories (name, description, color) VALUES
('Elektronik', 'Elektronik ürünler', '#FF5722'),
('Giyim', 'Giyim ve aksesuar ürünleri', '#4CAF50'),
('Ev & Yaşam', 'Ev ve yaşam ürünleri', '#2196F3'),
('Spor', 'Spor ve fitness ürünleri', '#FF9800'),
('Kitap', 'Kitap ve yayınlar', '#9C27B0'),
('Gıda', 'Gıda ve içecek ürünleri', '#795548'),
('Kozmetik', 'Kozmetik ve kişisel bakım', '#E91E63'),
('Diğer', 'Diğer ürünler', '#607D8B')
ON CONFLICT (name) DO NOTHING;

-- Products tablosuna category_id sütunu ekle
ALTER TABLE products ADD COLUMN IF NOT EXISTS category_id INTEGER REFERENCES product_categories(id) ON DELETE SET NULL;

-- Mevcut ürünleri "Diğer" kategorisine ata
UPDATE products SET category_id = (SELECT id FROM product_categories WHERE name = 'Diğer' LIMIT 1) WHERE category_id IS NULL;

-- Kategori indeksi oluştur
CREATE INDEX IF NOT EXISTS idx_products_category_id ON products(category_id);

-- Kategori adı için indeks
CREATE INDEX IF NOT EXISTS idx_product_categories_name ON product_categories(name);

-- PostgreSQL Migration Script - Ürünler Kullanıcıya Özel Hale Getiriliyor
-- Bu script mevcut PostgreSQL veritabanını günceller

-- Ürünler tablosuna user_id sütunu ekle
ALTER TABLE products ADD COLUMN IF NOT EXISTS user_id INTEGER REFERENCES users(id) ON DELETE CASCADE;

-- Mevcut ürünleri varsayılan kullanıcıya ata (ilk kullanıcı)
UPDATE products SET user_id = (SELECT id FROM users LIMIT 1) WHERE user_id IS NULL;

-- user_id sütununu NOT NULL yap
ALTER TABLE products ALTER COLUMN user_id SET NOT NULL;

-- Ürünler için user_id indeksi oluştur (performans için)
CREATE INDEX IF NOT EXISTS idx_products_user_id ON products(user_id);

-- Kategoriler de kullanıcıya özel olsun
ALTER TABLE product_categories ADD COLUMN IF NOT EXISTS user_id INTEGER REFERENCES users(id) ON DELETE CASCADE;

-- Mevcut kategorileri varsayılan kullanıcıya ata
UPDATE product_categories SET user_id = (SELECT id FROM users LIMIT 1) WHERE user_id IS NULL;

-- Kategoriler için user_id indeksi oluştur
CREATE INDEX IF NOT EXISTS idx_product_categories_user_id ON product_categories(user_id);

-- Ürünler tablosunda user_id ve name kombinasyonu için unique constraint
CREATE UNIQUE INDEX IF NOT EXISTS idx_products_user_name_unique ON products(user_id, name);

-- Kategoriler tablosunda user_id ve name kombinasyonu için unique constraint
CREATE UNIQUE INDEX IF NOT EXISTS idx_product_categories_user_name_unique ON product_categories(user_id, name);

-- =====================================================
-- INVOICE SYSTEM REVERT - User yerine Customer kullanımına geri dönüş
-- =====================================================

-- Invoices tablosundan user_id sütununu kaldır
ALTER TABLE invoices DROP COLUMN IF EXISTS user_id;

-- user_id ile ilgili indeksleri kaldır
DROP INDEX IF EXISTS idx_invoices_user_id;

-- Debug için mevcut verileri kontrol et
SELECT 'Products count:' as info, COUNT(*) as count FROM products;
SELECT 'Categories count:' as info, COUNT(*) as count FROM product_categories;
SELECT 'Users count:' as info, COUNT(*) as count FROM users;
SELECT 'Invoices count:' as info, COUNT(*) as count FROM invoices;

-- Tablo yapılarını kontrol et
SELECT 'products' as table_name, column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'products' 
ORDER BY ordinal_position;

SELECT 'users' as table_name, column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position;

SELECT 'invoices' as table_name, column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'invoices' 
ORDER BY ordinal_position; 
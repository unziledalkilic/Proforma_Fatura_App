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

-- Tablo yapılarını kontrol et
SELECT 'products' as table_name, column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'products' 
ORDER BY ordinal_position;

SELECT 'users' as table_name, column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position; 
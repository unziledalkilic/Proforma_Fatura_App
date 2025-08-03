-- =====================================================
-- PROFORMA FATURA VERİTABANI KURULUM SCRIPTİ
-- PostgreSQL için tablo oluşturma kodları
-- =====================================================

-- Veritabanı oluşturma (pgAdmin'de manuel olarak yapın)
-- CREATE DATABASE proforma_fatura_db;

-- Veritabanına bağlanın
-- \c proforma_fatura_db;

-- =====================================================
-- 1. KULLANICILAR TABLOSU
-- =====================================================
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    company_name VARCHAR(100),
    phone VARCHAR(20),
    address TEXT,
    tax_number VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 2. MÜŞTERİLER TABLOSU
-- =====================================================
CREATE TABLE IF NOT EXISTS customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    phone VARCHAR(20),
    address TEXT,
    tax_number VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 3. ÜRÜN KATEGORİLERİ TABLOSU
-- =====================================================
CREATE TABLE IF NOT EXISTS product_categories (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    color VARCHAR(7) DEFAULT '#2196F3',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 4. ÜRÜNLER TABLOSU
-- =====================================================
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    category_id INTEGER REFERENCES product_categories(id) ON DELETE SET NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'TRY',
    unit VARCHAR(20) NOT NULL DEFAULT 'Adet',
    barcode VARCHAR(50),
    tax_rate DECIMAL(5,2) DEFAULT 18.00,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 5. FATURALAR TABLOSU
-- =====================================================
CREATE TABLE IF NOT EXISTS invoices (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    invoice_number VARCHAR(50) UNIQUE NOT NULL,
    customer_id INTEGER REFERENCES customers(id) ON DELETE CASCADE NOT NULL,
    invoice_date DATE NOT NULL,
    due_date DATE NOT NULL,
    notes TEXT,
    terms TEXT,
    discount_rate DECIMAL(5,2) DEFAULT 0.00,
    status VARCHAR(20) DEFAULT 'draft',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 6. FATURA KALEMLERİ TABLOSU
-- =====================================================
CREATE TABLE IF NOT EXISTS invoice_items (
    id SERIAL PRIMARY KEY,
    invoice_id INTEGER REFERENCES invoices(id) ON DELETE CASCADE NOT NULL,
    product_id INTEGER REFERENCES products(id) ON DELETE CASCADE NOT NULL,
    quantity DECIMAL(10,2) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    discount_rate DECIMAL(5,2) DEFAULT 0.00,
    tax_rate DECIMAL(5,2) DEFAULT 0.00,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- İNDEKSLER (PERFORMANS İÇİN)
-- =====================================================

-- Kullanıcılar için indeksler
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_active ON users(is_active);

-- Müşteriler için indeksler
CREATE INDEX IF NOT EXISTS idx_customers_name ON customers(name);
CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email);
CREATE INDEX IF NOT EXISTS idx_customers_tax_number ON customers(tax_number);

-- Ürün kategorileri için indeksler
CREATE INDEX IF NOT EXISTS idx_product_categories_user_id ON product_categories(user_id);
CREATE INDEX IF NOT EXISTS idx_product_categories_name ON product_categories(name);

-- Ürünler için indeksler
CREATE INDEX IF NOT EXISTS idx_products_user_id ON products(user_id);
CREATE INDEX IF NOT EXISTS idx_products_category_id ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_name ON products(name);
CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode);
CREATE INDEX IF NOT EXISTS idx_products_price ON products(price);

-- Faturalar için indeksler
CREATE INDEX IF NOT EXISTS idx_invoices_user_id ON invoices(user_id);
CREATE INDEX IF NOT EXISTS idx_invoices_number ON invoices(invoice_number);
CREATE INDEX IF NOT EXISTS idx_invoices_customer_id ON invoices(customer_id);
CREATE INDEX IF NOT EXISTS idx_invoices_date ON invoices(invoice_date);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices(status);

-- Fatura kalemleri için indeksler
CREATE INDEX IF NOT EXISTS idx_invoice_items_invoice_id ON invoice_items(invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_items_product_id ON invoice_items(product_id);

-- =====================================================
-- TRIGGER'LAR (AUTOMATIC UPDATED_AT)
-- =====================================================

-- Kullanıcılar için updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger'ları oluştur
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_customers_updated_at ON customers;
CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON customers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_product_categories_updated_at ON product_categories;
CREATE TRIGGER update_product_categories_updated_at BEFORE UPDATE ON product_categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_products_updated_at ON products;
CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_invoices_updated_at ON invoices;
CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON invoices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_invoice_items_updated_at ON invoice_items;
CREATE TRIGGER update_invoice_items_updated_at BEFORE UPDATE ON invoice_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- ÖRNEK VERİLER (İSTEĞE BAĞLI)
-- =====================================================

-- Örnek kullanıcı (şifre: 12345678)
INSERT INTO users (username, email, password_hash, full_name, phone) VALUES
('admin@example.com', 'admin@example.com', 'MTIzNDU2Nzg=', 'Admin User', '0555 123 45 67')
ON CONFLICT (username) DO NOTHING;

-- Örnek müşteriler
INSERT INTO customers (name, email, phone, address, tax_number) VALUES
('ABC Şirketi A.Ş.', 'info@abc.com', '0212 555 01 01', 'İstanbul, Türkiye', '1234567890'),
('XYZ Ltd. Şti.', 'contact@xyz.com', '0312 555 02 02', 'Ankara, Türkiye', '0987654321'),
('DEF Ticaret', 'info@def.com', '0232 555 03 03', 'İzmir, Türkiye', '1122334455')
ON CONFLICT DO NOTHING;

-- Örnek ürün kategorileri
INSERT INTO product_categories (user_id, name, description, color) VALUES
(1, 'Elektronik', 'Elektronik ürünler', '#FF5722'),
(1, 'Giyim', 'Giyim ürünleri', '#2196F3'),
(1, 'Ev & Yaşam', 'Ev ve yaşam ürünleri', '#4CAF50'),
(1, 'Spor', 'Spor ürünleri', '#FF9800'),
(1, 'Kitap', 'Kitap ve yayınlar', '#9C27B0'),
(1, 'Gıda', 'Gıda ürünleri', '#795548'),
(1, 'Kozmetik', 'Kozmetik ürünleri', '#E91E63'),
(1, 'Diğer', 'Diğer ürünler', '#9E9E9E')
ON CONFLICT DO NOTHING;

-- Örnek ürünler
INSERT INTO products (user_id, category_id, name, description, price, unit, tax_rate) VALUES
(1, 1, 'Laptop', 'Dizüstü bilgisayar', 15000.00, 'adet', 18.00),
(1, 1, 'Mouse', 'Kablosuz mouse', 150.00, 'adet', 18.00),
(1, 1, 'Klavye', 'Mekanik klavye', 500.00, 'adet', 18.00),
(1, 1, 'Monitör', '24 inç LED monitör', 2000.00, 'adet', 18.00),
(1, 1, 'Yazıcı', 'Lazer yazıcı', 3000.00, 'adet', 18.00)
ON CONFLICT DO NOTHING;

-- =====================================================
-- VERİTABANI BİLGİLERİ
-- =====================================================

-- Tabloları listele
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Tablo yapılarını görüntüle (pgAdmin için uygun SQL sorguları)
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position;

SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'customers' 
ORDER BY ordinal_position;

SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'product_categories' 
ORDER BY ordinal_position;

SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'products' 
ORDER BY ordinal_position;

SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'invoices' 
ORDER BY ordinal_position;

SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'invoice_items' 
ORDER BY ordinal_position; 

-- Firma bilgileri tablosu
CREATE TABLE IF NOT EXISTS company_info (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address TEXT,
    phone VARCHAR(50),
    email VARCHAR(255),
    website VARCHAR(255),
    tax_number VARCHAR(50),
    tax_office VARCHAR(255),
    logo TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Firma bilgileri için index
CREATE INDEX IF NOT EXISTS idx_company_info_name ON company_info(name);

-- Örnek firma bilgileri
INSERT INTO company_info (name, address, phone, email, website, tax_number, tax_office) VALUES 
('ABC Şirketi A.Ş.', 'İstanbul, Türkiye', '+90 212 123 45 67', 'info@abc.com', 'www.abc.com', '1234567890', 'İstanbul Vergi Dairesi')
ON CONFLICT DO NOTHING; 
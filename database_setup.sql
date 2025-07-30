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
CREATE TABLE users (
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
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    phone VARCHAR(20),
    address TEXT,
    tax_number VARCHAR(20),
    tax_office VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 3. ÜRÜNLER TABLOSU
-- =====================================================
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'TRY',
    unit VARCHAR(20) NOT NULL DEFAULT 'Adet',
    barcode VARCHAR(50),
    tax_rate DECIMAL(5,2) DEFAULT 18.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 4. FATURALAR TABLOSU
-- =====================================================
CREATE TABLE invoices (
    id SERIAL PRIMARY KEY,
    invoice_number VARCHAR(50) NOT NULL UNIQUE,
    customer_id INTEGER NOT NULL,
    invoice_date DATE NOT NULL,
    due_date DATE NOT NULL,
    notes TEXT,
    terms TEXT,
    discount_rate DECIMAL(5,2) DEFAULT 0.00,
    status VARCHAR(20) DEFAULT 'draft',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);

-- =====================================================
-- 5. FATURA KALEMLERİ TABLOSU
-- =====================================================
CREATE TABLE invoice_items (
    id SERIAL PRIMARY KEY,
    invoice_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity DECIMAL(10,2) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    discount_rate DECIMAL(5,2) DEFAULT 0.00,
    tax_rate DECIMAL(5,2) DEFAULT 18.00,
    notes TEXT,
    FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

-- =====================================================
-- İNDEKSLER (PERFORMANS İÇİN)
-- =====================================================

-- Kullanıcılar için indeksler
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_active ON users(is_active);

-- Müşteriler için indeksler
CREATE INDEX idx_customers_name ON customers(name);
CREATE INDEX idx_customers_email ON customers(email);
CREATE INDEX idx_customers_tax_number ON customers(tax_number);

-- Ürünler için indeksler
CREATE INDEX idx_products_name ON products(name);
CREATE INDEX idx_products_barcode ON products(barcode);
CREATE INDEX idx_products_price ON products(price);

-- Faturalar için indeksler
CREATE INDEX idx_invoices_number ON invoices(invoice_number);
CREATE INDEX idx_invoices_customer_id ON invoices(customer_id);
CREATE INDEX idx_invoices_date ON invoices(invoice_date);
CREATE INDEX idx_invoices_status ON invoices(status);

-- Fatura kalemleri için indeksler
CREATE INDEX idx_invoice_items_invoice_id ON invoice_items(invoice_id);
CREATE INDEX idx_invoice_items_product_id ON invoice_items(product_id);

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
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON customers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON invoices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- ÖRNEK VERİLER (İSTEĞE BAĞLI)
-- =====================================================

-- Örnek kullanıcı (şifre: 12345678)
INSERT INTO users (username, email, password_hash, full_name, phone) VALUES
('admin@example.com', 'admin@example.com', 'MTIzNDU2Nzg=', 'Admin User', '0555 123 45 67');

-- Örnek müşteriler
INSERT INTO customers (name, email, phone, address, tax_number, tax_office) VALUES
('ABC Şirketi A.Ş.', 'info@abc.com', '0212 555 01 01', 'İstanbul, Türkiye', '1234567890', 'Kadıköy'),
('XYZ Ltd. Şti.', 'contact@xyz.com', '0312 555 02 02', 'Ankara, Türkiye', '0987654321', 'Çankaya'),
('DEF Ticaret', 'info@def.com', '0232 555 03 03', 'İzmir, Türkiye', '1122334455', 'Konak');

-- Örnek ürünler
INSERT INTO products (name, description, price, unit, tax_rate) VALUES
('Laptop', 'Dizüstü bilgisayar', 15000.00, 'adet', 18.00),
('Mouse', 'Kablosuz mouse', 150.00, 'adet', 18.00),
('Klavye', 'Mekanik klavye', 500.00, 'adet', 18.00),
('Monitör', '24 inç LED monitör', 2000.00, 'adet', 18.00),
('Yazıcı', 'Lazer yazıcı', 3000.00, 'adet', 18.00);

-- =====================================================
-- VERİTABANI BİLGİLERİ
-- =====================================================

-- Tabloları listele
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Tablo yapılarını görüntüle
\d users;
\d customers;
\d products;
\d invoices;
\d invoice_items; 
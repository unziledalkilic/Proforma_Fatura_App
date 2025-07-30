import 'package:postgres/postgres.dart';
import '../models/user.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/product_category.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';

class PostgresService {
  static final PostgresService _instance = PostgresService._internal();
  factory PostgresService() => _instance;
  PostgresService._internal();

  PostgreSQLConnection? _connection;
  bool _isConnected = false;

  // Veritabanı bağlantı bilgileri
  // Android emülatörü için 10.0.2.2, gerçek cihaz için localhost
  static const String _host = '10.0.2.2';
  static const int _port = 5432;
  static const String _database = 'proforma_fatura_db';
  static const String _username = 'postgres';
  static const String _password = 'Proforma123';

  bool get isConnected => _isConnected;

  /// PostgreSQL veritabanına bağlan
  Future<bool> connect() async {
    try {
      print('🔄 PostgreSQL bağlantısı kuruluyor...');
      print('📍 Host: $_host, Port: $_port, Database: $_database');
      _connection = PostgreSQLConnection(
        _host,
        _port,
        _database,
        username: _username,
        password: _password,
      );

      await _connection!.open();
      _isConnected = true;
      print('✅ PostgreSQL bağlantısı başarılı!');
      return true;
    } catch (e) {
      print('❌ PostgreSQL bağlantı hatası: $e');
      _isConnected = false;
      return false;
    }
  }

  /// Bağlantıyı kapat
  Future<void> disconnect() async {
    if (_connection != null) {
      await _connection!.close();
      _isConnected = false;
      print('🔌 PostgreSQL bağlantısı kapatıldı');
    }
  }

  // =====================================================
  // KULLANICI İŞLEMLERİ
  // =====================================================

  /// Kullanıcı kaydet
  Future<int?> insertUser(User user) async {
    if (!_isConnected) return null;
    try {
      final results = await _connection!.query(
        'INSERT INTO users (username, email, password_hash, full_name, phone, company_name, address, tax_number) VALUES (@username, @email, @passwordHash, @fullName, @phone, @companyName, @address, @taxNumber) RETURNING id',
        substitutionValues: {
          'username': user.username,
          'email': user.email,
          'passwordHash': user.passwordHash,
          'fullName': user.fullName,
          'phone': user.phone,
          'companyName': user.companyName,
          'address': user.address,
          'taxNumber': user.taxNumber,
        },
      );
      if (results.isNotEmpty && results[0].isNotEmpty) {
        return results[0][0] as int;
      }
      return null;
    } catch (e) {
      print('❌ Kullanıcı ekleme hatası: $e');
      return null;
    }
  }

  /// Kullanıcı giriş kontrolü
  Future<User?> getUserByUsernameOrEmail(String username, String email) async {
    if (!_isConnected) return null;
    try {
      final results = await _connection!.query(
        'SELECT * FROM users WHERE (username = @username OR email = @email) AND is_active = true',
        substitutionValues: {'username': username, 'email': email},
      );
      if (results.isNotEmpty) {
        final row = results[0];
        return User(
          id: row[0] as int,
          username: row[1] as String,
          email: row[2] as String,
          passwordHash: row[3] as String,
          fullName: row[4] as String?,
          companyName: row[5] as String?,
          phone: row[6] as String?,
          address: row[7] as String?,
          taxNumber: row[8]?.toString(),
          isActive: row[9] as bool,
          createdAt: DateTime.parse(row[10].toString()),
          updatedAt: DateTime.parse(row[11].toString()),
        );
      }
      return null;
    } catch (e) {
      print('❌ Kullanıcı sorgulama hatası: $e');
      return null;
    }
  }

  /// Kullanıcı güncelle
  Future<bool> updateUser(User user) async {
    if (!_isConnected || user.id == null) return false;
    try {
      await _connection!.execute(
        'UPDATE users SET full_name = @fullName, company_name = @companyName, phone = @phone, address = @address, tax_number = @taxNumber WHERE id = @id',
        substitutionValues: {
          'id': user.id,
          'fullName': user.fullName,
          'companyName': user.companyName,
          'phone': user.phone,
          'address': user.address,
          'taxNumber': user.taxNumber,
        },
      );
      return true;
    } catch (e) {
      print('❌ Kullanıcı güncelleme hatası: $e');
      return false;
    }
  }

  // =====================================================
  // MÜŞTERİ İŞLEMLERİ
  // =====================================================

  /// Müşteri ekle
  Future<int?> insertCustomer(Customer customer) async {
    if (!_isConnected) return null;
    try {
      final results = await _connection!.query(
        'INSERT INTO customers (name, email, phone, address, tax_number, tax_office) VALUES (@name, @email, @phone, @address, @taxNumber, @taxOffice) RETURNING id',
        substitutionValues: {
          'name': customer.name,
          'email': customer.email,
          'phone': customer.phone,
          'address': customer.address,
          'taxNumber': customer.taxNumber,
          'taxOffice': customer.taxOffice,
        },
      );
      if (results.isNotEmpty && results[0].isNotEmpty) {
        return results[0][0] as int;
      }
      return null;
    } catch (e) {
      print('❌ Müşteri ekleme hatası: $e');
      return null;
    }
  }

  /// Tüm müşterileri getir
  Future<List<Customer>> getAllCustomers() async {
    if (!_isConnected) return [];
    try {
      final results = await _connection!.query(
        'SELECT * FROM customers ORDER BY name',
      );
      return results
          .map(
            (row) => Customer(
              id: row[0] as int,
              name: row[1] as String,
              email: row[2] as String?,
              phone: row[3] as String?,
              address: row[4] as String?,
              taxNumber: row[5] as String?,
              taxOffice: row[6] as String?,
              createdAt: DateTime.parse(row[7].toString()),
              updatedAt: DateTime.parse(row[8].toString()),
            ),
          )
          .toList();
    } catch (e) {
      print('❌ Müşteri listesi hatası: $e');
      return [];
    }
  }

  /// Müşteri güncelle
  Future<bool> updateCustomer(Customer customer) async {
    if (!_isConnected || customer.id == null) return false;
    try {
      await _connection!.execute(
        'UPDATE customers SET name = @name, email = @email, phone = @phone, address = @address, tax_number = @taxNumber, tax_office = @taxOffice, updated_at = CURRENT_TIMESTAMP WHERE id = @id',
        substitutionValues: {
          'id': customer.id,
          'name': customer.name,
          'email': customer.email,
          'phone': customer.phone,
          'address': customer.address,
          'taxNumber': customer.taxNumber,
          'taxOffice': customer.taxOffice,
        },
      );
      return true;
    } catch (e) {
      print('❌ Müşteri güncelleme hatası: $e');
      return false;
    }
  }

  /// Müşteri sil
  Future<bool> deleteCustomer(int id) async {
    if (!_isConnected) return false;
    try {
      await _connection!.execute(
        'DELETE FROM customers WHERE id = @id',
        substitutionValues: {'id': id},
      );
      return true;
    } catch (e) {
      print('❌ Müşteri silme hatası: $e');
      return false;
    }
  }

  /// Müşteri getir (ID ile)
  Future<Customer?> getCustomerById(int id) async {
    if (!_isConnected) return null;
    try {
      final results = await _connection!.query(
        'SELECT * FROM customers WHERE id = @id',
        substitutionValues: {'id': id},
      );
      if (results.isNotEmpty) {
        final row = results[0];
        return Customer(
          id: row[0] as int,
          name: row[1] as String,
          email: row[2] as String?,
          phone: row[3] as String?,
          address: row[4] as String?,
          taxNumber: row[5] as String?,
          taxOffice: row[6] as String?,
          createdAt: DateTime.parse(row[7].toString()),
          updatedAt: DateTime.parse(row[8].toString()),
        );
      }
      return null;
    } catch (e) {
      print('❌ Müşteri getirme hatası: $e');
      return null;
    }
  }

  // =====================================================
  // ÜRÜN İŞLEMLERİ
  // =====================================================

  /// Ürün ekle
  Future<int?> insertProduct(Product product) async {
    if (!_isConnected) return null;
    try {
      final results = await _connection!.query(
        'INSERT INTO products (name, description, price, currency, unit, barcode, tax_rate, category_id) VALUES (@name, @description, @price, @currency, @unit, @barcode, @taxRate, @categoryId) RETURNING id',
        substitutionValues: {
          'name': product.name,
          'description': product.description,
          'price': product.price,
          'currency': product.currency,
          'unit': product.unit,
          'barcode': product.barcode,
          'taxRate': product.taxRate,
          'categoryId': product.category?.id,
        },
      );
      if (results.isNotEmpty && results[0].isNotEmpty) {
        return results[0][0] as int;
      }
      return null;
    } catch (e) {
      print('❌ Ürün ekleme hatası: $e');
      return null;
    }
  }

  /// Tüm ürünleri getir
  Future<List<Product>> getAllProducts() async {
    if (!_isConnected) {
      print('❌ PostgreSQL bağlantısı yok!');
      return [];
    }
    try {
      print('🔄 PostgreSQL\'den ürünler getiriliyor...');

      // Önce kategorisiz ürünleri "Diğer" kategorisine ata
      await _connection!.execute('''
        UPDATE products 
        SET category_id = (SELECT id FROM product_categories WHERE name = 'Diğer' LIMIT 1) 
        WHERE category_id IS NULL
      ''');

      final results = await _connection!.query('''
        SELECT p.id, p.name, p.description, p.price, p.unit, p.barcode, p.tax_rate, 
               p.created_at, p.updated_at, p.currency, p.category_id,
               pc.id as cat_id, pc.name as cat_name, pc.description as cat_description, 
               pc.color as cat_color, pc.is_active as cat_is_active, 
               pc.created_at as cat_created_at, pc.updated_at as cat_updated_at
        FROM products p 
        LEFT JOIN product_categories pc ON p.category_id = pc.id 
        ORDER BY p.name
        ''');
      print('✅ PostgreSQL\'den ${results.length} ürün getirildi');

      return results.map((row) {
        ProductCategory? category;
        if (row[11] != null) {
          // cat_id
          category = ProductCategory(
            id: row[11] as int,
            name: row[12] as String,
            description: row[13] as String?,
            color: row[14] as String,
            isActive: row[15] as bool,
            createdAt: DateTime.parse(row[16].toString()),
            updatedAt: DateTime.parse(row[17].toString()),
          );
        }

        return Product(
          id: row[0] as int,
          name: row[1] as String,
          description: row[2] as String?,
          price: double.tryParse(row[3].toString()) ?? 0.0,
          currency: row[9] as String, // row[9] = currency
          unit: row[4] as String, // row[4] = unit
          barcode: row[5] as String?, // row[5] = barcode
          taxRate:
              double.tryParse(row[6].toString()) ?? 0.0, // row[6] = tax_rate
          category: category,
          createdAt: DateTime.parse(row[7].toString()), // row[7] = created_at
          updatedAt: DateTime.parse(row[8].toString()), // row[8] = updated_at
        );
      }).toList();
    } catch (e) {
      print('❌ Ürün listesi hatası: $e');
      return [];
    }
  }

  /// Ürün güncelle
  Future<bool> updateProduct(Product product) async {
    if (!_isConnected || product.id == null) return false;
    try {
      await _connection!.execute(
        'UPDATE products SET name = @name, description = @description, price = @price, currency = @currency, unit = @unit, barcode = @barcode, tax_rate = @taxRate, category_id = @categoryId, updated_at = CURRENT_TIMESTAMP WHERE id = @id',
        substitutionValues: {
          'id': product.id,
          'name': product.name,
          'description': product.description,
          'price': product.price,
          'currency': product.currency,
          'unit': product.unit,
          'barcode': product.barcode,
          'taxRate': product.taxRate,
          'categoryId': product.category?.id,
        },
      );
      return true;
    } catch (e) {
      print('❌ Ürün güncelleme hatası: $e');
      return false;
    }
  }

  /// Ürün getir (ID ile)
  Future<Product?> getProductById(int id) async {
    if (!_isConnected) return null;
    try {
      // Önce bu ürünü "Diğer" kategorisine ata (eğer kategorisiz ise)
      await _connection!.execute(
        '''
        UPDATE products 
        SET category_id = (SELECT id FROM product_categories WHERE name = 'Diğer' LIMIT 1) 
        WHERE id = @id AND category_id IS NULL
      ''',
        substitutionValues: {'id': id},
      );

      final results = await _connection!.query(
        '''
        SELECT p.id, p.name, p.description, p.price, p.unit, p.barcode, p.tax_rate, 
               p.created_at, p.updated_at, p.currency, p.category_id,
               pc.id as cat_id, pc.name as cat_name, pc.description as cat_description, 
               pc.color as cat_color, pc.is_active as cat_is_active, 
               pc.created_at as cat_created_at, pc.updated_at as cat_updated_at
        FROM products p 
        LEFT JOIN product_categories pc ON p.category_id = pc.id 
        WHERE p.id = @id
        ''',
        substitutionValues: {'id': id},
      );
      if (results.isNotEmpty) {
        final row = results[0];
        ProductCategory? category;
        if (row[11] != null) {
          // cat_id
          category = ProductCategory(
            id: row[11] as int,
            name: row[12] as String,
            description: row[13] as String?,
            color: row[14] as String,
            isActive: row[15] as bool,
            createdAt: DateTime.parse(row[16].toString()),
            updatedAt: DateTime.parse(row[17].toString()),
          );
        }

        return Product(
          id: row[0] as int,
          name: row[1] as String,
          description: row[2] as String?,
          price: double.tryParse(row[3].toString()) ?? 0.0,
          currency: row[9] as String, // row[9] = currency
          unit: row[4] as String, // row[4] = unit
          barcode: row[5] as String?, // row[5] = barcode
          taxRate:
              double.tryParse(row[6].toString()) ?? 0.0, // row[6] = tax_rate
          category: category,
          createdAt: DateTime.parse(row[7].toString()), // row[7] = created_at
          updatedAt: DateTime.parse(row[8].toString()), // row[8] = updated_at
        );
      }
      return null;
    } catch (e) {
      print('❌ Ürün getirme hatası: $e');
      return null;
    }
  }

  /// Ürün sil
  Future<bool> deleteProduct(int id) async {
    if (!_isConnected) return false;
    try {
      await _connection!.execute(
        'DELETE FROM products WHERE id = @id',
        substitutionValues: {'id': id},
      );
      return true;
    } catch (e) {
      print('❌ Ürün silme hatası: $e');
      return false;
    }
  }

  // =====================================================
  // KATEGORİ İŞLEMLERİ
  // =====================================================

  /// Tüm kategorileri getir
  Future<List<ProductCategory>> getAllCategories() async {
    if (!_isConnected) return [];
    try {
      final results = await _connection!.query(
        'SELECT * FROM product_categories WHERE is_active = true ORDER BY name',
      );
      return results
          .map(
            (row) => ProductCategory(
              id: row[0] as int,
              name: row[1] as String,
              description: row[2] as String?,
              color: row[3] as String,
              isActive: row[4] as bool,
              createdAt: DateTime.parse(row[5].toString()),
              updatedAt: DateTime.parse(row[6].toString()),
            ),
          )
          .toList();
    } catch (e) {
      print('❌ Kategori listesi hatası: $e');
      print('❌ Hata detayı: ${e.toString()}');
      return [];
    }
  }

  /// Kategori ekle
  Future<int?> insertCategory(ProductCategory category) async {
    if (!_isConnected) return null;
    try {
      print('🔄 Kategori ekleniyor: ${category.name}');
      final results = await _connection!.query(
        'INSERT INTO product_categories (name, description, color) VALUES (@name, @description, @color) RETURNING id',
        substitutionValues: {
          'name': category.name,
          'description': category.description,
          'color': category.color,
        },
      );
      if (results.isNotEmpty && results[0].isNotEmpty) {
        final id = results[0][0] as int;
        print('✅ Kategori eklendi. ID: $id');
        return id;
      }
      print('❌ Kategori eklenemedi: Sonuç boş');
      return null;
    } catch (e) {
      print('❌ Kategori ekleme hatası: $e');
      print('❌ Hata detayı: ${e.toString()}');
      return null;
    }
  }

  // =====================================================
  // FATURA İŞLEMLERİ
  // =====================================================

  /// Fatura ekle
  Future<int?> insertInvoice(Invoice invoice) async {
    if (!_isConnected) return null;
    try {
      final results = await _connection!.query(
        'INSERT INTO invoices (invoice_number, customer_id, invoice_date, due_date, notes, terms, discount_rate, status) VALUES (@invoiceNumber, @customerId, @invoiceDate, @dueDate, @notes, @terms, @discountRate, @status) RETURNING id',
        substitutionValues: {
          'invoiceNumber': invoice.invoiceNumber,
          'customerId': invoice.customer.id,
          'invoiceDate': invoice.invoiceDate.toIso8601String().split('T')[0],
          'dueDate': invoice.dueDate.toIso8601String().split('T')[0],
          'notes': invoice.notes,
          'terms': invoice.terms,
          'discountRate': invoice.discountRate,
          'status': invoice.status.toString().split('.').last,
        },
      );
      if (results.isNotEmpty && results[0].isNotEmpty) {
        return results[0][0] as int;
      }
      return null;
    } catch (e) {
      print('❌ Fatura ekleme hatası: $e');
      return null;
    }
  }

  /// Tüm faturaları getir
  Future<List<Invoice>> getAllInvoices() async {
    if (!_isConnected) return [];
    try {
      final results = await _connection!.query(
        'SELECT c.*, i.* FROM invoices i JOIN customers c ON i.customer_id = c.id ORDER BY i.invoice_date DESC',
      );
      return results.map((row) {
        final customer = Customer(
          id: row[0] as int,
          name: row[1] as String,
          email: row[2] as String?,
          phone: row[3] as String?,
          address: row[4] as String?,
          taxNumber: row[5] as String?,
          taxOffice: row[6] as String?,
          createdAt: DateTime.parse(row[7].toString()),
          updatedAt: DateTime.parse(row[8].toString()),
        );
        // InvoiceStatus enum ise stringden dönüştür
        final statusStr = row[16] as String;
        final status = InvoiceStatus.values.firstWhere(
          (e) => e.toString().split('.').last == statusStr,
          orElse: () => InvoiceStatus.draft,
        );
        return Invoice(
          id: row[9] as int,
          invoiceNumber: row[10] as String,
          customer: customer,
          invoiceDate: DateTime.parse(row[11].toString()),
          dueDate: DateTime.parse(row[12].toString()),
          notes: row[13] as String?,
          terms: row[14] as String?,
          discountRate: (row[15] as num).toDouble(),
          status: status,
          createdAt: DateTime.parse(row[17].toString()),
          updatedAt: DateTime.parse(row[18].toString()),
          items: const [],
        );
      }).toList();
    } catch (e) {
      print('❌ Fatura listesi hatası: $e');
      return [];
    }
  }

  /// Fatura güncelle
  Future<bool> updateInvoice(Invoice invoice) async {
    if (!_isConnected || invoice.id == null) return false;
    try {
      await _connection!.execute(
        'UPDATE invoices SET invoice_number = @invoiceNumber, customer_id = @customerId, invoice_date = @invoiceDate, due_date = @dueDate, notes = @notes, terms = @terms, discount_rate = @discountRate, status = @status, updated_at = CURRENT_TIMESTAMP WHERE id = @id',
        substitutionValues: {
          'id': invoice.id,
          'invoiceNumber': invoice.invoiceNumber,
          'customerId': invoice.customer.id,
          'invoiceDate': invoice.invoiceDate.toIso8601String().split('T')[0],
          'dueDate': invoice.dueDate.toIso8601String().split('T')[0],
          'notes': invoice.notes,
          'terms': invoice.terms,
          'discountRate': invoice.discountRate,
          'status': invoice.status.toString().split('.').last,
        },
      );
      return true;
    } catch (e) {
      print('❌ Fatura güncelleme hatası: $e');
      return false;
    }
  }

  /// Fatura sil
  Future<bool> deleteInvoice(int id) async {
    if (!_isConnected) return false;
    try {
      await _connection!.execute(
        'DELETE FROM invoices WHERE id = @id',
        substitutionValues: {'id': id},
      );
      return true;
    } catch (e) {
      print('❌ Fatura silme hatası: $e');
      return false;
    }
  }

  /// Fatura getir (ID ile)
  Future<Invoice?> getInvoiceById(int id) async {
    if (!_isConnected) return null;
    try {
      final results = await _connection!.query(
        'SELECT c.*, i.* FROM invoices i JOIN customers c ON i.customer_id = c.id WHERE i.id = @id',
        substitutionValues: {'id': id},
      );
      if (results.isNotEmpty) {
        final row = results[0];
        final customer = Customer(
          id: row[0] as int,
          name: row[1] as String,
          email: row[2] as String?,
          phone: row[3] as String?,
          address: row[4] as String?,
          taxNumber: row[5] as String?,
          taxOffice: row[6] as String?,
          createdAt: DateTime.parse(row[7].toString()),
          updatedAt: DateTime.parse(row[8].toString()),
        );
        final statusStr = row[16] as String;
        final status = InvoiceStatus.values.firstWhere(
          (e) => e.toString().split('.').last == statusStr,
          orElse: () => InvoiceStatus.draft,
        );
        return Invoice(
          id: row[9] as int,
          invoiceNumber: row[10] as String,
          customer: customer,
          invoiceDate: DateTime.parse(row[11].toString()),
          dueDate: DateTime.parse(row[12].toString()),
          notes: row[13] as String?,
          terms: row[14] as String?,
          discountRate: (row[15] as num).toDouble(),
          status: status,
          createdAt: DateTime.parse(row[17].toString()),
          updatedAt: DateTime.parse(row[18].toString()),
          items: const [],
        );
      }
      return null;
    } catch (e) {
      print('❌ Fatura getirme hatası: $e');
      return null;
    }
  }

  // =====================================================
  // FATURA KALEMİ İŞLEMLERİ
  // =====================================================

  /// Fatura kalemi ekle
  Future<int?> insertInvoiceItem(InvoiceItem item) async {
    if (!_isConnected) return null;
    try {
      final results = await _connection!.query(
        'INSERT INTO invoice_items (invoice_id, product_id, quantity, unit_price, discount_rate, tax_rate, notes) VALUES (@invoiceId, @productId, @quantity, @unitPrice, @discountRate, @taxRate, @notes) RETURNING id',
        substitutionValues: {
          'invoiceId': item.invoiceId,
          'productId': item.product.id,
          'quantity': item.quantity,
          'unitPrice': item.unitPrice,
          'discountRate': item.discountRate,
          'taxRate': item.taxRate,
          'notes': item.notes,
        },
      );
      if (results.isNotEmpty && results[0].isNotEmpty) {
        return results[0][0] as int;
      }
      return null;
    } catch (e) {
      print('❌ Fatura kalemi ekleme hatası: $e');
      return null;
    }
  }

  /// Fatura kalemlerini getir
  Future<List<InvoiceItem>> getInvoiceItems(int invoiceId) async {
    if (!_isConnected) return [];
    try {
      final results = await _connection!.query(
        'SELECT ii.*, p.name as product_name, p.description as product_description FROM invoice_items ii JOIN products p ON ii.product_id = p.id WHERE ii.invoice_id = @invoiceId',
        substitutionValues: {'invoiceId': invoiceId},
      );
      return results.map((row) {
        final product = Product(
          id: row[2] as int,
          name: row[9] as String,
          description: row[10] as String?,
          price: (row[4] as num).toDouble(),
          unit: 'adet',
          taxRate: (row[6] as num).toDouble(),
          createdAt: DateTime.parse(row[11].toString()),
          updatedAt: DateTime.parse(row[12].toString()),
        );
        return InvoiceItem(
          id: row[0] as int,
          invoiceId: row[1] as int,
          product: product,
          quantity: (row[3] as num).toDouble(),
          unitPrice: (row[4] as num).toDouble(),
          discountRate: (row[5] as num).toDouble(),
          taxRate: (row[6] as num).toDouble(),
          notes: row[7] as String?,
        );
      }).toList();
    } catch (e) {
      print('❌ Fatura kalemleri hatası: $e');
      return [];
    }
  }
}

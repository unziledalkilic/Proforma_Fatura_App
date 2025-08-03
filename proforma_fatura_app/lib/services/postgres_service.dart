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
  PostgreSQLConnection? get connection => _connection;

  /// Tarih formatını güvenli şekilde parse et
  DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    try {
      if (value is DateTime) return value;

      final stringValue = value.toString().trim();

      // Boş string veya geçersiz değerler için
      if (stringValue.isEmpty ||
          stringValue == 'null' ||
          stringValue == 'undefined') {
        return DateTime.now();
      }

      // Sayısal değerler için (timestamp)
      if (RegExp(r'^\d+$').hasMatch(stringValue)) {
        final timestamp = int.tryParse(stringValue);
        if (timestamp != null) {
          // Unix timestamp (saniye cinsinden)
          if (timestamp < 10000000000) {
            return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
          }
          // Unix timestamp (milisaniye cinsinden)
          return DateTime.fromMillisecondsSinceEpoch(timestamp);
        }
      }

      // ISO format veya diğer tarih formatları
      return DateTime.parse(stringValue);
    } catch (e) {
      print('⚠️ Tarih parse hatası: $value, hata: $e');
      return DateTime.now();
    }
  }

  /// Güvenli string dönüşümü
  String? _safeString(dynamic value) {
    if (value == null) return null;
    try {
      return value.toString();
    } catch (e) {
      print('⚠️ String dönüşüm hatası: $value, hata: $e');
      return null;
    }
  }

  /// Güvenli double dönüşümü
  double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    try {
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    } catch (e) {
      print('⚠️ Double dönüşüm hatası: $value, hata: $e');
      return 0.0;
    }
  }

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
        'INSERT INTO customers (name, email, phone, address, tax_number) VALUES (@name, @email, @phone, @address, @taxNumber) RETURNING id',
        substitutionValues: {
          'name': customer.name,
          'email': customer.email,
          'phone': customer.phone,
          'address': customer.address,
          'taxNumber': customer.taxNumber,
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
              name: _safeString(row[1]) ?? '',
              email: _safeString(row[2]),
              phone: _safeString(row[3]),
              address: _safeString(row[4]),
              taxNumber: _safeString(row[5]),
              createdAt: _parseDateTime(row[6]),
              updatedAt: _parseDateTime(row[7]),
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
        'UPDATE customers SET name = @name, email = @email, phone = @phone, address = @address, tax_number = @taxNumber, updated_at = CURRENT_TIMESTAMP WHERE id = @id',
        substitutionValues: {
          'id': customer.id,
          'name': customer.name,
          'email': customer.email,
          'phone': customer.phone,
          'address': customer.address,
          'taxNumber': customer.taxNumber,
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
          name: _safeString(row[1]) ?? '',
          email: _safeString(row[2]),
          phone: _safeString(row[3]),
          address: _safeString(row[4]),
          taxNumber: _safeString(row[5]),
          createdAt: _parseDateTime(row[6]),
          updatedAt: _parseDateTime(row[7]),
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
        'INSERT INTO products (user_id, name, description, price, currency, unit, barcode, tax_rate, category_id) VALUES (@userId, @name, @description, @price, @currency, @unit, @barcode, @taxRate, @categoryId) RETURNING id',
        substitutionValues: {
          'userId': product.userId,
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

  /// Kullanıcıya özel tüm ürünleri getir
  Future<List<Product>> getAllProducts(int userId) async {
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

      final results = await _connection!.query(
        '''
        SELECT p.id, p.user_id, p.name, p.description, p.price, p.unit, p.barcode, p.tax_rate, 
               p.created_at, p.updated_at, p.currency, p.category_id,
               pc.id as cat_id, pc.user_id as cat_user_id, pc.name as cat_name, pc.description as cat_description, 
               pc.color as cat_color, pc.is_active as cat_is_active, 
               pc.created_at as cat_created_at, pc.updated_at as cat_updated_at
        FROM products p 
        LEFT JOIN product_categories pc ON p.category_id = pc.id 
        WHERE p.user_id = @userId
        ORDER BY p.name
        ''',
        substitutionValues: {'userId': userId},
      );
      print('✅ PostgreSQL\'den ${results.length} ürün getirildi');

      return results.map((row) {
        ProductCategory? category;
        if (row[12] != null) {
          // cat_id
          category = ProductCategory(
            id: row[12] as int,
            userId: row[13] as int, // cat_user_id
            name: row[14] as String, // cat_name
            description: row[15] as String?, // cat_description
            color: row[16] as String, // cat_color
            isActive: row[17] as bool, // cat_is_active
            createdAt: _parseDateTime(row[18]), // cat_created_at
            updatedAt: _parseDateTime(row[19]), // cat_updated_at
          );
        }

        return Product(
          id: row[0] as int,
          userId: row[1] as int, // user_id
          name: row[2] as String, // name
          description: row[3] as String?, // description
          price: double.tryParse(row[4].toString()) ?? 0.0, // price
          currency: row[10] as String, // currency
          unit: row[5] as String, // unit
          barcode: row[6] as String?, // barcode
          taxRate: double.tryParse(row[7].toString()) ?? 0.0, // tax_rate
          category: category,
          createdAt: _parseDateTime(row[8]), // created_at
          updatedAt: _parseDateTime(row[9]), // updated_at
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
        'UPDATE products SET name = @name, description = @description, price = @price, currency = @currency, unit = @unit, barcode = @barcode, tax_rate = @taxRate, category_id = @categoryId, updated_at = CURRENT_TIMESTAMP WHERE id = @id AND user_id = @userId',
        substitutionValues: {
          'id': product.id,
          'userId': product.userId,
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

  /// Kullanıcıya özel ürün getir (ID ile)
  Future<Product?> getProductById(int id, int userId) async {
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
            userId: userId, // Kullanıcı ID'si parametre olarak geçiliyor
            name: row[12] as String,
            description: row[13] as String?,
            color: row[14] as String,
            isActive: row[15] as bool,
            createdAt: _parseDateTime(row[16]),
            updatedAt: _parseDateTime(row[17]),
          );
        }

        return Product(
          id: row[0] as int,
          userId: userId, // Kullanıcı ID'si parametre olarak geçiliyor
          name: row[1] as String,
          description: row[2] as String?,
          price: double.tryParse(row[3].toString()) ?? 0.0,
          currency: row[9] as String, // row[9] = currency
          unit: row[4] as String, // row[4] = unit
          barcode: row[5] as String?, // row[5] = barcode
          taxRate:
              double.tryParse(row[6].toString()) ?? 0.0, // row[6] = tax_rate
          category: category,
          createdAt: _parseDateTime(row[7]), // row[7] = created_at
          updatedAt: _parseDateTime(row[8]), // row[8] = updated_at
        );
      }
      return null;
    } catch (e) {
      print('❌ Ürün getirme hatası: $e');
      return null;
    }
  }

  /// Ürün sil
  Future<bool> deleteProduct(int id, int userId) async {
    if (!_isConnected) return false;
    try {
      await _connection!.execute(
        'DELETE FROM products WHERE id = @id AND user_id = @userId',
        substitutionValues: {'id': id, 'userId': userId},
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

  /// Kullanıcıya özel tüm kategorileri getir
  Future<List<ProductCategory>> getAllCategories(int userId) async {
    if (!_isConnected) return [];
    try {
      final results = await _connection!.query(
        'SELECT * FROM product_categories WHERE user_id = @userId AND is_active = true ORDER BY name',
        substitutionValues: {'userId': userId},
      );
      return results
          .map(
            (row) => ProductCategory(
              id: row[0] as int,
              name: row[1] as String, // name
              description: row[2] as String?, // description
              color: row[3] as String, // color
              isActive: row[4] as bool, // is_active
              createdAt: _parseDateTime(row[5]), // created_at
              updatedAt: _parseDateTime(row[6]), // updated_at
              userId: row[7] as int, // user_id
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

      // Aynı kullanıcıda aynı isimde kategori var mı kontrol et
      final existingResults = await _connection!.query(
        'SELECT id FROM product_categories WHERE name = @name AND user_id = @userId',
        substitutionValues: {'name': category.name, 'userId': category.userId},
      );

      if (existingResults.isNotEmpty) {
        print('⚠️ Aynı isimde kategori zaten var: ${category.name}');
        return existingResults[0][0] as int; // Mevcut kategori ID'sini döndür
      }

      final results = await _connection!.query(
        'INSERT INTO product_categories (user_id, name, description, color, is_active) VALUES (@userId, @name, @description, @color, @isActive) RETURNING id',
        substitutionValues: {
          'userId': category.userId,
          'name': category.name,
          'description': category.description ?? '',
          'color': category.color,
          'isActive': category.isActive,
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
        'INSERT INTO invoices (user_id, invoice_number, customer_id, invoice_date, due_date, notes, terms, discount_rate, status) VALUES (@userId, @invoiceNumber, @customerId, @invoiceDate, @dueDate, @notes, @terms, @discountRate, @status) RETURNING id',
        substitutionValues: {
          'userId': 1, // Şimdilik sabit user_id (admin kullanıcısı)
          'invoiceNumber': invoice.invoiceNumber,
          'customerId': invoice.customer.id,
          'invoiceDate': invoice.invoiceDate.toIso8601String().split('T')[0],
          'dueDate': invoice.dueDate.toIso8601String().split('T')[0],
          'notes': invoice.notes,
          'terms': invoice.terms,
          'discountRate': invoice.discountRate,
          'status': invoice.status.name,
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
        'SELECT c.*, i.* FROM invoices i JOIN customers c ON i.customer_id = c.id ORDER BY i.created_at DESC',
      );

      List<Invoice> invoices = [];
      for (final row in results) {
        final customer = Customer(
          id: row[0] as int,
          name: row[1] as String,
          email: _safeString(row[2]),
          phone: _safeString(row[3]),
          address: _safeString(row[4]),
          taxNumber: _safeString(row[5]),
          createdAt: _parseDateTime(row[6]),
          updatedAt: _parseDateTime(row[7]),
        );

        // InvoiceStatus enum ise stringden dönüştür
        final statusStr = _safeString(row[15]) ?? 'draft';
        final status = InvoiceStatus.values.firstWhere(
          (e) => e.name == statusStr,
          orElse: () => InvoiceStatus.draft,
        );

        final invoiceId = row[8] as int;

        // Fatura ürünlerini getir
        final items = await getInvoiceItems(invoiceId);

        final invoice = Invoice(
          id: invoiceId,
          invoiceNumber: _safeString(row[9]) ?? '',
          customer: customer,
          invoiceDate: _parseDateTime(row[10]),
          dueDate: _parseDateTime(row[11]),
          notes: _safeString(row[12]),
          terms: _safeString(row[13]),
          discountRate: _safeDouble(row[14]),
          status: status,
          createdAt: _parseDateTime(row[16]),
          updatedAt: _parseDateTime(row[17]),
          items: items,
        );

        invoices.add(invoice);
      }

      return invoices;
    } catch (e) {
      print('❌ Fatura listesi hatası: $e');
      return [];
    }
  }

  /// Fatura güncelle
  Future<bool> updateInvoice(Invoice invoice) async {
    if (!_isConnected || invoice.id == null) return false;
    try {
      // Transaction başlat
      await _connection!.execute('BEGIN');

      // Fatura bilgilerini güncelle
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
          'status': invoice.status.name,
        },
      );

      // Mevcut fatura ürünlerini sil
      await _connection!.execute(
        'DELETE FROM invoice_items WHERE invoice_id = @invoiceId',
        substitutionValues: {'invoiceId': invoice.id},
      );

      // Yeni fatura ürünlerini ekle
      for (final item in invoice.items) {
        final itemWithInvoiceId = item.copyWith(invoiceId: invoice.id!);
        await insertInvoiceItem(itemWithInvoiceId);
      }

      // Transaction'ı commit et
      await _connection!.execute('COMMIT');
      return true;
    } catch (e) {
      // Hata durumunda rollback yap
      await _connection!.execute('ROLLBACK');
      print('❌ Fatura güncelleme hatası: $e');
      return false;
    }
  }

  /// Fatura sil
  Future<bool> deleteInvoice(int id) async {
    if (!_isConnected) return false;
    try {
      // Transaction başlat
      await _connection!.execute('BEGIN');

      // Önce fatura ürünlerini sil
      await _connection!.execute(
        'DELETE FROM invoice_items WHERE invoice_id = @invoiceId',
        substitutionValues: {'invoiceId': id},
      );

      // Sonra faturayı sil
      await _connection!.execute(
        'DELETE FROM invoices WHERE id = @id',
        substitutionValues: {'id': id},
      );

      // Transaction'ı commit et
      await _connection!.execute('COMMIT');
      return true;
    } catch (e) {
      // Hata durumunda rollback yap
      await _connection!.execute('ROLLBACK');
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
          name: _safeString(row[1]) ?? '',
          email: _safeString(row[2]),
          phone: _safeString(row[3]),
          address: _safeString(row[4]),
          taxNumber: _safeString(row[5]),
          createdAt: _parseDateTime(row[6]),
          updatedAt: _parseDateTime(row[7]),
        );
        final statusStr = _safeString(row[15]) ?? 'draft';
        final status = InvoiceStatus.values.firstWhere(
          (e) => e.name == statusStr,
          orElse: () => InvoiceStatus.draft,
        );

        // Fatura ürünlerini getir
        final items = await getInvoiceItems(id);

        return Invoice(
          id: row[8] as int,
          invoiceNumber: _safeString(row[9]) ?? '',
          customer: customer,
          invoiceDate: _parseDateTime(row[10]),
          dueDate: _parseDateTime(row[11]),
          notes: _safeString(row[12]),
          terms: _safeString(row[13]),
          discountRate: _safeDouble(row[14]),
          status: status,
          createdAt: _parseDateTime(row[16]),
          updatedAt: _parseDateTime(row[17]),
          items: items,
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
    if (item.invoiceId == null) {
      print('❌ Fatura kalemi eklenemedi - invoiceId null');
      return null;
    }

    try {
      print('🔄 Fatura kalemi ekleniyor:');
      print('   - Invoice ID: ${item.invoiceId}');
      print('   - Product ID: ${item.product.id}');
      print('   - Product Name: ${item.product.name}');
      print('   - Quantity: ${item.quantity}');
      print('   - Unit Price: ${item.unitPrice}');
      print('   - Discount Rate: ${item.discountRate}');
      print('   - Tax Rate: ${item.taxRate}');
      print('   - Notes: ${item.notes}');

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
        final itemId = results[0][0] as int;
        print('✅ Fatura kalemi başarıyla eklendi. ID: $itemId');
        return itemId;
      }
      print('❌ Fatura kalemi eklenemedi - sonuç boş');
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
      print('🔍 Fatura kalemleri getiriliyor: invoiceId = $invoiceId');

      // Daha basit ve güvenli sorgu kullanıyoruz
      final results = await _connection!.query(
        '''
        SELECT 
          ii.id as item_id,
          ii.invoice_id,
          ii.product_id,
          ii.quantity,
          ii.unit_price,
          ii.discount_rate,
          ii.tax_rate,
          ii.notes,
          p.name as product_name,
          p.description as product_description,
          p.price as product_price,
          p.unit as product_unit,
          p.user_id as product_user_id
        FROM invoice_items ii 
        JOIN products p ON ii.product_id = p.id 
        WHERE ii.invoice_id = @invoiceId
        ''',
        substitutionValues: {'invoiceId': invoiceId},
      );

      print('📊 Bulunan fatura kalemi sayısı: ${results.length}');

      return results.map((row) {
        try {
          print(
            '🔍 Row verisi: ${row.map((e) => '${e.runtimeType}: $e').join(', ')}',
          );

          final product = Product(
            id: row[2] as int, // product_id
            userId: row[12] as int, // product_user_id
            name: row[8] as String, // product_name
            description: row[9] as String?, // product_description
            price: double.tryParse(row[10].toString()) ?? 0.0, // product_price
            currency: 'TRY', // Varsayılan değer
            unit: row[11] as String? ?? 'adet', // product_unit
            taxRate: 0.0, // Ürünün varsayılan KDV oranı
            createdAt: DateTime.now(), // Şimdilik varsayılan
            updatedAt: DateTime.now(), // Şimdilik varsayılan
          );

          return InvoiceItem(
            id: row[0] as int, // item_id
            invoiceId: row[1] as int, // invoice_id
            product: product,
            quantity: double.tryParse(row[3].toString()) ?? 0.0, // quantity
            unitPrice: double.tryParse(row[4].toString()) ?? 0.0, // unit_price
            discountRate: row[5] != null
                ? double.tryParse(row[5].toString())
                : null, // discount_rate
            taxRate: row[6] != null
                ? double.tryParse(row[6].toString())
                : null, // tax_rate
            notes: row[7] as String?, // notes
          );
        } catch (e) {
          print('❌ Fatura kalemi parse hatası: $e');
          print(
            '❌ Row verisi: ${row.map((e) => '${e.runtimeType}: $e').join(', ')}',
          );
          rethrow;
        }
      }).toList();
    } catch (e) {
      print('❌ Fatura kalemleri hatası: $e');
      return [];
    }
  }
}

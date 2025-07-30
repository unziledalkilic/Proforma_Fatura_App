import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/user.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'proforma_fatura.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Kullanıcılar tablosu
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        full_name TEXT,
        company_name TEXT,
        phone TEXT,
        address TEXT,
        tax_number TEXT,
        tax_office TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Müşteriler tablosu
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        address TEXT,
        taxNumber TEXT,
        taxOffice TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Ürünler tablosu
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'TRY',
        unit TEXT NOT NULL DEFAULT 'Adet',
        barcode TEXT,
        taxRate REAL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Faturalar tablosu
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoiceNumber TEXT NOT NULL UNIQUE,
        customerId INTEGER NOT NULL,
        invoiceDate TEXT NOT NULL,
        dueDate TEXT NOT NULL,
        notes TEXT,
        terms TEXT,
        discountRate REAL,
        status TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (customerId) REFERENCES customers (id)
      )
    ''');

    // Fatura kalemleri tablosu
    await db.execute('''
      CREATE TABLE invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoiceId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        quantity REAL NOT NULL,
        unitPrice REAL NOT NULL,
        discountRate REAL,
        taxRate REAL,
        notes TEXT,
        FOREIGN KEY (invoiceId) REFERENCES invoices (id),
        FOREIGN KEY (productId) REFERENCES products (id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // currency sütunu ekle
      await db.execute(
        'ALTER TABLE products ADD COLUMN currency TEXT NOT NULL DEFAULT "TRY"',
      );
      // unit sütununu NOT NULL yap
      await db.execute(
        'ALTER TABLE products ADD COLUMN unit_new TEXT NOT NULL DEFAULT "Adet"',
      );
      await db.execute('UPDATE products SET unit_new = COALESCE(unit, "Adet")');
      await db.execute('ALTER TABLE products DROP COLUMN unit');
      await db.execute('ALTER TABLE products RENAME COLUMN unit_new TO unit');
    }
  }

  // Müşteri işlemleri
  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return await db.insert('customers', customer.toMap());
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('customers');
    return List.generate(maps.length, (i) => Customer.fromMap(maps[i]));
  }

  Future<Customer?> getCustomerById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Customer.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    final db = await database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // Ürün işlemleri
  Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert('products', product.toMap());
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  Future<Product?> getProductById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // Fatura işlemleri
  Future<int> insertInvoice(Invoice invoice) async {
    final db = await database;
    final invoiceId = await db.insert('invoices', invoice.toMap());

    // Fatura kalemlerini ekle
    for (var item in invoice.items) {
      final itemMap = item.toMap();
      itemMap['invoiceId'] = invoiceId;
      await db.insert('invoice_items', itemMap);
    }

    return invoiceId;
  }

  Future<List<Invoice>> getAllInvoices() async {
    final db = await database;
    final List<Map<String, dynamic>> invoiceMaps = await db.query('invoices');

    List<Invoice> invoices = [];
    for (var invoiceMap in invoiceMaps) {
      final customer = await getCustomerById(invoiceMap['customerId']);
      if (customer != null) {
        final items = await getInvoiceItemsByInvoiceId(invoiceMap['id']);
        invoices.add(Invoice.fromMap(invoiceMap, customer, items));
      }
    }

    return invoices;
  }

  Future<Invoice?> getInvoiceById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      final customer = await getCustomerById(maps.first['customerId']);
      if (customer != null) {
        final items = await getInvoiceItemsByInvoiceId(id);
        return Invoice.fromMap(maps.first, customer, items);
      }
    }
    return null;
  }

  Future<List<InvoiceItem>> getInvoiceItemsByInvoiceId(int invoiceId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'invoice_items',
      where: 'invoiceId = ?',
      whereArgs: [invoiceId],
    );

    List<InvoiceItem> items = [];
    for (var map in maps) {
      final product = await getProductById(map['productId']);
      if (product != null) {
        items.add(InvoiceItem.fromMap(map, product));
      }
    }

    return items;
  }

  Future<int> updateInvoice(Invoice invoice) async {
    final db = await database;

    // Önce mevcut kalemleri sil
    await db.delete(
      'invoice_items',
      where: 'invoiceId = ?',
      whereArgs: [invoice.id],
    );

    // Faturayı güncelle
    final result = await db.update(
      'invoices',
      invoice.toMap(),
      where: 'id = ?',
      whereArgs: [invoice.id],
    );

    // Yeni kalemleri ekle
    for (var item in invoice.items) {
      final itemMap = item.toMap();
      itemMap['invoiceId'] = invoice.id;
      await db.insert('invoice_items', itemMap);
    }

    return result;
  }

  Future<int> deleteInvoice(int id) async {
    final db = await database;

    // Önce kalemleri sil
    await db.delete('invoice_items', where: 'invoiceId = ?', whereArgs: [id]);

    // Sonra faturayı sil
    return await db.delete('invoices', where: 'id = ?', whereArgs: [id]);
  }

  // Kullanıcı işlemleri
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserByUsernameOrEmail(String username, String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ? OR email = ?',
      whereArgs: [username, email],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<bool> updateUser(User user) async {
    final db = await database;
    final result = await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
    return result > 0;
  }

  Future<bool> deleteUser(int id) async {
    final db = await database;
    final result = await db.delete('users', where: 'id = ?', whereArgs: [id]);
    return result > 0;
  }

  // Veritabanını kapat
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

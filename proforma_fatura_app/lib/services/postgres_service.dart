import '../models/customer.dart';

class PostgresService {
  // Geçici in-memory veri
  static List<Customer> _customers = [];
  static int _nextId = 1;

  // Tüm müşterileri getir
  Future<List<Customer>> getAllCustomers() async {
    print('📋 PostgresService: ${_customers.length} müşteri getiriliyor');
    await Future.delayed(const Duration(milliseconds: 500)); // Simülasyon
    return List.from(_customers);
  }

  // Müşteri ekle
  Future<int> insertCustomer(Customer customer) async {
    print('📝 PostgresService: Müşteri ekleniyor - ${customer.name}');
    await Future.delayed(const Duration(milliseconds: 800)); // Simülasyon

    final newCustomer = customer.copyWith(
      id: _nextId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _customers.add(newCustomer);
    print('✅ PostgresService: Müşteri eklendi - ID: $_nextId');

    return _nextId++;
  }

  // Müşteri güncelle
  Future<void> updateCustomer(Customer customer) async {
    print('✏️ PostgresService: Müşteri güncelleniyor - ${customer.name}');
    await Future.delayed(const Duration(milliseconds: 600)); // Simülasyon

    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index != -1) {
      _customers[index] = customer.copyWith(updatedAt: DateTime.now());
      print('✅ PostgresService: Müşteri güncellendi');
    } else {
      throw Exception('Müşteri bulunamadı');
    }
  }

  // Müşteri sil
  Future<void> deleteCustomer(int id) async {
    print('🗑️ PostgresService: Müşteri siliniyor - ID: $id');
    await Future.delayed(const Duration(milliseconds: 400)); // Simülasyon

    final initialLength = _customers.length;
    _customers.removeWhere((customer) => customer.id == id);
    if (_customers.length == initialLength) {
      throw Exception('Silinecek müşteri bulunamadı');
    }
    print('✅ PostgresService: Müşteri silindi');
  }

  // ID'ye göre müşteri getir
  Future<Customer?> getCustomerById(int id) async {
    print('🔍 PostgresService: Müşteri getiriliyor - ID: $id');
    await Future.delayed(const Duration(milliseconds: 300)); // Simülasyon

    try {
      return _customers.firstWhere((customer) => customer.id == id);
    } catch (e) {
      return null;
    }
  }

  // Test verileri ekle
  static void addTestData() {
    if (_customers.isEmpty) {
      _customers.addAll([
        Customer(
          id: _nextId++,
          name: 'Ahmet Yılmaz',
          email: 'ahmet@test.com',
          phone: '+90 532 123 4567',
          address: 'İstanbul',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Customer(
          id: _nextId++,
          name: 'Fatma Kaya',
          email: 'fatma@test.com',
          phone: '+90 533 987 6543',
          address: 'Ankara',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]);
      print('🧪 Test verileri eklendi: ${_customers.length} müşteri');
    }
  }
}

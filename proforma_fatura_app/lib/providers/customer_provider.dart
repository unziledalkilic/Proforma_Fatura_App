import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../services/postgres_service.dart';
import '../utils/text_formatter.dart';

class CustomerProvider with ChangeNotifier {
  final PostgresService _postgresService = PostgresService();
  List<Customer> _customers = [];
  bool _isLoading = false;
  String? _error;
  int? _currentUserId; // Kullanıcı ID'si eklendi

  List<Customer> get customers => _customers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Kullanıcı ID'sini ayarla
  void setCurrentUser(int userId) {
    _currentUserId = userId;
    print('👤 CustomerProvider: Kullanıcı ID ayarlandı: $userId');
  }

  // Müşterileri yükle
  Future<void> loadCustomers() async {
    if (_currentUserId == null) {
      print(
        '⚠️ CustomerProvider: Kullanıcı ID ayarlanmamış, müşteriler yüklenemiyor',
      );
      return;
    }

    print('🔄 Müşteriler yükleniyor... (Kullanıcı ID: $_currentUserId)');

    _setLoading(true);
    try {
      _customers = await _postgresService.getAllCustomers(_currentUserId!);
      print('✅ CustomerProvider: ${_customers.length} müşteri yüklendi');
      _error = null;

      print('✅ ${_customers.length} müşteri yüklendi');
      for (var customer in _customers) {
        print('   - ${customer.name} (ID: ${customer.id})');
      }
    } catch (e) {
      print('❌ CustomerProvider: Müşteri yükleme hatası: $e');
      _error = 'Müşteriler yüklenirken hata oluştu: $e';

      print('❌ Hata: $_error');
    } finally {
      _setLoading(false);
    }
  }

  // Müşteri ekle
  Future<bool> addCustomer(Customer customer) async {
    if (_currentUserId == null) {
      print(
        '⚠️ CustomerProvider: Kullanıcı ID ayarlanmamış, müşteri eklenemiyor',
      );
      return false;
    }

    print(
      '📝 Müşteri ekleniyor: ${customer.name} (Kullanıcı ID: $_currentUserId)',
    );
    _setLoading(true);
    try {
      // Müşteri bilgilerini formatla
      final formattedCustomer = customer.copyWith(
        name: TextFormatter.capitalizeWords(customer.name),
        email: customer.email != null
            ? TextFormatter.formatEmail(customer.email!)
            : null,
        phone: customer.phone != null
            ? TextFormatter.formatPhone(customer.phone!)
            : null,
        address: customer.address != null
            ? TextFormatter.formatAddress(customer.address!)
            : null,
      );

      print('📤 Veritabanına kaydediliyor...');
      final id = await _postgresService.insertCustomer(
        formattedCustomer,
        _currentUserId!,
      );
      print('✅ Müşteri kaydedildi, ID: $id');

      final newCustomer = formattedCustomer.copyWith(
        id: id,
        userId: _currentUserId,
      );

      // Listeye ekle
      _customers.add(newCustomer);
      print('📋 Listeye eklendi. Toplam müşteri: ${_customers.length}');

      _error = null;
      notifyListeners();

      return true;
    } catch (e) {
      _error = 'Müşteri eklenirken hata oluştu: $e';
      print('❌ Ekleme hatası: $_error');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Müşteri güncelle
  Future<bool> updateCustomer(Customer customer) async {
    print('✏️ Müşteri güncelleniyor: ${customer.name} (ID: ${customer.id})');
    _setLoading(true);
    try {
      // Müşteri bilgilerini formatla
      final formattedCustomer = customer.copyWith(
        name: TextFormatter.capitalizeWords(customer.name),
        email: customer.email != null
            ? TextFormatter.formatEmail(customer.email!)
            : null,
        phone: customer.phone != null
            ? TextFormatter.formatPhone(customer.phone!)
            : null,
        address: customer.address != null
            ? TextFormatter.formatAddress(customer.address!)
            : null,
      );

      await _postgresService.updateCustomer(formattedCustomer);
      print('✅ Müşteri güncellendi');

      final index = _customers.indexWhere((c) => c.id == customer.id);
      if (index != -1) {
        _customers[index] = formattedCustomer;
        print('📋 Listede güncellendi');
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Müşteri güncellenirken hata oluştu: $e';
      print('❌ Güncelleme hatası: $_error');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Müşteri sil
  Future<bool> deleteCustomer(int id) async {
    print('🗑️ Müşteri siliniyor: ID $id');
    _setLoading(true);
    try {
      await _postgresService.deleteCustomer(id);
      print('✅ Müşteri veritabanından silindi');

      _customers.removeWhere((customer) => customer.id == id);
      print('📋 Listeden silindi. Kalan müşteri: ${_customers.length}');

      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Müşteri silinirken hata oluştu: $e';
      print('❌ Silme hatası: $_error');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Müşteri getir
  Future<Customer?> getCustomerById(int id) async {
    try {
      return await _postgresService.getCustomerById(id);
    } catch (e) {
      _error = 'Müşteri getirilirken hata oluştu: $e';
      print('❌ Getirme hatası: $_error');
      return null;
    }
  }

  // Müşteri ara
  List<Customer> searchCustomers(String query) {
    if (query.isEmpty) return _customers;

    final results = _customers.where((customer) {
      return customer.name.toLowerCase().contains(query.toLowerCase()) ||
          (customer.email?.toLowerCase().contains(query.toLowerCase()) ??
              false) ||
          (customer.phone?.contains(query) ?? false);
    }).toList();

    print('🔍 Arama: "$query" - ${results.length} sonuç');
    return results;
  }

  // Loading durumunu ayarla
  void _setLoading(bool loading) {
    _isLoading = loading;
    // notifyListeners'ı asenkron olarak çağır
    Future.microtask(() => notifyListeners());
  }

  // Hata mesajını temizle
  void clearError() {
    _error = null;
    // notifyListeners'ı asenkron olarak çağır
    Future.microtask(() => notifyListeners());
  }
}

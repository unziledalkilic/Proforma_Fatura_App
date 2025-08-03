import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../services/postgres_service.dart';
import '../utils/text_formatter.dart';

class CustomerProvider with ChangeNotifier {
  final PostgresService _postgresService = PostgresService();
  List<Customer> _customers = [];
  bool _isLoading = false;
  String? _error;

  List<Customer> get customers => _customers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Müşterileri yükle
  Future<void> loadCustomers() async {
<<<<<<< HEAD
    // Eğer zaten yüklüyse tekrar yükleme
    if (_customers.isNotEmpty && !_isLoading) {
      print('📋 Müşteriler zaten yüklü, tekrar yüklenmiyor');
      return;
    }

    print('🔄 CustomerProvider: Müşteriler yükleniyor...');
=======
    print('🔄 Müşteriler yükleniyor...');
>>>>>>> 9edad2e098eae04be983b3a79e53f14538508736
    _setLoading(true);
    try {
      _customers = await _postgresService.getAllCustomers();
      print('✅ CustomerProvider: ${_customers.length} müşteri yüklendi');
      _error = null;
<<<<<<< HEAD
      notifyListeners();
=======
      print('✅ ${_customers.length} müşteri yüklendi');
      for (var customer in _customers) {
        print('   - ${customer.name} (ID: ${customer.id})');
      }
>>>>>>> 9edad2e098eae04be983b3a79e53f14538508736
    } catch (e) {
      print('❌ CustomerProvider: Müşteri yükleme hatası: $e');
      _error = 'Müşteriler yüklenirken hata oluştu: $e';
<<<<<<< HEAD
      notifyListeners();
=======
      print('❌ Hata: $_error');
>>>>>>> 9edad2e098eae04be983b3a79e53f14538508736
    } finally {
      _setLoading(false);
    }
  }

  // Müşteri ekle
  Future<bool> addCustomer(Customer customer) async {
    print('📝 Müşteri ekleniyor: ${customer.name}');
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
      final id = await _postgresService.insertCustomer(formattedCustomer);
      print('✅ Müşteri kaydedildi, ID: $id');

      final newCustomer = formattedCustomer.copyWith(id: id);

      // Listeye ekle
      _customers.add(newCustomer);
      print('📋 Listeye eklendi. Toplam müşteri: ${_customers.length}');

      _error = null;
      notifyListeners();

      // Kontrol için listeyi yeniden yükle
      print('🔄 Kontrol için liste yenileniyor...');
      await loadCustomers();

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

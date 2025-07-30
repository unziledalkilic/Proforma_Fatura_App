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
    _setLoading(true);
    try {
      _customers = await _postgresService.getAllCustomers();
      _error = null;
    } catch (e) {
      _error = 'Müşteriler yüklenirken hata oluştu: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Müşteri ekle
  Future<bool> addCustomer(Customer customer) async {
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

      final id = await _postgresService.insertCustomer(formattedCustomer);
      final newCustomer = formattedCustomer.copyWith(id: id);
      _customers.add(newCustomer);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Müşteri eklenirken hata oluştu: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Müşteri güncelle
  Future<bool> updateCustomer(Customer customer) async {
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
      final index = _customers.indexWhere((c) => c.id == customer.id);
      if (index != -1) {
        _customers[index] = formattedCustomer;
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Müşteri güncellenirken hata oluştu: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Müşteri sil
  Future<bool> deleteCustomer(int id) async {
    _setLoading(true);
    try {
      await _postgresService.deleteCustomer(id);
      _customers.removeWhere((customer) => customer.id == id);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Müşteri silinirken hata oluştu: $e';
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
      return null;
    }
  }

  // Müşteri ara
  List<Customer> searchCustomers(String query) {
    if (query.isEmpty) return _customers;

    return _customers.where((customer) {
      return customer.name.toLowerCase().contains(query.toLowerCase()) ||
          (customer.email?.toLowerCase().contains(query.toLowerCase()) ??
              false) ||
          (customer.phone?.contains(query) ?? false);
    }).toList();
  }

  // Loading durumunu ayarla
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Hata mesajını temizle
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

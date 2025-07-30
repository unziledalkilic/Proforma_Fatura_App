import 'package:flutter/foundation.dart';
import '../models/invoice.dart';
import '../services/postgres_service.dart';

class InvoiceProvider with ChangeNotifier {
  final PostgresService _postgresService = PostgresService();
  List<Invoice> _invoices = [];
  bool _isLoading = false;
  String? _error;

  List<Invoice> get invoices => _invoices;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Faturaları yükle
  Future<void> loadInvoices() async {
    _setLoading(true);
    try {
      _invoices = await _postgresService.getAllInvoices();
      _error = null;
    } catch (e) {
      _error = 'Faturalar yüklenirken hata oluştu: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Fatura ekle
  Future<bool> addInvoice(Invoice invoice) async {
    _setLoading(true);
    try {
      final id = await _postgresService.insertInvoice(invoice);
      final newInvoice = invoice.copyWith(id: id);
      _invoices.add(newInvoice);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Fatura eklenirken hata oluştu: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Fatura güncelle
  Future<bool> updateInvoice(Invoice invoice) async {
    _setLoading(true);
    try {
      await _postgresService.updateInvoice(invoice);
      final index = _invoices.indexWhere((i) => i.id == invoice.id);
      if (index != -1) {
        _invoices[index] = invoice;
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Fatura güncellenirken hata oluştu: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Fatura sil
  Future<bool> deleteInvoice(int id) async {
    _setLoading(true);
    try {
      await _postgresService.deleteInvoice(id);
      _invoices.removeWhere((invoice) => invoice.id == id);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Fatura silinirken hata oluştu: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Fatura getir
  Future<Invoice?> getInvoiceById(int id) async {
    try {
      return await _postgresService.getInvoiceById(id);
    } catch (e) {
      _error = 'Fatura getirilirken hata oluştu: $e';
      return null;
    }
  }

  // Fatura ara
  List<Invoice> searchInvoices(String query) {
    if (query.isEmpty) return _invoices;

    return _invoices.where((invoice) {
      return invoice.invoiceNumber.toLowerCase().contains(
            query.toLowerCase(),
          ) ||
          invoice.customer.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Duruma göre faturaları filtrele
  List<Invoice> getInvoicesByStatus(String status) {
    return _invoices.where((invoice) => invoice.status.name == status).toList();
  }

  // Müşteriye göre faturaları filtrele
  List<Invoice> getInvoicesByCustomer(int customerId) {
    return _invoices
        .where((invoice) => invoice.customer.id == customerId)
        .toList();
  }

  // Tarih aralığına göre faturaları filtrele
  List<Invoice> getInvoicesByDateRange(DateTime startDate, DateTime endDate) {
    return _invoices.where((invoice) {
      return invoice.invoiceDate.isAfter(
            startDate.subtract(const Duration(days: 1)),
          ) &&
          invoice.invoiceDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  // İstatistikler
  double get totalInvoiceAmount {
    return _invoices.fold(0.0, (sum, invoice) => sum + invoice.totalAmount);
  }

  int get totalInvoiceCount => _invoices.length;

  int get draftInvoiceCount {
    return _invoices.where((invoice) => invoice.status.name == 'draft').length;
  }

  int get sentInvoiceCount {
    return _invoices.where((invoice) => invoice.status.name == 'sent').length;
  }

  int get acceptedInvoiceCount {
    return _invoices
        .where((invoice) => invoice.status.name == 'accepted')
        .length;
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

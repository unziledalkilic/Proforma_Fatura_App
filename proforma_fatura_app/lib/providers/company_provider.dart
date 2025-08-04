import 'package:flutter/foundation.dart';
import '../models/company_info.dart';
import '../services/company_service.dart';

class CompanyProvider extends ChangeNotifier {
  final CompanyService _companyService = CompanyService();
  
  CompanyInfo? _companyInfo;
  bool _isLoading = false;
  String? _error;

  CompanyInfo? get companyInfo => _companyInfo;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool loading) {
    _isLoading = loading;
    Future.microtask(() => notifyListeners());
  }

  void clearError() {
    _error = null;
    Future.microtask(() => notifyListeners());
  }

  // Firma bilgilerini yükle
  Future<void> loadCompanyInfo() async {
    if (_companyInfo != null && !_isLoading) {
      return;
    }
    
    _setLoading(true);
    try {
      _companyInfo = await _companyService.getCompanyInfo();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Firma bilgileri yüklenirken hata oluştu: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Firma bilgilerini güncelle
  Future<bool> updateCompanyInfo(CompanyInfo companyInfo) async {
    _setLoading(true);
    try {
      final success = await _companyService.updateCompanyInfo(companyInfo);
      if (success) {
        _companyInfo = companyInfo;
        _error = null;
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = 'Firma bilgileri güncellenirken hata oluştu: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Firma bilgilerini oluştur
  Future<bool> createCompanyInfo(CompanyInfo companyInfo) async {
    _setLoading(true);
    try {
      final success = await _companyService.createCompanyInfo(companyInfo);
      if (success) {
        _companyInfo = companyInfo;
        _error = null;
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = 'Firma bilgileri oluşturulurken hata oluştu: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Firma bilgilerini kaydet (oluştur veya güncelle)
  Future<bool> saveCompanyInfo(CompanyInfo companyInfo) async {
    if (companyInfo.id == 0) {
      // Yeni kayıt oluştur
      return await createCompanyInfo(companyInfo);
    } else {
      // Mevcut kaydı güncelle
      return await updateCompanyInfo(companyInfo);
    }
  }
} 
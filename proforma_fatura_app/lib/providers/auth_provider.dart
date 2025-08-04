import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/user.dart';
import '../models/product_category.dart';
import '../services/postgres_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;

  bool _isLoading = false;
  String? _error;

  // Multiple providers'a kullanıcı ID'sini geçirmek için callback listesi
  Set<Function(int)> _onUserLoginCallbacks = {};

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isLoggedIn => _currentUser != null;

  // PostgreSQL servisi
  final PostgresService _postgresService = PostgresService();

  /// Kullanıcı giriş callback'ini ekle
  void addUserLoginCallback(Function(int) callback) {
    _onUserLoginCallbacks.add(callback);
  }

  /// Tüm callback'leri temizle
  void clearUserLoginCallbacks() {
    _onUserLoginCallbacks.clear();
  }

  /// Uygulama başlangıcında PostgreSQL bağlantısını kur
  Future<void> initializeDatabase() async {
    _isLoading = true;
    notifyListeners();

    try {
      final connected = await _postgresService.connect();
      if (!connected) {
        _error = 'PostgreSQL bağlantısı kurulamadı';
      }
    } catch (e) {
      _error = 'Veritabanı başlatma hatası: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Kullanıcı kaydı
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Şifreyi hash'le
      final passwordHash = _hashPassword(password);

      // Yeni kullanıcı oluştur
      final user = User(
        username: username,
        email: email,
        passwordHash: passwordHash,
        fullName: fullName,
        phone: phone,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // PostgreSQL'e kaydet
      final userId = await _postgresService.insertUser(user);

      if (userId != null) {
        _currentUser = user.copyWith(id: userId);

        // Yeni kullanıcı için varsayılan kategorileri oluştur
        await _createDefaultCategoriesForUser(userId);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Kullanıcı kaydı başarısız';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Kayıt hatası: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Kullanıcı girişi
  Future<bool> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // PostgreSQL'den kullanıcıyı bul
      final user = await _postgresService.getUserByUsernameOrEmail(
        usernameOrEmail,
        usernameOrEmail,
      );

      if (user != null) {
        // Şifre kontrolü
        final passwordHash = _hashPassword(password);
        if (user.passwordHash == passwordHash) {
          _currentUser = user;
          _isLoading = false;
          notifyListeners();

          // Tüm callback'leri çağır
          for (final callback in _onUserLoginCallbacks) {
            if (user.id != null) {
              callback(user.id!);
            }
          }

          return true;
        } else {
          _error = 'Hatalı şifre';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        _error = 'Kullanıcı bulunamadı';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Giriş hatası: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Kullanıcı çıkışı
  Future<void> logout() async {
    _currentUser = null;
    _error = null;
    clearUserLoginCallbacks(); // Callback'leri temizle
    notifyListeners();
  }

  /// Kullanıcı giriş durumunu kontrol et (uygulama başlangıcında çağrılır)
  Future<void> checkLoginStatus() async {
    // Eğer zaten giriş yapmışsa, tüm provider'lara kullanıcı ID'sini geçir
    if (_currentUser != null &&
        _currentUser!.id != null &&
        _onUserLoginCallbacks.isNotEmpty) {
      for (final callback in _onUserLoginCallbacks) {
        callback(_currentUser!.id!);
      }
    }
  }

  /// Profil güncelleme
  Future<bool> updateProfile({
    String? fullName,
    String? companyName,
    String? phone,
    String? address,
    String? taxNumber,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedUser = _currentUser!.copyWith(
        fullName: fullName ?? _currentUser!.fullName,
        companyName: companyName ?? _currentUser!.companyName,
        phone: phone ?? _currentUser!.phone,
        address: address ?? _currentUser!.address,
        taxNumber: taxNumber ?? _currentUser!.taxNumber,
      );

      final success = await _postgresService.updateUser(updatedUser);

      if (success) {
        _currentUser = updatedUser;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Profil güncellenemedi';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Güncelleme hatası: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Şifre değiştirme
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Mevcut şifre kontrolü
      final currentPasswordHash = _hashPassword(currentPassword);
      if (_currentUser!.passwordHash != currentPasswordHash) {
        _error = 'Mevcut şifre hatalı';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Yeni şifreyi hash'le
      final newPasswordHash = _hashPassword(newPassword);

      // Kullanıcıyı güncelle
      final updatedUser = _currentUser!.copyWith(passwordHash: newPasswordHash);
      final success = await _postgresService.updateUser(updatedUser);

      if (success) {
        _currentUser = updatedUser;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Şifre değiştirilemedi';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Şifre değiştirme hatası: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Hata mesajını temizle
  void clearError() {
    _error = null;
    // notifyListeners'ı asenkron olarak çağır
    Future.microtask(() => notifyListeners());
  }

  /// Basit şifre hash'leme (gerçek uygulamada bcrypt kullanın)
  String _hashPassword(String password) {
    return base64.encode(password.codeUnits);
  }

  /// Yeni kullanıcı için varsayılan kategorileri oluştur
  Future<void> _createDefaultCategoriesForUser(int userId) async {
    try {
      final defaultCategories = [
        {
          'name': 'Elektronik',
          'description': 'Elektronik ürünler',
          'color': '#FF5722',
        },
        {'name': 'Giyim', 'description': 'Giyim ürünleri', 'color': '#2196F3'},
        {
          'name': 'Ev & Yaşam',
          'description': 'Ev ve yaşam ürünleri',
          'color': '#4CAF50',
        },
        {'name': 'Spor', 'description': 'Spor ürünleri', 'color': '#FF9800'},
        {
          'name': 'Kitap',
          'description': 'Kitap ve yayınlar',
          'color': '#9C27B0',
        },
        {'name': 'Gıda', 'description': 'Gıda ürünleri', 'color': '#795548'},
        {
          'name': 'Kozmetik',
          'description': 'Kozmetik ürünleri',
          'color': '#E91E63',
        },
        {'name': 'Diğer', 'description': 'Diğer ürünler', 'color': '#9E9E9E'},
      ];

      for (final category in defaultCategories) {
        final productCategory = ProductCategory(
          userId: userId,
          name: category['name']!,
          description: category['description']!,
          color: category['color']!,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _postgresService.insertCategory(productCategory);
      }

      print(
        '✅ Kullanıcı $userId için ${defaultCategories.length} varsayılan kategori oluşturuldu',
      );
    } catch (e) {
      print('❌ Varsayılan kategori oluşturma hatası: $e');
    }
  }
}

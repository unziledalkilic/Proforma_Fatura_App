import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/user.dart';
import '../services/postgres_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  // PostgreSQL servisi
  final PostgresService _postgresService = PostgresService();

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
    notifyListeners();
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
    notifyListeners();
  }

  /// Basit şifre hash'leme (gerçek uygulamada bcrypt kullanın)
  String _hashPassword(String password) {
    return base64.encode(password.codeUnits);
  }
}

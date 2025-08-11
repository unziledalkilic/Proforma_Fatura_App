import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/hybrid_database_service.dart';
import '../services/firebase_service.dart';
import '../models/user.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/invoice.dart';
import '../models/company_info.dart';
import '../utils/id_converter.dart';
import '../utils/text_formatter.dart';

/// Hybrid Provider - SQLite (offline) + Firebase (online) desteği
class HybridProvider extends ChangeNotifier {
  final HybridDatabaseService _hybridService = HybridDatabaseService();
  final FirebaseService _firebaseService = FirebaseService();

  bool _isLoading = false;
  bool _isOnline = false;
  String? _error;
  DateTime? _lastSyncTime;
  Map<String, int> _syncStats = {};

  // Current user
  firebase_auth.User? _currentUser;
  User? _appUser;

  // Data lists
  List<Customer> _customers = [];
  List<Product> _products = [];
  List<Invoice> _invoices = [];
  CompanyInfo? _companyInfo;
  // Multi-company profiles
  List<CompanyInfo> _companies = [];
  CompanyInfo? _selectedCompany;

  // Getters
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;
  String? get error => _error;
  DateTime? get lastSyncTime => _lastSyncTime;
  Map<String, int> get syncStats => _syncStats;
  firebase_auth.User? get currentUser => _currentUser;
  User? get appUser => _appUser;
  List<Customer> get customers => _customers;
  List<Product> get products => _products;
  List<Invoice> get invoices => _invoices;
  CompanyInfo? get companyInfo => _companyInfo;
  List<CompanyInfo> get companies => _companies;
  CompanyInfo? get selectedCompany => _selectedCompany;

  // Expose limited controls for settings actions
  FirebaseService get firebaseService => _firebaseService;
  void enablePullOnce() {
    _hybridService.setPullEnabled(true);
  }

  void disablePull() {
    _hybridService.setPullEnabled(false);
  }

  // Connectivity status
  String get connectivityStatus {
    if (_isOnline) {
      return 'Çevrimiçi';
    } else {
      return 'Çevrimdışı';
    }
  }

  // Pending sync count
  int get pendingSyncCount {
    return _syncStats['pending_operations'] ?? 0;
  }

  /// Initialize hybrid provider
  Future<void> initialize() async {
    _setLoading(true);
    try {
      // Initialize hybrid database service
      await _hybridService.initialize();
      _isOnline = _hybridService.isOnline;

      // Initialize Firebase service
      await _firebaseService.initialize();

      // Listen to auth state changes
      _firebaseService.auth.authStateChanges().listen(
        (firebase_auth.User? user) {
          debugPrint('🔐 Auth state değişti: ${user?.email ?? 'null'}');
          _currentUser = user;
          if (user != null) {
            debugPrint('✅ Kullanıcı giriş yapmış: ${user.email}');
            _appUser = _convertFirebaseUserToAppUser(user);
            _loadUserData();
          } else {
            debugPrint('❌ Kullanıcı çıkış yapmış - veriler temizleniyor');
            _clearData();
          }
          notifyListeners();
        },
        onError: (error) {
          debugPrint('❌ Firebase Auth State Listener Error: $error');
        },
      );

      // Update sync stats
      await _updateSyncStats();

      _setError(null);
    } catch (e) {
      _setError('Hybrid sistem başlatılamadı: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Convert Firebase User to App User
  User _convertFirebaseUserToAppUser(firebase_auth.User firebaseUser) {
    return User(
      id: null, // Local ID will be set after SQLite sync
      username: firebaseUser.email?.split('@').first ?? 'user',
      email: firebaseUser.email ?? '',
      passwordHash: '',
      fullName:
          firebaseUser.displayName ??
          firebaseUser.email?.split('@').first ??
          'User',
      companyName: null,
      phone: firebaseUser.phoneNumber,
      address: null,

      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // ==================== AUTHENTICATION ====================

  Future<bool> registerUser(
    String email,
    String password,
    String name, [
    String? phone,
  ]) async {
    _setLoading(true);
    _setError(null);
    try {
      final userCredential = await _firebaseService.registerUser(
        email,
        password,
        name,
        phone,
      );
      if (userCredential != null || _firebaseService.auth.currentUser != null) {
        return true;
      } else {
        _setError('Kayıt işlemi başarısız');
        return false;
      }
    } catch (e) {
      _setError('Kayıt hatası: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loginUser(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      final userCredential = await _firebaseService.loginUser(email, password);
      if (userCredential != null || _firebaseService.auth.currentUser != null) {
        return true;
      } else {
        _setError('Giriş başarısız');
        return false;
      }
    } catch (e) {
      _setError('Giriş hatası: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logoutUser() async {
    _setLoading(true);
    try {
      await _firebaseService.logoutUser();
      _clearData();
      _setError(null);
    } catch (e) {
      _setError('Çıkış hatası: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ==================== CUSTOMER OPERATIONS ====================

  Future<bool> addCustomer(Customer customer) async {
    _setLoading(true);
    try {
      // Add to local database first (works offline)
      final currentUserId = await _hybridService.getCurrentLocalUserId();
      final enriched = customer.copyWith(userId: currentUserId.toString());
      final customerId = await _hybridService.insertCustomer(enriched);

      if (customerId > 0) {
        // Reload customers from local database
        await _loadCustomersFromLocal();
        _setError(null);
        return true;
      } else {
        _setError('Müşteri eklenemedi');
        return false;
      }
    } catch (e) {
      _setError('Müşteri ekleme hatası: $e');
      return false;
    } finally {
      _setLoading(false);
      await _updateSyncStats();
    }
  }

  Future<bool> updateCustomer(Customer customer) async {
    _setLoading(true);
    try {
      final result = await _hybridService.updateCustomer(customer);

      if (result > 0) {
        await _loadCustomersFromLocal();
        _setError(null);
        return true;
      } else {
        _setError('Müşteri güncellenemedi');
        return false;
      }
    } catch (e) {
      _setError('Müşteri güncelleme hatası: $e');
      return false;
    } finally {
      _setLoading(false);
      await _updateSyncStats();
    }
  }

  Future<bool> deleteCustomer(int customerId) async {
    _setLoading(true);
    try {
      final result = await _hybridService.deleteCustomer(customerId);

      if (result > 0) {
        await _loadCustomersFromLocal();
        _setError(null);
        return true;
      } else {
        _setError('Müşteri silinemedi');
        return false;
      }
    } catch (e) {
      _setError('Müşteri silme hatası: $e');
      return false;
    } finally {
      _setLoading(false);
      await _updateSyncStats();
    }
  }

  // ==================== PRODUCT OPERATIONS ====================

  Future<bool> addProduct(Product product) async {
    _setLoading(true);
    try {
      debugPrint('📦 Adding product: ${product.name}');
      debugPrint('🏢 Product company ID: ${product.companyId}');
      debugPrint('👤 Product user ID: ${product.userId}');

      final currentUserId = await _hybridService.getCurrentLocalUserId();
      final productWithUser = product.copyWith(
        userId: currentUserId.toString(),
      );

      debugPrint(
        '🔄 Final product data - CompanyID: ${productWithUser.companyId}, UserID: ${productWithUser.userId}',
      );

      final productId = await _hybridService.insertProduct(productWithUser);

      if (productId > 0) {
        debugPrint('✅ Product added successfully with ID: $productId');
        await _loadProductsFromLocal();
        debugPrint('📊 Products reloaded - total count: ${_products.length}');
        _setError(null);
        return true;
      } else {
        debugPrint('❌ Failed to insert product');
        _setError('Ürün eklenemedi');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Product add error: $e');
      _setError('Ürün ekleme hatası: $e');
      return false;
    } finally {
      _setLoading(false);
      await _updateSyncStats();
    }
  }

  Future<bool> updateProduct(Product product) async {
    _setLoading(true);
    try {
      final result = await _hybridService.updateProduct(product);

      if (result > 0) {
        await _loadProductsFromLocal();
        _setError(null);
        return true;
      } else {
        _setError('Ürün güncellenemedi');
        return false;
      }
    } catch (e) {
      // DatabaseException UNIQUE ise kullanıcı dostu mesaj
      final msg = e.toString().toLowerCase().contains('unique')
          ? 'Bu şirkette aynı isimde bir ürün zaten var'
          : 'Ürün güncelleme hatası: $e';
      _setError(msg);
      return false;
    } finally {
      _setLoading(false);
      await _updateSyncStats();
    }
  }

  Future<bool> deleteProduct(int productId) async {
    _setLoading(true);
    try {
      final result = await _hybridService.deleteProduct(productId);

      if (result > 0) {
        await _loadProductsFromLocal();
        _setError(null);
        return true;
      } else {
        _setError('Ürün silinemedi');
        return false;
      }
    } catch (e) {
      _setError('Ürün silme hatası: $e');
      return false;
    } finally {
      _setLoading(false);
      await _updateSyncStats();
    }
  }

  /// Firebase ID ile ürünü sil (kolaylık için)
  Future<bool> deleteProductByFirebaseId(String firebaseId) async {
    _setLoading(true);
    try {
      final sqliteId = await _hybridService.deleteProductByFirebaseId(
        firebaseId,
      ); // returns affected rows
      if (sqliteId > 0) {
        await _loadProductsFromLocal();
        _setError(null);
        return true;
      }
      _setError('Ürün silinemedi');
      return false;
    } catch (e) {
      _setError('Ürün silme hatası: $e');
      return false;
    } finally {
      _setLoading(false);
      await _updateSyncStats();
    }
  }

  // ==================== INVOICE OPERATIONS ====================

  Future<bool> addInvoice(Invoice invoice) async {
    _setLoading(true);
    try {
      final invoiceId = await _hybridService.insertInvoice(invoice);

      if (invoiceId > 0) {
        await _loadInvoicesFromLocal();
        _setError(null);
        return true;
      } else {
        _setError('Fatura eklenemedi');
        return false;
      }
    } catch (e) {
      _setError('Fatura ekleme hatası: $e');
      return false;
    } finally {
      _setLoading(false);
      await _updateSyncStats();
    }
  }

  // ==================== SYNC OPERATIONS ====================

  /// Manual sync trigger
  Future<void> performSync() async {
    if (!_isOnline) {
      _setError('İnternet bağlantısı yok - senkronizasyon yapılamıyor');
      return;
    }

    _setLoading(true);
    try {
      await _hybridService.performManualSync();

      // Reload data after sync
      await _loadUserData();

      _lastSyncTime = DateTime.now();
      await _updateSyncStats();
      _setError(null);
    } catch (e) {
      _setError('Senkronizasyon hatası: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Database maintenance işlemi
  Future<Map<String, dynamic>> performMaintenance() async {
    _setLoading(true);
    try {
      final results = await _hybridService.runMaintenance();
      _setError(null);
      return results;
    } catch (e) {
      _setError('Database maintenance hatası: $e');
      return {'error': e.toString()};
    } finally {
      _setLoading(false);
    }
  }

  /// Database validation işlemi
  Future<Map<String, dynamic>> performValidation() async {
    _setLoading(true);
    try {
      final results = await _hybridService.runValidation();
      _setError(null);
      return results;
    } catch (e) {
      _setError('Database validation hatası: $e');
      return {'error': e.toString()};
    } finally {
      _setLoading(false);
    }
  }

  // ==================== COMPANY PROFILES ====================

  Future<void> loadCompanyProfiles() async {
    try {
      debugPrint('🔍 Şirket profilleri yükleniyor...');

      // Initialize empty list first to prevent null issues
      _companies = [];

      // 1) Local first - with more safety checks
      final localUserId = _appUser?.id;
      debugPrint('🔍 Local user ID: $localUserId');

      List<CompanyInfo> local = [];
      try {
        local = await _hybridService.getAllCompanyProfiles(userId: localUserId);
        debugPrint('📊 Local şirket sayısı: ${local.length}');
      } catch (e) {
        debugPrint('⚠️ Local şirket profilleri yüklenemedi: $e');
        local = [];
      }

      // 2) Remote if online - with timeout
      List<CompanyInfo> remote = [];
      if (_isOnline) {
        try {
          // Add timeout to prevent hanging
          remote = await _firebaseService.getCompanyProfiles().timeout(
            const Duration(seconds: 10),
          );
          debugPrint('📊 Remote şirket sayısı: ${remote.length}');
        } catch (e) {
          debugPrint('⚠️ Remote şirket profilleri yüklenemedi: $e');
          remote = [];
        }
      }

      // 3) Simple merge - avoid complex operations that might crash
      final Set<String> seenIds = {};
      final List<CompanyInfo> mergedList = [];

      // Add local companies first
      for (final c in local) {
        if (c.name.trim().isNotEmpty) {
          final id = c.firebaseId ?? '${c.id}';
          if (!seenIds.contains(id)) {
            seenIds.add(id);
            mergedList.add(c);
          }
        }
      }

      // Add remote companies (only if not already seen)
      for (final c in remote) {
        if (c.name.trim().isNotEmpty) {
          final id = c.firebaseId ?? '${c.id}';
          if (!seenIds.contains(id)) {
            seenIds.add(id);
            mergedList.add(c);
          }
        }
      }

      _companies = mergedList;

      // Simple sort by name instead of date to avoid DateTime issues
      try {
        _companies.sort((a, b) => a.name.compareTo(b.name));
      } catch (e) {
        debugPrint('⚠️ Sort error: $e');
        // Keep unsorted if sort fails
      }

      debugPrint('✅ Toplam şirket sayısı: ${_companies.length}');

      // Safe selection (auto-select first if exists)
      if (_selectedCompany == null && _companies.isNotEmpty) {
        _selectedCompany = _companies.first;
        debugPrint('✅ Seçili şirket: ${_selectedCompany?.name}');
      }

      // Notify listeners at the end
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('❌ Şirket profilleri yüklenemedi: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      _setError('Şirket profilleri yüklenemedi: $e');

      // Ensure _companies is always initialized
      _companies = [];
      _selectedCompany = null;

      // Still notify listeners to update UI
      notifyListeners();
    }
  }

  Future<bool> addCompanyProfile(CompanyInfo company) async {
    _setLoading(true);
    try {
      debugPrint('📝 Şirket ekleniyor: ${company.name}');

      // 1) Local insert (offline-first)
      final localId = await _hybridService.insertCompanyProfile(company);
      debugPrint('✅ Şirket SQLite\'a eklendi, ID: $localId');

      if (localId > 0) {
        // 2) Refresh list to include the new company
        await loadCompanyProfiles();
        debugPrint('📊 Şirket listesi yenilendi: ${_companies.length} şirket');
        _setError(null);
        return true;
      } else {
        _setError('Şirket SQLite\'a eklenemedi');
        debugPrint('❌ Şirket SQLite\'a eklenemedi');
        return false;
      }
    } catch (e) {
      _setError('Şirket eklenemedi: $e');
      debugPrint('❌ Şirket ekleme hatası: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateCompanyProfile(CompanyInfo company) async {
    try {
      // 1) Local-first update so UI immediately reflects changes (including local logo path)
      final updated = await _hybridService.updateCompanyProfileLocal(company);
      if (updated > 0) {
        // 2) Best-effort remote update (non-blocking for UI correctness)
        try {
          await _firebaseService.updateCompanyProfile(company);
        } catch (_) {
          // Remote optional – ignore if fails (no storage etc.)
        }
        // 3) Reload list
        await loadCompanyProfiles();
        return true;
      } else {
        _setError('Şirket yerelde güncellenemedi');
      }
    } catch (e) {
      _setError('Şirket güncellenemedi: $e');
    }
    return false;
  }

  Future<bool> deleteCompanyProfile(String firebaseId) async {
    try {
      // Önce local ürünlerde company_id'yi null yap ki ürünler silinmesin
      await _hybridService.nullifyProductsCompany(firebaseId);

      final ok = await _firebaseService.deleteCompanyProfile(firebaseId);
      if (ok) {
        // Local company_info'dan da sil
        await _hybridService.deleteCompanyProfileByFirebaseId(firebaseId);
        await loadCompanyProfiles();
        if (_selectedCompany?.firebaseId == firebaseId) {
          _selectedCompany = _companies.isNotEmpty ? _companies.first : null;
        }
        // Ürünleri yeniden yükle
        await _loadProductsFromLocal();
        return true;
      }
    } catch (e) {
      _setError('Şirket silinemedi: $e');
    }
    return false;
  }

  void selectCompany(CompanyInfo? company) {
    _selectedCompany = company;
    notifyListeners();
  }

  /// Update connectivity status
  void updateConnectivity(bool isOnline) {
    _isOnline = isOnline;
    notifyListeners();
  }

  // ==================== USER PROFILE SYNC ====================

  /// Firestore'da kullanıcı dokümanı yoksa oluşturur
  Future<void> _ensureFirestoreUserDocument() async {
    if (_currentUser == null) return;
    try {
      final uid = _currentUser!.uid;
      final userRef = _firebaseService.firestore.collection('users').doc(uid);
      final snap = await userRef.get();
      if (!snap.exists) {
        await userRef.set({
          'email': _currentUser!.email,
          'name':
              _currentUser!.displayName ??
              _currentUser!.email?.split('@').first,
          'phone': _currentUser!.phoneNumber,
          'address': null,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ Firestore kullanıcı dokümanı oluşturuldu');
      }
    } catch (e) {
      debugPrint('⚠️ Firestore kullanıcı dokümanı oluşturulamadı: $e');
    }
  }

  /// Kullanıcı profil bilgilerini Firestore'dan güncelle
  Future<void> _updateUserProfileFromFirestore() async {
    if (_currentUser == null || _appUser == null) return;

    try {
      final userDoc = await _firebaseService.firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        final updatedUser = _appUser!.copyWith(
          fullName: data['name'] as String? ?? _appUser!.fullName,
          phone: data['phone'] as String? ?? _appUser!.phone,
          address: data['address'] as String? ?? _appUser!.address,
          updatedAt: DateTime.now(),
        );

        // Eğer veriler değiştiyse güncelle
        if (updatedUser.fullName != _appUser!.fullName ||
            updatedUser.phone != _appUser!.phone ||
            updatedUser.address != _appUser!.address) {
          _appUser = updatedUser;
          debugPrint('✅ Kullanıcı profili Firestore\'dan güncellendi');
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('⚠️ Firestore\'dan profil güncellenemedi: $e');
    }
  }

  // ==================== DATA LOADING ====================

  Future<void> _loadUserData() async {
    debugPrint('🔄 Kullanıcı verileri yükleniyor...');
    try {
      debugPrint(
        '👤 FirebaseUser: ${_currentUser?.uid} / ${_currentUser?.email}',
      );
      debugPrint(
        '🧑‍💻 AppUser: id=${_appUser?.id} name=${_appUser?.fullName} phone=${_appUser?.phone}',
      );
    } catch (_) {}

    // Firestore kullanıcı kaydını garanti altına al
    await _ensureFirestoreUserDocument();

    // Kullanıcı profil bilgilerini Firestore'dan güncelle
    await _updateUserProfileFromFirestore();

    // Kullanıcı ID'si yoksa Firebase sync yap
    if (_appUser?.id == null) {
      debugPrint('⚠️ Kullanıcı ID bulunamadı - Firebase sync yapılıyor');
      // Sonsuz döngü olmaması için _loadUserData'ya tekrar çağrı yapmıyoruz
      await _syncFromFirebaseOnLogin();
      return;
    }

    // Önce yerel verileri yükle (hızlı gösterim için)
    await Future.wait([
      _loadCustomersFromLocal(),
      _loadProductsFromLocal(),
      _loadInvoicesFromLocal(),
      loadCompanyProfiles(), // Güvenli hale getirildi
    ]);

    debugPrint(
      '📊 Yerel veriler: ${_customers.length} müşteri, ${_products.length} ürün, ${_invoices.length} fatura',
    );

    // Eğer yerel veriler boş ise veya online ise Firebase'den sync yap
    if ((_customers.isEmpty || _products.isEmpty || _invoices.isEmpty) &&
        _isOnline) {
      debugPrint('🔄 Firebase\'den senkronizasyon başlatılıyor...');
      await _syncFromFirebaseOnLogin();
    }
  }

  Future<void> _loadCustomersFromLocal() async {
    try {
      final userId = _appUser?.id;
      debugPrint('🔍 Müşteriler SQLite\'dan yükleniyor... UserID: $userId');
      final customers = await _hybridService.getAllCustomers(userId: userId);
      _customers = _dedupCustomers(customers);
      debugPrint('✅ SQLite\'dan ${_customers.length} müşteri yüklendi');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Müşteri yükleme hatası: $e');
      _setError('Müşteriler yüklenemedi: $e');
    }
  }

  Future<void> _loadProductsFromLocal() async {
    try {
      final userId = _appUser?.id;
      debugPrint('🔍 Ürünler SQLite\'dan yükleniyor... UserID: $userId');
      final products = await _hybridService.getAllProducts(userId: userId);
      _products = _dedupProducts(products);
      debugPrint('✅ SQLite\'dan ${_products.length} ürün yüklendi');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Ürün yükleme hatası: $e');
      _setError('Ürünler yüklenemedi: $e');
    }
  }

  Future<void> _loadInvoicesFromLocal() async {
    try {
      final userId = _appUser?.id;
      debugPrint('🔍 Faturalar SQLite\'dan yükleniyor... UserID: $userId');
      final invoices = await _hybridService.getAllInvoices(userId: userId);
      _invoices = _dedupInvoices(invoices);
      debugPrint('✅ SQLite\'dan ${_invoices.length} fatura yüklendi');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Fatura yükleme hatası: $e');
      _setError('Faturalar yüklenemedi: $e');
    }
  }

  // ==================== DEDUP HELPERS ====================

  List<Customer> _dedupCustomers(List<Customer> list) {
    final seen = <String, Customer>{};
    for (final c in list) {
      final key = ((c.id ?? '').isNotEmpty)
          ? c.id!
          : '${c.userId ?? ''}|${TextFormatter.normalizeForSearchTr(c.email ?? '')}|${TextFormatter.normalizeForSearchTr(c.phone ?? '')}|${TextFormatter.normalizeForSearchTr(c.taxNumber ?? '')}|${TextFormatter.normalizeForSearchTr(c.name)}';
      if (!seen.containsKey(key)) {
        seen[key] = c;
      }
    }
    return seen.values.toList(growable: false);
  }

  List<Product> _dedupProducts(List<Product> list) {
    final seen = <String, Product>{};
    for (final p in list) {
      final key = ((p.id ?? '').isNotEmpty)
          ? p.id!
          : '${p.userId}|${TextFormatter.normalizeForSearchTr(p.barcode ?? '')}|${TextFormatter.normalizeForSearchTr(p.name)}';
      if (!seen.containsKey(key)) {
        seen[key] = p;
      }
    }
    return seen.values.toList(growable: false);
  }

  List<Invoice> _dedupInvoices(List<Invoice> list) {
    final seen = <String, Invoice>{};
    for (final i in list) {
      // invoiceNumber her kullanıcı için benzersiz kabul edilir
      final key = i.invoiceNumber;
      if (!seen.containsKey(key)) {
        seen[key] = i;
      }
    }
    return seen.values.toList(growable: false);
  }

  Future<void> _updateSyncStats() async {
    try {
      _syncStats = await _hybridService.getSyncStats();
      notifyListeners();
    } catch (e) {
      debugPrint('Sync stats update error: $e');
    }
  }

  /// Firebase'den ilk giriş senkronizasyonu
  Future<void> _syncFromFirebaseOnLogin() async {
    if (!_isOnline || _currentUser == null) {
      debugPrint('❌ Offline veya kullanıcı yok - Firebase sync atlanıyor');
      return;
    }

    try {
      debugPrint('🔄 Firebase\'den veriler çekiliyor...');

      // Firebase'den verileri çek
      final firebaseCustomers = await _firebaseService.getCustomers();
      final firebaseProducts = await _firebaseService.getProducts();
      final firebaseInvoices = await _firebaseService.getInvoices();

      debugPrint(
        '📥 Firebase\'den alınan: ${firebaseCustomers.length} müşteri, ${firebaseProducts.length} ürün, ${firebaseInvoices.length} fatura',
      );

      // Kullanıcı ID'sini SQLite'dan al - getUserByEmail metodu yok, bu kısmı kaldırıyorum
      // _appUser.id zaten _convertFirebaseUserToAppUser'da null olarak set edildi
      // Veri yükleme sırasında otomatik olarak güncellenecek

      // Verileri yerel listeye ekle (SQLite sync HybridService'de yapılacak)
      // Bu kısmı kaldırıyoruz çünkü artık SQLite'dan yüklüyoruz
      debugPrint('📝 Veriler SQLite\'dan yüklenecek...');

      // Hybrid service ile SQLite'a da sync yap
      await _hybridService.performManualSync();

      // Kullanıcı ID'sini SQLite'dan al ve set et
      if (_appUser != null && _appUser!.id == null) {
        final localUserId = await _hybridService.getCurrentLocalUserId();
        _appUser = _appUser!.copyWith(id: localUserId);
        debugPrint('✅ Kullanıcı ID set edildi (SQLite): ${_appUser?.id}');
      }

      // Kullanıcı ID'si set edildikten sonra verileri yükle
      await Future.wait([
        _loadCustomersFromLocal(),
        _loadProductsFromLocal(),
        _loadInvoicesFromLocal(),
      ]);

      debugPrint('✅ Firebase sync tamamlandı');
    } catch (e) {
      debugPrint('❌ Firebase sync hatası: $e');
      _setError('Veriler yüklenirken hata oluştu: $e');
    }
  }

  // ==================== UTILITY METHODS ====================

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearData() {
    debugPrint('🧹 Tüm veriler temizleniyor...');
    debugPrint(
      '📊 Temizlenmeden önce: ${_customers.length} müşteri, ${_products.length} ürün, ${_invoices.length} fatura',
    );

    _appUser = null;
    _customers.clear();
    _products.clear();
    _invoices.clear();
    _companyInfo = null;
    _syncStats.clear();

    debugPrint('✅ Veriler temizlendi');
    notifyListeners();
  }

  void clearError() {
    _setError(null);
  }

  // ==================== CATEGORY METHODS ====================

  List<String> get categories => [
    'Elektronik',
    'Gıda',
    'Tekstil',
    'Otomotiv',
    'Sağlık',
    'Eğitim',
    'Diğer',
  ];

  // ==================== FILTER METHODS ====================

  List<Product> getProductsByCategory(String category) {
    if (category == 'Tümü') return _products;
    return _products.where((product) => product.category == category).toList();
  }

  List<Customer> searchCustomers(String query) {
    if (query.isEmpty) return _customers;
    final q = TextFormatter.normalizeForSearchTr(query);
    return _customers.where((customer) {
      final name = TextFormatter.normalizeForSearchTr(customer.name);
      final email = TextFormatter.normalizeForSearchTr(customer.email ?? '');
      return name.contains(q) || email.contains(q);
    }).toList();
  }

  List<Product> searchProducts(String query) {
    if (query.isEmpty) return _products;
    final q = TextFormatter.normalizeForSearchTr(query);
    return _products.where((product) {
      final name = TextFormatter.normalizeForSearchTr(product.name);
      final desc = TextFormatter.normalizeForSearchTr(
        product.description ?? '',
      );
      return name.contains(q) || desc.contains(q);
    }).toList();
  }

  // ==================== STATISTICS ====================

  Map<String, dynamic> get statistics {
    return {
      'total_customers': _customers.length,
      'total_products': _products.length,
      'total_invoices': _invoices.length,

      'is_online': _isOnline,
      'last_sync': _lastSyncTime?.toIso8601String(),
      'pending_sync_count': pendingSyncCount,
    };
  }

  // ==================== MISSING METHODS FOR COMPATIBILITY ====================

  /// Load customers (compatibility method)
  Future<void> loadCustomers() async {
    await _loadCustomersFromLocal();
  }

  /// Load products (compatibility method)
  Future<void> loadProducts() async {
    await _loadProductsFromLocal();
  }

  /// Load invoices (compatibility method)
  Future<void> loadInvoices() async {
    await _loadInvoicesFromLocal();
  }

  /// Load company info (compatibility method)
  Future<void> loadCompanyInfo() async {
    try {
      _setLoading(true);
      // Company info is loaded during initialization
      // This is just for compatibility
      _setError(null);
    } catch (e) {
      _setError('Şirket bilgileri yüklenemedi: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load categories (compatibility method)
  Future<void> loadCategories() async {
    // Categories are static in hybrid provider
    // This is just for compatibility
  }

  /// Manuel Firebase sync (test için)
  Future<void> forceFirebaseSync() async {
    debugPrint('🔄 Manuel Firebase sync başlatılıyor...');
    await _syncFromFirebaseOnLogin();
  }

  /// Firebase verilerini kontrol et (debug)
  Future<void> inspectFirebaseData() async {
    if (!_isOnline || _currentUser == null) {
      debugPrint('❌ Offline veya kullanıcı yok');
      return;
    }

    try {
      debugPrint('🔍 Firebase verileri kontrol ediliyor...');

      // Raw Firebase verilerini çek
      final customers = await _firebaseService.getCustomers();
      final products = await _firebaseService.getProducts();
      final invoices = await _firebaseService.getInvoices();

      debugPrint('📊 Firebase Veri Yapısı:');
      debugPrint('==================');

      if (customers.isNotEmpty) {
        final firstCustomer = customers.first;
        debugPrint('👤 İlk Müşteri:');
        debugPrint('  - ID: ${firstCustomer.id}');
        debugPrint('  - UserID: ${firstCustomer.userId}');
        debugPrint('  - Name: ${firstCustomer.name}');
        debugPrint('  - Raw Map: ${firstCustomer.toMap()}');
      }

      if (products.isNotEmpty) {
        final firstProduct = products.first;
        debugPrint('🛍️ İlk Ürün:');
        debugPrint('  - ID: ${firstProduct.id}');
        debugPrint('  - UserID: ${firstProduct.userId}');
        debugPrint('  - Name: ${firstProduct.name}');
        debugPrint('  - Raw Map: ${firstProduct.toMap()}');
      }

      if (invoices.isNotEmpty) {
        final firstInvoice = invoices.first;
        debugPrint('📄 İlk Fatura:');
        debugPrint('  - ID: ${firstInvoice.id}');
        debugPrint('  - Number: ${firstInvoice.invoiceNumber}');
        debugPrint('  - Customer ID: ${firstInvoice.customer.id}');
      }

      debugPrint('==================');
    } catch (e) {
      debugPrint('❌ Firebase veri kontrolü hatası: $e');
    }
  }

  /// Search invoices (compatibility method)
  List<Invoice> searchInvoices(String query) {
    if (query.isEmpty) return _invoices;

    final q = TextFormatter.normalizeForSearchTr(query);
    return _invoices.where((invoice) {
      final inv = TextFormatter.normalizeForSearchTr(invoice.invoiceNumber);
      final cname = TextFormatter.normalizeForSearchTr(invoice.customer.name);
      return inv.contains(q) || cname.contains(q);
    }).toList();
  }

  /// Update profile (compatibility method)
  Future<bool> updateProfile(User user) async {
    try {
      _setLoading(true);

      // Update Firebase user profile
      final currentUser = _firebaseService.auth.currentUser;
      if (currentUser != null) {
        await currentUser.updateDisplayName(user.fullName);
        await currentUser.updateEmail(user.email);

        // Update Firestore user document with additional info
        try {
          await _firebaseService.firestore
              .collection('users')
              .doc(currentUser.uid)
              .update({
                'name': user.fullName,
                'phone': user.phone,
                'address': user.address,
                'updatedAt': FieldValue.serverTimestamp(),
              });
        } catch (firestoreError) {
          debugPrint(
            'Firestore güncelleme hatası (kritik değil): $firestoreError',
          );
        }

        // Update local user data
        _appUser = user;
        notifyListeners();

        return true;
      }

      return false;
    } catch (e) {
      _setError('Profil güncellenemedi: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Logout user (compatibility method)
  Future<void> logout() async {
    try {
      _setLoading(true);
      debugPrint('🚪 Çıkış işlemi başlatılıyor...');

      // Firebase'den çıkış yap
      await _firebaseService.auth.signOut();
      debugPrint('✅ Firebase çıkışı tamamlandı');

      // Tüm verileri temizle
      _clearData();
      debugPrint('✅ Çıkış işlemi tamamlandı');
    } catch (e) {
      debugPrint('❌ Çıkış hatası: $e');
      _setError('Çıkış yapılamadı: $e');
      rethrow; // Hatayı yeniden fırlat ki UI'da yakalanabilsin
    } finally {
      _setLoading(false);
    }
  }

  /// Delete invoice (compatibility method)
  Future<bool> deleteInvoice(String invoiceId) async {
    try {
      _setLoading(true);

      // Convert string ID to int for local database - güvenli dönüşüm
      final id = IdConverter.stringToInt(invoiceId);
      if (id == null) {
        _setError('Geçersiz fatura ID: $invoiceId');
        return false;
      }

      final result = await _hybridService.deleteInvoice(id);

      if (result > 0) {
        await _loadInvoicesFromLocal();
        await _updateSyncStats();
        return true;
      }

      return false;
    } catch (e) {
      _setError('Fatura silinemedi: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update invoice (compatibility method)
  Future<bool> updateInvoice(Invoice invoice) async {
    try {
      _setLoading(true);

      final result = await _hybridService.updateInvoice(invoice);

      if (result > 0) {
        await _loadInvoicesFromLocal();
        await _updateSyncStats();
        return true;
      }

      return false;
    } catch (e) {
      _setError('Fatura güncellenemedi: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // === Invoice Terms helpers ===
  Future<List<String>> getInvoiceTermsTextByInvoiceId(int invoiceId) {
    return _hybridService.getInvoiceTermsTextByInvoiceId(invoiceId);
  }

  /// Save company info (compatibility method)
  Future<bool> saveCompanyInfo(CompanyInfo companyInfo) async {
    try {
      _setLoading(true);

      // Save to Firebase
      await _firebaseService.saveCompanyInfo(companyInfo);

      // Update local data
      _companyInfo = companyInfo;
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Şirket bilgileri kaydedilemedi: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    _hybridService.dispose();
    super.dispose();
  }
}

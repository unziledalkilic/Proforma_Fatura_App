import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/product_category.dart';
import '../services/postgres_service.dart';
import '../utils/text_formatter.dart';

class ProductProvider with ChangeNotifier {
  final PostgresService _postgresService = PostgresService();
  List<Product> _products = [];
  List<ProductCategory> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  List<ProductCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Ürünleri yükle
  Future<void> loadProducts() async {
    _setLoading(true);
    try {
      print('🔄 Ürünler yükleniyor...');
      _products = await _postgresService.getAllProducts();
      print('✅ ${_products.length} ürün yüklendi');
      _error = null;
      notifyListeners();
    } catch (e) {
      print('❌ Ürün yükleme hatası: $e');
      _error = 'Ürünler yüklenirken hata oluştu: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Kategorileri yükle
  Future<void> loadCategories() async {
    try {
      print('🔄 Kategoriler yükleniyor...');
      _categories = await _postgresService.getAllCategories();
      print('✅ ${_categories.length} kategori yüklendi');
      _error = null;
      notifyListeners();
    } catch (e) {
      print('❌ Kategori yükleme hatası: $e');
      _error = 'Kategoriler yüklenirken hata oluştu: $e';
      notifyListeners();
    }
  }

  // Ürün ekle
  Future<bool> addProduct(Product product) async {
    _setLoading(true);
    try {
      print('🔄 Ürün ekleniyor: ${product.name}');
      // Ürün bilgilerini formatla
      final formattedProduct = product.copyWith(
        name: TextFormatter.capitalizeWords(product.name),
        description: product.description != null
            ? TextFormatter.capitalizeFirst(product.description!)
            : null,
        unit: TextFormatter.capitalizeFirst(product.unit),
      );

      final id = await _postgresService.insertProduct(formattedProduct);
      final newProduct = formattedProduct.copyWith(id: id);
      _products.add(newProduct);
      print('✅ Ürün eklendi. ID: $id, Toplam ürün sayısı: ${_products.length}');
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Ürün ekleme hatası: $e');
      _error = 'Ürün eklenirken hata oluştu: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Ürün güncelle
  Future<bool> updateProduct(Product product) async {
    _setLoading(true);
    try {
      // Ürün bilgilerini formatla
      final formattedProduct = product.copyWith(
        name: TextFormatter.capitalizeWords(product.name),
        description: product.description != null
            ? TextFormatter.capitalizeFirst(product.description!)
            : null,
        unit: TextFormatter.capitalizeFirst(product.unit),
      );

      await _postgresService.updateProduct(formattedProduct);
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = formattedProduct;
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ürün güncellenirken hata oluştu: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Ürün sil
  Future<bool> deleteProduct(int id) async {
    _setLoading(true);
    try {
      await _postgresService.deleteProduct(id);
      _products.removeWhere((product) => product.id == id);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ürün silinirken hata oluştu: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Ürün getir
  Future<Product?> getProductById(int id) async {
    try {
      return await _postgresService.getProductById(id);
    } catch (e) {
      _error = 'Ürün getirilirken hata oluştu: $e';
      return null;
    }
  }

  // Kategori ekle
  Future<bool> addCategory(ProductCategory category) async {
    try {
      print('🔄 Kategori ekleniyor: ${category.name}');
      final id = await _postgresService.insertCategory(category);
      if (id != null) {
        final newCategory = category.copyWith(id: id);
        _categories.add(newCategory);
        print(
          '✅ Kategori eklendi. ID: $id, Toplam kategori sayısı: ${_categories.length}',
        );
        _error = null;
        notifyListeners();
        return true;
      } else {
        print('❌ Kategori eklenemedi: ID null döndü');
        _error = 'Kategori eklenemedi';
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ Kategori ekleme hatası: $e');
      _error = 'Kategori eklenirken hata oluştu: $e';
      notifyListeners();
      return false;
    }
  }

  // Ürün ara
  List<Product> searchProducts(String query) {
    if (query.isEmpty) return _products;

    return _products.where((product) {
      return product.name.toLowerCase().contains(query.toLowerCase()) ||
          (product.description?.toLowerCase().contains(query.toLowerCase()) ??
              false) ||
          (product.barcode?.contains(query) ?? false);
    }).toList();
  }

  // Barkod ile ürün bul
  Product? getProductByBarcode(String barcode) {
    try {
      return _products.firstWhere((product) => product.barcode == barcode);
    } catch (e) {
      return null;
    }
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

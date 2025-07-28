import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';

class ProductService {
  static final _supabase = Supabase.instance.client;

  // Kullanıcının tüm ürünlerini getir (kategori bilgisi ile)
  static Future<List<Product>> getProducts() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Kullanıcı giriş yapmamış');

      final response = await _supabase
          .from('products')
          .select('''
            *,
            categories!left(
              name
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response.map<Product>((json) {
        // Category name'i düzelt
        json['category_name'] = json['categories']?['name'];
        return Product.fromJson(json);
      }).toList();
    } catch (e) {
      print('❌ Ürünler alınamadı: $e');
      throw Exception('Ürünler yüklenirken hata oluştu: $e');
    }
  }

  // Belirli kategorideki ürünleri getir
  static Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Kullanıcı giriş yapmamış');

      final response = await _supabase
          .from('products')
          .select('''
            *,
            categories!left(
              name
            )
          ''')
          .eq('user_id', userId)
          .eq('category_id', categoryId)
          .order('created_at', ascending: false);

      return response.map<Product>((json) {
        json['category_name'] = json['categories']?['name'];
        return Product.fromJson(json);
      }).toList();
    } catch (e) {
      print('❌ Kategori ürünleri alınamadı: $e');
      throw Exception('Kategori ürünleri yüklenirken hata oluştu: $e');
    }
  }

  // Favori ürünleri getir
  static Future<List<Product>> getFavoriteProducts() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Kullanıcı giriş yapmamış');

      final response = await _supabase
          .from('products')
          .select('''
            *,
            categories!left(
              name
            )
          ''')
          .eq('user_id', userId)
          .eq('is_favorite', true)
          .order('created_at', ascending: false);

      return response.map<Product>((json) {
        json['category_name'] = json['categories']?['name'];
        return Product.fromJson(json);
      }).toList();
    } catch (e) {
      print('❌ Favori ürünler alınamadı: $e');
      throw Exception('Favori ürünler yüklenirken hata oluştu: $e');
    }
  }

  // Yeni ürün ekle
  static Future<Product> addProduct(Product product) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Kullanıcı giriş yapmamış');

      final productData = product.toInsertJson();
      productData['user_id'] = userId;

      final response = await _supabase
          .from('products')
          .insert(productData)
          .select('''
            *,
            categories!left(
              name
            )
          ''')
          .single();

      response['category_name'] = response['categories']?['name'];
      return Product.fromJson(response);
    } catch (e) {
      print('❌ Ürün eklenemedi: $e');
      throw Exception('Ürün eklenirken hata oluştu: $e');
    }
  }

  // Ürün güncelle
  static Future<Product> updateProduct(Product product) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Kullanıcı giriş yapmamış');

      final response = await _supabase
          .from('products')
          .update(product.toUpdateJson())
          .eq('id', product.id)
          .eq('user_id', userId)
          .select('''
            *,
            categories!left(
              name
            )
          ''')
          .single();

      response['category_name'] = response['categories']?['name'];
      return Product.fromJson(response);
    } catch (e) {
      print('❌ Ürün güncellenemedi: $e');
      throw Exception('Ürün güncellenirken hata oluştu: $e');
    }
  }

  // Ürün sil
  static Future<void> deleteProduct(String productId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Kullanıcı giriş yapmamış');

      await _supabase
          .from('products')
          .delete()
          .eq('id', productId)
          .eq('user_id', userId);

      print('✅ Ürün silindi: $productId');
    } catch (e) {
      print('❌ Ürün silinemedi: $e');
      throw Exception('Ürün silinirken hata oluştu: $e');
    }
  }

  // Favori durumu değiştir
  static Future<Product> toggleFavorite(Product product) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Kullanıcı giriş yapmamış');

      final response = await _supabase
          .from('products')
          .update({
            'is_favorite': !product.isFavorite,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', product.id)
          .eq('user_id', userId)
          .select('''
            *,
            categories!left(
              name
            )
          ''')
          .single();

      response['category_name'] = response['categories']?['name'];
      return Product.fromJson(response);
    } catch (e) {
      print('❌ Favori durumu değiştirilemedi: $e');
      throw Exception('Favori durumu değiştirilirken hata oluştu: $e');
    }
  }

  // Ürün ara (isim veya kategori)
  static Future<List<Product>> searchProducts(String searchTerm) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Kullanıcı giriş yapmamış');

      final response = await _supabase
          .from('products')
          .select('''
            *,
            categories!left(
              name
            )
          ''')
          .eq('user_id', userId)
          .or('name.ilike.%$searchTerm%,categories.name.ilike.%$searchTerm%')
          .order('created_at', ascending: false);

      return response.map<Product>((json) {
        json['category_name'] = json['categories']?['name'];
        return Product.fromJson(json);
      }).toList();
    } catch (e) {
      print('❌ Ürün araması başarısız: $e');
      throw Exception('Ürün arama işlemi başarısız: $e');
    }
  }

  // KATEGORI İŞLEMLERİ
  
  // Kullanıcının tüm kategorilerini getir
  static Future<List<Category>> getCategories() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Kullanıcı giriş yapmamış');

      final response = await _supabase
          .from('categories')
          .select('*')
          .eq('user_id', userId)
          .order('name', ascending: true);

      return response.map<Category>((json) => Category.fromJson(json)).toList();
    } catch (e) {
      print('❌ Kategoriler alınamadı: $e');
      throw Exception('Kategoriler yüklenirken hata oluştu: $e');
    }
  }

  // Kategorileri ürün sayısı ile getir
  static Future<List<Category>> getCategoriesWithCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Kullanıcı giriş yapmamış');

      // Önce kategorileri al
      final categoriesResponse = await _supabase
          .from('categories')
          .select('*')
          .eq('user_id', userId)
          .order('name', ascending: true);

      List<Category> categories = [];
      
      // Her kategori için ürün sayısını hesapla
      for (var categoryJson in categoriesResponse) {
        final categoryId = categoryJson['id'];
        
        final productCountResponse = await _supabase
            .from('products')
            .select('id')
            .eq('user_id', userId)
            .eq('category_id', categoryId);
            
        categoryJson['product_count'] = productCountResponse.length;
        categories.add(Category.fromJson(categoryJson));
      }

      return categories;
    } catch (e) {
      print('❌ Kategoriler (sayım ile) alınamadı: $e');
      throw Exception('Kategoriler yüklenirken hata oluştu: $e');
    }
  }

  // Yeni kategori ekle
  static Future<Category> addCategory(Category category) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Kullanıcı giriş yapmamış');

      final categoryData = category.toInsertJson();
      categoryData['user_id'] = userId;

      final response = await _supabase
          .from('categories')
          .insert(categoryData)
          .select()
          .single();

      return Category.fromJson(response);
    } catch (e) {
      print('❌ Kategori eklenemedi: $e');
      throw Exception('Kategori eklenirken hata oluştu: $e');
    }
  }

  // Kategori güncelle
  static Future<Category> updateCategory(Category category) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Kullanıcı giriş yapmamış');

      final response = await _supabase
          .from('categories')
          .update(category.toUpdateJson())
          .eq('id', category.id)
          .eq('user_id', userId)
          .select()
          .single();

      return Category.fromJson(response);
    } catch (e) {
      print('❌ Kategori güncellenemedi: $e');
      throw Exception('Kategori güncellenirken hata oluştu: $e');
    }
  }

  // Kategori sil
  static Future<void> deleteCategory(String categoryId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Kullanıcı giriş yapmamış');

      // Önce bu kategorideki ürünlerin category_id'sini null yap
      await _supabase
          .from('products')
          .update({'category_id': null})
          .eq('category_id', categoryId)
          .eq('user_id', userId);

      // Sonra kategoriyi sil
      await _supabase
          .from('categories')
          .delete()
          .eq('id', categoryId)
          .eq('user_id', userId);

      print('✅ Kategori silindi: $categoryId');
    } catch (e) {
      print('❌ Kategori silinemedi: $e');
      throw Exception('Kategori silinirken hata oluştu: $e');
    }
  }

  // İSTATİSTİKLER

  // Kullanıcının toplam ürün sayısı
  static Future<int> getTotalProductCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _supabase
          .from('products')
          .select('id')
          .eq('user_id', userId);

      return response.length;
    } catch (e) {
      print('❌ Ürün sayısı alınamadı: $e');
      return 0;
    }
  }

  // Kullanıcının favori ürün sayısı
  static Future<int> getFavoriteProductCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _supabase
          .from('products')
          .select('id')
          .eq('user_id', userId)
          .eq('is_favorite', true);

      return response.length;
    } catch (e) {
      print('❌ Favori ürün sayısı alınamadı: $e');
      return 0;
    }
  }

  // Kullanıcının toplam kategori sayısı
  static Future<int> getTotalCategoryCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _supabase
          .from('categories')
          .select('id')
          .eq('user_id', userId);

      return response.length;
    } catch (e) {
      print('❌ Kategori sayısı alınamadı: $e');
      return 0;
    }
  }
}
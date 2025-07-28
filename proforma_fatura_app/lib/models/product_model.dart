class Product {
  final String id;
  final String userId;
  final String name;
  final double price;
  final String unit;
  final String? categoryId;
  final String? categoryName; // Join'den gelecek
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.userId,
    required this.name,
    required this.price,
    required this.unit,
    this.categoryId,
    this.categoryName,
    required this.isFavorite,
    required this.createdAt,
    required this.updatedAt,
  });

  // Fiyatı formatlanmış string olarak döndür
  String get formattedPrice => '₺${price.toStringAsFixed(2)}';

  // Fiyat + birim
  String get priceWithUnit => '$formattedPrice / $unit';

  // Kategori adı veya varsayılan
  String get displayCategory => categoryName ?? 'Kategorisiz';

  // JSON'dan Product oluştur
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      unit: json['unit'] ?? 'Adet',
      categoryId: json['category_id'],
      categoryName: json['category_name'], // JOIN'den gelecek
      isFavorite: json['is_favorite'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  // Product'ı JSON'a çevir (INSERT/UPDATE için)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'unit': unit,
      'category_id': categoryId,
      'is_favorite': isFavorite,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // INSERT için (ID ve timestamps hariç)
  Map<String, dynamic> toInsertJson() {
    return {
      'name': name,
      'price': price,
      'unit': unit,
      'category_id': categoryId,
      'is_favorite': isFavorite,
    };
  }

  // UPDATE için (sadece değişebilir alanlar)
  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'price': price,
      'unit': unit,
      'category_id': categoryId,
      'is_favorite': isFavorite,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // Kopyalama (güncelleme için)
  Product copyWith({
    String? name,
    double? price,
    String? unit,
    String? categoryId,
    String? categoryName,
    bool? isFavorite,
  }) {
    return Product(
      id: id,
      userId: userId,
      name: name ?? this.name,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Debug için
  @override
  String toString() {
    return 'Product{id: $id, name: $name, price: $formattedPrice, unit: $unit, category: $displayCategory, favorite: $isFavorite}';
  }

  // Validasyon
  bool get isValid {
    return name.isNotEmpty && price >= 0 && unit.isNotEmpty;
  }

  // Arama için (case-insensitive)
  bool containsSearchTerm(String searchTerm) {
    if (searchTerm.isEmpty) return true;
    
    final term = searchTerm.toLowerCase();
    return name.toLowerCase().contains(term) ||
           displayCategory.toLowerCase().contains(term) ||
           unit.toLowerCase().contains(term);
  }
}

class Category {
  final String id;
  final String userId;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? productCount; // İstatistik için

  Category({
    required this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.productCount,
  });

  // JSON'dan Category oluştur
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      productCount: json['product_count'],
    );
  }

  // Category'yi JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // INSERT için
  Map<String, dynamic> toInsertJson() {
    return {
      'name': name,
    };
  }

  // UPDATE için
  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // Kopyalama
  Category copyWith({
    String? name,
    int? productCount,
  }) {
    return Category(
      id: id,
      userId: userId,
      name: name ?? this.name,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      productCount: productCount ?? this.productCount,
    );
  }

  // Debug için
  @override
  String toString() {
    return 'Category{id: $id, name: $name, productCount: ${productCount ?? 0}}';
  }

  // Validasyon
  bool get isValid {
    return name.isNotEmpty && name.length >= 2;
  }

  // Arama için
  bool containsSearchTerm(String searchTerm) {
    if (searchTerm.isEmpty) return true;
    return name.toLowerCase().contains(searchTerm.toLowerCase());
  }
}

// Dropdown'lar için basit model
class CategoryOption {
  final String id;
  final String name;

  CategoryOption({required this.id, required this.name});

  factory CategoryOption.fromCategory(Category category) {
    return CategoryOption(
      id: category.id,
      name: category.name,
    );
  }

  @override
  String toString() => name;
}
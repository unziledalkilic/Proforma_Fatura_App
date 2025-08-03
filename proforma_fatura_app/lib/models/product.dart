import 'product_category.dart';

class Product {
  final int? id;
  final int userId; // Kullanıcıya özel
  final String name;
  final String? description;
  final double price;
  final String currency; // TRY, USD, EUR, GBP
  final String unit; // adet, kg, metre vb.
  final String? barcode;
  final double? taxRate; // KDV oranı
  final ProductCategory? category;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.price,
    this.currency = 'TRY',
    required this.unit,
    this.barcode,
    this.taxRate,
    this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'unit': unit,
      'barcode': barcode,
      'taxRate': taxRate,
      'category_id': category?.id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      userId: map['user_id'] ?? map['userId'],
      name: map['name'],
      description: map['description'],
      price: map['price'].toDouble(),
      currency: map['currency'] ?? 'TRY',
      unit: map['unit'] ?? 'Adet',
      barcode: map['barcode'],
      taxRate: map['taxRate']?.toDouble(),
      category: map['category'] != null
          ? ProductCategory.fromMap(map['category'])
          : null,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Product copyWith({
    int? id,
    int? userId,
    String? name,
    String? description,
    double? price,
    String? currency,
    String? unit,
    String? barcode,
    double? taxRate,
    ProductCategory? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      unit: unit ?? this.unit,
      barcode: barcode ?? this.barcode,
      taxRate: taxRate ?? this.taxRate,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // KDV dahil fiyat hesaplama
  double get priceWithTax {
    if (taxRate == null || taxRate == 0) return price;
    return price * (1 + taxRate! / 100);
  }
}

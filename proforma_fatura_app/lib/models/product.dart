class Product {
  final String? id;
  final String userId; // Kullanıcıya özel
  final String? companyId; // Şirkete özel
  final String name;
  final String? description;
  final double price;
  final String currency; // TRY, USD, EUR, GBP
  final String unit; // adet, kg, metre vb.
  final String? barcode;
  final double? taxRate; // KDV oranı
  final String? category; // String olarak değiştirildi
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    this.id,
    required this.userId,
    this.companyId,
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
      'company_id': companyId,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'unit': unit,
      'barcode': barcode,
      'tax_rate': taxRate, // SQLite için tax_rate
      // Kategoriyi doğrudan metin olarak sakla (SQLite dinamik tip)
      'category_id': category,
      'created_at': createdAt.toIso8601String(), // SQLite için created_at
      'updated_at': updatedAt.toIso8601String(), // SQLite için updated_at
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id']?.toString(),
      userId: map['user_id']?.toString() ?? map['userId']?.toString() ?? '',
      companyId: map['company_id']?.toString() ?? map['companyId']?.toString(),
      name: map['name'] ?? '',
      description: map['description'],
      price: (map['price'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'TRY',
      unit: map['unit'] ?? 'Adet',
      barcode: map['barcode'],
      taxRate: (map['tax_rate'] ?? map['taxRate'])?.toDouble(),
      category: map['category_id']?.toString() ?? map['category']?.toString(),
      createdAt: DateTime.parse(
        map['created_at'] ??
            map['createdAt'] ??
            DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        map['updated_at'] ??
            map['updatedAt'] ??
            DateTime.now().toIso8601String(),
      ),
    );
  }

  Product copyWith({
    String? id,
    String? userId,
    String? companyId,
    String? name,
    String? description,
    double? price,
    String? currency,
    String? unit,
    String? barcode,
    double? taxRate,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      companyId: companyId ?? this.companyId,
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

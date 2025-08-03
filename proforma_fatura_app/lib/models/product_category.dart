class ProductCategory {
  final int? id;
  final int userId; // Kullanıcıya özel
  final String name;
  final String? description;
  final String color;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductCategory({
    this.id,
    required this.userId,
    required this.name,
    this.description,
    this.color = '#2196F3',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  ProductCategory copyWith({
    int? id,
    int? userId,
    String? name,
    String? description,
    String? color,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductCategory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'color': color,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ProductCategory.fromMap(Map<String, dynamic> map) {
    return ProductCategory(
      id: map['id'] as int?,
      userId: map['user_id'] ?? map['userId'],
      name: map['name'] as String,
      description: map['description'] as String?,
      color: map['color'] as String? ?? '#2196F3',
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  @override
  String toString() {
    return 'ProductCategory(id: $id, name: $name, description: $description, color: $color, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductCategory && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}

class Customer {
  final String? id;
  final String? firebaseId;
  final String? userId; // Kullanıcı ID'si eklendi
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? taxNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    this.id,
    this.firebaseId,
    this.userId, // Kullanıcı ID'si eklendi
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.taxNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firebase_id': firebaseId,
      'user_id': userId, // SQLite için user_id olarak map et
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'tax_number': taxNumber, // SQLite için tax_number olarak map et
      'created_at': createdAt.toIso8601String(), // SQLite için created_at
      'updated_at': updatedAt.toIso8601String(), // SQLite için updated_at
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id']?.toString(),
      firebaseId: map['firebase_id']?.toString(),
      userId: map['user_id']?.toString() ?? map['userId']?.toString(),
      name: map['name'] ?? '',
      email: map['email'],
      phone: map['phone'],
      address: map['address'],
      taxNumber: map['tax_number'] ?? map['taxNumber'],
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

  Customer copyWith({
    String? id,
    String? firebaseId,
    String? userId, // Kullanıcı ID'si eklendi
    String? name,
    String? email,
    String? phone,
    String? address,
    String? taxNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      firebaseId: firebaseId ?? this.firebaseId,
      userId: userId ?? this.userId, // Kullanıcı ID'si eklendi
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      taxNumber: taxNumber ?? this.taxNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

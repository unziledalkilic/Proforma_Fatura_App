class CompanyInfo {
  final int id;
  final String? firebaseId;
  final String? userId;
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final String? website;
  final String? taxNumber;
  final String? logo;
  final DateTime createdAt;
  final DateTime updatedAt;

  CompanyInfo({
    required this.id,
    this.firebaseId,
    this.userId,
    required this.name,
    this.address,
    this.phone,
    this.email,
    this.website,
    this.taxNumber,
    this.logo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CompanyInfo.fromMap(Map<String, dynamic> map) {
    return CompanyInfo(
      id: int.tryParse(map['id']?.toString() ?? '1') ?? 1,
      firebaseId: map['firebase_id']?.toString(),
      userId: map['user_id']?.toString() ?? map['userId']?.toString(),
      name: (map['name'] ?? '') as String,
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      website: map['website'] as String?,
      taxNumber:
          map['taxNumber'] ??
          map['tax_number'] as String?, // Her iki format da destekle
      logo: map['logo'] as String?,
      createdAt: DateTime.parse(
        map['createdAt'] ??
            map['created_at'] ??
            DateTime.now().toIso8601String(),
      ), // Her iki format da destekle
      updatedAt: DateTime.parse(
        map['updatedAt'] ??
            map['updated_at'] ??
            DateTime.now().toIso8601String(),
      ), // Her iki format da destekle
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firebase_id': firebaseId,
      'user_id': userId,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'tax_number': taxNumber,
      'logo': logo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CompanyInfo copyWith({
    int? id,
    String? firebaseId,
    String? userId,
    String? name,
    String? address,
    String? phone,
    String? email,
    String? website,
    String? taxNumber,
    String? logo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CompanyInfo(
      id: id ?? this.id,
      firebaseId: firebaseId ?? this.firebaseId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      taxNumber: taxNumber ?? this.taxNumber,
      logo: logo ?? this.logo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

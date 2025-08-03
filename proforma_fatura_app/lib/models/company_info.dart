class CompanyInfo {
  final int id;
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final String? website;
  final String? taxNumber;
  final String? taxOffice;
  final String? logo;
  final DateTime createdAt;
  final DateTime updatedAt;

  CompanyInfo({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.email,
    this.website,
    this.taxNumber,
    this.taxOffice,
    this.logo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CompanyInfo.fromMap(Map<String, dynamic> map) {
    return CompanyInfo(
      id: map['id'] as int,
      name: map['name'] as String,
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      website: map['website'] as String?,
      taxNumber: map['tax_number'] as String?,
      taxOffice: map['tax_office'] as String?,
      logo: map['logo'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'tax_number': taxNumber,
      'tax_office': taxOffice,
      'logo': logo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CompanyInfo copyWith({
    int? id,
    String? name,
    String? address,
    String? phone,
    String? email,
    String? website,
    String? taxNumber,
    String? taxOffice,
    String? logo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CompanyInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      taxNumber: taxNumber ?? this.taxNumber,
      taxOffice: taxOffice ?? this.taxOffice,
      logo: logo ?? this.logo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

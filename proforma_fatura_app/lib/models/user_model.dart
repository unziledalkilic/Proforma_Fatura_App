class UserProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? companyName;
  final String? taxNumber;
  final String? address;
  final String? invoiceNumber;
  final String? defaultCurrency;
  final String? companyLogo;
  final String? invoiceFooter;
  final String? profileImage;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.companyName,
    this.taxNumber,
    this.address,
    this.invoiceNumber,
    this.defaultCurrency,
    this.companyLogo,
    this.invoiceFooter,
    this.profileImage,
    required this.createdAt,
    required this.updatedAt,
  });

  // Tam ad döndür
  String get fullName => '$firstName $lastName';

  // Telefon numarası formatlanmış halini döndür
  String get formattedPhone {
    if (phone == null || phone!.isEmpty) return 'Telefon girilmemiş';
    return phone!;
  }

  // Profil başharflerini döndür (Avatar için)
  String get initials {
    String firstInitial =
        firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    String lastInitial = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$firstInitial$lastInitial';
  }

  // JSON'dan UserProfile oluştur
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      companyName: json['company_name'],
      taxNumber: json['tax_number'],
      address: json['address'],
      invoiceNumber: json['invoice_number'],
      defaultCurrency: json['default_currency'],
      companyLogo: json['company_logo_url'],
      invoiceFooter: json['invoice_footer'],
      profileImage: json['profile_image'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  // UserProfile'ı JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'company_name': companyName,
      'tax_number': taxNumber,
      'address': address,
      'invoice_number': invoiceNumber,
      'default_currency': defaultCurrency,
      'company_logo_url': companyLogo,
      'invoice_footer': invoiceFooter,
      'profile_image': profileImage,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // Kayıt sırasında kullanılacak data (Supabase auth için)
  Map<String, dynamic> toAuthData() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
    };
  }

  // Profil kopyalama (güncelleme için)
  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? companyName,
    String? taxNumber,
    String? address,
    String? invoiceNumber,
    String? defaultCurrency,
    String? companyLogo,
    String? invoiceFooter,
    String? profileImage,
  }) {
    return UserProfile(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      companyName: companyName ?? this.companyName,
      taxNumber: taxNumber ?? this.taxNumber,
      address: address ?? this.address,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      companyLogo: companyLogo ?? this.companyLogo,
      invoiceFooter: invoiceFooter ?? this.invoiceFooter,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Debug için string gösterimi
  @override
  String toString() {
    return 'UserProfile{id: $id, fullName: $fullName, email: $email, phone: ${phone ?? 'Yok'}, companyName: ${companyName ?? 'Yok'}, taxNumber: ${taxNumber ?? 'Yok'}, address: ${address ?? 'Yok'}, invoiceNumber: ${invoiceNumber ?? 'Yok'}, defaultCurrency: ${defaultCurrency ?? 'TRY'}, invoiceFooter: ${invoiceFooter ?? 'Yok'}}';
  }

  // Validasyon metodları
  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool get hasPhone {
    return phone != null && phone!.isNotEmpty;
  }

  bool get isProfileComplete {
    return firstName.isNotEmpty &&
        lastName.isNotEmpty &&
        email.isNotEmpty &&
        isValidEmail;
  }
}

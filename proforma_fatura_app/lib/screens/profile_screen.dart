import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isEditingCompany = false;
  bool _isEditingSettings = false;

  // Controllers for editing
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _taxNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _invoiceNumberController =
      TextEditingController();
  final TextEditingController _invoiceFooterController =
      TextEditingController();

  final List<String> currencies = [
    'TRY',
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'CNY',
    'CAD',
    'AUD',
    'CHF',
    'SEK',
    'NOK',
    'DKK',
    'PLN',
    'CZK',
    'HUF',
    'RON',
    'BGN',
    'HRK',
    'RUB',
    'INR',
    'BRL',
    'MXN',
    'ZAR',
    'KRW',
    'SGD',
    'HKD',
    'NZD',
    'THB',
    'MYR',
    'IDR',
    'PHP',
    'VND',
    'EGP',
    'SAR',
    'AED',
    'QAR',
    'KWD',
    'BHD',
    'OMR',
    'JOD',
    'LBP',
    'ILS',
    'IRR',
    'AFN',
    'PKR',
    'BDT',
    'LKR',
    'NPR',
    'MMK',
    'KHR',
    'LAK',
    'MNT',
    'KZT',
    'UZS',
    'TJS',
    'TMT',
    'AZN',
    'GEL',
    'AMD',
    'BYN',
    'MDL',
    'UAH',
    'KGS',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _companyNameController.dispose();
    _taxNumberController.dispose();
    _addressController.dispose();
    _invoiceNumberController.dispose();
    _invoiceFooterController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final authService = AuthService();
      final profile = await authService.getCurrentUserProfile();
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profil yüklenirken hata: $e')),
      );
    }
  }

  void _initializeControllers() {
    if (_userProfile != null) {
      _firstNameController.text = _userProfile!.firstName;
      _lastNameController.text = _userProfile!.lastName;
      _phoneController.text = _userProfile!.phone ?? '';
      _companyNameController.text = _userProfile!.companyName ?? '';
      _taxNumberController.text = _userProfile!.taxNumber ?? '';
      _addressController.text = _userProfile!.address ?? '';
      _invoiceNumberController.text = _userProfile!.invoiceNumber ?? '';
      _invoiceFooterController.text = _userProfile!.invoiceFooter ?? '';
    }
  }

  String toTitleCase(String input) {
    return input
        .split(' ')
        .map((str) => str.isNotEmpty
            ? str[0].toUpperCase() + str.substring(1).toLowerCase()
            : '')
        .join(' ');
  }

  Future<void> _pickProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // TODO: Supabase Storage'a yükle
      setState(() {
        // _userProfile = _userProfile?.copyWith(profileImage: image.path);
      });
    }
  }

  Future<void> _pickCompanyLogo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // TODO: Supabase Storage'a yükle
      setState(() {
        // _userProfile = _userProfile?.copyWith(companyLogo: image.path);
      });
    }
  }

  Future<void> _saveProfileChanges() async {
    if (_userProfile == null) return;

    try {
      final updatedProfile = _userProfile!.copyWith(
        firstName: toTitleCase(_firstNameController.text.trim()),
        lastName: toTitleCase(_lastNameController.text.trim()),
        phone: _phoneController.text.trim(),
      );

      final authService = AuthService();
      await authService.updateUserProfile(updatedProfile);

      setState(() {
        _userProfile = updatedProfile;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil başarıyla güncellendi')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Güncelleme hatası: $e')),
      );
    }
  }

  Future<void> _saveCompanyChanges() async {
    if (_userProfile == null) return;

    try {
      final updatedProfile = _userProfile!.copyWith(
        companyName: toTitleCase(_companyNameController.text.trim()),
        taxNumber: _taxNumberController.text.trim(),
        address: toTitleCase(_addressController.text.trim()),
      );

      final authService = AuthService();
      await authService.updateUserProfile(updatedProfile);

      setState(() {
        _userProfile = updatedProfile;
        _isEditingCompany = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şirket bilgileri başarıyla güncellendi')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Güncelleme hatası: $e')),
      );
    }
  }

  Future<void> _saveSettingsChanges() async {
    if (_userProfile == null) return;

    try {
      final updatedProfile = _userProfile!.copyWith(
        invoiceNumber: _invoiceNumberController.text.trim(),
        invoiceFooter: _invoiceFooterController.text.trim(),
      );

      final authService = AuthService();
      await authService.updateUserProfile(updatedProfile);

      setState(() {
        _userProfile = updatedProfile;
        _isEditingSettings = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fatura ayarları başarıyla güncellendi')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Güncelleme hatası: $e')),
      );
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Çıkış Yap'),
          content: const Text(
              'Hesabınızdan çıkış yapmak istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performLogout();
              },
              child: const Text('Çıkış Yap'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout() async {
    try {
      final authService = AuthService();
      await authService.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Çıkış yapılırken hata: $e')),
      );
    }
  }

  Widget _buildProfileEditForm() {
    _initializeControllers();

    return Column(
      children: [
        TextField(
          controller: _firstNameController,
          decoration: const InputDecoration(
            labelText: 'Ad',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _lastNameController,
          decoration: const InputDecoration(
            labelText: 'Soyad',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Telefon',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _saveProfileChanges,
                child: const Text('Kaydet'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                  });
                },
                child: const Text('İptal'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompanyEditForm() {
    return Column(
      children: [
        TextField(
          controller: _companyNameController,
          decoration: const InputDecoration(
            labelText: 'Şirket Adı',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _taxNumberController,
          decoration: const InputDecoration(
            labelText: 'Vergi Numarası',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Adres',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _saveCompanyChanges,
                child: const Text('Kaydet'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isEditingCompany = false;
                  });
                },
                child: const Text('İptal'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsEditForm() {
    return Column(
      children: [
        TextField(
          controller: _invoiceNumberController,
          decoration: const InputDecoration(
            labelText: 'Fatura Numarası',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: TextEditingController(
                    text: _userProfile?.defaultCurrency ?? 'TRY'),
                decoration: const InputDecoration(
                  labelText: 'Varsayılan Para Birimi',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: const Icon(Icons.arrow_drop_down),
              onSelected: (val) async {
                if (_userProfile != null) {
                  final updatedProfile =
                      _userProfile!.copyWith(defaultCurrency: val);
                  final authService = AuthService();
                  await authService.updateUserProfile(updatedProfile);
                  setState(() {
                    _userProfile = updatedProfile;
                  });
                }
              },
              itemBuilder: (context) => currencies
                  .map((currency) => PopupMenuItem(
                        value: currency,
                        child: Text(currency),
                      ))
                  .toList(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _invoiceFooterController,
          decoration: const InputDecoration(
            labelText: 'Fatura Alt Bilgisi',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _saveSettingsChanges,
                child: const Text('Kaydet'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isEditingSettings = false;
                  });
                },
                child: const Text('İptal'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userProfile == null) {
      return const Scaffold(
        body: Center(child: Text('Profil yüklenemedi')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profil Kartı
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _pickProfileImage,
                          child: CircleAvatar(
                            radius: 40,
                            backgroundImage: _userProfile!.profileImage != null
                                ? FileImage(File(_userProfile!.profileImage!))
                                : null,
                            child: _userProfile!.profileImage == null
                                ? const Icon(Icons.person, size: 40)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_userProfile!.firstName} ${_userProfile!.lastName}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _userProfile!.email,
                                style: const TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                              if (_userProfile!.phone != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _userProfile!.phone!,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (!_isEditing)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _isEditing = true;
                              });
                            },
                            icon: const Icon(Icons.edit),
                          ),
                      ],
                    ),
                    if (_isEditing) ...[
                      const SizedBox(height: 16),
                      _buildProfileEditForm(),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Şirket Bilgileri
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Şirket Bilgileri',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!_isEditingCompany)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _isEditingCompany = true;
                              });
                            },
                            icon: const Icon(Icons.edit),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!_isEditingCompany) ...[
                      if (_userProfile!.companyName != null) ...[
                        _buildInfoRow('Şirket Adı', _userProfile!.companyName!),
                        const SizedBox(height: 8),
                      ],
                      if (_userProfile!.taxNumber != null) ...[
                        _buildInfoRow(
                            'Vergi Numarası', _userProfile!.taxNumber!),
                        const SizedBox(height: 8),
                      ],
                      if (_userProfile!.address != null) ...[
                        _buildInfoRow('Adres', _userProfile!.address!),
                        const SizedBox(height: 8),
                      ],
                    ] else ...[
                      _buildCompanyEditForm(),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Fatura Ayarları
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Fatura Ayarları',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!_isEditingSettings)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _isEditingSettings = true;
                              });
                            },
                            icon: const Icon(Icons.edit),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!_isEditingSettings) ...[
                      if (_userProfile!.invoiceNumber != null) ...[
                        _buildInfoRow(
                            'Fatura Numarası', _userProfile!.invoiceNumber!),
                        const SizedBox(height: 8),
                      ],
                      _buildInfoRow('Varsayılan Para Birimi',
                          _userProfile!.defaultCurrency ?? 'TRY'),
                      const SizedBox(height: 8),
                      if (_userProfile!.invoiceFooter != null) ...[
                        _buildInfoRow(
                            'Fatura Alt Bilgisi', _userProfile!.invoiceFooter!),
                        const SizedBox(height: 8),
                      ],
                    ] else ...[
                      _buildSettingsEditForm(),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Çıkış Yap Butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showLogoutDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Çıkış Yap'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/company_provider.dart';
import '../models/company_info.dart';

class CompanyInfoScreen extends StatefulWidget {
  const CompanyInfoScreen({super.key});

  @override
  State<CompanyInfoScreen> createState() => _CompanyInfoScreenState();
}

class _CompanyInfoScreenState extends State<CompanyInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _taxNumberController = TextEditingController();
  final _taxOfficeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCompanyInfo();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _taxNumberController.dispose();
    _taxOfficeController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanyInfo() async {
    final companyProvider = context.read<CompanyProvider>();
    await companyProvider.loadCompanyInfo();
    
    if (companyProvider.companyInfo != null) {
      final company = companyProvider.companyInfo!;
      _nameController.text = company.name;
      _addressController.text = company.address ?? '';
      _phoneController.text = company.phone ?? '';
      _emailController.text = company.email ?? '';
      _websiteController.text = company.website ?? '';
      _taxNumberController.text = company.taxNumber ?? '';
      _taxOfficeController.text = company.taxOffice ?? '';
    }
  }

  Future<void> _saveCompanyInfo() async {
    if (!_formKey.currentState!.validate()) return;

    final companyProvider = context.read<CompanyProvider>();
    
    final companyInfo = CompanyInfo(
      id: companyProvider.companyInfo?.id ?? 0,
      name: _nameController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
      taxNumber: _taxNumberController.text.trim().isEmpty ? null : _taxNumberController.text.trim(),
      taxOffice: _taxOfficeController.text.trim().isEmpty ? null : _taxOfficeController.text.trim(),
      createdAt: companyProvider.companyInfo?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await companyProvider.saveCompanyInfo(companyInfo);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şirket bilgileri başarıyla kaydedildi!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(companyProvider.error ?? 'Kaydetme başarısız'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Şirket Bilgileri'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Consumer<CompanyProvider>(
          builder: (context, companyProvider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo ve başlık
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.business,
                        size: 40,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Şirket Bilgilerinizi Güncelleyin',
                      style: AppConstants.headingStyle.copyWith(
                        color: AppConstants.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Proforma faturalarınızda görünecek şirket bilgilerini düzenleyin',
                      style: AppConstants.bodyStyle.copyWith(
                        color: AppConstants.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Şirket Adı
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Şirket Adı *',
                        hintText: 'Şirketinizin tam adı',
                        prefixIcon: Icon(Icons.business),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Şirket adı gerekli';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Adres
                    TextFormField(
                      controller: _addressController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Adres',
                        hintText: 'Şirket adresiniz',
                        prefixIcon: Icon(Icons.location_on),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Telefon
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Telefon',
                        hintText: '0212 555 01 01',
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // E-posta
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-posta',
                        hintText: 'info@sirketiniz.com',
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Geçerli bir e-posta adresi girin';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Website
                    TextFormField(
                      controller: _websiteController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Website',
                        hintText: 'www.sirketiniz.com',
                        prefixIcon: Icon(Icons.language),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Vergi Numarası
                    TextFormField(
                      controller: _taxNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Vergi Numarası',
                        hintText: '1234567890',
                        prefixIcon: Icon(Icons.receipt),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Vergi Dairesi
                    TextFormField(
                      controller: _taxOfficeController,
                      decoration: const InputDecoration(
                        labelText: 'Vergi Dairesi',
                        hintText: 'Kadıköy Vergi Dairesi',
                        prefixIcon: Icon(Icons.account_balance),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Kaydet butonu
                    ElevatedButton(
                      onPressed: companyProvider.isLoading ? null : _saveCompanyInfo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppConstants.paddingMedium,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadius,
                          ),
                        ),
                      ),
                      child: companyProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text('Kaydet', style: AppConstants.buttonStyle),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
} 
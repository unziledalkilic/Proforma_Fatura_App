import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/company_logo_avatar.dart';
import '../constants/app_constants.dart';
import '../providers/hybrid_provider.dart';
import '../models/company_info.dart';
import '../utils/text_formatter.dart';

class CompanyManagementScreen extends StatefulWidget {
  const CompanyManagementScreen({super.key});

  @override
  State<CompanyManagementScreen> createState() =>
      _CompanyManagementScreenState();
}

class _CompanyManagementScreenState extends State<CompanyManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Şirket listesini yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HybridProvider>().loadCompanyProfiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Şirket Yönetimi'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: AppConstants.textOnPrimary,
      ),
      body: Consumer<HybridProvider>(
        builder: (context, provider, _) {
          final companies = provider.companies;
          final isLoading = provider.isLoading;

          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppConstants.primaryColor,
                      AppConstants.primaryLight,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.business_center,
                      size: 48,
                      color: AppConstants.textOnPrimary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Şirketlerinizi Yönetin',
                      style: AppConstants.headingStyle.copyWith(
                        color: AppConstants.textOnPrimary,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      '${companies.length} kayıtlı şirket',
                      style: AppConstants.captionStyle.copyWith(
                        color: AppConstants.textOnPrimary.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),

              // Company List
              Expanded(
                child: companies.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.business_outlined,
                              size: 64,
                              color: AppConstants.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Henüz şirket kaydınız yok',
                              style: AppConstants.bodyStyle.copyWith(
                                color: AppConstants.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'İlk şirketinizi eklemek için + butonuna tıklayın',
                              style: AppConstants.captionStyle.copyWith(
                                color: AppConstants.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: companies.length,
                        itemBuilder: (context, index) {
                          final company = companies[index];
                          final isSelected =
                              provider.selectedCompany?.id == company.id;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: isSelected ? 4 : 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: isSelected
                                  ? BorderSide(
                                      color: AppConstants.primaryColor,
                                      width: 2,
                                    )
                                  : BorderSide.none,
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CompanyLogoAvatar(
                                logoPathOrUrl: company.logo,
                                size: 48,
                                circular: true,
                                backgroundColor: AppConstants.primaryLight,
                                fallbackIcon: Icons.business,
                                fallbackIconColor: AppConstants.primaryColor,
                              ),
                              title: Text(
                                company.name,
                                style: AppConstants.bodyStyle.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? AppConstants.primaryColor
                                      : null,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (company.address?.isNotEmpty == true) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      company.address!,
                                      style: AppConstants.captionStyle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  if (company.phone?.isNotEmpty == true) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      company.phone!,
                                      style: AppConstants.captionStyle,
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppConstants.primaryColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Seçili',
                                        style: AppConstants.captionStyle
                                            .copyWith(
                                              color: AppConstants.textOnPrimary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  PopupMenuButton<String>(
                                    onSelected: (value) =>
                                        _handleMenuAction(value, company),
                                    itemBuilder: (context) => [
                                      if (!isSelected)
                                        PopupMenuItem(
                                          value: 'select',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                size: 16,
                                                color:
                                                    AppConstants.successColor,
                                              ),
                                              const SizedBox(width: 8),
                                              const Text('Seç'),
                                            ],
                                          ),
                                        ),
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.edit,
                                              size: 16,
                                              color: AppConstants.textSecondary,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text('Düzenle'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete,
                                              size: 16,
                                              color: AppConstants.errorColor,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Sil',
                                              style: TextStyle(
                                                color: AppConstants.errorColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              onTap: () {
                                provider.selectCompany(company);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddCompanyScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Yeni Şirket'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: AppConstants.textOnPrimary,
      ),
    );
  }

  void _handleMenuAction(String action, CompanyInfo company) async {
    final provider = context.read<HybridProvider>();

    switch (action) {
      case 'select':
        provider.selectCompany(company);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${company.name} seçildi'),
            backgroundColor: AppConstants.successColor,
          ),
        );
        break;

      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditCompanyScreen(company: company),
          ),
        );
        break;

      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Şirketi Sil'),
            content: Text(
              '${company.name} şirketini silmek istediğinizden emin misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.errorColor,
                ),
                child: const Text('Sil'),
              ),
            ],
          ),
        );

        if (confirmed == true && company.firebaseId != null) {
          final success = await provider.deleteCompanyProfile(
            company.firebaseId!,
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? '${company.name} silindi'
                      : 'Silme işlemi başarısız',
                ),
                backgroundColor: success
                    ? AppConstants.successColor
                    : AppConstants.errorColor,
              ),
            );
          }
          // Silme sonrası listeyi yenile
          if (success) {
            provider.selectCompany(
              provider.companies.isNotEmpty ? provider.companies.first : null,
            );
          }
        }
        break;
    }
  }
}

// Şirket Ekleme Ekranı
class AddCompanyScreen extends StatefulWidget {
  const AddCompanyScreen({super.key});

  @override
  State<AddCompanyScreen> createState() => _AddCompanyScreenState();
}

class _AddCompanyScreenState extends State<AddCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _taxController = TextEditingController();

  File? _selectedLogo;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Şirket Ekle'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: AppConstants.textOnPrimary,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo Section
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _selectedLogo != null
                          ? FileImage(_selectedLogo!)
                          : null,
                      backgroundColor: AppConstants.primaryLight,
                      child: _selectedLogo == null
                          ? Icon(
                              Icons.business,
                              size: 40,
                              color: AppConstants.primaryColor,
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _pickLogoSheet,
                      icon: const Icon(Icons.upload),
                      label: const Text('Logo Seç'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Company Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Şirket Adı *',
                  hintText: 'Şirket adını girin',
                  prefixIcon: Icon(Icons.business),
                ),
                textCapitalization: TextCapitalization.words,
                inputFormatters: [CapitalizeWordsFormatter()],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Şirket adı zorunludur';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adres',
                  hintText: 'Şirket adresini girin',
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.words,
                inputFormatters: [CapitalizeWordsFormatter()],
              ),
              const SizedBox(height: 16),

              // Phone
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefon',
                  hintText: '0555 123 45 67',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [PhoneNumberFormatter()],
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  hintText: 'info@sirket.com',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Geçerli bir e-posta adresi girin';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tax Number
              TextFormField(
                controller: _taxController,
                decoration: const InputDecoration(
                  labelText: 'Vergi Numarası',
                  hintText: 'Vergi numarasını girin',
                  prefixIcon: Icon(Icons.receipt_long),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveCompany,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: AppConstants.textOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Şirketi Kaydet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickLogo() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedLogo = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logo seçilirken hata oluştu: $e'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  // Duplicated block removed

  Future<void> _pickLogoFromDownloads() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Logoyu Seç (Downloads)',
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedLogo = File(result.files.single.path!);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dosya seçilemedi: $e'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  void _pickLogoSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeriden Seç'),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickLogo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Dosyadan Seç (Downloads)'),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickLogoFromDownloads();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Persist selected logo into app documents directory for stable path
  Future<String> _persistLogoFile(File source) async {
    final dir = await getApplicationDocumentsDirectory();
    final logosDir = Directory('${dir.path}/logos');
    if (!await logosDir.exists()) {
      await logosDir.create(recursive: true);
    }
    final ext = source.path.split('.').last;
    final targetPath =
        '${logosDir.path}/logo_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final copied = await source.copy(targetPath);
    return copied.path;
  }

  // Removed duplicate _pickLogoSheetEdit from AddCompanyScreen state

  Future<void> _saveCompany() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = context.read<HybridProvider>();

      // Logo depolama stratejisi (Firebase Storage yoksa):
      // Seçilen dosyanın yerel yolunu kaydediyoruz. Production'da Storage eklenince URL'e geçilebilir.
      String? logoUrl;
      if (_selectedLogo != null) {
        logoUrl = await _persistLogoFile(_selectedLogo!);
      }

      // Create company
      final company = CompanyInfo(
        id: 0,
        userId: provider.currentUser?.uid,
        name: _nameController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        taxNumber: _taxController.text.trim().isEmpty
            ? null
            : _taxController.text.trim(),
        logo: logoUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await provider.addCompanyProfile(company);

      if (context.mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Şirket başarıyla eklendi'),
              backgroundColor: AppConstants.successColor,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.error ?? 'Şirket eklenemedi'),
              backgroundColor: AppConstants.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (context.mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

// Şirket Düzenleme Ekranı
class EditCompanyScreen extends StatefulWidget {
  final CompanyInfo company;

  const EditCompanyScreen({super.key, required this.company});

  @override
  State<EditCompanyScreen> createState() => _EditCompanyScreenState();
}

class _EditCompanyScreenState extends State<EditCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _taxController;

  File? _selectedLogo;
  bool _isLoading = false;

  Future<String> _persistLogoFile(File source) async {
    final dir = await getApplicationDocumentsDirectory();
    final logosDir = Directory('${dir.path}/logos');
    if (!await logosDir.exists()) {
      await logosDir.create(recursive: true);
    }
    final ext = source.path.split('.').last;
    final targetPath =
        '${logosDir.path}/logo_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final copied = await source.copy(targetPath);
    return copied.path;
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.company.name);
    _addressController = TextEditingController(
      text: widget.company.address ?? '',
    );
    _phoneController = TextEditingController(text: widget.company.phone ?? '');
    _emailController = TextEditingController(text: widget.company.email ?? '');
    _taxController = TextEditingController(
      text: widget.company.taxNumber ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Şirketi Düzenle'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: AppConstants.textOnPrimary,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo Section
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _selectedLogo != null
                          ? FileImage(_selectedLogo!)
                          : (widget.company.logo != null &&
                                    widget.company.logo!.isNotEmpty
                                ? (widget.company.logo!.startsWith('http')
                                      ? NetworkImage(widget.company.logo!)
                                      : FileImage(File(widget.company.logo!))
                                            as ImageProvider)
                                : null),
                      backgroundColor: AppConstants.primaryLight,
                      child:
                          (_selectedLogo == null &&
                              (widget.company.logo == null ||
                                  widget.company.logo!.isEmpty))
                          ? Icon(
                              Icons.business,
                              size: 40,
                              color: AppConstants.primaryColor,
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _pickLogo,
                      icon: const Icon(Icons.upload),
                      label: const Text('Logo Değiştir'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Company Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Şirket Adı *',
                  hintText: 'Şirket adını girin',
                  prefixIcon: Icon(Icons.business),
                ),
                textCapitalization: TextCapitalization.words,
                inputFormatters: [CapitalizeWordsFormatter()],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Şirket adı zorunludur';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adres',
                  hintText: 'Şirket adresini girin',
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.words,
                inputFormatters: [CapitalizeWordsFormatter()],
              ),
              const SizedBox(height: 16),

              // Phone
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefon',
                  hintText: '0555 123 45 67',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [PhoneNumberFormatter()],
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  hintText: 'info@sirket.com',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Geçerli bir e-posta adresi girin';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tax Number
              TextFormField(
                controller: _taxController,
                decoration: const InputDecoration(
                  labelText: 'Vergi Numarası',
                  hintText: 'Vergi numarasını girin',
                  prefixIcon: Icon(Icons.receipt_long),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _updateCompany,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: AppConstants.textOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Değişiklikleri Kaydet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickLogo() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedLogo = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logo seçilirken hata oluştu: $e'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  Future<void> _updateCompany() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = context.read<HybridProvider>();

      // Logo depolama stratejisi (Firebase Storage yoksa)
      String? logoUrl = widget.company.logo;
      if (_selectedLogo != null) {
        logoUrl = await _persistLogoFile(_selectedLogo!);
      }

      // Update company
      final updatedCompany = widget.company.copyWith(
        name: _nameController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        taxNumber: _taxController.text.trim().isEmpty
            ? null
            : _taxController.text.trim(),
        logo: logoUrl,
        updatedAt: DateTime.now(),
      );

      final success = await provider.updateCompanyProfile(updatedCompany);

      if (context.mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Şirket başarıyla güncellendi'),
              backgroundColor: AppConstants.successColor,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.error ?? 'Şirket güncellenemedi'),
              backgroundColor: AppConstants.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (context.mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

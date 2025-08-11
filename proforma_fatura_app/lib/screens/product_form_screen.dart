import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../models/product.dart';
import '../providers/hybrid_provider.dart';
import '../utils/text_formatter.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product; // null ise yeni ürün, dolu ise düzenleme

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _unitController = TextEditingController();
  final _barcodeController = TextEditingController();

  bool _isLoading = false;

  // Önceden tanımlanmış birimler
  final List<String> _predefinedUnits = [
    'Adet',
    'Kg',
    'Litre',
    'Metre',
    'Metre²',
    'Metre³',
    'Paket',
    'Kutu',
    'Çift',
    'Takım',
    'Set',
    'Düzine',
    'Gros',
  ];

  // Önceden tanımlanmış para birimleri
  final List<String> _predefinedCurrencies = ['TRY', 'USD', 'EUR', 'GBP'];

  String _selectedCurrency = 'TRY';
  String? _selectedCategory;
  String? _selectedCompanyId;

  // Para birimi sembolü getir
  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'TRY':
        return '₺';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return currency;
    }
  }

  @override
  void initState() {
    super.initState();

    // Aktif şirketi otomatik seç
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hybridProvider = context.read<HybridProvider>();
      if (hybridProvider.selectedCompany != null) {
        setState(() {
          _selectedCompanyId = hybridProvider.selectedCompany!.firebaseId;
        });
        debugPrint(
          '🏢 Auto-selected company: ${hybridProvider.selectedCompany!.name} (ID: ${hybridProvider.selectedCompany!.firebaseId})',
        );
      } else {
        debugPrint('⚠️ No company selected - product form may fail');
      }
    });

    // Form verilerini yükle
    if (widget.product != null) {
      // Düzenleme modu - mevcut verileri yükle
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description ?? '';
      _priceController.text = widget.product!.price.toString();
      _selectedCurrency = widget.product!.currency;
      _unitController.text = widget.product!.unit;
      _barcodeController.text = widget.product!.barcode ?? '';
      _selectedCompanyId = widget.product!.companyId;
    } else {
      // Yeni ürün - varsayılan değerler
      _unitController.text = 'Adet';
    }

    // Kategorileri yükle ve kategori seçimini yap
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        try {
          debugPrint('🔄 Kategoriler yükleniyor...');
          await context.read<HybridProvider>().loadCategories();

          if (mounted) {
            setState(() {
              final categories = context.read<HybridProvider>().categories;
              debugPrint('✅ ${categories.length} kategori yüklendi');

              if (widget.product != null) {
                // Düzenleme modu - mevcut ürünün kategorisini bul ve seç
                if (widget.product!.category != null) {
                  _selectedCategory = widget.product!.category;
                  debugPrint(
                    '📝 Düzenleme modu: Kategori seçildi: $_selectedCategory',
                  );
                }
              } else {
                // Yeni ürün için varsayılan kategori seç (ilk kategori)
                if (categories.isNotEmpty) {
                  _selectedCategory = categories.first;
                  debugPrint(
                    '🆕 Yeni ürün: Varsayılan kategori seçildi: $_selectedCategory',
                  );
                } else {
                  debugPrint('⚠️ Hiç kategori bulunamadı!');
                }
              }
            });
          }
        } catch (e) {
          debugPrint('❌ initState kategori yükleme hatası: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    // Kategori validasyonu
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir kategori seçin'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final price = double.tryParse(_priceController.text) ?? 0.0;

      // Mevcut kullanıcının ID'sini al
      final currentUser = context.read<HybridProvider>().currentUser;
      if (currentUser?.uid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kullanıcı bilgisi bulunamadı'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
        return;
      }

      // Debug: Şirket ID'si kontrolü
      if (_selectedCompanyId == null) {
        debugPrint('❌ HATA: Şirket ID null! Ürün kaydedilemeyecek.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şirket seçimi yapılmadı. Lütfen bir şirket seçin.'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final product = Product(
        id: widget.product?.id,
        userId: currentUser!.uid,
        companyId: _selectedCompanyId,
        name: _nameController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        price: price,
        currency: _selectedCurrency,
        unit: _unitController.text,
        barcode: _barcodeController.text.isEmpty
            ? null
            : _barcodeController.text,
        category: _selectedCategory,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      debugPrint(
        '💾 Saving product: ${product.name} for company: $_selectedCompanyId',
      );

      if (!mounted) return;

      final hybridProvider = context.read<HybridProvider>();
      bool success;

      if (widget.product == null) {
        // Yeni ürün ekle
        success = await hybridProvider.addProduct(product);
      } else {
        // Mevcut ürünü güncelle
        success = await hybridProvider.updateProduct(product);
      }

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.product == null
                  ? 'Ürün başarıyla eklendi'
                  : 'Ürün başarıyla güncellendi',
            ),
            backgroundColor: AppConstants.successColor,
          ),
        );
        Navigator.of(
          context,
        ).pop(true); // true döndürerek başarılı olduğunu belirt
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hybridProvider.error ?? 'Bir hata oluştu'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Ürün Düzenle' : 'Yeni Ürün'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: AppConstants.textOnPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Başlık
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  isEditing ? Icons.edit : Icons.add_box,
                  size: 40,
                  color: AppConstants.primaryColor,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                isEditing ? 'Ürün Bilgilerini Düzenleyin' : 'Yeni Ürün Ekle',
                style: AppConstants.headingStyle.copyWith(
                  color: AppConstants.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Text(
                isEditing
                    ? 'Ürün bilgilerini güncelleyin'
                    : 'Ürün bilgilerini girerek yeni ürün ekleyin',
                style: AppConstants.bodyStyle.copyWith(
                  color: AppConstants.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Ürün Adı
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ürün Adı *',
                  hintText: 'Ürün adını girin',
                  prefixIcon: Icon(Icons.inventory),
                ),
                textCapitalization: TextCapitalization.words,
                inputFormatters: [CapitalizeWordsFormatter()],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ürün adı gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              Consumer<HybridProvider>(
                builder: (context, provider, _) {
                  final companies = provider.companies;
                  return DropdownButtonFormField<String>(
                    value: _selectedCompanyId,
                    decoration: const InputDecoration(
                      labelText: 'Şirket *',
                      hintText: 'Bu ürün hangi şirket için?',
                      prefixIcon: Icon(Icons.business),
                    ),
                    items: companies
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.firebaseId,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedCompanyId = val),
                    validator: (val) => (val == null || val.isEmpty)
                        ? 'Şirket seçimi gerekli'
                        : null,
                  );
                },
              ),
              const SizedBox(height: 20),

              // Açıklama
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  hintText: 'Ürün açıklaması (opsiyonel)',
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                textCapitalization: TextCapitalization.sentences,
                inputFormatters: [CapitalizeFirstFormatter()],
              ),
              const SizedBox(height: 20),

              // Fiyat ve Para Birimi
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Fiyat *',
                        hintText: '0.00',
                        prefixIcon: Container(
                          width: 48,
                          alignment: Alignment.center,
                          child: Text(
                            _getCurrencySymbol(_selectedCurrency),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Fiyat gerekli';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price < 0) {
                          return 'Geçerli bir fiyat girin';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppConstants.borderColor),
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                      ),
                      child: PopupMenuButton<String>(
                        initialValue: _selectedCurrency,
                        onSelected: (value) {
                          setState(() {
                            _selectedCurrency = value;
                            // Fiyat kutusundaki para birimi simgesi de otomatik güncellenecek
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedCurrency,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_drop_down, size: 20),
                            ],
                          ),
                        ),
                        itemBuilder: (context) => [
                          ..._predefinedCurrencies.map(
                            (currency) => PopupMenuItem(
                              value: currency,
                              child: Row(
                                children: [
                                  Text(_getCurrencySymbol(currency)),
                                  const SizedBox(width: 8),
                                  Text(currency),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Birim
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      decoration: InputDecoration(
                        labelText: 'Birim *',
                        hintText: 'Adet, kg, lt, m² vb.',
                        prefixIcon: const Icon(Icons.straighten),
                        suffixIcon: PopupMenuButton<String>(
                          icon: const Icon(Icons.arrow_drop_down),
                          onSelected: (value) {
                            setState(() {
                              _unitController.text = value;
                            });
                          },
                          itemBuilder: (context) => [
                            ..._predefinedUnits.map(
                              (unit) =>
                                  PopupMenuItem(value: unit, child: Text(unit)),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'custom',
                              child: const Text('Özel Birim'),
                            ),
                          ],
                        ),
                      ),
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: [CapitalizeWordsFormatter()],
                      onChanged: (value) {
                        // Unit değiştiğinde herhangi bir işlem yapmaya gerek yok
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Birim gerekli';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Kategori
              Consumer<HybridProvider>(
                builder: (context, hybridProvider, child) {
                  final categories = hybridProvider.categories;

                  // Debug mesajı
                  debugPrint(
                    '🔍 ProductFormScreen - Kategori sayısı: ${categories.length}',
                  );
                  if (categories.isNotEmpty) {
                    debugPrint(
                      '📋 Mevcut kategoriler: ${categories.join(', ')}',
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kategori *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppConstants.borderColor,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppConstants.borderRadius,
                                ),
                              ),
                              child: PopupMenuButton<String?>(
                                enabled: categories.isNotEmpty,
                                initialValue: _selectedCategory,
                                onSelected: (category) {
                                  if (!mounted) return;
                                  setState(() {
                                    _selectedCategory = category;
                                  });
                                  debugPrint('🎯 Kategori seçildi: $category');
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_selectedCategory != null) ...[
                                        Expanded(
                                          child: Text(
                                            _selectedCategory!,
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ] else
                                        Text(
                                          'Kategori Seçin',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: AppConstants.textSecondary,
                                          ),
                                        ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.arrow_drop_down,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                                itemBuilder: (context) => [
                                  if (categories.isEmpty)
                                    const PopupMenuItem(
                                      enabled: false,
                                      child: Text('Kategori bulunamadı'),
                                    )
                                  else
                                    ...categories.map(
                                      (category) => PopupMenuItem(
                                        value: category,
                                        child: Text(category),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // Barkod
              TextFormField(
                controller: _barcodeController,
                decoration: const InputDecoration(
                  labelText: 'Barkod',
                  hintText: 'Barkod numarası (opsiyonel)',
                  prefixIcon: Icon(Icons.qr_code),
                ),
              ),
              const SizedBox(height: 32),

              // Kaydet butonu
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: AppConstants.textOnPrimary,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppConstants.paddingMedium,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppConstants.textOnPrimary,
                          ),
                        ),
                      )
                    : Text(
                        isEditing ? 'Güncelle' : 'Kaydet',
                        style: AppConstants.buttonStyle,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

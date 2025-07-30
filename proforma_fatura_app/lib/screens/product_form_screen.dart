import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../models/product.dart';
import '../models/product_category.dart';
import '../providers/product_provider.dart';
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
  bool _isCustomUnit = false;
  final bool _isCustomPrice = false;

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
  ProductCategory? _selectedCategory;
  bool _isCustomCategory = false;
  final _customCategoryController = TextEditingController();

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
    // Kategorileri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          context.read<ProductProvider>().loadCategories();
        } catch (e) {
          print('❌ initState kategori yükleme hatası: $e');
        }
      }
    });

    if (widget.product != null) {
      // Düzenleme modu - mevcut verileri yükle
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description ?? '';
      _priceController.text = widget.product!.price.toString();
      _selectedCurrency = widget.product!.currency;
      _unitController.text = widget.product!.unit;
      _barcodeController.text = widget.product!.barcode ?? '';
      _selectedCategory = widget.product!.category;
    } else {
      // Yeni ürün - varsayılan değerler
      _unitController.text = 'Adet';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    _barcodeController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final price = double.tryParse(_priceController.text) ?? 0.0;

      // Kategori işlemi
      ProductCategory? finalCategory = _selectedCategory;
      if (_isCustomCategory &&
          _customCategoryController.text.isNotEmpty &&
          mounted) {
        try {
          // Yeni kategori oluştur
          final newCategory = ProductCategory(
            name: TextFormatter.capitalizeWords(_customCategoryController.text),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          if (!mounted) return;

          final success = await context.read<ProductProvider>().addCategory(
            newCategory,
          );
          if (success && mounted) {
            // Kategorileri yeniden yükle ve yeni kategoriyi bul
            await context.read<ProductProvider>().loadCategories();
            if (mounted) {
              final categories = context.read<ProductProvider>().categories;
              finalCategory = categories.firstWhere(
                (cat) => cat.name == newCategory.name,
                orElse: () => newCategory,
              );
            }
          }
        } catch (e) {
          print('❌ Kategori ekleme hatası: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Kategori eklenirken hata oluştu: $e'),
                backgroundColor: AppConstants.errorColor,
              ),
            );
          }
        }
      }

      final product = Product(
        id: widget.product?.id ?? 0,
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
        category: finalCategory,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (!mounted) return;

      final productProvider = context.read<ProductProvider>();
      bool success;

      if (widget.product == null) {
        // Yeni ürün ekle
        success = await productProvider.addProduct(product);
      } else {
        // Mevcut ürünü güncelle
        success = await productProvider.updateProduct(product);
      }

      if (success && mounted) {
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
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(productProvider.error ?? 'Bir hata oluştu'),
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
        foregroundColor: Colors.white,
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ürün adı gerekli';
                  }
                  return null;
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
                        prefixIcon: const Icon(Icons.attach_money),
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
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: PopupMenuButton<String>(
                        initialValue: _selectedCurrency,
                        onSelected: (value) {
                          setState(() {
                            _selectedCurrency = value;
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
                              _isCustomUnit = false;
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
                      onChanged: (value) {
                        setState(() {
                          _isCustomUnit = !_predefinedUnits.contains(value);
                        });
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
              Consumer<ProductProvider>(
                builder: (context, productProvider, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kategori',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: PopupMenuButton<ProductCategory?>(
                                initialValue: _selectedCategory,
                                onSelected: (category) {
                                  if (!mounted) return;

                                  setState(() {
                                    if (category?.id == -1) {
                                      // Yeni kategori ekle seçildi
                                      _isCustomCategory = true;
                                      _selectedCategory = null;
                                      _customCategoryController.clear();
                                    } else {
                                      _selectedCategory = category;
                                      _isCustomCategory = false;
                                    }
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
                                      if (_selectedCategory != null) ...[
                                        Container(
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: Color(
                                              int.parse(
                                                _selectedCategory!.color
                                                    .replaceAll('#', '0xFF'),
                                              ),
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _selectedCategory!.name,
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
                                            color: Colors.grey[600],
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
                                  ...productProvider.categories.map(
                                    (category) => PopupMenuItem(
                                      value: category,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 16,
                                            height: 16,
                                            decoration: BoxDecoration(
                                              color: Color(
                                                int.parse(
                                                  category.color.replaceAll(
                                                    '#',
                                                    '0xFF',
                                                  ),
                                                ),
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(category.name),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const PopupMenuDivider(),
                                  PopupMenuItem(
                                    value: null,
                                    child: const Text('Kategori Yok'),
                                  ),
                                  const PopupMenuDivider(),
                                  PopupMenuItem(
                                    value: ProductCategory(
                                      id: -1,
                                      name: 'custom',
                                      createdAt: DateTime.now(),
                                      updatedAt: DateTime.now(),
                                    ),
                                    child: const Text('Yeni Kategori Ekle'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_isCustomCategory) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _customCategoryController,
                          decoration: const InputDecoration(
                            labelText: 'Yeni Kategori Adı',
                            hintText: 'Kategori adını girin',
                            prefixIcon: Icon(Icons.category),
                          ),
                          validator: (value) {
                            if (_isCustomCategory &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Kategori adı gerekli';
                            }
                            return null;
                          },
                        ),
                      ],
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
                child: _isLoading
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

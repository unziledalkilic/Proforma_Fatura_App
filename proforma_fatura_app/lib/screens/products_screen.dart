import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../models/product_category.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import 'product_form_screen.dart';

class ProductsScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const ProductsScreen({super.key, this.onBackToHome});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredProducts = [];
  ProductCategory? _selectedCategoryFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    try {
      final productProvider = context.read<ProductProvider>();
      await productProvider.loadProducts();
      if (mounted) {
        await productProvider.loadCategories();
      }
    } catch (e) {
      // Error handling for initState
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterProducts(String query) {
    if (!mounted) return;

    try {
      // BuildContext'i güvenli şekilde kullan
      final productProvider = context.read<ProductProvider>();

      final allProducts = productProvider.products;
      List<Product> filtered = List.from(allProducts); // Yeni liste oluştur

      // Kategori filtresi
      if (_selectedCategoryFilter != null) {
        filtered = filtered
            .where(
              (product) => product.category?.id == _selectedCategoryFilter!.id,
            )
            .toList();
      }

      // Arama filtresi
      if (query.isNotEmpty) {
        filtered = filtered.where((product) {
          return product.name.toLowerCase().contains(query.toLowerCase()) ||
              (product.description?.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ??
                  false) ||
              (product.barcode?.contains(query) ?? false);
        }).toList();
      }

      if (mounted) {
        setState(() {
          _filteredProducts = filtered;
        });
      }
    } catch (e) {
      // Error handling for _filterProducts
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.productsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Ana sayfaya (Dashboard) dön
            widget.onBackToHome?.call();
          },
        ),
      ),
      body: Column(
        children: [
          // Arama çubuğu
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Ürün ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          if (mounted) {
                            _filterProducts('');
                          }
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                if (mounted) {
                  _filterProducts(value);
                }
              },
            ),
          ),

          // Kategori filtresi
          Consumer<ProductProvider>(
            builder: (context, productProvider, child) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMedium,
                ),
                child: Row(
                  children: [
                    const Text(
                      'Kategori: ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: PopupMenuButton<ProductCategory?>(
                          initialValue: _selectedCategoryFilter,
                          onSelected: (category) {
                            if (!mounted) return;

                            setState(() {
                              _selectedCategoryFilter = category;
                            });

                            // Filtrelemeyi güvenli şekilde uygula
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                _filterProducts(_searchController.text);
                              }
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_selectedCategoryFilter != null) ...[
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Color(
                                        int.parse(
                                          _selectedCategoryFilter!.color
                                              .replaceAll('#', '0xFF'),
                                        ),
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _selectedCategoryFilter!.name,
                                      style: const TextStyle(fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ] else
                                  Text(
                                    'Tümü',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_drop_down, size: 16),
                              ],
                            ),
                          ),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: null,
                              child: const Text('Tümü'),
                            ),
                            const PopupMenuDivider(),
                            ...productProvider.categories.map(
                              (category) => PopupMenuItem(
                                value: category,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
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
                                    const SizedBox(width: 6),
                                    Text(category.name),
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
              );
            },
          ),

          // Filtreleme temizleme butonu
          if (_selectedCategoryFilter != null ||
              _searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMedium,
                vertical: AppConstants.paddingSmall,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedCategoryFilter = null;
                          _searchController.clear();
                        });
                        if (mounted) {
                          _filterProducts('');
                        }
                      },
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Filtreleri Temizle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Ürün listesi
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                if (productProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (productProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppConstants.errorColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          productProvider.error!,
                          style: AppConstants.bodyStyle,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            productProvider.loadProducts();
                          },
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  );
                }

                // Filtreleme durumuna göre ürünleri belirle
                final products =
                    (_searchController.text.isNotEmpty ||
                        _selectedCategoryFilter != null)
                    ? _filteredProducts
                    : productProvider.products;

                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty &&
                                  _selectedCategoryFilter == null
                              ? 'Henüz ürün bulunmuyor'
                              : 'Arama sonucu bulunamadı',
                          style: AppConstants.bodyStyle,
                        ),
                        if (_searchController.text.isEmpty &&
                            _selectedCategoryFilter == null) ...[
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () async {
                              final navigatorContext = context;
                              final result =
                                  await Navigator.of(navigatorContext).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ProductFormScreen(),
                                    ),
                                  );
                              if (result == true && mounted) {
                                final productProvider = navigatorContext
                                    .read<ProductProvider>();
                                await productProvider.loadProducts();
                                _filterProducts(_searchController.text);
                              }
                            },
                            child: const Text('İlk Ürünü Ekle'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await productProvider.loadProducts();
                    _filterProducts(_searchController.text);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Card(
                        margin: const EdgeInsets.only(
                          bottom: AppConstants.paddingSmall,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: product.category?.color != null
                                ? Color(
                                    int.parse(
                                      product.category!.color.replaceAll(
                                        '#',
                                        '0xFF',
                                      ),
                                    ),
                                  )
                                : Colors.grey,
                            child: Text(
                              product.name.isNotEmpty
                                  ? product.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            product.name,
                            style: AppConstants.bodyStyle.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (product.description?.isNotEmpty == true)
                                Text(
                                  product.description!,
                                  style: AppConstants.captionStyle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '${product.price.toStringAsFixed(2)} ${product.currency}',
                                    style: AppConstants.bodyStyle.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: AppConstants.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '/ ${product.unit}',
                                    style: AppConstants.captionStyle,
                                  ),
                                ],
                              ),
                              if (product.category != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Color(
                                          int.parse(
                                            product.category!.color.replaceAll(
                                              '#',
                                              '0xFF',
                                            ),
                                          ),
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      product.category!.name,
                                      style: AppConstants.captionStyle.copyWith(
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (!mounted) return;

                              switch (value) {
                                case 'edit':
                                  final navigatorContext = context;

                                  // Kategorilerin yüklendiğinden emin ol
                                  final productProvider = navigatorContext
                                      .read<ProductProvider>();
                                  if (productProvider.categories.isEmpty) {
                                    print(
                                      '🔄 Düzenleme için kategoriler yükleniyor...',
                                    );
                                    await productProvider.loadCategories();
                                    print(
                                      '✅ ${productProvider.categories.length} kategori yüklendi',
                                    );
                                  }

                                  final result =
                                      await Navigator.of(navigatorContext).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ProductFormScreen(
                                                product: product,
                                              ),
                                        ),
                                      );
                                  if (result == true && mounted) {
                                    await productProvider.loadProducts();
                                    _filterProducts(_searchController.text);
                                  }
                                  break;
                                case 'delete':
                                  _showDeleteDialog(product);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 16),
                                    SizedBox(width: 8),
                                    Text('Düzenle'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      size: 16,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Sil',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final navigatorContext = context;

          // Kategorilerin yüklendiğinden emin ol
          final productProvider = navigatorContext.read<ProductProvider>();
          if (productProvider.categories.isEmpty) {
            print('🔄 Kategoriler yükleniyor...');
            await productProvider.loadCategories();
            print('✅ ${productProvider.categories.length} kategori yüklendi');
          }

          final result = await Navigator.of(navigatorContext).push(
            MaterialPageRoute(builder: (context) => const ProductFormScreen()),
          );
          // Eğer ürün eklendi/güncellendi ise listeyi yeniden yükle
          if (result == true && mounted) {
            await productProvider.loadProducts();
            // Filtrelemeyi yeniden uygula
            _filterProducts(_searchController.text);
          }
        },
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showDeleteDialog(Product product) {
    final dialogContext = context;
    showDialog(
      context: dialogContext,
      builder: (context) => AlertDialog(
        title: const Text('Ürünü Sil'),
        content: Text(
          '${product.name} ürününü silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              // ProductProvider'ı dialog kapatılmadan önce al
              final productProvider = dialogContext.read<ProductProvider>();
              Navigator.of(context).pop();
              if (mounted && product.id != null) {
                productProvider.deleteProduct(product.id!);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppConstants.errorColor,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

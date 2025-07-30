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
      if (mounted) {
        try {
          print('🔄 ProductsScreen: Ürünler yükleniyor...');
          context.read<ProductProvider>().loadProducts();
          context.read<ProductProvider>().loadCategories();
        } catch (e) {
          print('❌ initState Provider hatası: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterProducts(String query) {
    if (!mounted) return;

    try {
      setState(() {
        final productProvider = context.read<ProductProvider>();
        final allProducts = productProvider.products;
        List<Product> filtered = allProducts;

        // Kategori filtresi
        if (_selectedCategoryFilter != null) {
          filtered = filtered
              .where(
                (product) =>
                    product.category?.id == _selectedCategoryFilter!.id,
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

        _filteredProducts = filtered;
      });
    } catch (e) {
      print('❌ _filterProducts hatası: $e');
    }
  }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProductFormScreen(),
                ),
              );
              // Eğer ürün eklendi/güncellendi ise listeyi yeniden yükle
              if (result == true && mounted) {
                print(
                  '🔄 ProductsScreen: Ürün eklendi/güncellendi, liste yenileniyor...',
                );
                context.read<ProductProvider>().loadProducts();
              }
            },
          ),
        ],
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
                          _filterProducts('');
                        },
                      )
                    : null,
              ),
              onChanged: _filterProducts,
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
                              _filterProducts(_searchController.text);
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

                final products = _searchController.text.isEmpty
                    ? productProvider.products
                    : _filteredProducts;

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
                          _searchController.text.isEmpty
                              ? 'Henüz ürün bulunmuyor'
                              : 'Arama sonucu bulunamadı',
                          style: AppConstants.bodyStyle,
                        ),
                        if (_searchController.text.isEmpty) ...[
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () async {
                              final result = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ProductFormScreen(),
                                ),
                              );
                              // Eğer ürün eklendi/güncellendi ise listeyi yeniden yükle
                              if (result == true && mounted) {
                                print(
                                  '🔄 ProductsScreen: Ürün eklendi/güncellendi, liste yenileniyor...',
                                );
                                context.read<ProductProvider>().loadProducts();
                              }
                            },
                            child: const Text('İlk Ürünü Ekle'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
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
                          backgroundColor: product.category != null
                              ? Color(
                                  int.parse(
                                    product.category!.color.replaceAll(
                                      '#',
                                      '0xFF',
                                    ),
                                  ),
                                )
                              : AppConstants.successColor,
                          child: const Icon(
                            Icons.inventory,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (product.description != null)
                              Text(product.description!),
                            Text(
                              '${_getCurrencySymbol(product.currency)}${product.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                            Row(
                              children: [
                                Text('Birim: ${product.unit}'),
                                if (product.category != null) ...[
                                  const SizedBox(width: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Color(
                                        int.parse(
                                          product.category!.color.replaceAll(
                                            '#',
                                            '0xFF',
                                          ),
                                        ),
                                      ).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Color(
                                          int.parse(
                                            product.category!.color.replaceAll(
                                              '#',
                                              '0xFF',
                                            ),
                                          ),
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      product.category!.name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(
                                          int.parse(
                                            product.category!.color.replaceAll(
                                              '#',
                                              '0xFF',
                                            ),
                                          ),
                                        ),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (!mounted) return;

                            switch (value) {
                              case 'edit':
                                final result = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ProductFormScreen(product: product),
                                  ),
                                );
                                // Eğer ürün güncellendi ise listeyi yeniden yükle
                                if (result == true && mounted) {
                                  print(
                                    '🔄 ProductsScreen: Ürün güncellendi, liste yenileniyor...',
                                  );
                                  context
                                      .read<ProductProvider>()
                                      .loadProducts();
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
                                  Icon(Icons.edit),
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
                                    color: AppConstants.errorColor,
                                  ),
                                  SizedBox(width: 8),
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
                        onTap: () {
                          // Ürün detay sayfasına git
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const ProductFormScreen()),
          );
          // Eğer ürün eklendi/güncellendi ise listeyi yeniden yükle
          if (result == true && mounted) {
            print(
              '🔄 ProductsScreen: Ürün eklendi/güncellendi, liste yenileniyor...',
            );
            context.read<ProductProvider>().loadProducts();
          }
        },
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showDeleteDialog(Product product) {
    showDialog(
      context: context,
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
              final productProvider = context.read<ProductProvider>();
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

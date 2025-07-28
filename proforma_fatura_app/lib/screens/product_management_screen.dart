import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  List<Product> products = [];
  List<Product> filteredProducts = [];
  List<Category> categories = [];
  String selectedCategoryId = 'all';
  bool isLoading = false;
  bool isGridView = false;
  bool showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Paralel olarak ürünler ve kategorileri yükle
      final results = await Future.wait([
        ProductService.getProducts(),
        ProductService.getCategoriesWithCount(),
      ]);

      setState(() {
        products = results[0] as List<Product>;
        categories = [
          Category(
            id: 'all',
            userId: '',
            name: 'Tümü',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            productCount: products.length,
          ),
          ...(results[1] as List<Category>),
        ];
        filteredProducts = products;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veri yüklenirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterProducts() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredProducts = products.where((product) {
        bool matchesSearch = product.containsSearchTerm(query);
        bool matchesCategory = selectedCategoryId == 'all' ||
            product.categoryId == selectedCategoryId;
        bool matchesFavorite = !showFavoritesOnly || product.isFavorite;
        return matchesSearch && matchesCategory && matchesFavorite;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Ürün Yönetimi'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                isGridView = !isGridView;
              });
            },
            icon: Icon(isGridView ? Icons.list : Icons.grid_view),
          ),
          IconButton(
            onPressed: _showAddProductDialog,
            icon: const Icon(Icons.add),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: 'Ürünler'),
            Tab(text: 'Kategoriler'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryFilter(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProductsTab(),
                _buildCategoriesTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Ürün ara...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                  },
                  icon: const Icon(Icons.clear),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      color: Colors.white,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('Favoriler'),
              selected: showFavoritesOnly,
              onSelected: (selected) {
                setState(() {
                  showFavoritesOnly = selected;
                  if (showFavoritesOnly) {
                    selectedCategoryId = 'all';
                  }
                  _filterProducts();
                });
              },
              backgroundColor: Colors.grey[200],
              selectedColor: Colors.amber.withOpacity(0.2),
              checkmarkColor: Colors.amber,
              labelStyle: TextStyle(
                color: showFavoritesOnly ? Colors.amber[800] : Colors.grey[700],
                fontWeight:
                    showFavoritesOnly ? FontWeight.bold : FontWeight.normal,
              ),
              avatar: Icon(
                showFavoritesOnly ? Icons.star : Icons.star_border,
                color: showFavoritesOnly ? Colors.amber[800] : Colors.grey,
                size: 20,
              ),
            ),
          ),
          ...categories.map((category) {
            final isSelected =
                selectedCategoryId == category.id && !showFavoritesOnly;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text('${category.name} (${category.productCount ?? 0})'),
                selected: isSelected,
                onSelected: (selected) {
                  if (showFavoritesOnly) return;
                  setState(() {
                    selectedCategoryId = category.id;
                    _filterProducts();
                  });
                },
                backgroundColor: Colors.grey[200],
                selectedColor: Colors.orange.withOpacity(0.2),
                checkmarkColor: Colors.orange,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.orange : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredProducts.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isGridView ? _buildGridView() : _buildListView(),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return _buildProductGridCard(product);
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.inventory_2,
                color: Colors.orange,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _toggleFavorite(product),
                        icon: Icon(
                          product.isFavorite ? Icons.star : Icons.star_border,
                          color:
                              product.isFavorite ? Colors.amber : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.displayCategory,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.formattedPrice,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            '/ ${product.unit}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => _editProduct(product),
                            icon: const Icon(Icons.edit, color: Colors.blue),
                          ),
                          IconButton(
                            onPressed: () => _deleteProduct(product),
                            icon: const Icon(Icons.delete, color: Colors.red),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGridCard(Product product) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.inventory_2,
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
                IconButton(
                  onPressed: () => _toggleFavorite(product),
                  icon: Icon(
                    product.isFavorite ? Icons.star : Icons.star_border,
                    color: product.isFavorite ? Colors.amber : Colors.grey,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              product.displayCategory,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
            const Spacer(),
            Text(
              product.formattedPrice,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            Text(
              '/ ${product.unit}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                InkWell(
                  onTap: () => _editProduct(product),
                  child: const Icon(Icons.edit, color: Colors.blue, size: 20),
                ),
                InkWell(
                  onTap: () => _deleteProduct(product),
                  child: const Icon(Icons.delete, color: Colors.red, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.category, color: Colors.orange, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Kategoriler',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddCategoryDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Yeni Kategori'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                itemCount: categories.where((c) => c.id != 'all').length,
                itemBuilder: (context, index) {
                  final category =
                      categories.where((c) => c.id != 'all').toList()[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.category,
                          color: Colors.orange,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        category.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text('${category.productCount ?? 0} ürün'),
                      trailing: PopupMenuButton(
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
                                Icon(Icons.delete, color: Colors.red, size: 16),
                                SizedBox(width: 8),
                                Text('Sil',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editCategory(category);
                          } else if (value == 'delete') {
                            _deleteCategory(category);
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty
                ? 'Aradığınız kriterlere uygun ürün bulunamadı'
                : 'Henüz ürün eklenmemiş',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddProductDialog,
            icon: const Icon(Icons.add),
            label: const Text('İlk Ürünü Ekle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      currentIndex: 0, // Ana Sayfa seçili gibi göster (ama ürün yönetimindeyiz)
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/home');
            break;
          case 1:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Proformalar yakında!')),
            );
            break;
          case 2:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Müşteriler yakında!')),
            );
            break;
          case 3:
            _showProfile();
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Ana Sayfa',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.description_outlined),
          activeIcon: Icon(Icons.description),
          label: 'Proformalar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'Müşteriler',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    );
  }

  Future<void> _toggleFavorite(Product product) async {
    try {
      final updatedProduct = await ProductService.toggleFavorite(product);

      setState(() {
        // products listesindeki ürünü güncelle
        final index = products.indexWhere((p) => p.id == product.id);
        if (index != -1) {
          products[index] = updatedProduct;
        }

        // filteredProducts listesindeki ürünü güncelle
        final filteredIndex =
            filteredProducts.indexWhere((p) => p.id == product.id);
        if (filteredIndex != -1) {
          filteredProducts[filteredIndex] = updatedProduct;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(updatedProduct.isFavorite
              ? '${updatedProduct.name} favorilere eklendi!'
              : '${updatedProduct.name} favorilerden çıkarıldı!'),
          backgroundColor:
              updatedProduct.isFavorite ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Her kelimenin ilk harfini büyük yapan fonksiyon
  String toTitleCase(String input) {
    return input
        .split(' ')
        .map((str) => str.isNotEmpty
            ? str[0].toUpperCase() + str.substring(1).toLowerCase()
            : '')
        .join(' ');
  }

  void _showAddProductDialog({Product? product}) {
    final isEdit = product != null;
    final nameController = TextEditingController(text: product?.name ?? '');
    final priceController =
        TextEditingController(text: product?.price.toString() ?? '');
    final unitController = TextEditingController(text: product?.unit ?? 'Adet');
    const List<String> units = [
      'Adet',
      'Kg',
      'Litre',
      'Paket',
      'Koli',
      'Metre'
    ];
    String? selectedCategoryId = product?.categoryId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Ürünü Düzenle' : 'Yeni Ürün Ekle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Ürün Adı'),
              ),
              TextField(
                controller: priceController,
                decoration: InputDecoration(labelText: 'Fiyat'),
                keyboardType: TextInputType.number,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: unitController,
                      decoration: const InputDecoration(labelText: 'Birim'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.arrow_drop_down),
                    onSelected: (val) {
                      unitController.text = val;
                    },
                    itemBuilder: (context) => units
                        .map((unit) => PopupMenuItem(
                              value: unit,
                              child: Text(unit),
                            ))
                        .toList(),
                  ),
                ],
              ),
              DropdownButtonFormField<String>(
                value: selectedCategoryId,
                items: categories
                    .where((c) => c.id != 'all')
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        ))
                    .toList(),
                onChanged: (val) => selectedCategoryId = val,
                decoration: InputDecoration(labelText: 'Kategori'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text) ?? 0;
              final unit = unitController.text.trim();
              // Her kelimenin ilk harfini büyük yap
              String formattedName = toTitleCase(name);
              String formattedUnit = toTitleCase(unit);

              if (formattedName.isEmpty ||
                  price <= 0 ||
                  formattedUnit.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tüm alanları doldurun!')),
                );
                return;
              }

              try {
                if (isEdit) {
                  final updated = product!.copyWith(
                    name: formattedName,
                    price: price,
                    unit: formattedUnit,
                    categoryId: selectedCategoryId,
                  );
                  await ProductService.updateProduct(updated);
                } else {
                  final newProduct = Product(
                    id: '', // Supabase otomatik oluşturacak
                    userId: '', // Servis ekleyecek
                    name: formattedName,
                    price: price,
                    unit: formattedUnit,
                    categoryId: selectedCategoryId,
                    categoryName: null,
                    isFavorite: false,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  await ProductService.addProduct(newProduct);
                }
                Navigator.pop(context);
                _loadData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Hata: $e')),
                );
              }
            },
            child: Text(isEdit ? 'Kaydet' : 'Ekle'),
          ),
        ],
      ),
    );
  }

  // Kategori ekleme/düzenleme dialogu
  void _showCategoryDialog({Category? category}) {
    final isEdit = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    const List<String> defaultCategories = [
      'Gıda',
      'Temizlik',
      'Kırtasiye',
      'Elektronik',
      'Giyim',
      'Diğer'
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Kategoriyi Düzenle' : 'Yeni Kategori Ekle'),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Kategori Adı'),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: const Icon(Icons.arrow_drop_down),
              onSelected: (val) {
                nameController.text = val;
              },
              itemBuilder: (context) => defaultCategories
                  .map((cat) => PopupMenuItem(
                        value: cat,
                        child: Text(cat),
                      ))
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              String formattedName = toTitleCase(name);
              if (formattedName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kategori adı boş olamaz!')),
                );
                return;
              }
              try {
                if (isEdit) {
                  final updated = category!.copyWith(name: formattedName);
                  await ProductService.updateCategory(updated);
                } else {
                  final newCategory = Category(
                    id: '',
                    userId: '',
                    name: formattedName,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  await ProductService.addCategory(newCategory);
                }
                Navigator.pop(context);
                _loadData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Hata: $e')),
                );
              }
            },
            child: Text(isEdit ? 'Kaydet' : 'Ekle'),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    _showCategoryDialog();
  }

  void _editCategory(Category category) {
    _showCategoryDialog(category: category);
  }

  void _editProduct(Product product) {
    _showAddProductDialog(product: product);
  }

  Future<void> _deleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ürünü Sil'),
        content:
            Text('${product.name} ürünü silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ProductService.deleteProduct(product.id);

        setState(() {
          products.removeWhere((p) => p.id == product.id);
          filteredProducts.removeWhere((p) => p.id == product.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} silindi'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silme işlemi başarısız: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteCategory(Category category) async {
    // Kategori silme kontrolü
    final productCountInCategory =
        products.where((p) => p.categoryId == category.id).length;

    if (productCountInCategory > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Bu kategoride $productCountInCategory ürün var. Önce ürünleri başka kategoriye taşıyın veya silin.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kategoriyi Sil'),
        content: Text(
            '${category.name} kategorisini silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ProductService.deleteCategory(category.id);

        setState(() {
          categories.removeWhere((c) => c.id == category.id);
          if (selectedCategoryId == category.id) {
            selectedCategoryId = 'all';
            _filterProducts();
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${category.name} kategorisi silindi'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silme işlemi başarısız: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profil Bilgileri'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ad Soyad: Test Kullanıcı'),
            Text('Email: test@test.com'),
            Text('Şirket: Test Şirketi A.Ş.'),
            Text('Telefon: +90 555 123 45 67'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/customer_provider.dart';
import '../models/customer.dart';
import 'add_customer_screen.dart';

class CustomersScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const CustomersScreen({super.key, this.onBackToHome});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Customer> _filteredCustomers = [];
  String _selectedCategory = 'Tümü';
  final List<String> _categories = [
    'Tümü',
    'Son Eklenenler',
    'E-posta Var',
    'Telefon Var',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCustomers(String query) {
    final customerProvider = context.read<CustomerProvider>();
    setState(() {
      _filteredCustomers = customerProvider.searchCustomers(query);
    });
  }

  List<Customer> _getCategorizedCustomers(List<Customer> customers) {
    switch (_selectedCategory) {
      case 'Son Eklenenler':
        final sortedCustomers = List<Customer>.from(customers);
        sortedCustomers.sort(
          (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
            a.createdAt ?? DateTime.now(),
          ),
        );
        return sortedCustomers.take(10).toList();
      case 'E-posta Var':
        return customers
            .where((c) => c.email != null && c.email!.isNotEmpty)
            .toList();
      case 'Telefon Var':
        return customers
            .where((c) => c.phone != null && c.phone!.isNotEmpty)
            .toList();
      default:
        return customers;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Müşteriler'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            widget.onBackToHome?.call();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddCustomerScreen(),
                ),
              );
              if (result == true && mounted) {
                context.read<CustomerProvider>().loadCustomers();
              }
            },
          ),
        ],
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, customerProvider, child) {
          return Column(
            children: [
              // Arama çubuğu
              Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Müşteri ara...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterCustomers('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: _filterCustomers,
                ),
              ),

              // İstatistikler ve Kategori Filtreleri
              if (!customerProvider.isLoading &&
                  customerProvider.error == null) ...[
                // Hızlı İstatistikler
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingMedium,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Toplam',
                          customerProvider.customers.length.toString(),
                          Icons.people,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'E-posta',
                          customerProvider.customers
                              .where(
                                (c) => c.email != null && c.email!.isNotEmpty,
                              )
                              .length
                              .toString(),
                          Icons.email,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'Telefon',
                          customerProvider.customers
                              .where(
                                (c) => c.phone != null && c.phone!.isNotEmpty,
                              )
                              .length
                              .toString(),
                          Icons.phone,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Kategori Filtreleri
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingMedium,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          backgroundColor: Colors.grey[100],
                          selectedColor: AppConstants.primaryColor.withOpacity(
                            0.2,
                          ),
                          checkmarkColor: AppConstants.primaryColor,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Müşteri listesi
              Expanded(child: _buildCustomersList(customerProvider)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCustomersList(CustomerProvider customerProvider) {
    if (customerProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (customerProvider.error != null) {
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
              customerProvider.error!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                customerProvider.clearError();
                customerProvider.loadCustomers();
              },
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    List<Customer> customers;
    if (_searchController.text.isEmpty) {
      customers = _getCategorizedCustomers(customerProvider.customers);
    } else {
      customers = _getCategorizedCustomers(_filteredCustomers);
    }

    if (customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchController.text.isEmpty
                  ? Icons.people_outline
                  : Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'Henüz müşteri bulunmuyor'
                  : 'Arama sonucu bulunamadı',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index];
        return _buildCustomerCard(customer);
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Müşteri detay sayfasına gitme işlemi burada olacak
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppConstants.primaryColor,
                    radius: 24,
                    child: Text(
                      customer.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (customer.taxOffice != null &&
                            customer.taxOffice!.isNotEmpty)
                          Text(
                            customer.taxOffice!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      switch (value) {
                        case 'edit':
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddCustomerScreen(customer: customer),
                            ),
                          );
                          if (result == true && mounted) {
                            context.read<CustomerProvider>().loadCustomers();
                          }
                          break;
                        case 'delete':
                          _showDeleteDialog(customer);
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
                            Icon(Icons.delete, color: AppConstants.errorColor),
                            SizedBox(width: 8),
                            Text(
                              'Sil',
                              style: TextStyle(color: AppConstants.errorColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // İletişim bilgileri
              if (customer.phone != null && customer.phone!.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.phone, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      customer.phone!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              if (customer.email != null && customer.email!.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.email, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      customer.email!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              if (customer.address != null && customer.address!.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        customer.address!,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (customer.taxNumber != null &&
                  customer.taxNumber!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Vergi No: ${customer.taxNumber}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Müşteriyi Sil'),
        content: Text(
          '${customer.name} müşterisini silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await context
                  .read<CustomerProvider>()
                  .deleteCustomer(customer.id!);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? '${customer.name} başarıyla silindi'
                          : 'Müşteri silinirken hata oluştu',
                    ),
                    backgroundColor: success
                        ? Colors.green
                        : AppConstants.errorColor,
                  ),
                );
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

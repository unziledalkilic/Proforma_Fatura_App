import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/invoice_provider.dart';

class InvoicesScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const InvoicesScreen({super.key, this.onBackToHome});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredInvoices = [];
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoiceProvider>().loadInvoices();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterInvoices(String query) {
    setState(() {
      _filteredInvoices = context.read<InvoiceProvider>().searchInvoices(query);
    });
  }

  void _filterByStatus(String status) {
    setState(() {
      _selectedStatus = status;
    });
  }

  List<dynamic> _getFilteredInvoices() {
    final invoiceProvider = context.read<InvoiceProvider>();
    List<dynamic> invoices = _searchController.text.isEmpty
        ? invoiceProvider.invoices
        : _filteredInvoices;

    if (_selectedStatus != 'all') {
      invoices = invoices
          .where((invoice) => invoice.status.name == _selectedStatus)
          .toList();
    }

    return invoices;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.invoicesTitle),
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
            onPressed: () {
              // Yeni fatura oluşturma sayfasına git
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama ve filtre çubuğu
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Fatura ara...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterInvoices('');
                            },
                          )
                        : null,
                  ),
                  onChanged: _filterInvoices,
                ),
                const SizedBox(height: AppConstants.paddingSmall),

                // Durum filtreleri
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusFilter('Tümü', 'all'),
                      _buildStatusFilter('Taslak', 'draft'),
                      _buildStatusFilter('Gönderildi', 'sent'),
                      _buildStatusFilter('Kabul Edildi', 'accepted'),
                      _buildStatusFilter('Reddedildi', 'rejected'),
                      _buildStatusFilter('Süresi Doldu', 'expired'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Fatura listesi
          Expanded(
            child: Consumer<InvoiceProvider>(
              builder: (context, invoiceProvider, child) {
                if (invoiceProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (invoiceProvider.error != null) {
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
                          invoiceProvider.error!,
                          style: AppConstants.bodyStyle,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            invoiceProvider.loadInvoices();
                          },
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  );
                }

                final invoices = _getFilteredInvoices();

                if (invoices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty &&
                                  _selectedStatus == 'all'
                              ? 'Henüz fatura bulunmuyor'
                              : 'Arama sonucu bulunamadı',
                          style: AppConstants.bodyStyle,
                        ),
                        if (_searchController.text.isEmpty &&
                            _selectedStatus == 'all') ...[
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              // Yeni fatura oluşturma sayfasına git
                            },
                            child: const Text('İlk Faturayı Oluştur'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  itemCount: invoices.length,
                  itemBuilder: (context, index) {
                    final invoice = invoices[index];
                    return Card(
                      margin: const EdgeInsets.only(
                        bottom: AppConstants.paddingSmall,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppConstants.warningColor,
                          child: Text(
                            invoice.invoiceNumber.substring(0, 2),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          invoice.invoiceNumber,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(invoice.customer.name),
                            Text(
                              'Tarih: ${invoice.invoiceDate.day}/${invoice.invoiceDate.month}/${invoice.invoiceDate.year}',
                              style: AppConstants.captionStyle,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppConstants
                                    .invoiceStatusColors[invoice.status.name],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                AppConstants.invoiceStatusLabels[invoice
                                        .status
                                        .name] ??
                                    '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₺${invoice.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryColor,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${invoice.itemCount} kalem',
                              style: AppConstants.captionStyle,
                            ),
                          ],
                        ),
                        onTap: () {
                          // Fatura detay sayfasına git
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
        onPressed: () {
          // Yeni fatura oluşturma sayfasına git
        },
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatusFilter(String label, String status) {
    final isSelected = _selectedStatus == status;
    return Container(
      margin: const EdgeInsets.only(right: AppConstants.paddingSmall),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          _filterByStatus(status);
        },
        selectedColor: AppConstants.primaryColor,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}

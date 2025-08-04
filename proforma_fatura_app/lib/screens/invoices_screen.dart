import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../constants/app_constants.dart';
import '../providers/invoice_provider.dart';
import '../services/pdf_service.dart';
import 'invoice_form_screen.dart';
import 'invoice_detail_screen.dart';

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
                            onPressed: () async {
                              print('🔄 İlk Faturayı Oluştur butonuna basıldı');
                              try {
                                print(
                                  '🔄 Navigator.push başlıyor (İlk Fatura)...',
                                );
                                final result = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) {
                                      print(
                                        '🔄 InvoiceFormScreen builder çağrıldı (İlk Fatura)',
                                      );
                                      return const InvoiceFormScreen();
                                    },
                                  ),
                                );
                                print(
                                  '✅ Navigator.push tamamlandı (İlk Fatura), result: $result',
                                );
                                if (result == true && mounted) {
                                  print(
                                    '🔄 InvoiceProvider.loadInvoices çağrılıyor (İlk Fatura)',
                                  );
                                  context
                                      .read<InvoiceProvider>()
                                      .loadInvoices();
                                  print(
                                    '✅ InvoiceProvider.loadInvoices tamamlandı (İlk Fatura)',
                                  );
                                }
                              } catch (e) {
                                print('❌ İlk Fatura buton hatası: $e');
                              }
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
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
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (value) =>
                                  _handleMenuAction(value, invoice),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text('Düzenle'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'pdf',
                                  child: Row(
                                    children: [
                                      Icon(Icons.picture_as_pdf, color: Colors.orange),
                                      SizedBox(width: 8),
                                      Text('PDF İndir'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Sil'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  InvoiceDetailScreen(invoice: invoice),
                            ),
                          );
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
          print('🔄 FAB + butonuna basıldı');
          try {
            print('🔄 Navigator.push başlıyor (FAB)...');
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  print('🔄 InvoiceFormScreen builder çağrıldı (FAB)');
                  return const InvoiceFormScreen();
                },
              ),
            );
            print('✅ Navigator.push tamamlandı (FAB), result: $result');
            if (result == true && mounted) {
              print('🔄 InvoiceProvider.loadInvoices çağrılıyor (FAB)');
              context.read<InvoiceProvider>().loadInvoices();
              print('✅ InvoiceProvider.loadInvoices tamamlandı (FAB)');
            }
          } catch (e) {
            print('❌ FAB buton hatası: $e');
          }
        },
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _handleMenuAction(String action, dynamic invoice) async {
    switch (action) {
      case 'edit':
        await _editInvoice(invoice);
        break;
      case 'pdf':
        await _generatePdf(invoice);
        break;
      case 'delete':
        await _deleteInvoice(invoice);
        break;
    }
  }

  Future<void> _editInvoice(dynamic invoice) async {
    try {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => InvoiceFormScreen(invoice: invoice),
        ),
      );
      if (result == true && mounted) {
        context.read<InvoiceProvider>().loadInvoices();
      }
    } catch (e) {
      print('❌ Fatura düzenleme hatası: $e');
    }
  }

  Future<void> _generatePdf(dynamic invoice) async {
    try {
      // Loading göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('PDF oluşturuluyor...'),
            ],
          ),
        ),
      );

      // PDF oluştur
      final pdfService = PdfService();
      final filePath = await pdfService.generateInvoicePdf(invoice);

      // Loading dialog'u kapat
      Navigator.of(context).pop();

      // Başarı mesajı göster
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF başarıyla oluşturuldu: $filePath'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Dosyayı Aç',
              onPressed: () {
                // TODO: Dosyayı açma işlemi
              },
            ),
          ),
        );
      }
    } catch (e) {
      // Loading dialog'u kapat
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Hata mesajı göster
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF oluşturulurken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteInvoice(dynamic invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Faturayı Sil'),
        content: Text(
          '${invoice.invoiceNumber} numaralı faturayı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final success = await context.read<InvoiceProvider>().deleteInvoice(
          invoice.id,
        );
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${invoice.invoiceNumber} numaralı fatura silindi'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fatura silinirken hata oluştu'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print('❌ Fatura silme hatası: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fatura silinirken hata oluştu: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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

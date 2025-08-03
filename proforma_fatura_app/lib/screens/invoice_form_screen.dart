import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/product.dart';
import '../providers/customer_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/product_provider.dart';

class InvoiceFormScreen extends StatefulWidget {
  final Invoice? invoice; // Düzenleme modu için

  const InvoiceFormScreen({super.key, this.invoice});

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceNumberController = TextEditingController();

  // Alıcı bilgileri için controller'lar
  final _customerNameController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _customerTaxNumberController = TextEditingController();

  // Kayıtlı müşteri seçimi için
  String? _selectedCustomerId;
  bool _isLoading = false;

  // Ürün seçimi için
  List<InvoiceItem> _invoiceItems = [];
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _discountRateController = TextEditingController();
  final _taxRateController = TextEditingController();
  final _itemNotesController = TextEditingController();
  Product? _selectedProduct;

  @override
  void initState() {
    super.initState();
    print('🔄 InvoiceFormScreen initState başladı');

    // Düzenleme modu ise mevcut fatura bilgilerini yükle
    if (widget.invoice != null) {
      _loadInvoiceData(widget.invoice!);
    } else {
      try {
        _invoiceNumberController.text =
            'PF-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}-${(1000 + DateTime.now().millisecondsSinceEpoch % 9000)}';
        print(
          '✅ Fatura numarası oluşturuldu: ${_invoiceNumberController.text}',
        );
      } catch (e) {
        print('❌ Fatura numarası oluşturma hatası: $e');
      }
    }

    // Müşterileri ve ürünleri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCustomers();
      _loadProducts();
    });

    print('✅ InvoiceFormScreen initState tamamlandı');
  }

  Future<void> _loadCustomers() async {
    final customerProvider = context.read<CustomerProvider>();
    await customerProvider.loadCustomers();
  }

  Future<void> _loadProducts() async {
    final productProvider = context.read<ProductProvider>();
    await productProvider.loadProducts();
  }

  void _loadInvoiceData(Invoice invoice) {
    // Fatura bilgilerini yükle
    _invoiceNumberController.text = invoice.invoiceNumber;

    // Müşteri bilgilerini yükle
    _customerNameController.text = invoice.customer.name;
    _customerAddressController.text = invoice.customer.address ?? '';
    _customerPhoneController.text = invoice.customer.phone ?? '';
    _customerEmailController.text = invoice.customer.email ?? '';
    _customerTaxNumberController.text = invoice.customer.taxNumber ?? '';
    _selectedCustomerId = invoice.customer.id.toString();

    // Fatura ürünlerini yükle
    _invoiceItems = List.from(invoice.items);

    print('✅ Fatura bilgileri yüklendi: ${invoice.invoiceNumber}');
  }

  @override
  void dispose() {
    print('🔄 InvoiceFormScreen dispose başladı');
    _invoiceNumberController.dispose();
    _customerNameController.dispose();
    _customerAddressController.dispose();
    _customerPhoneController.dispose();
    _customerEmailController.dispose();
    _customerTaxNumberController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _discountRateController.dispose();
    _taxRateController.dispose();
    _itemNotesController.dispose();
    super.dispose();
    print('✅ InvoiceFormScreen dispose tamamlandı');
  }

  void _onCustomerSelected(String? customerId) {
    setState(() {
      _selectedCustomerId = customerId;
    });

    if (customerId != null) {
      // Seçilen müşterinin bilgilerini yükle
      final customerProvider = context.read<CustomerProvider>();
      final customer = customerProvider.customers.firstWhere(
        (c) => c.id.toString() == customerId,
      );

      _customerNameController.text = customer.name;
      _customerAddressController.text = customer.address ?? '';
      _customerPhoneController.text = customer.phone ?? '';
      _customerEmailController.text = customer.email ?? '';
      _customerTaxNumberController.text = customer.taxNumber ?? '';
    } else {
      // Müşteri seçimi temizlendiğinde formu temizle
      _customerNameController.clear();
      _customerAddressController.clear();
      _customerPhoneController.clear();
      _customerEmailController.clear();
      _customerTaxNumberController.clear();
    }
  }

  void _onProductSelected(Product? product) {
    setState(() {
      _selectedProduct = product;
      if (product != null) {
        _unitPriceController.text = product.price.toString();
        _taxRateController.text = '18.0'; // Varsayılan KDV oranı
      } else {
        _unitPriceController.clear();
        _taxRateController.clear();
      }
    });
  }

  void _addProductToInvoice() {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir ürün seçin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final unitPrice = double.tryParse(_unitPriceController.text) ?? 0;
    final discountRate = double.tryParse(_discountRateController.text);
    final taxRate = double.tryParse(_taxRateController.text) ?? 0;

    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Miktar 0\'dan büyük olmalıdır'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (unitPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Birim fiyat 0\'dan büyük olmalıdır'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final invoiceItem = InvoiceItem(
      invoiceId: null, // Fatura kaydedilirken atanacak
      product: _selectedProduct!,
      quantity: quantity,
      unitPrice: unitPrice,
      discountRate: discountRate,
      taxRate: taxRate,
      notes: _itemNotesController.text.trim().isEmpty
          ? null
          : _itemNotesController.text.trim(),
    );

    setState(() {
      _invoiceItems.add(invoiceItem);
    });

    // Formu temizle
    _quantityController.clear();
    _unitPriceController.clear();
    _discountRateController.clear();
    _taxRateController.clear();
    _itemNotesController.clear();
    _selectedProduct = null;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ürün faturaya eklendi'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _removeProductFromInvoice(int index) {
    setState(() {
      _invoiceItems.removeAt(index);
    });
  }

  double _calculateSubtotal() {
    return _invoiceItems.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  double _calculateTotalDiscount() {
    return _invoiceItems.fold(0.0, (sum, item) => sum + item.discountAmount);
  }

  double _calculateTotalTax() {
    return _invoiceItems.fold(0.0, (sum, item) => sum + item.taxAmount);
  }

  double _calculateTotal() {
    return _invoiceItems.fold(0.0, (sum, item) => sum + item.totalAmount);
  }

  Future<void> _saveInvoice() async {
    print('🔄 _saveInvoice başladı');

    if (!_formKey.currentState!.validate()) {
      print('❌ Form validasyonu başarısız');
      return;
    }

    if (_invoiceItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('En az bir ürün eklemelisiniz'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final customerProvider = context.read<CustomerProvider>();
      final invoiceProvider = context.read<InvoiceProvider>();

      // Önce müşteriyi kaydet (eğer yeni müşteriyse)
      Customer customer;
      if (_selectedCustomerId != null) {
        // Mevcut müşteri seçilmişse
        customer = customerProvider.customers.firstWhere(
          (c) => c.id.toString() == _selectedCustomerId,
        );
      } else {
        // Yeni müşteri oluştur
        customer = Customer(
          name: _customerNameController.text.trim(),
          email: _customerEmailController.text.trim(),
          phone: _customerPhoneController.text.trim(),
          address: _customerAddressController.text.trim(),
          taxNumber: _customerTaxNumberController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Müşteriyi veritabanına kaydet
        final success = await customerProvider.addCustomer(customer);
        if (!success) {
          throw Exception('Müşteri kaydedilemedi');
        }

        // Yeni eklenen müşteriyi al
        customer = customerProvider.customers.last;
      }

      // Fatura oluştur veya güncelle
      Invoice invoice;
      bool success;

      if (widget.invoice != null) {
        // Düzenleme modu - mevcut faturayı güncelle
        invoice = widget.invoice!.copyWith(
          invoiceNumber: _invoiceNumberController.text.trim(),
          customer: customer,
          items: _invoiceItems,
          updatedAt: DateTime.now(),
        );
        success = await invoiceProvider.updateInvoice(invoice);
        if (!success) {
          throw Exception('Fatura güncellenemedi');
        }
        print('✅ Fatura başarıyla güncellendi');
      } else {
        // Yeni fatura oluştur
        invoice = Invoice(
          invoiceNumber: _invoiceNumberController.text.trim(),
          customer: customer,
          invoiceDate: DateTime.now(),
          dueDate: DateTime.now().add(const Duration(days: 30)), // 30 gün vade
          items: _invoiceItems,
          status: InvoiceStatus.draft,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        success = await invoiceProvider.addInvoice(invoice);
        if (!success) {
          throw Exception('Fatura kaydedilemedi');
        }
        print('✅ Fatura başarıyla oluşturuldu');
      }

      print('✅ Fatura başarıyla kaydedildi');
      print('📄 Fatura Numarası: ${invoice.invoiceNumber}');
      print('👤 Müşteri: ${customer.name}');
      print('📦 Ürün Sayısı: ${_invoiceItems.length}');
      print('💰 Toplam Tutar: ₺${_calculateTotal().toStringAsFixed(2)}');

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fatura başarıyla oluşturuldu!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Fatura kaydetme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
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
    print('🔄 InvoiceFormScreen build çağrıldı');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.invoice != null ? 'Faturayı Düzenle' : 'Yeni Fatura',
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(icon: const Icon(Icons.save), onPressed: _saveInvoice),
        ],
      ),
      body: SafeArea(
        child: Consumer2<CustomerProvider, ProductProvider>(
          builder: (context, customerProvider, productProvider, child) {
            return Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Fatura Numarası
                      TextFormField(
                        controller: _invoiceNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Fatura Numarası *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Fatura numarası gerekli';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Kayıtlı Müşteri Seçimi
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Kayıtlı Müşteri Seçimi',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (customerProvider.isLoading)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else
                                DropdownButtonFormField<String>(
                                  value: _selectedCustomerId,
                                  decoration: const InputDecoration(
                                    labelText: 'Müşteri Seçin',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.person_search),
                                  ),
                                  items: [
                                    const DropdownMenuItem<String>(
                                      value: null,
                                      child: Text('Yeni Müşteri'),
                                    ),
                                    ...customerProvider.customers.map((
                                      customer,
                                    ) {
                                      return DropdownMenuItem<String>(
                                        value: customer.id.toString(),
                                        child: Text(customer.name),
                                      );
                                    }),
                                  ],
                                  onChanged: _onCustomerSelected,
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Alıcı Bilgileri Başlığı
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Alıcı Bilgileri',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Alıcı Adı/Unvanı
                      TextFormField(
                        controller: _customerNameController,
                        decoration: const InputDecoration(
                          labelText: 'Alıcı Adı/Unvanı *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Alıcı adı gerekli';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Adres
                      TextFormField(
                        controller: _customerAddressController,
                        decoration: const InputDecoration(
                          labelText: 'Adres *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Adres gerekli';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Telefon ve E-posta satırı
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _customerPhoneController,
                              decoration: const InputDecoration(
                                labelText: 'Telefon *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.phone),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Telefon gerekli';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _customerEmailController,
                              decoration: const InputDecoration(
                                labelText: 'E-posta *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.email),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'E-posta gerekli';
                                }
                                if (!RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                ).hasMatch(value)) {
                                  return 'Geçerli e-posta adresi girin';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Vergi Numarası
                      TextFormField(
                        controller: _customerTaxNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Vergi Numarası (VKN/TCKN) *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.receipt_long),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vergi numarası gerekli';
                          }
                          if (value.length < 10 || value.length > 11) {
                            return 'Vergi numarası 10-11 haneli olmalı';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Ürün Seçimi Bölümü
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ürün Seçimi',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Ürün Seçimi
                              if (productProvider.isLoading)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else
                                DropdownButtonFormField<Product>(
                                  value: _selectedProduct,
                                  decoration: const InputDecoration(
                                    labelText: 'Ürün Seçin *',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.inventory),
                                  ),
                                  items: productProvider.products.map((
                                    product,
                                  ) {
                                    return DropdownMenuItem<Product>(
                                      value: product,
                                      child: Text(
                                        '${product.name} (₺${product.price.toStringAsFixed(2)})',
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: _onProductSelected,
                                ),
                              const SizedBox(height: 16),

                              // Ürün Detayları
                              if (_selectedProduct != null) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _quantityController,
                                        decoration: const InputDecoration(
                                          labelText: 'Miktar *',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(
                                            Icons.format_list_numbered,
                                          ),
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _unitPriceController,
                                        decoration: const InputDecoration(
                                          labelText: 'Birim Fiyat (₺) *',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.attach_money),
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _discountRateController,
                                        decoration: const InputDecoration(
                                          labelText: 'İndirim Oranı (%)',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.discount),
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _taxRateController,
                                        decoration: const InputDecoration(
                                          labelText: 'KDV Oranı (%) *',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.receipt),
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                TextFormField(
                                  controller: _itemNotesController,
                                  decoration: const InputDecoration(
                                    labelText: 'Ürün Notu',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.note),
                                  ),
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 16),

                                ElevatedButton.icon(
                                  onPressed: _addProductToInvoice,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Ürünü Faturaya Ekle'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Eklenen Ürünler Listesi
                      if (_invoiceItems.isNotEmpty) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Eklenen Ürünler',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${_invoiceItems.length} ürün',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                ..._invoiceItems.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final item = entry.value;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.product.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              if (item.notes != null) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Not: ${item.notes!}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            '${item.quantity} ${item.product.unit}',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            '₺${item.unitPrice.toStringAsFixed(2)}',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            '₺${item.totalAmount.toStringAsFixed(2)}',
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              _removeProductFromInvoice(index),
                                        ),
                                      ],
                                    ),
                                  );
                                }),

                                const Divider(),

                                // Toplam Bilgileri
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Ara Toplam:'),
                                    Text(
                                      '₺${_calculateSubtotal().toStringAsFixed(2)}',
                                    ),
                                  ],
                                ),
                                if (_calculateTotalDiscount() > 0) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Toplam İndirim:'),
                                      Text(
                                        '-₺${_calculateTotalDiscount().toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('KDV Toplamı:'),
                                    Text(
                                      '₺${_calculateTotalTax().toStringAsFixed(2)}',
                                    ),
                                  ],
                                ),
                                const Divider(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'TOPLAM:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                      '₺${_calculateTotal().toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Kaydet Butonu
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveInvoice,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Kaydediliyor...'),
                                ],
                              )
                            : const Text(
                                'Faturayı Kaydet',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/product_provider.dart';
import '../providers/invoice_provider.dart';

import '../services/currency_service.dart';
import '../widgets/invoice_stats_widget.dart';
import 'customers_screen.dart';
import 'products_screen.dart';
import 'invoices_screen.dart';
import 'invoice_detail_screen.dart';
import 'profile_screen.dart';
import 'product_form_screen.dart';
import 'invoice_form_screen.dart';
import 'add_customer_screen.dart';
import 'pdf_preview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const DashboardScreen(),
      CustomersScreen(onBackToHome: () => _goToDashboard()),
      ProductsScreen(onBackToHome: () => _goToDashboard()),
      InvoicesScreen(onBackToHome: () => _goToDashboard()),
      ProfileScreen(onBackToHome: () => _goToDashboard()),
    ];
    // Veri yükleme işlemini başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _goToDashboard() {
    setState(() {
      _currentIndex = 0;
    });
  }

  Future<void> _loadInitialData() async {
    try {
      // Önce kullanıcı giriş durumunu kontrol et
      final authProvider = context.read<AuthProvider>();
      if (authProvider.currentUser != null &&
          authProvider.currentUser!.id != null) {
        // Kullanıcı giriş yapmışsa, ProductProvider'a kullanıcı ID'sini geçir
        final productProvider = context.read<ProductProvider>();
        productProvider.setCurrentUser(authProvider.currentUser!.id!);

        // CustomerProvider'a kullanıcı ID'sini geçir
        final customerProvider = context.read<CustomerProvider>();
        customerProvider.setCurrentUser(authProvider.currentUser!.id!);

        // InvoiceProvider'a kullanıcı ID'sini geçir
        final invoiceProvider = context.read<InvoiceProvider>();
        invoiceProvider.setCurrentUser(authProvider.currentUser!.id!);

        await Future.wait([
          customerProvider.loadCustomers(),
          context.read<ProductProvider>().loadProducts(),
          invoiceProvider.loadInvoices(),
        ]);
      } else {
        // Kullanıcı giriş yapmamışsa sadece müşteri ve fatura verilerini yükle
        await Future.wait([
          context.read<CustomerProvider>().loadCustomers(),
          context.read<InvoiceProvider>().loadInvoices(),
        ]);
      }
    } catch (e) {
      debugPrint('Veri yükleme hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Müşteriler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Ürünler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Faturalar',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, double> _exchangeRates = {};
  bool _isLoadingRates = true;

  @override
  void initState() {
    super.initState();
    // Başlangıçta varsayılan değerleri göster
    _exchangeRates = {'USD': 34.50, 'EUR': 37.20, 'GBP': 43.80, 'JPY': 0.23};
    _isLoadingRates = false;
    // Sonra gerçek verileri yükle
    _loadExchangeRates();
  }

  Future<void> _loadExchangeRates() async {
    try {
      print('🔄 Dashboard: Doviz kurlari yukleniyor...');
      final rates = await CurrencyService.getExchangeRates();
      print('✅ Dashboard: Doviz kurlari alindi: $rates');

      // Widget hala aktif mi kontrol et
      if (mounted) {
        setState(() {
          _exchangeRates = rates;
          _isLoadingRates = false;
        });
      }
    } catch (e) {
      print('❌ Dashboard: Doviz kurlari yukleme hatasi: $e');

      // Widget hala aktif mi kontrol et
      if (mounted) {
        setState(() {
          _isLoadingRates = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.homeTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              _showAppInfoDialog(context);
            },
            tooltip: 'Uygulama Hakkında',
          ),
        ],
      ),
      body: Consumer3<CustomerProvider, ProductProvider, InvoiceProvider>(
        builder:
            (
              context,
              customerProvider,
              productProvider,
              invoiceProvider,
              child,
            ) {
              return RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    customerProvider.loadCustomers(),
                    productProvider.loadProducts(),
                    invoiceProvider.loadInvoices(),
                  ]);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hoş geldin mesajı
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          final userName =
                              authProvider.currentUser?.fullName ??
                              authProvider.currentUser?.username ??
                              'Kullanıcı';
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppConstants.paddingMedium,
                                vertical: AppConstants.paddingSmall,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: AppConstants.primaryColor
                                          .withAlpha(26),
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      size: 30,
                                      color: AppConstants.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: AppConstants.paddingMedium,
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Hoş Geldiniz!',
                                          style: AppConstants.captionStyle
                                              .copyWith(
                                                fontSize: 12,
                                                color:
                                                    AppConstants.textSecondary,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          userName,
                                          style: AppConstants.headingStyle
                                              .copyWith(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.waving_hand,
                                    color: AppConstants.warningColor,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),

                      // Döviz Kurları
                      Row(
                        children: [
                          Text(
                            'Güncel Döviz Kurları',
                            style: AppConstants.subheadingStyle,
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () {
                              if (mounted) {
                                setState(() {
                                  _isLoadingRates = true;
                                });
                                _loadExchangeRates();
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.paddingSmall),

                      // Döviz kartları
                      if (_isLoadingRates)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppConstants.paddingMedium),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else
                        Column(
                          children: [
                            // Cache durumu ve son güncelleme
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.blue[200]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue[600],
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'TCMB güncel döviz kurları',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Son güncelleme: ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppConstants.paddingSmall),

                            // Döviz kartları alt alta
                            Column(
                              children: [
                                _buildDetailedCurrencyCard(
                                  'USD',
                                  'Amerikan Doları',
                                  _exchangeRates['USD'] ?? 0,
                                  Colors.purple,
                                ),
                                const SizedBox(height: 4),
                                _buildDetailedCurrencyCard(
                                  'EUR',
                                  'Euro',
                                  _exchangeRates['EUR'] ?? 0,
                                  Colors.green,
                                ),
                                const SizedBox(height: 4),
                                _buildDetailedCurrencyCard(
                                  'GBP',
                                  'İngiliz Sterlini',
                                  _exchangeRates['GBP'] ?? 0,
                                  Colors.orange,
                                ),
                                const SizedBox(height: 4),
                                _buildDetailedCurrencyCard(
                                  'JPY',
                                  'Japon Yeni',
                                  _exchangeRates['JPY'] ?? 0,
                                  Colors.red,
                                ),
                              ],
                            ),
                          ],
                        ),
                      const SizedBox(height: AppConstants.paddingLarge),

                      // Hızlı işlemler
                      Container(
                        padding: const EdgeInsets.all(
                          AppConstants.paddingMedium,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppConstants.primaryColor.withOpacity(0.1),
                              AppConstants.primaryColor.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppConstants.primaryColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppConstants.primaryColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.flash_on,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Hızlı İşlemler',
                                  style: AppConstants.subheadingStyle.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppConstants.paddingMedium),

                            // Ana işlemler (2x2 grid)
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.2,
                              children: [
                                _buildModernQuickActionButton(
                                  'Yeni Fatura',
                                  Icons.receipt_long,
                                  AppConstants.primaryColor,
                                  () async {
                                    final productProvider = context
                                        .read<ProductProvider>();
                                    final customerProvider = context
                                        .read<CustomerProvider>();

                                    if (productProvider.categories.isEmpty) {
                                      await productProvider.loadCategories();
                                    }

                                    if (customerProvider.customers.isEmpty) {
                                      await customerProvider.loadCustomers();
                                    }

                                    if (mounted) {
                                      _showNewInvoiceOptions(context);
                                    }
                                  },
                                ),
                                _buildModernQuickActionButton(
                                  'Müşteri Ekle',
                                  Icons.person_add,
                                  AppConstants.successColor,
                                  () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AddCustomerScreen(),
                                      ),
                                    );
                                  },
                                ),
                                _buildModernQuickActionButton(
                                  'Ürün Ekle',
                                  Icons.add_box,
                                  AppConstants.warningColor,
                                  () async {
                                    final productProvider = context
                                        .read<ProductProvider>();
                                    if (productProvider.categories.isEmpty) {
                                      await productProvider.loadCategories();
                                    }

                                    if (mounted) {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ProductFormScreen(),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                _buildModernQuickActionButton(
                                  'Fatura Ara',
                                  Icons.search,
                                  AppConstants.errorColor,
                                  () {
                                    final homeScreen = context
                                        .findAncestorStateOfType<
                                          _HomeScreenState
                                        >();
                                    if (homeScreen != null) {
                                      homeScreen.setState(() {
                                        homeScreen._currentIndex = 3;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingLarge),

                      // Fatura İstatistikleri
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(
                            AppConstants.paddingMedium,
                          ),
                          child: InvoiceStatsWidget(
                            invoices: invoiceProvider.invoices,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),

                      // Son faturalar
                      Text(
                        'Son Faturalar',
                        style: AppConstants.subheadingStyle,
                      ),
                      const SizedBox(height: AppConstants.paddingSmall),

                      // Son faturalar listesi
                      if (invoiceProvider.invoices.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(AppConstants.paddingMedium),
                            child: Center(
                              child: Text(
                                'Henüz fatura bulunmuyor',
                                style: AppConstants.captionStyle,
                              ),
                            ),
                          ),
                        )
                      else
                        ...invoiceProvider.invoices
                            .take(5)
                            .map(
                              (invoice) => Card(
                                margin: const EdgeInsets.only(
                                  bottom: AppConstants.paddingSmall,
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppConstants.primaryColor,
                                    child: Text(
                                      invoice.invoiceNumber.substring(0, 2),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  title: Text(invoice.invoiceNumber),
                                  subtitle: Text(invoice.customer.name),
                                  trailing: Text(
                                    '₺${invoice.totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppConstants.primaryColor,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            InvoiceDetailScreen(
                                              invoice: invoice,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              );
            },
      ),
    );
  }

  Widget _buildDetailedCurrencyCard(
    String currency,
    String title,
    double rate,
    Color color,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Para birimi simgesi
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getCurrencySymbol(currency),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Para birimi adı ve kur bilgisi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₺${rate.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            // Dönüşüm oranı
            Text(
              '1 TRY = ${(1 / rate).toStringAsFixed(3)} $currency',
              style: const TextStyle(fontSize: 9, color: Colors.grey),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }

  String _getCurrencySymbol(String code) {
    switch (code.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      default:
        return code;
    }
  }

  void _showAppInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppConstants.primaryColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Proforma Fatura Uygulaması',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Misyon
                _buildInfoSection(
                  '🎯 Misyonumuz',
                  'Küçük ve orta ölçekli işletmelerin proforma fatura yönetim süreçlerini dijitalleştirerek, '
                      'zaman tasarrufu sağlamak ve iş süreçlerini optimize etmek. '
                      'Kullanıcı dostu arayüz ile karmaşık proforma fatura işlemlerini basitleştirmek.',
                ),
                const SizedBox(height: 16),

                // Vizyon
                _buildInfoSection(
                  '🚀 Vizyonumuz',
                  'Güvenilir ve kullanıcı dostu proforma fatura yönetim platformu olmak. '
                      'Teknoloji ile iş süreçlerini birleştirerek, işletmelerin büyümesine katkıda bulunmak.',
                ),
                const SizedBox(height: 16),

                // Nasıl Kullanılır
                _buildInfoSection(
                  '📖 Nasıl Kullanılır?',
                  '• Müşteriler: Müşteri bilgilerini ekleyin ve yönetin\n'
                      '• Ürünler: Ürün kataloğunuzu oluşturun\n'
                      '• Proforma Faturalar: Hızlıca proforma fatura oluşturun\n'
                      '• Döviz Kurları: Güncel kurları takip edin',
                ),
                const SizedBox(height: 16),

                // Özellikler
                _buildInfoSection(
                  '✨ Özellikler',
                  '• 📱 Mobil Uyumlu Arayüz\n'
                      '• 💾 Otomatik Veri Yedekleme\n'
                      '• 📊 Detaylı Raporlama\n'
                      '• 🔄 Gerçek Zamanlı Döviz Kurları\n'
                      '• 📄 PDF Proforma Fatura Oluşturma\n'
                      '• 🔍 Gelişmiş Arama ve Filtreleme',
                ),
                const SizedBox(height: 16),

                // İletişim
                _buildInfoSection(
                  '📞 Destek',
                  'Teknik destek ve önerileriniz için bizimle iletişime geçebilirsiniz.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Anladım',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          elevation: 8,
        );
      },
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  void _showNewInvoiceOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: AppConstants.primaryColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Yeni Proforma Fatura',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Proforma fatura oluşturmak için bir seçenek seçin:',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const InvoiceFormScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('Fatura Oluştur'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _showPdfTemplatePreview(context);
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('PDF Şablonunu Görüntüle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  void _showPdfTemplatePreview(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.picture_as_pdf,
                color: AppConstants.primaryColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'PDF Şablonu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    color: Colors.grey[100],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.picture_as_pdf,
                          size: 48,
                          color: AppConstants.primaryColor,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'PROFORMA FATURA',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Profesyonel PDF Şablonu',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Bu şablon ile oluşturulacak PDF dosyası:\n'
                '• Şirket logosu ve bilgileri\n'
                '• Müşteri bilgileri\n'
                '• Ürün listesi ve fiyatları\n'
                '• Toplam tutarlar ve vergiler\n'
                '• Profesyonel tasarım',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kapat'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const InvoiceFormScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Fatura Oluştur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(
          vertical: AppConstants.paddingSmall,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.white),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernQuickActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 28, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

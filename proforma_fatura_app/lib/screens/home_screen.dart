import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/product_provider.dart';
import '../providers/invoice_provider.dart';
import '../services/currency_service.dart';
import 'customers_screen.dart';
import 'products_screen.dart';
import 'invoices_screen.dart';
import 'profile_screen.dart';
import 'product_form_screen.dart';

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
      await Future.wait([
        context.read<CustomerProvider>().loadCustomers(),
        context.read<ProductProvider>().loadProducts(),
        context.read<InvoiceProvider>().loadInvoices(),
      ]);
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
    _loadExchangeRates();
  }

  Future<void> _loadExchangeRates() async {
    try {
      final rates = await CurrencyService.getExchangeRates();
      setState(() {
        _exchangeRates = rates;
        _isLoadingRates = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingRates = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.homeTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Ayarlar sayfasına git
            },
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
                                          .withOpacity(0.1),
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
                              setState(() {
                                _isLoadingRates = true;
                              });
                              _loadExchangeRates();
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
                            Row(
                              children: [
                                Expanded(
                                  child: _buildCurrencyCard(
                                    'USD',
                                    'Amerikan Doları',
                                    _exchangeRates['USD'] ?? 0,
                                    Icons.attach_money,
                                    AppConstants.primaryColor,
                                  ),
                                ),
                                const SizedBox(
                                  width: AppConstants.paddingSmall,
                                ),
                                Expanded(
                                  child: _buildCurrencyCard(
                                    'EUR',
                                    'Euro',
                                    _exchangeRates['EUR'] ?? 0,
                                    Icons.euro,
                                    AppConstants.successColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppConstants.paddingSmall),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildCurrencyCard(
                                    'GBP',
                                    'İngiliz Sterlini',
                                    _exchangeRates['GBP'] ?? 0,
                                    Icons.currency_pound,
                                    AppConstants.warningColor,
                                  ),
                                ),
                                const SizedBox(
                                  width: AppConstants.paddingSmall,
                                ),
                                Expanded(
                                  child: _buildCurrencyCard(
                                    'JPY',
                                    'Japon Yeni',
                                    _exchangeRates['JPY'] ?? 0,
                                    Icons.currency_yen,
                                    AppConstants.errorColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      const SizedBox(height: AppConstants.paddingLarge),

                      // Hızlı işlemler
                      Text(
                        'Hızlı İşlemler',
                        style: AppConstants.subheadingStyle,
                      ),
                      const SizedBox(height: AppConstants.paddingSmall),

                      // Hızlı işlem butonları
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionButton(
                              'Yeni Fatura',
                              Icons.receipt_long,
                              AppConstants.primaryColor,
                              () {
                                // Yeni fatura oluştur
                              },
                            ),
                          ),
                          const SizedBox(width: AppConstants.paddingSmall),
                          Expanded(
                            child: _buildQuickActionButton(
                              'Müşteri Ekle',
                              Icons.person_add,
                              AppConstants.successColor,
                              () {
                                // Müşteri ekle
                              },
                            ),
                          ),
                          const SizedBox(width: AppConstants.paddingSmall),
                          Expanded(
                            child: _buildQuickActionButton(
                              'Ürün Ekle',
                              Icons.add_box,
                              AppConstants.warningColor,
                              () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ProductFormScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.paddingSmall),
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionButton(
                              'Fatura Ara',
                              Icons.search,
                              AppConstants.errorColor,
                              () {
                                // Fatura ara
                              },
                            ),
                          ),
                          const SizedBox(width: AppConstants.paddingSmall),
                          Expanded(
                            child: _buildQuickActionButton(
                              'Raporlar',
                              Icons.analytics,
                              AppConstants.accentColor,
                              () {
                                // Raporlar
                              },
                            ),
                          ),
                          const SizedBox(width: AppConstants.paddingSmall),
                          Expanded(
                            child: _buildQuickActionButton(
                              'Hesap Makinesi',
                              Icons.calculate,
                              AppConstants.secondaryColor,
                              () {
                                // Hesap makinesi
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.paddingLarge),

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
                                    // Fatura detayına git
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

  Widget _buildCurrencyCard(
    String currency,
    String title,
    double rate,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingSmall),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              CurrencyService.formatCurrency(rate, currency),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: AppConstants.captionStyle.copyWith(fontSize: 11),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              '1 TRY = ${rate.toStringAsFixed(4)} $currency',
              style: AppConstants.captionStyle.copyWith(
                fontSize: 10,
                color: AppConstants.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
}

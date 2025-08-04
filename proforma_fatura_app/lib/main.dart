import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'constants/app_constants.dart';
import 'screens/login_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/product_provider.dart';
import 'providers/invoice_provider.dart';
import 'providers/company_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProformaFaturaApp());
}

class ProformaFaturaApp extends StatelessWidget {
  const ProformaFaturaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CompanyProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ProductProvider>(
          create: (_) => ProductProvider(),
          update: (_, auth, product) {
            if (product != null) {
              // AuthProvider'dan ProductProvider'a kullanıcı ID'sini geçir
              auth.addUserLoginCallback((userId) {
                product.setCurrentUser(userId);
              });
              // Uygulama başlangıcında giriş durumunu kontrol et
              WidgetsBinding.instance.addPostFrameCallback((_) {
                auth.checkLoginStatus();
              });
            }
            return product ?? ProductProvider();
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, CustomerProvider>(
          create: (_) => CustomerProvider(),
          update: (_, auth, customer) {
            if (customer != null) {
              // AuthProvider'dan CustomerProvider'a kullanıcı ID'sini geçir
              auth.addUserLoginCallback((userId) {
                customer.setCurrentUser(userId);
              });
              // Uygulama başlangıcında giriş durumunu kontrol et
              WidgetsBinding.instance.addPostFrameCallback((_) {
                auth.checkLoginStatus();
              });
            }
            return customer ?? CustomerProvider();
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, InvoiceProvider>(
          create: (_) => InvoiceProvider(),
          update: (_, auth, invoice) {
            if (invoice != null) {
              // AuthProvider'dan InvoiceProvider'a kullanıcı ID'sini geçir
              auth.addUserLoginCallback((userId) {
                invoice.setCurrentUser(userId);
              });
              // Uygulama başlangıcında giriş durumunu kontrol et
              WidgetsBinding.instance.addPostFrameCallback((_) {
                auth.checkLoginStatus();
              });
            }
            return invoice ?? InvoiceProvider();
          },
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppConstants.primaryColor,
            brightness: Brightness.light,
          ),
          primaryColor: AppConstants.primaryColor,
          scaffoldBackgroundColor: AppConstants.backgroundColor,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(
                double.infinity,
                AppConstants.buttonHeight,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              elevation: 0,
              shadowColor: AppConstants.primaryColor.withOpacity(0.3),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppConstants.surfaceColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              borderSide: const BorderSide(color: AppConstants.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              borderSide: const BorderSide(color: AppConstants.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              borderSide: const BorderSide(
                color: AppConstants.primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              borderSide: const BorderSide(color: AppConstants.errorColor),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMedium,
              vertical: AppConstants.paddingMedium,
            ),
            hintStyle: const TextStyle(color: AppConstants.textSecondary),
          ),
          cardTheme: CardThemeData(
            elevation: AppConstants.cardElevation,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            color: AppConstants.surfaceColor,
          ),
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('tr', 'TR'), Locale('en', 'US')],
        locale: const Locale('tr', 'TR'),
        home: const LoginScreen(),
      ),
    );
  }
}

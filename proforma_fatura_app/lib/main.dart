import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/kayitekrani.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // .env dosyasını yükle
    await dotenv.load(fileName: ".env");

    // Supabase'i başlat
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );

    print('✅ Supabase başarıyla başlatıldı');
    print('🔗 URL: ${dotenv.env['SUPABASE_URL']}');
  } catch (error) {
    print('❌ Supabase başlatma hatası: $error');
    print('🔍 .env dosyasını ve içeriğini kontrol edin');
  }

  runApp(MyApp());
}

// Global Supabase client - tüm projede kullanabilirsiniz
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Proforma Fatura',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,

      // İlk açılışta splash screen göster (auth kontrolü için)
      initialRoute: '/splash',

      routes: {
        '/splash': (context) => SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) =>
            DashboardScreen() // İleride eklenecek diğer sayfalar:
        // '/dashboard': (context) => DashboardScreen(),
        // '/customers': (context) => CustomersScreen(),
      },
    );
  }
}

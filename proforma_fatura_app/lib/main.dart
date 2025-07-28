import 'package:flutter/material.dart';
import 'screens/kayitekrani.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart'; 

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Proforma Fatura',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      debugShowCheckedModeBanner: false,
      // Ana sayfa login screen olarak ayarlandı
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        // İleride eklenecek diğer sayfalar:
        // '/dashboard': (context) => DashboardScreen(),
        // '/customers': (context) => CustomersScreen(),
      },
    );
  }
}

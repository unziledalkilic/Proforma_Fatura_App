import 'package:flutter/material.dart';
import 'screens/kayitekrani.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
        // İleride eklenecek diğer sayfalar:
        // '/dashboard': (context) => DashboardScreen(),
        // '/customers': (context) => CustomersScreen(),
      },
    );
  }
}

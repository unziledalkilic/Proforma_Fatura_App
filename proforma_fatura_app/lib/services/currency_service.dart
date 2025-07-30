import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  static const String _baseUrl =
      'https://api.exchangerate-api.com/v4/latest/TRY';

  static Future<Map<String, double>> getExchangeRates() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;

        // TRY'den diğer para birimlerine çevirme (1/rate)
        return {
          'USD': 1 / (rates['USD'] ?? 1),
          'EUR': 1 / (rates['EUR'] ?? 1),
          'GBP': 1 / (rates['GBP'] ?? 1),
          'JPY': 1 / (rates['JPY'] ?? 1),
        };
      } else {
        throw Exception('Döviz kurları alınamadı');
      }
    } catch (e) {
      // Hata durumunda varsayılan değerler
      return {'USD': 0.035, 'EUR': 0.032, 'GBP': 0.028, 'JPY': 5.2};
    }
  }

  static String formatCurrency(double value, String currency) {
    switch (currency) {
      case 'USD':
        return '\$${value.toStringAsFixed(4)}';
      case 'EUR':
        return '€${value.toStringAsFixed(4)}';
      case 'GBP':
        return '£${value.toStringAsFixed(4)}';
      case 'JPY':
        return '¥${value.toStringAsFixed(2)}';
      default:
        return value.toStringAsFixed(4);
    }
  }
}

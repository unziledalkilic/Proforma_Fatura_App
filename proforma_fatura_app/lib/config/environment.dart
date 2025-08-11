import 'package:flutter/foundation.dart';
class Environment {
  // Cloud API ayarları
  static const String cloudApiUrl = String.fromEnvironment(
    'CLOUD_API_URL',
    defaultValue: 'https://your-api.com/api',
  );

  static const String apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: 'your-api-key',
  );

  // Döviz API ayarları
  static const String currencyApiUrl = String.fromEnvironment(
    'CURRENCY_API_URL',
    defaultValue: 'http://hasanadiguzel.com.tr/api/kurgetir',
  );

  // Sync ayarları
  static const int syncIntervalMinutes = 5;
  static const int currencyCacheMinutes = 15;

  // Debug ayarları
  static const bool isDebug = bool.fromEnvironment('DEBUG', defaultValue: true);
  static const bool enableLogging = bool.fromEnvironment(
    'ENABLE_LOGGING',
    defaultValue: true,
  );

  // Database ayarları
  static const String localDatabaseName = 'proforma_fatura_hybrid.db';
  static const int localDatabaseVersion = 3;

  // App ayarları
  static const String appName = 'Proforma Fatura';
  static const String appVersion = '1.0.0';

  /// Environment bilgilerini yazdır
  static void printEnvironment() {
    if (enableLogging) {
      debugPrint('🌍 Environment Configuration:');
      debugPrint('   📱 App: $appName v$appVersion');
      debugPrint('   ☁️  Cloud API: $cloudApiUrl');
      debugPrint('   💱 Currency API: $currencyApiUrl');
      debugPrint('   🔄 Sync Interval: ${syncIntervalMinutes}min');
      debugPrint('   🗄️  Local DB: $localDatabaseName v$localDatabaseVersion');
      debugPrint('   🐛 Debug Mode: $isDebug');
      debugPrint('   📝 Logging: $enableLogging');
    }
  }
}

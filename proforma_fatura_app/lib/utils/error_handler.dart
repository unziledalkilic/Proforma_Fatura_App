import 'package:flutter/foundation.dart';

/// Kapsamlı error handling ve logging yardımcı sınıfı
class ErrorHandler {
  /// Database hatalarını yakalar ve loglar
  static void handleDatabaseError(String operation, dynamic error, [StackTrace? stackTrace]) {
    final errorMessage = 'Database Error in $operation: $error';
    debugPrint('❌ $errorMessage');
    
    if (stackTrace != null && kDebugMode) {
      debugPrint('Stack Trace: $stackTrace');
    }
    
    // Production'da crash reporting servisi kullanılabilir
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }

  /// Firebase hatalarını yakalar ve loglar
  static void handleFirebaseError(String operation, dynamic error, [StackTrace? stackTrace]) {
    final errorMessage = 'Firebase Error in $operation: $error';
    debugPrint('🔥 $errorMessage');
    
    if (stackTrace != null && kDebugMode) {
      debugPrint('Stack Trace: $stackTrace');
    }
  }

  /// Sync hatalarını yakalar ve loglar
  static void handleSyncError(String operation, dynamic error, [StackTrace? stackTrace]) {
    final errorMessage = 'Sync Error in $operation: $error';
    debugPrint('🔄 $errorMessage');
    
    if (stackTrace != null && kDebugMode) {
      debugPrint('Stack Trace: $stackTrace');
    }
  }

  /// ID dönüşüm hatalarını yakalar ve loglar
  static void handleIdConversionError(String context, dynamic id, [String? expectedType]) {
    final errorMessage = 'ID Conversion Error in $context: $id (expected: $expectedType)';
    debugPrint('🆔 $errorMessage');
  }

  /// Model validation hatalarını yakalar ve loglar
  static void handleValidationError(String model, String field, dynamic value) {
    final errorMessage = 'Validation Error in $model.$field: $value';
    debugPrint('✅ $errorMessage');
  }

  /// Network hatalarını yakalar ve loglar
  static void handleNetworkError(String operation, dynamic error) {
    final errorMessage = 'Network Error in $operation: $error';
    debugPrint('🌐 $errorMessage');
  }

  /// Genel hata yakalayıcı
  static void handleGenericError(String context, dynamic error, [StackTrace? stackTrace]) {
    final errorMessage = 'Generic Error in $context: $error';
    debugPrint('⚠️ $errorMessage');
    
    if (stackTrace != null && kDebugMode) {
      debugPrint('Stack Trace: $stackTrace');
    }
  }

  /// Hata mesajını kullanıcı dostu formata çevirir
  static String getUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('internet')) {
      return 'İnternet bağlantısı sorunu. Lütfen bağlantınızı kontrol edin.';
    }
    
    if (errorString.contains('permission') || errorString.contains('unauthorized')) {
      return 'Yetki sorunu. Lütfen tekrar giriş yapmayı deneyin.';
    }
    
    if (errorString.contains('database') || errorString.contains('sqlite')) {
      return 'Veri kaydetme sorunu. Lütfen tekrar deneyin.';
    }
    
    if (errorString.contains('firebase') || errorString.contains('firestore')) {
      return 'Sunucu bağlantı sorunu. Lütfen tekrar deneyin.';
    }
    
    if (errorString.contains('timeout')) {
      return 'İşlem zaman aşımına uğradı. Lütfen tekrar deneyin.';
    }
    
    return 'Bir hata oluştu. Lütfen tekrar deneyin.';
  }

  /// Debug modunda detaylı log yazdırır
  static void debugLog(String context, String message, [Map<String, dynamic>? data]) {
    if (kDebugMode) {
      debugPrint('🐛 [$context] $message');
      if (data != null) {
        debugPrint('📊 Data: $data');
      }
    }
  }

  /// Başarılı işlemleri loglar
  static void logSuccess(String operation, [Map<String, dynamic>? data]) {
    debugPrint('✅ $operation successful');
    if (data != null && kDebugMode) {
      debugPrint('📊 Data: $data');
    }
  }

  /// Performans metrikleri loglar
  static void logPerformance(String operation, Duration duration) {
    if (kDebugMode) {
      debugPrint('⏱️ $operation took ${duration.inMilliseconds}ms');
    }
  }

  /// Senkronizasyon durumu loglar
  static void logSyncStatus(String operation, String status, [Map<String, dynamic>? details]) {
    final emoji = status.toLowerCase() == 'success' ? '✅' : 
                  status.toLowerCase() == 'error' ? '❌' : 
                  status.toLowerCase() == 'pending' ? '⏳' : '🔄';
    
    debugPrint('$emoji Sync Status - $operation: $status');
    if (details != null && kDebugMode) {
      debugPrint('📊 Sync Details: $details');
    }
  }

  /// Veri çakışması hatalarını yakalar ve loglar
  static void handleDataConflict(String context, String conflictType, [Map<String, dynamic>? conflictData]) {
    final errorMessage = 'Data Conflict in $context: $conflictType';
    debugPrint('⚡ $errorMessage');
    
    if (conflictData != null && kDebugMode) {
      debugPrint('📊 Conflict Data: $conflictData');
    }
  }

  /// Senkronizasyon önceliği belirler
  static int getSyncPriority(String operation) {
    switch (operation.toLowerCase()) {
      case 'delete':
        return 1; // En yüksek öncelik
      case 'update':
        return 2;
      case 'insert':
        return 3;
      default:
        return 4;
    }
  }
}

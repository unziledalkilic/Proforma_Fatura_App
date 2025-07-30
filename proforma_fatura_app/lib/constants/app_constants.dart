import 'package:flutter/material.dart';

class AppConstants {
  // Uygulama bilgileri
  static const String appName = 'Proforma Fatura';
  static const String appVersion = '1.0.0';

  // Renkler - Modern ve sade
  static const Color primaryColor = Color(0xFF6366F1); // Modern indigo
  static const Color secondaryColor = Color(0xFF8B5CF6); // Modern mor
  static const Color accentColor = Color(0xFF06B6D4); // Modern cyan
  static const Color backgroundColor = Color(0xFFFAFAFA); // Çok açık gri
  static const Color surfaceColor = Color(0xFFFFFFFF); // Beyaz
  static const Color errorColor = Color(0xFFEF4444); // Modern kırmızı
  static const Color successColor = Color(0xFF10B981); // Modern yeşil
  static const Color warningColor = Color(0xFFF59E0B); // Modern turuncu
  static const Color textPrimary = Color(0xFF1F2937); // Koyu gri
  static const Color textSecondary = Color(0xFF6B7280); // Orta gri
  static const Color borderColor = Color(0xFFE5E7EB); // Açık gri border

  // Metin stilleri - Modern
  static const TextStyle headingStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.4,
  );

  static const TextStyle buttonStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  // Boyutlar - Modern
  static const double paddingSmall = 12.0;
  static const double paddingMedium = 20.0;
  static const double paddingLarge = 32.0;
  static const double borderRadius = 16.0;
  static const double buttonHeight = 56.0;
  static const double cardElevation = 2.0;

  // Animasyon süreleri
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration splashDuration = Duration(seconds: 2);

  // Sayfa başlıkları
  static const String homeTitle = 'Ana Sayfa';
  static const String customersTitle = 'Müşteriler';
  static const String productsTitle = 'Ürünler';
  static const String invoicesTitle = 'Faturalar';
  static const String settingsTitle = 'Ayarlar';

  // Mesajlar
  static const String saveSuccess = 'Başarıyla kaydedildi';
  static const String deleteSuccess = 'Başarıyla silindi';
  static const String updateSuccess = 'Başarıyla güncellendi';
  static const String errorMessage = 'Bir hata oluştu';
  static const String confirmDelete = 'Silmek istediğinizden emin misiniz?';
  static const String noDataFound = 'Veri bulunamadı';

  // Form validasyon mesajları
  static const String requiredField = 'Bu alan zorunludur';
  static const String invalidEmail = 'Geçersiz e-posta adresi';
  static const String invalidPhone = 'Geçersiz telefon numarası';
  static const String invalidPrice = 'Geçersiz fiyat';
  static const String invalidQuantity = 'Geçersiz miktar';

  // Fatura durumları
  static const Map<String, String> invoiceStatusLabels = {
    'draft': 'Taslak',
    'sent': 'Gönderildi',
    'accepted': 'Kabul Edildi',
    'rejected': 'Reddedildi',
    'expired': 'Süresi Doldu',
  };

  // Fatura durumu renkleri
  static const Map<String, Color> invoiceStatusColors = {
    'draft': Colors.grey,
    'sent': Colors.blue,
    'accepted': Colors.green,
    'rejected': Colors.red,
    'expired': Colors.orange,
  };
}

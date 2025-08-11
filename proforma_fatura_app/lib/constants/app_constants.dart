import 'package:flutter/material.dart';

class AppConstants {
  // Uygulama bilgileri
  static const String appName = 'Proforma Fatura';
  static const String appVersion = '1.0.0';

  // Ana renkler - Modern ve uyumlu palet
  static const Color primaryColor = Color(0xFF6366F1); // Modern indigo
  static const Color primaryLight = Color(0xFF8B8BF7); // Açık indigo
  static const Color primaryDark = Color(0xFF4F46E5); // Koyu indigo

  static const Color secondaryColor = Color(0xFF8B5CF6); // Modern mor
  static const Color secondaryLight = Color(0xFFA78BFA); // Açık mor
  static const Color secondaryDark = Color(0xFF7C3AED); // Koyu mor

  static const Color accentColor = Color(0xFF06B6D4); // Modern cyan
  static const Color accentLight = Color(0xFF22D3EE); // Açık cyan
  static const Color accentDark = Color(0xFF0891B2); // Koyu cyan

  // Yüzey renkleri
  static const Color backgroundColor = Color(0xFFFAFAFA); // Ana arkaplan
  static const Color surfaceColor = Color(0xFFFFFFFF); // Kart/yüzey rengi
  static const Color surfaceVariant = Color(0xFFF8FAFC); // Alternatif yüzey

  // Durum renkleri
  static const Color errorColor = Color(0xFFEF4444); // Hata
  static const Color errorLight = Color(0xFFFCA5A5); // Açık hata
  static const Color successColor = Color(0xFF10B981); // Başarı
  static const Color successLight = Color(0xFF6EE7B7); // Açık başarı
  static const Color warningColor = Color(0xFFF59E0B); // Uyarı
  static const Color warningLight = Color(0xFFFBBF24); // Açık uyarı
  static const Color infoColor = Color(0xFF3B82F6); // Bilgi
  static const Color infoLight = Color(0xFF93C5FD); // Açık bilgi

  // Metin renkleri
  static const Color textPrimary = Color(0xFF1F2937); // Ana metin
  static const Color textSecondary = Color(0xFF6B7280); // İkincil metin
  static const Color textTertiary = Color(0xFF9CA3AF); // Üçüncül metin
  static const Color textOnPrimary = Color(
    0xFFFFFFFF,
  ); // Birincil üzerinde metin
  static const Color textOnSurface = Color(0xFF1F2937); // Yüzey üzerinde metin

  // Çizgi ve kenarlık renkleri
  static const Color borderColor = Color(0xFFE5E7EB); // Ana kenarlık
  static const Color borderLight = Color(0xFFF3F4F6); // Açık kenarlık
  static const Color dividerColor = Color(0xFFE5E7EB); // Ayırıcı çizgi

  // Avatar renkleri - Tutarlı palet
  static const List<Color> avatarColors = [
    Color(0xFF6366F1), // Primary indigo
    Color(0xFF8B5CF6), // Secondary purple
    Color(0xFF06B6D4), // Accent cyan
    Color(0xFF10B981), // Success green
    Color(0xFFF59E0B), // Warning orange
    Color(0xFFEF4444), // Error red
    Color(0xFF3B82F6), // Info blue
    Color(0xFF8B5A2B), // Brown
  ];

  // Kategori renkleri - Ürün kategorileri için
  static const Map<String, Color> categoryColors = {
    'Elektronik': Color(0xFF3B82F6), // Mavi
    'Gıda': Color(0xFF10B981), // Yeşil
    'Tekstil': Color(0xFF8B5CF6), // Mor
    'Otomotiv': Color(0xFFEF4444), // Kırmızı
    'Sağlık': Color(0xFF06B6D4), // Cyan
    'Eğitim': Color(0xFFF59E0B), // Turuncu
    'Diğer': Color(0xFF6B7280), // Gri
  };

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

  // Yardımcı metodlar
  static Color getAvatarColor(String text) {
    if (text.isEmpty) return avatarColors[0];
    final index = text.codeUnitAt(0) % avatarColors.length;
    return avatarColors[index];
  }

  static Color getCategoryColor(String category) {
    return categoryColors[category] ?? categoryColors['Diğer']!;
  }
}

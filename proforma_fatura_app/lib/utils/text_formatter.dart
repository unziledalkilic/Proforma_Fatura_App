import 'package:flutter/services.dart';

class TextFormatter {
  /// Her kelimenin ilk harfini büyük yapar (Türkçe karakter desteği ile)
  static String capitalizeWords(String text) {
    if (text.isEmpty) return text;

    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return _capitalizeFirstChar(word) + toLowerCaseTr(word.substring(1));
        })
        .join(' ');
  }

  /// Sadece ilk harfi büyük yapar (Türkçe karakter desteği ile)
  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return _capitalizeFirstChar(text) + text.substring(1);
  }

  /// Türkçe karakterler için özel büyük harf dönüşümü
  static String _capitalizeFirstChar(String text) {
    if (text.isEmpty) return text;

    final firstChar = text[0];

    // Türkçe özel karakterler
    const turkishLowerToUpper = {
      'ç': 'Ç',
      'ğ': 'Ğ',
      'ı': 'I',
      'i': 'İ',
      'ö': 'Ö',
      'ş': 'Ş',
      'ü': 'Ü',
    };

    return turkishLowerToUpper[firstChar] ?? firstChar.toUpperCase();
  }

  /// Türkçe'ye duyarlı tamamını büyük harfe çevirme
  /// 'i'->'İ', 'ı'->'I', 'ş'->'Ş', 'ğ'->'Ğ', 'ü'->'Ü', 'ö'->'Ö', 'ç'->'Ç'
  static String toUpperCaseTr(String text) {
    if (text.isEmpty) return text;
    final replaced = text
        .replaceAll('i', 'İ')
        .replaceAll('ı', 'I')
        .replaceAll('ş', 'Ş')
        .replaceAll('ğ', 'Ğ')
        .replaceAll('ü', 'Ü')
        .replaceAll('ö', 'Ö')
        .replaceAll('ç', 'Ç');
    return replaced.toUpperCase();
  }

  /// Türkçe'ye duyarlı tamamını küçük harfe çevirme
  /// 'İ'->'i', 'I'->'ı', 'Ş'->'ş', 'Ğ'->'ğ', 'Ü'->'ü', 'Ö'->'ö', 'Ç'->'ç'
  static String toLowerCaseTr(String text) {
    if (text.isEmpty) return text;
    final replaced = text
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .replaceAll('Ş', 'ş')
        .replaceAll('Ğ', 'ğ')
        .replaceAll('Ü', 'ü')
        .replaceAll('Ö', 'ö')
        .replaceAll('Ç', 'ç');
    return replaced.toLowerCase();
  }

  /// Arama ve kıyaslama için normalizasyon (Türkçe destekli küçük harf + trim)
  static String normalizeForSearchTr(String text) {
    if (text.isEmpty) return '';
    final lowered = toLowerCaseTr(text);
    // Fazla boşlukları sadeleştir
    final collapsed = lowered.replaceAll(RegExp(r'\s+'), ' ').trim();
    return collapsed;
  }

  /// Türkçe'ye duyarlı ilk karakter (avatar vb. için)
  static String initialTr(String text, {String fallback = '?'}) {
    if (text.isEmpty) return fallback;
    final first = text[0];
    // Önce özel karakterleri büyük sürümlerine çevir, sonra tek karakter dön
    return toUpperCaseTr(first);
  }

  /// E-posta için özel formatlama (küçük harf)
  static String formatEmail(String email) {
    return email.toLowerCase().trim();
  }

  /// Telefon numarası için temizleme
  static String formatPhone(String phone) {
    return phone.trim();
  }

  /// Adres için formatlama
  static String formatAddress(String address) {
    return capitalizeWords(address.trim());
  }

  /// Firma adı için formatlama
  static String formatCompanyName(String companyName) {
    return capitalizeWords(companyName.trim());
  }

  /// İsim için formatlama
  static String formatName(String name) {
    return capitalizeWords(name.trim());
  }

  /// Vergi numarası için temizleme
  static String formatTaxNumber(String taxNumber) {
    return taxNumber.trim();
  }

  /// Ürün adı için formatlama
  static String formatProductName(String productName) {
    return capitalizeWords(productName.trim());
  }

  /// Açıklama için formatlama
  static String formatDescription(String description) {
    return capitalizeFirst(description.trim());
  }

  /// Notlar için formatlama
  static String formatNotes(String notes) {
    return capitalizeFirst(notes.trim());
  }

  // ===== Numeric display helpers =====
  /// Quantity gibi ondalık hesaplanan ama ekranda tam sayı gösterilecek alanlar için.
  static String formatQuantity(num value) {
    return value.toStringAsFixed(0);
  }

  /// Yüzdelik değerleri tam sayı gösterimi için (örn. %10.4 -> %10)
  static String formatPercent(double? value) {
    if (value == null) return '-';
    return value.toStringAsFixed(0);
  }

  /// Para formatı: iki ondalık basamaklı gösterim.
  static String formatMoney(double value, {int fractionDigits = 2}) {
    return value.toStringAsFixed(fractionDigits);
  }
}

/// Otomatik büyük harf başlatma için InputFormatter
class CapitalizeWordsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    // Sadece yeni karakter eklendiğinde format yap
    if (newValue.text.length > oldValue.text.length) {
      final lastChar = newValue.text[newValue.text.length - 1];

      // Boşluk veya noktalama işaretinden sonra büyük harf yap
      if (newValue.text.length == 1 ||
          (newValue.text.length > 1 &&
              (oldValue.text.endsWith(' ') ||
                  oldValue.text.endsWith('.') ||
                  oldValue.text.endsWith('!') ||
                  oldValue.text.endsWith('?')))) {
        final capitalizedChar = TextFormatter._capitalizeFirstChar(lastChar);
        final newText =
            newValue.text.substring(0, newValue.text.length - 1) +
            capitalizedChar;

        return newValue.copyWith(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
      }
    }

    return newValue;
  }
}

/// Sadece ilk harfi büyük yapan InputFormatter
class CapitalizeFirstFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    // Sadece ilk karakter için
    if (newValue.text.length == 1) {
      final capitalizedChar = TextFormatter._capitalizeFirstChar(
        newValue.text[0],
      );

      return newValue.copyWith(
        text: capitalizedChar,
        selection: TextSelection.collapsed(offset: 1),
      );
    }

    return newValue;
  }
}

/// E-posta için küçük harf formatter
class LowerCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toLowerCase(),
      selection: newValue.selection,
    );
  }
}

/// Fatura numarası için özel formatter
class InvoiceNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Harf (TR dahil), rakam ve tire karakterlerine izin ver
    final filteredText = newValue.text.replaceAll(
      RegExp(r'[^a-zA-Z0-9\-çğıöşüÇĞİÖŞÜ]'),
      '',
    );

    final upper = TextFormatter.toUpperCaseTr(filteredText);
    return newValue.copyWith(
      text: upper,
      selection: TextSelection.collapsed(offset: upper.length),
    );
  }
}

/// Telefon numarası için özel formatter
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Sadece rakam, boşluk, parantez ve tire karakterlerine izin ver
    final filteredText = newValue.text.replaceAll(
      RegExp(r'[^0-9\s\(\)\-]'),
      '',
    );

    return newValue.copyWith(
      text: filteredText,
      selection: TextSelection.collapsed(offset: filteredText.length),
    );
  }
}

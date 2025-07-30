class TextFormatter {
  /// Her kelimenin ilk harfini büyük yapar
  static String capitalizeWords(String text) {
    if (text.isEmpty) return text;
    
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
  
  /// Sadece ilk harfi büyük yapar
  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
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
  
  /// Vergi numarası için temizleme
  static String formatTaxNumber(String taxNumber) {
    return taxNumber.trim();
  }
  
  /// Vergi dairesi için formatlama
  static String formatTaxOffice(String taxOffice) {
    return capitalizeWords(taxOffice.trim());
  }
} 
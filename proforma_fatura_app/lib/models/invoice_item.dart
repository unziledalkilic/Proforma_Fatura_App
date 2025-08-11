import 'product.dart';

class InvoiceItem {
  final String? id;
  final String? invoiceId; // Opsiyonel yapıldı, fatura kaydedilirken atanacak
  final Product product;
  final double quantity;
  final double unitPrice;
  final double? discountRate; // İndirim oranı (%)
  final double? taxRate; // KDV oranı (%)
  final String? notes;

  InvoiceItem({
    this.id,
    this.invoiceId, // Opsiyonel yapıldı
    required this.product,
    required this.quantity,
    required this.unitPrice,
    this.discountRate,
    this.taxRate,
    this.notes,
  });

  // Ara toplam (indirim öncesi)
  double get subtotal => quantity * unitPrice;

  // İndirim tutarı
  double get discountAmount {
    if (discountRate == null || discountRate == 0) return 0;
    return subtotal * (discountRate! / 100);
  }

  // İndirim sonrası tutar
  double get amountAfterDiscount => subtotal - discountAmount;

  // KDV tutarı
  double get taxAmount {
    if (taxRate == null || taxRate == 0) return 0;
    return amountAfterDiscount * (taxRate! / 100);
  }

  // Toplam tutar (KDV dahil)
  double get totalAmount => amountAfterDiscount + taxAmount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId, // SQLite için snake_case
      'product_id': product.id, // SQLite için snake_case
      'quantity': quantity,
      'unit_price': unitPrice, // SQLite için snake_case
      'discount_rate': discountRate, // SQLite için snake_case
      'tax_rate': taxRate, // SQLite için snake_case
      'notes': notes,
      'created_at': DateTime.now().toIso8601String(), // SQLite için gerekli
      'updated_at': DateTime.now().toIso8601String(), // SQLite için gerekli
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map, Product product) {
    return InvoiceItem(
      id: map['id']?.toString(),
      invoiceId: map['invoice_id']?.toString() ?? map['invoiceId']?.toString(),
      product: product,
      quantity: (map['quantity'] ?? 0.0).toDouble(),
      unitPrice: (map['unit_price'] ?? map['unitPrice'] ?? 0.0).toDouble(),
      discountRate: (map['discount_rate'] ?? map['discountRate'])?.toDouble(),
      taxRate: (map['tax_rate'] ?? map['taxRate'])?.toDouble(),
      notes: map['notes'],
    );
  }

  InvoiceItem copyWith({
    String? id,
    String? invoiceId,
    Product? product,
    double? quantity,
    double? unitPrice,
    double? discountRate,
    double? taxRate,
    String? notes,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discountRate: discountRate ?? this.discountRate,
      taxRate: taxRate ?? this.taxRate,
      notes: notes ?? this.notes,
    );
  }
}

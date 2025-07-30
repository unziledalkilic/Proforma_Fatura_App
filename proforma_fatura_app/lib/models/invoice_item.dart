import 'product.dart';

class InvoiceItem {
  final int? id;
  final int invoiceId;
  final Product product;
  final double quantity;
  final double unitPrice;
  final double? discountRate; // İndirim oranı (%)
  final double? taxRate; // KDV oranı (%)
  final String? notes;

  InvoiceItem({
    this.id,
    required this.invoiceId,
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
      'invoiceId': invoiceId,
      'productId': product.id,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'discountRate': discountRate,
      'taxRate': taxRate,
      'notes': notes,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map, Product product) {
    return InvoiceItem(
      id: map['id'],
      invoiceId: map['invoiceId'],
      product: product,
      quantity: map['quantity'].toDouble(),
      unitPrice: map['unitPrice'].toDouble(),
      discountRate: map['discountRate']?.toDouble(),
      taxRate: map['taxRate']?.toDouble(),
      notes: map['notes'],
    );
  }

  InvoiceItem copyWith({
    int? id,
    int? invoiceId,
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
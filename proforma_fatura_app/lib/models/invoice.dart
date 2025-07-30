import 'customer.dart';
import 'invoice_item.dart';

enum InvoiceStatus {
  draft,      // Taslak
  sent,       // Gönderildi
  accepted,   // Kabul edildi
  rejected,   // Reddedildi
  expired,    // Süresi doldu
}

class Invoice {
  final int? id;
  final String invoiceNumber;
  final Customer customer;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final List<InvoiceItem> items;
  final String? notes;
  final String? terms;
  final double? discountRate; // Genel indirim oranı (%)
  final InvoiceStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Invoice({
    this.id,
    required this.invoiceNumber,
    required this.customer,
    required this.invoiceDate,
    required this.dueDate,
    required this.items,
    this.notes,
    this.terms,
    this.discountRate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  // Ara toplam (tüm kalemlerin toplamı)
  double get subtotal {
    return items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  // Genel indirim tutarı
  double get discountAmount {
    if (discountRate == null || discountRate == 0) return 0;
    return subtotal * (discountRate! / 100);
  }

  // İndirim sonrası tutar
  double get amountAfterDiscount => subtotal - discountAmount;

  // Toplam KDV tutarı
  double get totalTaxAmount {
    return items.fold(0.0, (sum, item) => sum + item.taxAmount);
  }

  // Toplam tutar (KDV dahil)
  double get totalAmount => amountAfterDiscount + totalTaxAmount;

  // Toplam kalem sayısı
  int get itemCount => items.length;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'customerId': customer.id,
      'invoiceDate': invoiceDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'notes': notes,
      'terms': terms,
      'discountRate': discountRate,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map, Customer customer, List<InvoiceItem> items) {
    return Invoice(
      id: map['id'],
      invoiceNumber: map['invoiceNumber'],
      customer: customer,
      invoiceDate: DateTime.parse(map['invoiceDate']),
      dueDate: DateTime.parse(map['dueDate']),
      items: items,
      notes: map['notes'],
      terms: map['terms'],
      discountRate: map['discountRate']?.toDouble(),
      status: InvoiceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => InvoiceStatus.draft,
      ),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Invoice copyWith({
    int? id,
    String? invoiceNumber,
    Customer? customer,
    DateTime? invoiceDate,
    DateTime? dueDate,
    List<InvoiceItem>? items,
    String? notes,
    String? terms,
    double? discountRate,
    InvoiceStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customer: customer ?? this.customer,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
      discountRate: discountRate ?? this.discountRate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Fatura numarası oluşturma
  static String generateInvoiceNumber() {
    final now = DateTime.now();
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final random = (1000 + DateTime.now().millisecondsSinceEpoch % 9000).toString();
    return 'PF-$year$month$day-$random';
  }
} 
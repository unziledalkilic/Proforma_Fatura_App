import 'customer.dart';
import 'invoice_item.dart';

class Invoice {
  final String? id;
  final String invoiceNumber;
  final Customer customer;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final List<InvoiceItem> items;
  final String? notes;
  final String? terms;
  final double? discountRate; // Genel iskonto oranı (%)
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
      'invoice_number': invoiceNumber, // SQLite için snake_case
      'customer_id': customer.id, // SQLite için snake_case
      'invoice_date': invoiceDate.toIso8601String(), // SQLite için snake_case
      'due_date': dueDate.toIso8601String(), // SQLite için snake_case
      'notes': notes,
      'terms': terms,
      'discount_rate': discountRate, // SQLite için snake_case
      'created_at': createdAt.toIso8601String(), // SQLite için snake_case
      'updated_at': updatedAt.toIso8601String(), // SQLite için snake_case
    };
  }

  factory Invoice.fromMap(
    Map<String, dynamic> map,
    Customer customer,
    List<InvoiceItem> items,
  ) {
    return Invoice(
      id: map['id']?.toString(),
      invoiceNumber: map['invoice_number'] ?? map['invoiceNumber'] ?? '',
      customer: customer,
      invoiceDate: DateTime.parse(
        map['invoice_date'] ??
            map['invoiceDate'] ??
            DateTime.now().toIso8601String(),
      ),
      dueDate: DateTime.parse(
        map['due_date'] ?? map['dueDate'] ?? DateTime.now().toIso8601String(),
      ),
      items: items,
      notes: map['notes'],
      terms: map['terms'],
      discountRate: (map['discount_rate'] ?? map['discountRate'])?.toDouble(),
      createdAt: DateTime.parse(
        map['created_at'] ??
            map['createdAt'] ??
            DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        map['updated_at'] ??
            map['updatedAt'] ??
            DateTime.now().toIso8601String(),
      ),
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
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id?.toString() ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customer: customer ?? this.customer,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
      discountRate: discountRate ?? this.discountRate,
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
    final random = (1000 + DateTime.now().millisecondsSinceEpoch % 9000)
        .toString();
    return 'PF-$year$month$day-$random';
  }
}

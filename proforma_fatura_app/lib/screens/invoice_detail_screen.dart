import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/invoice.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final Invoice invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fatura Detayı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Fatura düzenleme ekranına yönlendir
            },
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              // TODO: Fatura yazdırma işlemi
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fatura Başlığı
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'FATURA',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(invoice.status),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getStatusText(invoice.status),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Fatura No:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              invoice.invoiceNumber,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Toplam:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '₺${invoice.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Tarih Bilgileri
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Fatura Tarihi',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '${invoice.invoiceDate.day}/${invoice.invoiceDate.month}/${invoice.invoiceDate.year}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vade Tarihi',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '${invoice.dueDate.day}/${invoice.dueDate.month}/${invoice.dueDate.year}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Ürün Özeti
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'Ürün Sayısı',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${invoice.items.length}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: Colors.grey[300],
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'Toplam Miktar',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${invoice.items.fold<double>(0, (sum, item) => sum + item.quantity).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: Colors.grey[300],
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'Ortalama Birim Fiyat',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₺${(invoice.items.fold<double>(0, (sum, item) => sum + item.unitPrice) / invoice.items.length).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Müşteri Bilgileri
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Müşteri Bilgileri',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      invoice.customer.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (invoice.customer.email != null) ...[
                      const SizedBox(height: 4),
                      Text(invoice.customer.email!),
                    ],
                    if (invoice.customer.phone != null) ...[
                      const SizedBox(height: 4),
                      Text(invoice.customer.phone!),
                    ],
                    if (invoice.customer.address != null) ...[
                      const SizedBox(height: 4),
                      Text(invoice.customer.address!),
                    ],
                    if (invoice.customer.taxNumber != null) ...[
                      const SizedBox(height: 4),
                      Text('Vergi No: ${invoice.customer.taxNumber}'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Ürünler
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ürünler',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Tablo başlığı
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Ürün',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Miktar',
                              style: TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Birim Fiyat',
                              style: TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Toplam',
                              style: TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...invoice.items.map((item) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (item.notes != null) ...[
                                      Text(
                                        'Not: ${item.notes!}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                    ],
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      '${item.quantity.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    Text(
                                      item.product.unit,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                                                             Expanded(
                                 child: Column(
                                   children: [
                                     Text(
                                       '₺${item.unitPrice.toStringAsFixed(2)}',
                                       style: const TextStyle(
                                         fontWeight: FontWeight.bold,
                                       ),
                                       textAlign: TextAlign.center,
                                     ),
                                     const SizedBox(height: 2),
                                     if (item.discountRate != null && item.discountRate! > 0) ...[
                                       Container(
                                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                         decoration: BoxDecoration(
                                           color: Colors.green[100],
                                           borderRadius: BorderRadius.circular(12),
                                         ),
                                         child: Text(
                                           'İndirim: %${item.discountRate!.toStringAsFixed(1)}',
                                           style: const TextStyle(
                                             fontSize: 10,
                                             color: Colors.green,
                                             fontWeight: FontWeight.bold,
                                           ),
                                         ),
                                       ),
                                     ],
                                     if (item.taxRate != null && item.taxRate! > 0) ...[
                                       const SizedBox(height: 2),
                                       Container(
                                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                         decoration: BoxDecoration(
                                           color: Colors.blue[100],
                                           borderRadius: BorderRadius.circular(12),
                                         ),
                                         child: Text(
                                           'KDV: %${item.taxRate!.toStringAsFixed(1)}',
                                           style: const TextStyle(
                                             fontSize: 10,
                                             color: Colors.blue,
                                             fontWeight: FontWeight.bold,
                                           ),
                                         ),
                                       ),
                                     ],
                                   ],
                                 ),
                               ),
                                                             Expanded(
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.end,
                                   children: [
                                     Text(
                                       '₺${item.totalAmount.toStringAsFixed(2)}',
                                       style: const TextStyle(
                                         fontWeight: FontWeight.bold,
                                         fontSize: 16,
                                       ),
                                     ),
                                   ],
                                 ),
                               ),
                            ],
                          ),
                          // Detay satırı - ara toplam, indirim, KDV
                          if (item.discountRate != null && item.discountRate! > 0 || 
                              item.taxRate != null && item.taxRate! > 0) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Ara Toplam: ₺${item.subtotal.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  if (item.discountRate != null && item.discountRate! > 0) ...[
                                    const Spacer(),
                                    Text(
                                      'İndirim: -₺${item.discountAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                  if (item.taxRate != null && item.taxRate! > 0) ...[
                                    const Spacer(),
                                    Text(
                                      'KDV: +₺${item.taxAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    )),
                    const Divider(),
                    // Toplam Bilgileri
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Ara Toplam:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '₺${invoice.subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          if (invoice.discountRate != null && invoice.discountRate! > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'İndirim (%${invoice.discountRate!.toStringAsFixed(1)}):',
                                  style: const TextStyle(color: Colors.green),
                                ),
                                Text(
                                  '-₺${invoice.discountAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'KDV Toplamı:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '₺${invoice.totalTaxAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TOPLAM:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              Text(
                                '₺${invoice.totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: AppConstants.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Notlar ve Şartlar
            if (invoice.notes != null || invoice.terms != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (invoice.notes != null) ...[
                        const Text(
                          'Notlar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(invoice.notes!),
                        if (invoice.terms != null) const SizedBox(height: 16),
                      ],
                      if (invoice.terms != null) ...[
                        const Text(
                          'Ödeme Şartları',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(invoice.terms!),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return Colors.grey;
      case InvoiceStatus.sent:
        return Colors.blue;
      case InvoiceStatus.accepted:
        return Colors.green;
      case InvoiceStatus.rejected:
        return Colors.red;
      case InvoiceStatus.expired:
        return Colors.orange;
    }
  }

  String _getStatusText(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return 'Taslak';
      case InvoiceStatus.sent:
        return 'Gönderildi';
      case InvoiceStatus.accepted:
        return 'Kabul Edildi';
      case InvoiceStatus.rejected:
        return 'Reddedildi';
      case InvoiceStatus.expired:
        return 'Süresi Doldu';
    }
  }
} 
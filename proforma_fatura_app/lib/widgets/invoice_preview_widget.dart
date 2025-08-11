import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../utils/text_formatter.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';

class InvoicePreviewWidget extends StatelessWidget {
  final Invoice invoice;
  final bool showActions;

  const InvoicePreviewWidget({
    super.key,
    required this.invoice,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Fatura Başlığı
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: const BoxDecoration(
              color: AppConstants.primaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROFORMA FATURA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      invoice.invoiceNumber,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Fatura İçeriği
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Müşteri Bilgileri
                _buildSection(
                  'Müşteri Bilgileri',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.customer.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (invoice.customer.email != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          invoice.customer.email!,
                          style: AppConstants.captionStyle,
                        ),
                      ],
                      if (invoice.customer.phone != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          invoice.customer.phone!,
                          style: AppConstants.captionStyle,
                        ),
                      ],
                      if (invoice.customer.address != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          invoice.customer.address!,
                          style: AppConstants.captionStyle,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppConstants.paddingMedium),

                // Fatura Tarihleri
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        'Fatura Tarihi',
                        '${invoice.invoiceDate.day}/${invoice.invoiceDate.month}/${invoice.invoiceDate.year}',
                        Icons.calendar_today,
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingSmall),
                    Expanded(
                      child: _buildInfoCard(
                        'Vade Tarihi',
                        '${invoice.dueDate.day}/${invoice.dueDate.month}/${invoice.dueDate.year}',
                        Icons.schedule,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppConstants.paddingMedium),

                // Fatura Kalemleri
                _buildSection(
                  'Fatura Kalemleri',
                  Column(
                    children: invoice.items
                        .map((item) => _buildInvoiceItem(item))
                        .toList(),
                  ),
                ),

                const SizedBox(height: AppConstants.paddingMedium),

                // Toplam Bilgileri
                _buildSection(
                  'Toplam Bilgileri',
                  Column(
                    children: [
                      _buildTotalRow('Ara Toplam', invoice.subtotal),
                      if (invoice.discountRate != null &&
                          invoice.discountRate! > 0)
                        _buildTotalRow(
                          'İndirim (%${invoice.discountRate!.toStringAsFixed(1)})',
                          -invoice.discountAmount,
                          isDiscount: true,
                        ),
                      _buildTotalRow('KDV Toplamı', invoice.totalTaxAmount),
                      const Divider(),
                      _buildTotalRow(
                        'TOPLAM',
                        invoice.totalAmount,
                        isTotal: true,
                      ),
                    ],
                  ),
                ),

                // Notlar ve Şartlar
                if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                  const SizedBox(height: AppConstants.paddingMedium),
                  _buildSection('Notlar', Text(invoice.notes!)),
                ],

                if (invoice.terms != null && invoice.terms!.isNotEmpty) ...[
                  const SizedBox(height: AppConstants.paddingMedium),
                  _buildSection('Ödeme Şartları', Text(invoice.terms!)),
                ],
              ],
            ),
          ),

          // Aksiyon Butonları
          if (showActions) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // PDF oluştur
                      },
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('PDF'),
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Paylaş
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Paylaş'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryColor,
          ),
        ),
        const SizedBox(height: AppConstants.paddingSmall),
        content,
      ],
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingSmall),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppConstants.primaryColor),
              const SizedBox(width: 4),
              Text(title, style: AppConstants.captionStyle),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildInvoiceItem(InvoiceItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      padding: const EdgeInsets.all(AppConstants.paddingSmall),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.product.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '₺${item.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${TextFormatter.formatQuantity(item.quantity)} ${item.product.unit} x ₺${item.unitPrice.toStringAsFixed(2)}',
            style: AppConstants.captionStyle,
          ),
          if (item.discountRate != null && item.discountRate! > 0) ...[
            const SizedBox(height: 2),
            Text(
              'İndirim: %${TextFormatter.formatPercent(item.discountRate)}',
              style: AppConstants.captionStyle.copyWith(color: Colors.green),
            ),
          ],
          if (item.taxRate != null && item.taxRate! > 0) ...[
            const SizedBox(height: 2),
            Text(
              'KDV: %${TextFormatter.formatPercent(item.taxRate)}',
              style: AppConstants.captionStyle,
            ),
          ],
          if (item.notes != null && item.notes!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text('Not: ${item.notes}', style: AppConstants.captionStyle),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    double amount, {
    bool isDiscount = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            '${isDiscount ? '-' : ''}₺${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? AppConstants.primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }
}

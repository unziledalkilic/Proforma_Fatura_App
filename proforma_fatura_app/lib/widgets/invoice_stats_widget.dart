import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/invoice.dart';

class InvoiceStatsWidget extends StatelessWidget {
  final List<Invoice> invoices;

  const InvoiceStatsWidget({super.key, required this.invoices});

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fatura İstatistikleri',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppConstants.paddingMedium),

        // Genel İstatistikler
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Toplam Fatura',
                '${invoices.length}',
                Icons.receipt,
                AppConstants.primaryColor,
              ),
            ),
            const SizedBox(width: AppConstants.paddingSmall),
            Expanded(
              child: _buildStatCard(
                'Toplam Tutar',
                '₺${stats.totalAmount.toStringAsFixed(2)}',
                Icons.attach_money,
                AppConstants.successColor,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppConstants.paddingMedium),

        // Durum İstatistikleri
        const Text(
          'Durum Dağılımı',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppConstants.paddingSmall),

        ...InvoiceStatus.values.map((status) {
          final count = stats.statusCounts[status] ?? 0;
          final percentage = invoices.isEmpty
              ? 0.0
              : (count / invoices.length) * 100;

          return _buildStatusRow(status, count, percentage);
        }),

        const SizedBox(height: AppConstants.paddingMedium),

        // Aylık İstatistikler
        if (invoices.isNotEmpty) ...[
          const Text(
            'Son 6 Ay',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          SizedBox(height: 120, child: _buildMonthlyChart(stats.monthlyData)),
        ],
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(InvoiceStatus status, int count, double percentage) {
    final color = AppConstants.invoiceStatusColors[status.name];
    final label = AppConstants.invoiceStatusLabels[status.name] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      padding: const EdgeInsets.all(AppConstants.paddingSmall),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '(${percentage.toStringAsFixed(1)}%)',
            style: AppConstants.captionStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart(Map<String, double> monthlyData) {
    final months = monthlyData.keys.toList()..sort();
    final maxAmount = monthlyData.values.isEmpty
        ? 1.0
        : monthlyData.values.reduce((a, b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: months.map((month) {
        final amount = monthlyData[month] ?? 0.0;
        final height = maxAmount > 0 ? (amount / maxAmount) * 80 : 0.0;

        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20,
                height: height,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  month,
                  style: AppConstants.captionStyle,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                child: Text(
                  '₺${amount.toStringAsFixed(0)}',
                  style: AppConstants.captionStyle,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  _InvoiceStats _calculateStats() {
    final statusCounts = <InvoiceStatus, int>{};
    final monthlyData = <String, double>{};

    double totalAmount = 0;

    for (final invoice in invoices) {
      // Durum sayıları
      statusCounts[invoice.status] = (statusCounts[invoice.status] ?? 0) + 1;

      // Toplam tutar
      totalAmount += invoice.totalAmount;

      // Aylık veriler (son 6 ay)
      final monthKey =
          '${invoice.invoiceDate.month}/${invoice.invoiceDate.year}';
      monthlyData[monthKey] =
          (monthlyData[monthKey] ?? 0) + invoice.totalAmount;
    }

    return _InvoiceStats(
      totalAmount: totalAmount,
      statusCounts: statusCounts,
      monthlyData: monthlyData,
    );
  }
}

class _InvoiceStats {
  final double totalAmount;
  final Map<InvoiceStatus, int> statusCounts;
  final Map<String, double> monthlyData;

  _InvoiceStats({
    required this.totalAmount,
    required this.statusCounts,
    required this.monthlyData,
  });
}

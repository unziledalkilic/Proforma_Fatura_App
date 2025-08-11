import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/hybrid_provider.dart';

class InvoiceTermsList extends StatelessWidget {
  final int? invoiceId; // null ise hiçbir şey göstermez
  final String title; // başlık yazısı
  final EdgeInsets? padding; // dışarıdan ayarlanabilir padding

  const InvoiceTermsList({
    super.key,
    required this.invoiceId,
    this.title = 'Ödeme ve Şartlar',
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (invoiceId == null) return const SizedBox.shrink();

    final hybrid = context.read<HybridProvider>();

    return FutureBuilder<List<String>>(
      future: hybrid.getInvoiceTermsTextByInvoiceId(invoiceId!),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink(); // istersen küçük bir progress koy
        }
        final terms = (snap.data ?? [])
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        if (terms.isEmpty) return const SizedBox.shrink();

        return Card(
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ...terms.map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      t,
                      style: const TextStyle(fontSize: 29), // bir tık büyük
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

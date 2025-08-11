import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/hybrid_provider.dart';

/// Sync durumu widget'ı - Online/Offline durumu ve senkronizasyon bilgilerini gösterir
class SyncStatusWidget extends StatelessWidget {
  final bool showDetails;
  final bool showSyncButton;

  const SyncStatusWidget({
    super.key,
    this.showDetails = true,
    this.showSyncButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<HybridProvider>(
      builder: (context, provider, child) {
        return Container(
          margin: const EdgeInsets.all(8.0),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: provider.isOnline
                ? AppConstants.successColor.withOpacity(0.1)
                : AppConstants.warningColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: provider.isOnline
                  ? AppConstants.successColor.withOpacity(0.3)
                  : AppConstants.warningColor.withOpacity(0.3),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              // Status icon
              Icon(
                provider.isOnline ? Icons.cloud_done : Icons.cloud_off,
                color: provider.isOnline
                    ? AppConstants.successColor
                    : AppConstants.warningColor,
                size: 20,
              ),
              const SizedBox(width: 8),

              // Status text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      provider.connectivityStatus,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: provider.isOnline
                            ? AppConstants.successColor
                            : AppConstants.warningColor,
                        fontSize: 12,
                      ),
                    ),
                    if (showDetails) ...[
                      if (provider.pendingSyncCount > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${provider.pendingSyncCount} bekleyen değişiklik',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppConstants.textSecondary,
                          ),
                        ),
                      ],
                      if (provider.lastSyncTime != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Son senkronizasyon: ${_formatSyncTime(provider.lastSyncTime!)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppConstants.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),

              // Sync button (varsayılan: gizli; otomatik senkron devrede)
              if (showSyncButton && provider.isOnline) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: provider.isLoading
                      ? null
                      : () => _performSync(context, provider),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppConstants.infoColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: provider.isLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppConstants.infoColor,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.sync,
                            size: 16,
                            color: AppConstants.infoColor,
                          ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _formatSyncTime(DateTime syncTime) {
    final now = DateTime.now();
    final difference = now.difference(syncTime);

    if (difference.inMinutes < 1) {
      return 'Şimdi';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else {
      return '${difference.inDays} gün önce';
    }
  }

  Future<void> _performSync(
    BuildContext context,
    HybridProvider provider,
  ) async {
    try {
      await provider.performSync();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Senkronizasyon tamamlandı'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Senkronizasyon hatası: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

/// Compact sync status widget for app bar
class CompactSyncStatusWidget extends StatelessWidget {
  const CompactSyncStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HybridProvider>(
      builder: (context, provider, child) {
        return GestureDetector(
          onTap: () => _showSyncDetails(context, provider),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: provider.isOnline
                  ? Colors.green.withOpacity(0.2)
                  : Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  provider.isOnline ? Icons.cloud_done : Icons.cloud_off,
                  color: provider.isOnline
                      ? AppConstants.successColor
                      : AppConstants.warningColor,
                  size: 16,
                ),
                const SizedBox(width: 4),
                if (provider.pendingSyncCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${provider.pendingSyncCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
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

  void _showSyncDetails(BuildContext context, HybridProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Senkronizasyon Durumu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Durum', provider.connectivityStatus),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Bekleyen işlemler',
              '${provider.pendingSyncCount}',
            ),
            const SizedBox(height: 8),
            if (provider.lastSyncTime != null)
              _buildDetailRow(
                'Son senkronizasyon',
                _formatSyncTime(provider.lastSyncTime!),
              ),
            const SizedBox(height: 16),

            // Sync stats
            if (provider.syncStats.isNotEmpty) ...[
              const Text(
                'Detaylar:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...provider.syncStats.entries.map(
                (entry) => _buildDetailRow(
                  _formatStatKey(entry.key),
                  '${entry.value}',
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
          if (provider.isOnline && !provider.isLoading)
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await provider.performSync();
              },
              child: const Text('Senkronize Et'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value),
      ],
    );
  }

  String _formatStatKey(String key) {
    switch (key) {
      case 'unsynced_customers':
        return 'Senkronize edilmemiş müşteriler';
      case 'unsynced_products':
        return 'Senkronize edilmemiş ürünler';
      case 'unsynced_invoices':
        return 'Senkronize edilmemiş faturalar';
      case 'pending_operations':
        return 'Bekleyen işlemler';
      default:
        return key;
    }
  }

  String _formatSyncTime(DateTime syncTime) {
    final now = DateTime.now();
    final difference = now.difference(syncTime);

    if (difference.inMinutes < 1) {
      return 'Şimdi';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else {
      return '${difference.inDays} gün önce';
    }
  }
}

/// Floating sync button
class SyncFloatingActionButton extends StatelessWidget {
  const SyncFloatingActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HybridProvider>(
      builder: (context, provider, child) {
        if (!provider.isOnline || provider.pendingSyncCount == 0) {
          return const SizedBox.shrink();
        }

        return FloatingActionButton(
          onPressed: provider.isLoading ? null : () => provider.performSync(),
          backgroundColor: Colors.blue,
          child: provider.isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Stack(
                  children: [
                    const Icon(Icons.sync, color: Colors.white),
                    if (provider.pendingSyncCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${provider.pendingSyncCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

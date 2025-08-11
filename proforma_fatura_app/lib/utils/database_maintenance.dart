import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import 'error_handler.dart';
import 'database_validator.dart';

/// Database maintenance ve optimization yardımcı sınıfı
class DatabaseMaintenance {
  /// Database'i optimize eder
  static Future<void> optimizeDatabase(Database db) async {
    try {
      debugPrint('🔧 Starting database optimization...');
      
      // VACUUM komutu ile database'i optimize et
      await db.execute('VACUUM');
      debugPrint('✅ Database vacuum completed');
      
      // ANALYZE komutu ile istatistikleri güncelle
      await db.execute('ANALYZE');
      debugPrint('✅ Database analyze completed');
      
      // İndeksleri yeniden oluştur
      await _rebuildIndexes(db);
      
      debugPrint('✅ Database optimization completed successfully');
    } catch (e) {
      ErrorHandler.handleDatabaseError('Database Optimization', e);
    }
  }

  /// İndeksleri yeniden oluşturur
  static Future<void> _rebuildIndexes(Database db) async {
    try {
      // Mevcut indeksleri al
      final indexes = await db.rawQuery('PRAGMA index_list(customers)');
      
      for (final index in indexes) {
        final indexName = index['name'] as String;
        if (indexName != 'sqlite_autoindex_customers_1') { // Primary key index
          await db.execute('REINDEX $indexName');
          debugPrint('🔄 Rebuilt index: $indexName');
        }
      }
      
      debugPrint('✅ Index rebuilding completed');
    } catch (e) {
      ErrorHandler.handleDatabaseError('Index Rebuilding', e);
    }
  }

  /// Orphaned records'ları temizler
  static Future<int> cleanupOrphanedRecords(Database db) async {
    int totalCleaned = 0;
    
    try {
      debugPrint('🧹 Starting orphaned records cleanup...');
      
      // Orphaned customers
      final orphanedCustomers = await db.rawQuery('''
        SELECT c.id FROM customers c 
        LEFT JOIN users u ON c.user_id = u.id 
        WHERE u.id IS NULL
      ''');
      
      for (final customer in orphanedCustomers) {
        final customerId = customer['id'] as int;
        await db.delete('customers', where: 'id = ?', whereArgs: [customerId]);
        totalCleaned++;
        debugPrint('🗑️ Cleaned orphaned customer: $customerId');
      }
      
      // Orphaned products
      final orphanedProducts = await db.rawQuery('''
        SELECT p.id FROM products p 
        LEFT JOIN users u ON p.user_id = u.id 
        WHERE u.id IS NULL
      ''');
      
      for (final product in orphanedProducts) {
        final productId = product['id'] as int;
        await db.delete('products', where: 'id = ?', whereArgs: [productId]);
        totalCleaned++;
        debugPrint('🗑️ Cleaned orphaned product: $productId');
      }
      
      // Orphaned invoices
      final orphanedInvoices = await db.rawQuery('''
        SELECT i.id FROM invoices i 
        LEFT JOIN users u ON i.user_id = u.id 
        WHERE u.id IS NULL
      ''');
      
      for (final invoice in orphanedInvoices) {
        final invoiceId = invoice['id'] as int;
        // Önce invoice items'ları sil
        await db.delete('invoice_items', where: 'invoice_id = ?', whereArgs: [invoiceId]);
        await db.delete('invoices', where: 'id = ?', whereArgs: [invoiceId]);
        totalCleaned++;
        debugPrint('🗑️ Cleaned orphaned invoice: $invoiceId');
      }
      
      // Orphaned invoice items
      final orphanedInvoiceItems = await db.rawQuery('''
        SELECT ii.id FROM invoice_items ii 
        LEFT JOIN invoices i ON ii.invoice_id = i.id 
        WHERE i.id IS NULL
      ''');
      
      for (final item in orphanedInvoiceItems) {
        final itemId = item['id'] as int;
        await db.delete('invoice_items', where: 'id = ?', whereArgs: [itemId]);
        totalCleaned++;
        debugPrint('🗑️ Cleaned orphaned invoice item: $itemId');
      }
      
      debugPrint('✅ Orphaned records cleanup completed. Total cleaned: $totalCleaned');
      return totalCleaned;
    } catch (e) {
      ErrorHandler.handleDatabaseError('Orphaned Records Cleanup', e);
      return 0;
    }
  }

  /// Duplicate records'ları temizler
  static Future<int> cleanupDuplicateRecords(Database db) async {
    int totalCleaned = 0;
    
    try {
      debugPrint('🧹 Starting duplicate records cleanup...');
      
      // Duplicate customers by email
      final duplicateCustomers = await db.rawQuery('''
        SELECT email, COUNT(*) as cnt, MIN(id) as keep_id
        FROM customers 
        WHERE email IS NOT NULL AND email != ''
        GROUP BY email 
        HAVING cnt > 1
      ''');
      
      for (final duplicate in duplicateCustomers) {
        final email = duplicate['email'] as String;
        final keepId = duplicate['keep_id'] as int;
        
        // Keep the first record, delete others
        final deletedCount = await db.delete(
          'customers',
          where: 'email = ? AND id != ?',
          whereArgs: [email, keepId],
        );
        
        totalCleaned += deletedCount;
        debugPrint('🗑️ Cleaned $deletedCount duplicate customers for email: $email');
      }
      
      // Duplicate products by name and user_id
      final duplicateProducts = await db.rawQuery('''
        SELECT name, user_id, COUNT(*) as cnt, MIN(id) as keep_id
        FROM products 
        GROUP BY name, user_id 
        HAVING cnt > 1
      ''');
      
      for (final duplicate in duplicateProducts) {
        final name = duplicate['name'] as String;
        final userId = duplicate['user_id'] as int;
        final keepId = duplicate['keep_id'] as int;
        
        // Keep the first record, delete others
        final deletedCount = await db.delete(
          'products',
          where: 'name = ? AND user_id = ? AND id != ?',
          whereArgs: [name, userId, keepId],
        );
        
        totalCleaned += deletedCount;
        debugPrint('🗑️ Cleaned $deletedCount duplicate products for name: $name');
      }
      
      debugPrint('✅ Duplicate records cleanup completed. Total cleaned: $totalCleaned');
      return totalCleaned;
    } catch (e) {
      ErrorHandler.handleDatabaseError('Duplicate Records Cleanup', e);
      return 0;
    }
  }

  /// Eski sync log kayıtlarını temizler
  static Future<int> cleanupOldSyncLogs(Database db, {int daysToKeep = 30}) async {
    try {
      debugPrint('🧹 Starting old sync logs cleanup...');
      
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final cutoffString = cutoffDate.toIso8601String();
      
      final result = await db.delete(
        'sync_log',
        where: 'timestamp < ? AND synced = 1',
        whereArgs: [cutoffString],
      );
      
      debugPrint('✅ Cleaned $result old sync log records');
      return result;
    } catch (e) {
      ErrorHandler.handleDatabaseError('Old Sync Logs Cleanup', e);
      return 0;
    }
  }

  /// Database boyutunu küçültür
  static Future<void> shrinkDatabase(Database db) async {
    try {
      debugPrint('📦 Starting database shrinking...');
      
      // VACUUM komutu ile database'i sıkıştır
      await db.execute('VACUUM');
      debugPrint('✅ Database shrinking completed');
      
      // WAL mode'u optimize et
      await db.execute('PRAGMA wal_checkpoint(TRUNCATE)');
      debugPrint('✅ WAL checkpoint completed');
      
    } catch (e) {
      ErrorHandler.handleDatabaseError('Database Shrinking', e);
    }
  }

  /// Database istatistiklerini günceller
  static Future<void> updateDatabaseStatistics(Database db) async {
    try {
      debugPrint('📊 Updating database statistics...');
      
      // Tüm tablolar için istatistikleri güncelle
      final tables = ['users', 'customers', 'products', 'invoices', 'invoice_items', 'company_info'];
      
      for (final table in tables) {
        await db.execute('ANALYZE $table');
        debugPrint('📊 Updated statistics for table: $table');
      }
      
      debugPrint('✅ Database statistics update completed');
    } catch (e) {
      ErrorHandler.handleDatabaseError('Database Statistics Update', e);
    }
  }

  /// Database integrity check'i çalıştırır
  static Future<bool> checkDatabaseIntegrity(Database db) async {
    try {
      debugPrint('🔍 Checking database integrity...');
      
      final result = await db.rawQuery('PRAGMA integrity_check');
      
      if (result.isNotEmpty && result.first['integrity_check'] == 'ok') {
        debugPrint('✅ Database integrity check passed');
        return true;
      } else {
        debugPrint('❌ Database integrity check failed: $result');
        return false;
      }
    } catch (e) {
      ErrorHandler.handleDatabaseError('Database Integrity Check', e);
      return false;
    }
  }

  /// Kapsamlı database maintenance çalıştırır
  static Future<Map<String, dynamic>> runFullMaintenance(Database db) async {
    final results = <String, dynamic>{};
    
    try {
      debugPrint('🔧 Starting full database maintenance...');
      
      // Integrity check
      results['integrity_check'] = await checkDatabaseIntegrity(db);
      
      // Cleanup operations
      results['orphaned_records_cleaned'] = await cleanupOrphanedRecords(db);
      results['duplicate_records_cleaned'] = await cleanupDuplicateRecords(db);
      results['old_sync_logs_cleaned'] = await cleanupOldSyncLogs(db);
      
      // Optimization
      await optimizeDatabase(db);
      await updateDatabaseStatistics(db);
      await shrinkDatabase(db);
      
      // Final validation
      final validationResults = await DatabaseValidator.runFullValidation(db);
      results['post_maintenance_validation'] = validationResults;
      
      debugPrint('✅ Full database maintenance completed successfully');
      return results;
    } catch (e) {
      ErrorHandler.handleDatabaseError('Full Database Maintenance', e);
      return {'error': e.toString()};
    }
  }

  /// Maintenance sonuçlarını raporlar
  static void reportMaintenanceResults(Map<String, dynamic> results) {
    debugPrint('🔧 Database Maintenance Report:');
    debugPrint('================================');
    
    for (final entry in results.entries) {
      if (entry.value is Map) {
        debugPrint('${entry.key}:');
        final subMap = entry.value as Map;
        for (final subEntry in subMap.entries) {
          debugPrint('  ${subEntry.key}: ${subEntry.value}');
        }
      } else {
        debugPrint('${entry.key}: ${entry.value}');
      }
    }
    
    debugPrint('================================');
  }
}

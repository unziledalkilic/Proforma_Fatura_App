import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import 'error_handler.dart';

/// Database validation ve integrity check yardımcı sınıfı
class DatabaseValidator {
  /// Tablo yapısını doğrular
  static Future<bool> validateTableStructure(
    Database db,
    String tableName,
  ) async {
    try {
      final result = await db.rawQuery('PRAGMA table_info($tableName)');
      if (result.isEmpty) {
        ErrorHandler.handleDatabaseError(
          'Table Structure Validation',
          'Table $tableName not found',
        );
        return false;
      }

      debugPrint(
        '✅ Table $tableName structure validated: ${result.length} columns',
      );
      return true;
    } catch (e) {
      ErrorHandler.handleDatabaseError('Table Structure Validation', e);
      return false;
    }
  }

  /// Foreign key constraint'leri kontrol eder
  static Future<bool> validateForeignKeys(Database db, String tableName) async {
    try {
      final result = await db.rawQuery('PRAGMA foreign_key_list($tableName)');
      debugPrint(
        '🔗 Table $tableName has ${result.length} foreign key constraints',
      );
      return true;
    } catch (e) {
      ErrorHandler.handleDatabaseError('Foreign Key Validation', e);
      return false;
    }
  }

  /// Veri tutarlılığını kontrol eder
  static Future<Map<String, int>> validateDataIntegrity(Database db) async {
    final results = <String, int>{};

    try {
      // Orphaned records kontrolü
      final orphanedCustomers = await db.rawQuery('''
        SELECT COUNT(*) as count FROM customers c 
        LEFT JOIN users u ON c.user_id = u.id 
        WHERE u.id IS NULL
      ''');
      results['orphaned_customers'] = orphanedCustomers.first['count'] as int;

      final orphanedProducts = await db.rawQuery('''
        SELECT COUNT(*) as count FROM products p 
        LEFT JOIN users u ON p.user_id = u.id 
        WHERE u.id IS NULL
      ''');
      results['orphaned_products'] = orphanedProducts.first['count'] as int;

      final orphanedInvoices = await db.rawQuery('''
        SELECT COUNT(*) as count FROM invoices i 
        LEFT JOIN users u ON i.user_id = u.id 
        WHERE u.id IS NULL
      ''');
      results['orphaned_invoices'] = orphanedInvoices.first['count'] as int;

      final orphanedInvoiceItems = await db.rawQuery('''
        SELECT COUNT(*) as count FROM invoice_items ii 
        LEFT JOIN invoices i ON ii.invoice_id = i.id 
        WHERE i.id IS NULL
      ''');
      results['orphaned_invoice_items'] =
          orphanedInvoiceItems.first['count'] as int;

      debugPrint('🔍 Data integrity check completed: $results');
      return results;
    } catch (e) {
      ErrorHandler.handleDatabaseError('Data Integrity Validation', e);
      return {};
    }
  }

  /// Senkronizasyon durumunu kontrol eder
  static Future<Map<String, int>> validateSyncStatus(Database db) async {
    final results = <String, int>{};

    try {
      final unsyncedUsers = await db.rawQuery(
        'SELECT COUNT(*) as count FROM users WHERE firebase_synced = 0',
      );
      results['unsynced_users'] = unsyncedUsers.first['count'] as int;

      final unsyncedCustomers = await db.rawQuery(
        'SELECT COUNT(*) as count FROM customers WHERE firebase_synced = 0',
      );
      results['unsynced_customers'] = unsyncedCustomers.first['count'] as int;

      final unsyncedProducts = await db.rawQuery(
        'SELECT COUNT(*) as count FROM products WHERE firebase_synced = 0',
      );
      results['unsynced_products'] = unsyncedProducts.first['count'] as int;

      final unsyncedInvoices = await db.rawQuery(
        'SELECT COUNT(*) as count FROM invoices WHERE firebase_synced = 0',
      );
      results['unsynced_invoices'] = unsyncedInvoices.first['count'] as int;

      final pendingSyncOps = await db.rawQuery(
        'SELECT COUNT(*) as count FROM sync_log WHERE synced = 0',
      );
      results['pending_sync_operations'] = pendingSyncOps.first['count'] as int;

      debugPrint('🔄 Sync status validation completed: $results');
      return results;
    } catch (e) {
      ErrorHandler.handleDatabaseError('Sync Status Validation', e);
      return {};
    }
  }

  /// ID tutarlılığını kontrol eder
  static Future<Map<String, int>> validateIdConsistency(Database db) async {
    final results = <String, int>{};

    try {
      // Firebase ID olan ama SQLite ID olmayan kayıtlar
      final invalidFirebaseIds = await db.rawQuery('''
        SELECT COUNT(*) as count FROM customers 
        WHERE firebase_id IS NOT NULL AND firebase_id != '' 
        AND id IS NULL
      ''');
      results['invalid_firebase_ids'] =
          invalidFirebaseIds.first['count'] as int;

      // Duplicate Firebase ID'ler
      final duplicateFirebaseIds = await db.rawQuery('''
        SELECT COUNT(*) as count FROM (
          SELECT firebase_id, COUNT(*) as cnt 
          FROM customers 
          WHERE firebase_id IS NOT NULL AND firebase_id != ''
          GROUP BY firebase_id 
          HAVING cnt > 1
        )
      ''');
      results['duplicate_firebase_ids'] =
          duplicateFirebaseIds.first['count'] as int;

      debugPrint('🆔 ID consistency validation completed: $results');
      return results;
    } catch (e) {
      ErrorHandler.handleDatabaseError('ID Consistency Validation', e);
      return {};
    }
  }

  /// Database performansını test eder
  static Future<Map<String, Duration>> testDatabasePerformance(
    Database db,
  ) async {
    final results = <String, Duration>{};

    try {
      // Select performance test
      final selectStart = DateTime.now();
      await db.rawQuery('SELECT COUNT(*) FROM customers');
      results['select_performance'] = DateTime.now().difference(selectStart);

      // Insert performance test
      final insertStart = DateTime.now();
      await db.insert('customers', {
        'name': 'Test Customer',
        'email': 'test@test.com',
        'user_id': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      results['insert_performance'] = DateTime.now().difference(insertStart);

      // Clean up test data
      await db.delete(
        'customers',
        where: 'email = ?',
        whereArgs: ['test@test.com'],
      );

      debugPrint('⏱️ Database performance test completed: $results');
      return results;
    } catch (e) {
      ErrorHandler.handleDatabaseError('Database Performance Test', e);
      return {};
    }
  }

  /// Tüm validasyonları çalıştırır
  static Future<Map<String, dynamic>> runFullValidation(Database db) async {
    final validationResults = <String, dynamic>{};

    try {
      debugPrint('🔍 Starting full database validation...');

      // Table structure validation
      final tables = [
        'users',
        'customers',
        'products',
        'invoices',
        'invoice_items',
        'company_info',
      ];
      for (final table in tables) {
        validationResults['table_$table'] = await validateTableStructure(
          db,
          table,
        );
        await validateForeignKeys(db, table);
      }

      // Data integrity validation
      validationResults['data_integrity'] = await validateDataIntegrity(db);

      // Sync status validation
      validationResults['sync_status'] = await validateSyncStatus(db);

      // ID consistency validation
      validationResults['id_consistency'] = await validateIdConsistency(db);

      // Performance test
      validationResults['performance'] = await testDatabasePerformance(db);

      debugPrint('✅ Full database validation completed successfully');
      return validationResults;
    } catch (e) {
      ErrorHandler.handleDatabaseError('Full Database Validation', e);
      return {'error': e.toString()};
    }
  }

  /// Validation sonuçlarını raporlar
  static void reportValidationResults(Map<String, dynamic> results) {
    debugPrint('📊 Database Validation Report:');
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

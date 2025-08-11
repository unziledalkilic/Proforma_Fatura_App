import 'package:sqflite/sqflite.dart';

/// ID dönüşüm yardımcı sınıfı
/// SQLite ve Firebase arasındaki ID dönüşümlerini güvenli hale getirir
class IdConverter {
  /// String ID'yi güvenli şekilde int'e çevirir
  /// SQLite için kullanılır
  static int? stringToInt(String? stringId) {
    if (stringId == null || stringId.isEmpty) return null;
    return int.tryParse(stringId);
  }

  /// String ID'yi güvenli şekilde int'e çevirir, null ise varsayılan değer döner
  static int stringToIntWithDefault(String? stringId, {int defaultValue = 0}) {
    if (stringId == null || stringId.isEmpty) return defaultValue;
    return int.tryParse(stringId) ?? defaultValue;
  }

  /// int ID'yi String'e çevirir
  /// Firebase için kullanılır
  static String? intToString(int? intId) {
    if (intId == null) return null;
    return intId.toString();
  }

  /// int ID'yi String'e çevirir, null ise varsayılan değer döner
  static String intToStringWithDefault(int? intId, {String defaultValue = ''}) {
    if (intId == null) return defaultValue;
    return intId.toString();
  }

  /// Mixed ID'yi String'e çevirir (int veya String olabilir)
  static String? mixedToString(dynamic id) {
    if (id == null) return null;
    if (id is String) return id;
    if (id is int) return id.toString();
    return id.toString();
  }

  /// Mixed ID'yi int'e çevirir (int veya String olabilir)
  static int? mixedToInt(dynamic id) {
    if (id == null) return null;
    if (id is int) return id;
    if (id is String) return int.tryParse(id);
    return int.tryParse(id.toString());
  }

  /// Firebase ID'nin geçerli olup olmadığını kontrol eder
  static bool isValidFirebaseId(String? id) {
    return id != null && id.isNotEmpty && id != '0';
  }

  /// SQLite ID'nin geçerli olup olmadığını kontrol eder
  static bool isValidSQLiteId(int? id) {
    return id != null && id > 0;
  }

  /// Geçici ID oluşturur (yeni kayıtlar için)
  static String generateTempId() {
    return 'temp_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// ID'nin geçici olup olmadığını kontrol eder
  static bool isTempId(String? id) {
    return id != null && id.startsWith('temp_');
  }

  /// SQLite'dan gelen Map'teki ID'leri String'e çevirir
  static Map<String, dynamic> convertSqliteMap(Map<String, dynamic> map) {
    final convertedMap = Map<String, dynamic>.from(map);

    // ID alanlarını String'e çevir
    if (convertedMap['id'] is int) {
      convertedMap['id'] = convertedMap['id'].toString();
    }

    // Foreign key alanlarını String'e çevir
    if (convertedMap['user_id'] is int) {
      convertedMap['user_id'] = convertedMap['user_id'].toString();
    }
    if (convertedMap['customer_id'] is int) {
      convertedMap['customer_id'] = convertedMap['customer_id'].toString();
    }
    if (convertedMap['product_id'] is int) {
      convertedMap['product_id'] = convertedMap['product_id'].toString();
    }
    if (convertedMap['invoice_id'] is int) {
      convertedMap['invoice_id'] = convertedMap['invoice_id'].toString();
    }

    return convertedMap;
  }

  /// Firebase ID'den SQLite ID'yi bulur
  static Future<int?> findSqliteIdByFirebaseId(
    Database db,
    String tableName,
    String firebaseId,
  ) async {
    final List<Map<String, dynamic>> result = await db.query(
      tableName,
      columns: ['id'],
      where: 'firebase_id = ?',
      whereArgs: [firebaseId],
    );

    if (result.isNotEmpty) {
      return result.first['id'] as int;
    }
    return null;
  }

  /// SQLite ID'den Firebase ID'yi bulur
  static Future<String?> findFirebaseIdBySqliteId(
    Database db,
    String tableName,
    int sqliteId,
  ) async {
    final List<Map<String, dynamic>> result = await db.query(
      tableName,
      columns: ['firebase_id'],
      where: 'id = ?',
      whereArgs: [sqliteId],
    );

    if (result.isNotEmpty) {
      return result.first['firebase_id'] as String?;
    }
    return null;
  }

  /// Toplu ID dönüşümü için yardımcı metod
  static List<String> convertIntIdsToStrings(List<int> intIds) {
    return intIds.map((id) => id.toString()).toList();
  }

  /// Toplu String ID dönüşümü için yardımcı metod
  static List<int?> convertStringIdsToInts(List<String> stringIds) {
    return stringIds.map((id) => stringToInt(id)).toList();
  }

  /// ID listesindeki geçersiz ID'leri filtreler
  static List<String> filterValidFirebaseIds(List<String> ids) {
    return ids.where((id) => isValidFirebaseId(id)).toList();
  }

  /// ID listesindeki geçersiz ID'leri filtreler
  static List<int> filterValidSQLiteIds(List<int> ids) {
    return ids.where((id) => isValidSQLiteId(id)).toList();
  }

  /// ID çakışması olup olmadığını kontrol eder
  static bool hasIdConflict(String? firebaseId, int? sqliteId) {
    if (firebaseId == null || sqliteId == null) return false;

    // Firebase ID'nin SQLite ID'ye dönüştürülebilir olup olmadığını kontrol et
    final convertedSqliteId = stringToInt(firebaseId);
    return convertedSqliteId == sqliteId;
  }

  /// Güvenli ID eşleştirme
  static Map<String, int> createIdMapping(
    List<String> firebaseIds,
    List<int> sqliteIds,
  ) {
    final mapping = <String, int>{};

    for (int i = 0; i < firebaseIds.length && i < sqliteIds.length; i++) {
      if (isValidFirebaseId(firebaseIds[i]) && isValidSQLiteId(sqliteIds[i])) {
        mapping[firebaseIds[i]] = sqliteIds[i];
      }
    }

    return mapping;
  }
}

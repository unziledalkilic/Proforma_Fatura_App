import '../models/company_info.dart';
import 'postgres_service.dart';

class CompanyService {
  final PostgresService _postgresService = PostgresService();

  // Firma bilgilerini getir
  Future<CompanyInfo?> getCompanyInfo() async {
    if (!_postgresService.isConnected) return null;
    try {
      final results = await _postgresService.connection!.query(
        'SELECT * FROM company_info LIMIT 1',
      );

      if (results.isNotEmpty) {
        final row = results[0];
        return CompanyInfo.fromMap({
          'id': row[0],
          'name': row[1],
          'address': row[2],
          'phone': row[3],
          'email': row[4],
          'website': row[5],
          'tax_number': row[6],
          'tax_office': row[7],
          'logo': row[8],
          'created_at': row[9].toString(),
          'updated_at': row[10].toString(),
        });
      }
      return null;
    } catch (e) {
      print('❌ Firma bilgileri getirme hatası: $e');
      rethrow;
    }
  }

  // Firma bilgilerini güncelle
  Future<bool> updateCompanyInfo(CompanyInfo companyInfo) async {
    if (!_postgresService.isConnected) return false;
    try {
      final results = await _postgresService.connection!.query(
        '''
        UPDATE company_info 
        SET name = @name, address = @address, phone = @phone, email = @email, 
            website = @website, tax_number = @taxNumber, tax_office = @taxOffice, 
            logo = @logo, updated_at = CURRENT_TIMESTAMP
        WHERE id = @id
        ''',
        substitutionValues: {
          'name': companyInfo.name,
          'address': companyInfo.address,
          'phone': companyInfo.phone,
          'email': companyInfo.email,
          'website': companyInfo.website,
          'taxNumber': companyInfo.taxNumber,
          'taxOffice': companyInfo.taxOffice,
          'logo': companyInfo.logo,
          'id': companyInfo.id,
        },
      );

      return results.isNotEmpty;
    } catch (e) {
      print('❌ Firma bilgileri güncelleme hatası: $e');
      return false;
    }
  }

  // Firma bilgilerini oluştur
  Future<bool> createCompanyInfo(CompanyInfo companyInfo) async {
    if (!_postgresService.isConnected) return false;
    try {
      final results = await _postgresService.connection!.query(
        '''
        INSERT INTO company_info (name, address, phone, email, website, tax_number, tax_office, logo)
        VALUES (@name, @address, @phone, @email, @website, @taxNumber, @taxOffice, @logo)
        RETURNING id
        ''',
        substitutionValues: {
          'name': companyInfo.name,
          'address': companyInfo.address,
          'phone': companyInfo.phone,
          'email': companyInfo.email,
          'website': companyInfo.website,
          'taxNumber': companyInfo.taxNumber,
          'taxOffice': companyInfo.taxOffice,
          'logo': companyInfo.logo,
        },
      );

      return results.isNotEmpty;
    } catch (e) {
      print('❌ Firma bilgileri oluşturma hatası: $e');
      return false;
    }
  }
} 
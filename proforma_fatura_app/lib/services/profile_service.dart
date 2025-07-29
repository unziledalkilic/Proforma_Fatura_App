import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class ProfileService {
  static final _supabase = Supabase.instance.client;

  // Kullanıcının profilini getir
  static Future<Profile?> getProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Kullanıcı giriş yapmamış');

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .single();

      return Profile.fromJson(response);
    } catch (e) {
      if (e.toString().contains('No rows found')) {
        return null; // Profil henüz oluşturulmamış
      }
      print('❌ Profil alınamadı: $e');
      throw Exception('Profil yüklenirken hata oluştu: $e');
    }
  }

  // Profil oluştur veya güncelle
  static Future<Profile> upsertProfile(Profile profile) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Kullanıcı giriş yapmamış');

      final profileData = profile.toInsertJson();
      profileData['user_id'] = userId;

      final response = await _supabase
          .from('profiles')
          .upsert(profileData, onConflict: 'user_id')
          .select()
          .single();

      return Profile.fromJson(response);
    } catch (e) {
      print('❌ Profil kaydedilemedi: $e');
      throw Exception('Profil kaydedilirken hata oluştu: $e');
    }
  }

  // Profil güncelle
  static Future<Profile> updateProfile(Profile profile) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Kullanıcı giriş yapmamış');

      final response = await _supabase
          .from('profiles')
          .update(profile.toUpdateJson())
          .eq('id', profile.id)
          .eq('user_id', userId)
          .select()
          .single();

      return Profile.fromJson(response);
    } catch (e) {
      print('❌ Profil güncellenemedi: $e');
      throw Exception('Profil güncellenirken hata oluştu: $e');
    }
  }

  // Şirket ayarlarını getir
  static Future<CompanySettings?> getCompanySettings() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Kullanıcı giriş yapmamış');

      final response = await _supabase
          .from('company_settings')
          .select()
          .eq('user_id', userId)
          .single();

      return CompanySettings.fromJson(response);
    } catch (e) {
      if (e.toString().contains('No rows found')) {
        return null; // Ayarlar henüz oluşturulmamış
      }
      print('❌ Şirket ayarları alınamadı: $e');
      throw Exception('Şirket ayarları yüklenirken hata oluştu: $e');
    }
  }

  // Şirket ayarlarını oluştur veya güncelle
  static Future<CompanySettings> upsertCompanySettings(
      CompanySettings settings) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Kullanıcı giriş yapmamış');

      final settingsData = settings.toInsertJson();
      settingsData['user_id'] = userId;

      final response = await _supabase
          .from('company_settings')
          .upsert(settingsData, onConflict: 'user_id')
          .select()
          .single();

      return CompanySettings.fromJson(response);
    } catch (e) {
      print('❌ Şirket ayarları kaydedilemedi: $e');
      throw Exception('Şirket ayarları kaydedilirken hata oluştu: $e');
    }
  }

  // Şirket ayarlarını güncelle
  static Future<CompanySettings> updateCompanySettings(
      CompanySettings settings) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Kullanıcı giriş yapmamış');

      final response = await _supabase
          .from('company_settings')
          .update(settings.toUpdateJson())
          .eq('id', settings.id)
          .eq('user_id', userId)
          .select()
          .single();

      return CompanySettings.fromJson(response);
    } catch (e) {
      print('❌ Şirket ayarları güncellenemedi: $e');
      throw Exception('Şirket ayarları güncellenirken hata oluştu: $e');
    }
  }

  // Varsayılan şirket ayarlarını oluştur
  static CompanySettings getDefaultCompanySettings() {
    return CompanySettings(
      id: '',
      userId: '',
      companyLogoUrl: null,
      invoiceTitle: 'PROFORMA FATURA',
      invoiceFooter: null,
      defaultCurrency: 'TL',
      defaultLanguage: 'tr',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Kullanıcı bilgilerini auth.users tablosundan al
  static Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      return {
        'id': user.id,
        'email': user.email,
        'created_at': user.createdAt?.toString(),
      };
    } catch (e) {
      print('❌ Kullanıcı bilgileri alınamadı: $e');
      return null;
    }
  }
}

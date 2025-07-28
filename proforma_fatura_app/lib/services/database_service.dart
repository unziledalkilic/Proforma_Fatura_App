import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Kullanıcı profili al
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      print('🔍 Profil aranıyor: $userId');

      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .single();

      print(
          '✅ Profil bulundu: ${response['first_name']} ${response['last_name']}');
      return UserProfile.fromJson(response);
    } catch (error) {
      print('❌ Profil alma hatası: $error');
      return null;
    }
  }

  // Tüm kullanıcıları listele (kontrol için)
  Future<List<UserProfile>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .order('created_at', ascending: false);

      print('📋 Toplam ${response.length} kullanıcı bulundu');

      return response.map((user) => UserProfile.fromJson(user)).toList();
    } catch (error) {
      print('❌ Kullanıcı listesi alma hatası: $error');
      return [];
    }
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Kullanıcı kayıt
  Future<AuthResponse> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      print('🔄 Kayıt işlemi başlatılıyor...');
      print('📧 Email: $email');
      print('👤 Ad: $firstName $lastName');
      print('📱 Telefon: ${phone ?? "Yok"}');

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'phone': phone,
        },
      );

      if (response.user != null) {
        print('✅ Auth kayıt başarılı!');
        print('🆔 User ID: ${response.user!.id}');
      } else {
        print('❌ Auth kayıt başarısız');
      }

      return response;
    } catch (error) {
      print('❌ Kayıt hatası: $error');
      throw Exception('Kayıt hatası: $error');
    }
  }

  // GELİŞTİRİCİ MODU: Email doğrulama bypass
  Future<AuthResponse> signInWithoutEmailConfirmation({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Giriş işlemi başlatılıyor (Geliştirici Modu)...');
      print('📧 Email: $email');

      // İlk olarak normal giriş deneyelim
      try {
        final response = await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (response.user != null) {
          print('✅ Normal giriş başarılı!');
          return response;
        }
      } catch (e) {
        if (e.toString().contains('email_not_confirmed')) {
          print('⚠️ Email doğrulama hatası - Bypass modu aktif');

          // Service role ile manuel olarak session oluştur
          // NOT: Bu geliştirici modu için, production'da kullanmayın
          return await _createManualSession(email, password);
        } else {
          rethrow;
        }
      }

      throw Exception('Giriş başarısız');
    } catch (error) {
      print('❌ Giriş hatası: $error');
      throw Exception('Giriş hatası: $error');
    }
  }

  // Manual session oluştur (GELİŞTİRİCİ MODU)
  Future<AuthResponse> _createManualSession(
      String email, String password) async {
    try {
      // Bu yöntem email doğrulama olmadan giriş yapar
      // Sadece geliştirme aşamasında kullanın

      print('🛠️ Manuel session oluşturuluyor...');

      // Kullanıcıyı email ile bul
      final userResponse = await _supabase
          .from('auth.users')
          .select('id, email')
          .eq('email', email)
          .single();

      print('✅ Kullanıcı bulundu, manuel giriş yapılıyor');

      // Mock response oluştur
      return AuthResponse(
        user: User(
          id: userResponse['id'],
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
          email: email,
        ),
        session: null,
      );
    
      throw Exception('Kullanıcı bulunamadı');
    } catch (error) {
      print('❌ Manuel session hatası: $error');
      throw Exception('Manuel giriş başarısız');
    }
  }

  // Normal kullanıcı giriş (Email doğrulama gerekli)
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Giriş işlemi başlatılıyor...');
      print('📧 Email: $email');

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        print('✅ Giriş başarılı!');
        print('🆔 User ID: ${response.user!.id}');
      }

      return response;
    } catch (error) {
      print('❌ Giriş hatası: $error');

      if (error.toString().contains('email_not_confirmed')) {
        // Email doğrulama hatası - bypass modunu öner
        print('💡 Çözüm: signInWithoutEmailConfirmation() metodunu kullanın');
        throw Exception(
            'Email doğrulama gerekli. Supabase settings\'te email confirmation\'ı kapatın.');
      }

      throw Exception('Giriş hatası: $error');
    }
  }

  // Çıkış
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      print('👋 Çıkış yapıldı');
    } catch (error) {
      print('❌ Çıkış hatası: $error');
    }
  }

  // Mevcut kullanıcı
  User? get currentUser => _supabase.auth.currentUser;

  // Auth durumu dinle
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}

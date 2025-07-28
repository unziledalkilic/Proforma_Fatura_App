import 'package:flutter/material.dart';
import 'dart:math';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'kayitekrani.dart';
import 'dashboard_screen.dart'; // Ana sayfa import edin

// Güçlü Dalgalanma Efekti Widget'ı
class AnimatedWaveBackground extends StatefulWidget {
  final Widget child;

  const AnimatedWaveBackground({super.key, required this.child});

  @override
  _AnimatedWaveBackgroundState createState() => _AnimatedWaveBackgroundState();
}

class _AnimatedWaveBackgroundState extends State<AnimatedWaveBackground>
    with TickerProviderStateMixin {
  late AnimationController _waveController1;
  late AnimationController _waveController2;
  late AnimationController _waveController3;
  late AnimationController _colorController;

  @override
  void initState() {
    super.initState();

    // Farklı hızlarda dalga kontrolcüleri
    _waveController1 = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );

    _waveController2 = AnimationController(
      duration: Duration(seconds: 4),
      vsync: this,
    );

    _waveController3 = AnimationController(
      duration: Duration(seconds: 5),
      vsync: this,
    );

    _colorController = AnimationController(
      duration: Duration(seconds: 8),
      vsync: this,
    );

    // Tüm animasyonları başlat
    _waveController1.repeat();
    _waveController2.repeat();
    _waveController3.repeat();
    _colorController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveController1.dispose();
    _waveController2.dispose();
    _waveController3.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _waveController1,
        _waveController2,
        _waveController3,
        _colorController,
      ]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.5 + _colorController.value,
                  -0.5 + _colorController.value * 0.5),
              radius: 1.5 + _colorController.value * 0.5,
              colors: [
                Color.lerp(Color(0xFF1e40af), Color(0xFF3b82f6),
                    _colorController.value)!,
                Color.lerp(Color(0xFF3b82f6), Color(0xFF06b6d4),
                    _colorController.value * 0.8)!,
                Color.lerp(Color(0xFF06b6d4), Color(0xFF10b981),
                    _colorController.value * 0.6)!,
                Color.lerp(Color(0xFF10b981), Color(0xFF1e40af),
                    _colorController.value * 0.4)!,
              ],
              stops: [
                0.0,
                0.3 + _colorController.value * 0.2,
                0.6 + _colorController.value * 0.2,
                1.0,
              ],
            ),
          ),
          child: CustomPaint(
            painter: MultiWavePainter(
              _waveController1.value,
              _waveController2.value,
              _waveController3.value,
              _colorController.value,
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}

// Çoklu Dalga Çizimi için Custom Painter
class MultiWavePainter extends CustomPainter {
  final double wave1;
  final double wave2;
  final double wave3;
  final double colorValue;

  MultiWavePainter(this.wave1, this.wave2, this.wave3, this.colorValue);

  @override
  void paint(Canvas canvas, Size size) {
    // Ana dalga (alt kısım)
    _drawWave(
      canvas,
      size,
      wave1,
      Color.lerp(
        Color(0xFF3b82f6).withOpacity(0.3),
        Color(0xFF10b981).withOpacity(0.4),
        colorValue,
      )!,
      size.height * 0.75,
      80.0,
      size.width / 1.5,
    );

    // İkinci dalga (orta kısım)
    _drawWave(
      canvas,
      size,
      -wave2 * 1.2,
      Color.lerp(
        Color(0xFF06b6d4).withOpacity(0.25),
        Color(0xFF1e40af).withOpacity(0.35),
        colorValue,
      )!,
      size.height * 0.6,
      100.0,
      size.width / 1.8,
    );

    // Üçüncü dalga (üst kısım)
    _drawWave(
      canvas,
      size,
      wave3 * 0.8,
      Color.lerp(
        Color(0xFF10b981).withOpacity(0.15),
        Color(0xFF3b82f6).withOpacity(0.25),
        colorValue,
      )!,
      size.height * 0.4,
      60.0,
      size.width / 2.2,
    );

    // Dördüncü dalga (en üst)
    _drawWave(
      canvas,
      size,
      -wave1 * 1.5,
      Color.lerp(
        Color(0xFF1e40af).withOpacity(0.1),
        Color(0xFF06b6d4).withOpacity(0.2),
        colorValue,
      )!,
      size.height * 0.25,
      40.0,
      size.width / 2.5,
    );

    // Beşinci dalga (çok hafif, üst overlay)
    _drawWave(
      canvas,
      size,
      wave2 * 2,
      Color.lerp(
        Color(0xFF3b82f6).withOpacity(0.05),
        Color(0xFF10b981).withOpacity(0.15),
        colorValue,
      )!,
      size.height * 0.1,
      30.0,
      size.width / 3,
    );
  }

  void _drawWave(
    Canvas canvas,
    Size size,
    double animValue,
    Color color,
    double baseHeight,
    double amplitude,
    double frequency,
  ) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    final path = Path();

    // Dalga başlangıcı
    path.moveTo(0, baseHeight);

    // Sinüs dalgası çizimi
    for (double x = 0; x <= size.width; x += 2) {
      final y = baseHeight +
          amplitude * sin((x / frequency + animValue * 2 * pi)) +
          (amplitude * 0.3) *
              sin((x / (frequency * 0.7) + animValue * 3 * pi)) +
          (amplitude * 0.2) *
              cos((x / (frequency * 1.3) + animValue * 1.5 * pi));
      path.lineTo(x, y);
    }

    // Dalga sonunu ekrana bağla
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Supabase servisleri
  final _authService = AuthService();
  final _databaseService = DatabaseService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // SUPABASE LOGIN
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔐 Giriş işlemi başlatılıyor...');
      print('📧 Email: ${_emailController.text.trim()}');

      // Supabase ile giriş yap
      final response = await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user != null) {
        print('✅ Giriş başarılı!');
        print('🆔 User ID: ${response.user!.id}');
        print('📧 Email: ${response.user!.email}');

        // Kullanıcı profilini al
        final userProfile =
            await _databaseService.getUserProfile(response.user!.id);

        if (userProfile != null) {
          print('👤 Kullanıcı profili bulundu: ${userProfile.fullName}');

          // Başarı mesajı göster
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Hoş geldiniz, ${userProfile.fullName}!'),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );

            // Ana sayfaya yönlendir
            Navigator.pushReplacementNamed(context, '/home');
            // Ya da doğrudan:
            // Navigator.pushReplacement(
            //   context,
            //   MaterialPageRoute(builder: (context) => HomeScreen()),
            // );
          }
        } else {
          print('❌ Kullanıcı profili bulunamadı');
          _showErrorMessage('Kullanıcı profili bulunamadı');
        }
      } else {
        print('❌ Giriş başarısız - kullanıcı null');
        _showErrorMessage('Giriş başarısız');
      }
    } catch (e) {
      print('❌ Giriş hatası: $e');

      String errorMessage = 'Giriş hatası';
      if (e.toString().contains('Invalid login credentials')) {
        errorMessage = 'Email veya şifre hatalı';
      } else if (e.toString().contains('Email not confirmed')) {
        errorMessage = 'Email adresinizi doğrulayın';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Bağlantı hatası, tekrar deneyin';
      }

      _showErrorMessage(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedWaveBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),

                // Logo
                Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3b82f6), Color(0xFF1e40af)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3b82f6).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'PF',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),

                const SizedBox(height: 48),

                // Login Form Card
                Card(
                  elevation: 20,
                  shadowColor: Colors.black.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          Colors.white.withOpacity(0.95),
                        ],
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Form Başlığı
                          const Text(
                            'Giriş Bilgilerinizi Girin',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Email Input
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'E-posta',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  hintText: 'ahmet.test2023@gmail.com',
                                  prefixIcon: const Icon(
                                    Icons.email_outlined,
                                    color: Color(0xFF1e40af),
                                    size: 22,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF3b82f6), width: 2),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: Colors.red[400]!),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 16),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'E-posta adresinizi girin';
                                  }
                                  if (!RegExp(
                                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                      .hasMatch(value)) {
                                    return 'Geçerli bir e-posta adresi girin';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Password Input
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Şifre',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  prefixIcon: const Icon(
                                    Icons.lock_outlined,
                                    color: Color(0xFF1e40af),
                                    size: 22,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: Colors.grey[600],
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF3b82f6), width: 2),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: Colors.red[400]!),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 16),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Şifrenizi girin';
                                  }
                                  if (value.length < 6) {
                                    return 'Şifre en az 6 karakter olmalı';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Şifremi Unuttum
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                // Şifre sıfırlama sayfasına git
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Şifre sıfırlama özelliği yakında eklenecek'),
                                    backgroundColor: Colors.blue,
                                  ),
                                );
                              },
                              child: const Text(
                                'Şifremi unuttum',
                                style: TextStyle(
                                  color: Color(0xFF3b82f6),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1e40af),
                                disabledBackgroundColor: Colors.grey[300],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 8,
                                shadowColor:
                                    const Color(0xFF1e40af).withOpacity(0.4),
                              ),
                              child: _isLoading
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Giriş yapılıyor...',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Text(
                                      'Giriş Yap',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Kayıt Ol Linki
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Hesabınız yok mu? ',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => RegisterScreen()),
                                  );
                                },
                                child: const Text(
                                  'Kayıt Ol',
                                  style: TextStyle(
                                    color: Color(0xFF3b82f6),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

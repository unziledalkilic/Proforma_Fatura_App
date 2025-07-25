import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Proforma Fatura - Kayıt',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: RegisterScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

// Güçlü Dalgalanma Efekti Widget'ı
class AnimatedWaveBackground extends StatefulWidget {
  final Widget child;

  const AnimatedWaveBackground({Key? key, required this.child})
      : super(key: key);

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

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Kullanıcı kaydı controllers
  final _userNameController = TextEditingController();
  final _userSurnameController = TextEditingController();
  final _userEmailController = TextEditingController();
  final _userPhoneController = TextEditingController();
  final _userPasswordController = TextEditingController();

  // Şirket kaydı controllers
  final _companyNameController = TextEditingController();
  final _companySicilController = TextEditingController();
  final _companyIbanController = TextEditingController();
  final _companyEmailController = TextEditingController();
  final _companyPasswordController = TextEditingController();

  bool _isUserRegistration = true; // true: kullanıcı, false: şirket
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _acceptTerms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedWaveBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Registration Type Buttons
              _buildRegistrationTypeButtons(),

              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        SizedBox(height: 20),
                        _buildFormCard(),
                        SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          // Logo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF3b82f6), // Güvenilir mavi
                  Color(0xFF1e40af), // Koyu mavi
                ],
              ),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF3b82f6).withOpacity(0.3),
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'PF',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRegistrationTypeButtons() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isUserRegistration = true;
                  _clearForm();
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color:
                      _isUserRegistration ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _isUserRegistration
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_outline,
                      color: _isUserRegistration
                          ? Color(0xFF667eea)
                          : Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Kullanıcı Kaydı',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _isUserRegistration
                            ? Color(0xFF1e40af)
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isUserRegistration = false;
                  _clearForm();
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color:
                      !_isUserRegistration ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: !_isUserRegistration
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.business_outlined,
                      color: !_isUserRegistration
                          ? Color(0xFF1e40af)
                          : Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Şirket Kaydı',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: !_isUserRegistration
                            ? Color(0xFF1e40af)
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      elevation: 20,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: EdgeInsets.all(28),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Form Başlığı
              Center(
                child: Text(
                  _isUserRegistration
                      ? 'Kullanıcı Bilgilerinizi Girin'
                      : 'Şirket Bilgilerinizi Girin',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Form Alanları
              _isUserRegistration ? _buildUserForm() : _buildCompanyForm(),

              SizedBox(height: 20),

              // Kullanım Şartları
              Row(
                children: [
                  Checkbox(
                    value: _acceptTerms,
                    onChanged: (value) {
                      setState(() {
                        _acceptTerms = value!;
                      });
                    },
                    activeColor:
                        Color(0xFF10b981), // Modern yeşil (başarı rengi)
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                        children: [
                          TextSpan(text: 'Kullanım şartlarını ve '),
                          TextSpan(
                            text: 'gizlilik politikasını',
                            style: TextStyle(
                              color: Color(0xFF667eea),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(text: ' kabul ediyorum.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32),

              // Kayıt Ol Butonu
              Container(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      _isLoading || !_acceptTerms ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1e40af), // Profesyonel koyu mavi
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: Color(0xFF1e40af).withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
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
                              'Kayıt Oluşturuluyor...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          _isUserRegistration
                              ? 'Kullanıcı Kaydı Oluştur'
                              : 'Şirket Kaydı Oluştur',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 24),

              // Giriş Linki
              Center(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    children: [
                      TextSpan(text: 'Zaten hesabınız var mı? '),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () {
                            // Giriş ekranına git
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Giriş Yap',
                            style: TextStyle(
                              color: Color(0xFF667eea),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserForm() {
    return Column(
      children: [
        // Ad ve Soyad (Yan Yana)
        Row(
          children: [
            Expanded(
              child: _buildTextFormField(
                controller: _userNameController,
                label: 'Ad',
                hint: 'Adınız',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ad zorunludur';
                  }
                  if (value.length < 2) {
                    return 'Ad en az 2 karakter olmalı';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildTextFormField(
                controller: _userSurnameController,
                label: 'Soyad',
                hint: 'Soyadınız',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Soyad zorunludur';
                  }
                  if (value.length < 2) {
                    return 'Soyad en az 2 karakter olmalı';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 20),

        // Email
        _buildTextFormField(
          controller: _userEmailController,
          label: 'E-posta',
          hint: 'ornek@email.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'E-posta zorunludur';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Geçerli bir e-posta adresi girin';
            }
            return null;
          },
        ),
        SizedBox(height: 20),

        // Telefon
        _buildTextFormField(
          controller: _userPhoneController,
          label: 'Telefon',
          hint: '0555 123 45 67',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Telefon numarası zorunludur';
            }
            if (value.length != 11) {
              return 'Telefon numarası 11 haneli olmalı';
            }
            if (!value.startsWith('0')) {
              return 'Telefon numarası 0 ile başlamalı';
            }
            return null;
          },
        ),
        SizedBox(height: 20),

        // Şifre
        _buildPasswordField(
          controller: _userPasswordController,
          label: 'Şifre',
          hint: 'En az 8 karakter',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Şifre zorunludur';
            }
            if (value.length < 8) {
              return 'Şifre en az 8 karakter olmalı';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCompanyForm() {
    return Column(
      children: [
        // Şirket Adı
        _buildTextFormField(
          controller: _companyNameController,
          label: 'Şirket Adı',
          hint: 'ABC Teknoloji Ltd. Şti.',
          icon: Icons.business_outlined,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Şirket adı zorunludur';
            }
            if (value.length < 3) {
              return 'Şirket adı en az 3 karakter olmalı';
            }
            return null;
          },
        ),
        SizedBox(height: 20),

        // Sicil No
        _buildTextFormField(
          controller: _companySicilController,
          label: 'Sicil No',
          hint: '12345678901',
          icon: Icons.numbers_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Sicil numarası zorunludur';
            }
            if (value.length != 11) {
              return 'Sicil numarası 11 haneli olmalı';
            }
            return null;
          },
        ),
        SizedBox(height: 20),

        // IBAN No
        _buildTextFormField(
          controller: _companyIbanController,
          label: 'IBAN No',
          hint: 'TR00 0000 0000 0000 0000 0000 00',
          icon: Icons.account_balance_outlined,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'IBAN numarası zorunludur';
            }
            // IBAN doğrulaması basitleştirilmiş
            String iban = value.replaceAll(' ', '').toUpperCase();
            if (!iban.startsWith('TR') || iban.length != 26) {
              return 'Geçerli bir TR IBAN numarası girin';
            }
            return null;
          },
        ),
        SizedBox(height: 20),

        // Email
        _buildTextFormField(
          controller: _companyEmailController,
          label: 'E-posta',
          hint: 'info@sirket.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'E-posta zorunludur';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Geçerli bir e-posta adresi girin';
            }
            return null;
          },
        ),
        SizedBox(height: 20),

        // Şifre
        _buildPasswordField(
          controller: _companyPasswordController,
          label: 'Şifre',
          hint: 'En az 8 karakter',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Şifre zorunludur';
            }
            if (value.length < 8) {
              return 'Şifre en az 8 karakter olmalı';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              color: Color(0xFF1e40af), // Profesyonel koyu mavi
              size: 22,
            ),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: Color(0xFF3b82f6), width: 2), // Güvenilir mavi
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red[400]!),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: _obscurePassword,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              Icons.lock_outlined,
              color: Color(0xFF1e40af), // Profesyonel koyu mavi
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
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: Color(0xFF3b82f6), width: 2), // Güvenilir mavi
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red[400]!),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _userNameController.clear();
    _userSurnameController.clear();
    _userEmailController.clear();
    _userPhoneController.clear();
    _userPasswordController.clear();
    _companyNameController.clear();
    _companySicilController.clear();
    _companyIbanController.clear();
    _companyEmailController.clear();
    _companyPasswordController.clear();
    setState(() {
      _acceptTerms = false;
    });
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simüle edilmiş kayıt işlemi
    await Future.delayed(Duration(seconds: 2));

    if (_isUserRegistration) {
      // Kullanıcı kayıt bilgileri
      print('=== KULLANICI KAYIT BİLGİLERİ ===');
      print('Ad: ${_userNameController.text}');
      print('Soyad: ${_userSurnameController.text}');
      print('E-posta: ${_userEmailController.text}');
      print('Telefon: ${_userPhoneController.text}');
      print('Şifre: ${_userPasswordController.text}');
      print('================================');
    } else {
      // Şirket kayıt bilgileri
      print('=== ŞİRKET KAYIT BİLGİLERİ ===');
      print('Şirket Adı: ${_companyNameController.text}');
      print('Sicil No: ${_companySicilController.text}');
      print('IBAN: ${_companyIbanController.text}');
      print('E-posta: ${_companyEmailController.text}');
      print('Şifre: ${_companyPasswordController.text}');
      print('================================');
    }

    setState(() {
      _isLoading = false;
    });

    // Başarı mesajı göster
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text(_isUserRegistration
                ? 'Kullanıcı kaydı başarıyla oluşturuldu!'
                : 'Şirket kaydı başarıyla oluşturuldu!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _userSurnameController.dispose();
    _userEmailController.dispose();
    _userPhoneController.dispose();
    _userPasswordController.dispose();
    _companyNameController.dispose();
    _companySicilController.dispose();
    _companyIbanController.dispose();
    _companyEmailController.dispose();
    _companyPasswordController.dispose();
    super.dispose();
  }
}

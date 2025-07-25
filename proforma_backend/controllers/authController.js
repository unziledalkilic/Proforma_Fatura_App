const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

// JWT token oluşturma fonksiyonu
const generateToken = (userId) => {
  return jwt.sign(
    { userId: userId },
    process.env.JWT_SECRET,
    { expiresIn: '7d' }
  );
};

// Kullanıcı Kayıt
const register = async (req, res) => {
  try {
    const { name, email, password, company } = req.body;

    // Validation
    if (!name || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Ad, email ve şifre gerekli!'
      });
    }

    // Kullanıcı zaten var mı kontrol et
    const existingUser = User.findByEmail(email);
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'Bu email adresi zaten kayıtlı!'
      });
    }

    // Şifreyi hashle
    const hashedPassword = await bcrypt.hash(password, 10);

    // Yeni kullanıcı oluştur
    const newUser = User.create({
      name,
      email: email.toLowerCase(),
      password: hashedPassword,
      company: company || null
    });

    // Token oluştur
    const token = generateToken(newUser.id);

    // Şifreyi response'dan çıkar
    const { password: _, ...userWithoutPassword } = newUser;

    res.status(201).json({
      success: true,
      message: 'Kullanıcı başarıyla oluşturuldu!',
      data: {
        user: userWithoutPassword,
        token
      }
    });

  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası!'
    });
  }
};

// Kullanıcı Giriş
const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validation
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email ve şifre gerekli!'
      });
    }

    // Kullanıcıyı bul
    const user = User.findByEmail(email.toLowerCase());
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Geçersiz email veya şifre!'
      });
    }

    // Şifre kontrolü
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Geçersiz email veya şifre!'
      });
    }

    // Token oluştur
    const token = generateToken(user.id);

    // Şifreyi response'dan çıkar
    const { password: _, ...userWithoutPassword } = user;

    res.status(200).json({
      success: true,
      message: 'Giriş başarılı!',
      data: {
        user: userWithoutPassword,
        token
      }
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası!'
    });
  }
};

module.exports = {
  register,
  login
};
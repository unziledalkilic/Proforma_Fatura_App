const jwt = require('jsonwebtoken');
const User = require('../models/User');

const authenticateToken = async (req, res, next) => {
  try {
    // Token'ı header'dan al
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Erişim token\'ı gerekli!'
      });
    }

    // Token'ı doğrula
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Kullanıcının var olduğunu kontrol et
    const user = User.findById(decoded.userId);
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Geçersiz token!'
      });
    }

    // User bilgisini request'e ekle
    req.user = decoded;
    next();

  } catch (error) {
    console.error('Auth middleware error:', error);
    
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        success: false,
        message: 'Geçersiz token!'
      });
    }
    
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        message: 'Token süresi dolmuş!'
      });
    }

    res.status(500).json({
      success: false,
      message: 'Token doğrulama hatası!'
    });
  }
};

module.exports = authenticateToken;
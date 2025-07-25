const express = require('express');
const router = express.Router();
const { register, login } = require('../controllers/authController');
const authenticateToken = require('../middleware/auth');

// Genel routes (authentication gerektirmeyen)
router.post('/register', register);
router.post('/login', login);

// Test route
router.get('/test', (req, res) => {
  res.json({ message: 'Auth route çalışıyor!' });
});

// Korumalı test route
router.get('/protected', authenticateToken, (req, res) => {
  res.json({ 
    message: 'Bu korumalı route!',
    user: req.user
  });
});

module.exports = router;
const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');

// Debug için - .env dosyasını yükle
console.log('🔍 .env dosyası yükleniyor...');
dotenv.config();

// Debug bilgileri
console.log('🔍 PORT:', process.env.PORT);
console.log('🔍 DATABASE_URL var mı:', !!process.env.DATABASE_URL);

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Test Route - BU SATIRDAN ÖNCE HATA YOK
app.get('/', (req, res) => {
  console.log('✅ Ana route çalıştı');
  res.json({ 
    message: 'Proforma Fatura API Çalışıyor!',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
});

// API Routes - YENİ EKLENEN KISIM
app.use('/api/auth', require('./routes/auth'));
app.use('/api/customers', (req, res) => {
  res.json({ message: 'Customers route - yakında gelecek!' });
});
app.use('/api/products', (req, res) => {
  res.json({ message: 'Products route - yakında gelecek!' });
});
app.use('/api/invoices', (req, res) => {
  res.json({ message: 'Invoices route - yakında gelecek!' });
});

console.log('🔍 Routes tanımlandı');

// Database bağlantısını en sona alalım
const { connectDB } = require('./config/database');
connectDB();

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`🚀 Server ${PORT} portunda çalışıyor`);
  console.log(`📍 API URL: http://localhost:${PORT}`);
});
const { Sequelize } = require('sequelize');

const connectDB = async () => {
  console.log('📢 Database bağlantısı geçici olarak devre dışı');
  console.log('✅ Uygulama database olmadan çalışmaya devam ediyor');
  console.log('🔧 Database sorunu sonradan çözülecek');
};

// Boş sequelize objesi export et
const sequelize = null;

module.exports = { sequelize, connectDB };
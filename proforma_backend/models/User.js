// Mock User Data - Database yerine kullanacağız
let users = [
  {
    id: 1,
    name: "Test Kullanıcı",
    email: "test@example.com",
    password: "$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", // password
    company: "Test Şirketi",
    createdAt: new Date(),
    updatedAt: new Date()
  }
];

// User işlemleri için helper fonksiyonlar
const User = {
  // Email ile kullanıcı bul
  findByEmail: (email) => {
    return users.find(user => user.email === email);
  },

  // ID ile kullanıcı bul  
  findById: (id) => {
    return users.find(user => user.id === parseInt(id));
  },

  // Yeni kullanıcı oluştur
  create: (userData) => {
    const newUser = {
      id: users.length + 1,
      ...userData,
      createdAt: new Date(),
      updatedAt: new Date()
    };
    users.push(newUser);
    return newUser;
  }
};

module.exports = User;
# =====================================================
# PROFORMA FATURA - VERİTABANI KURULUM SCRIPTİ
# PowerShell ile PostgreSQL kurulumu ve tablo oluşturma
# =====================================================

Write-Host "🗄️ Proforma Fatura Veritabanı Kurulum Scripti" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# PostgreSQL kurulum kontrolü
Write-Host "`n📋 PostgreSQL Kurulum Kontrolü..." -ForegroundColor Yellow

try {
    $psqlVersion = psql --version 2>$null
    if ($psqlVersion) {
        Write-Host "✅ PostgreSQL kurulu: $psqlVersion" -ForegroundColor Green
    } else {
        Write-Host "❌ PostgreSQL kurulu değil!" -ForegroundColor Red
        Write-Host "`n📥 PostgreSQL Kurulum Adımları:" -ForegroundColor Yellow
        Write-Host "1. https://www.postgresql.org/download/windows/ adresine gidin" -ForegroundColor White
        Write-Host "2. 'Download the installer' butonuna tıklayın" -ForegroundColor White
        Write-Host "3. En son sürümü indirin ve kurun" -ForegroundColor White
        Write-Host "4. Kurulum sırasında şifrenizi not alın!" -ForegroundColor Red
        Write-Host "5. Bu script'i tekrar çalıştırın" -ForegroundColor White
        exit 1
    }
} catch {
    Write-Host "❌ PostgreSQL kurulu değil!" -ForegroundColor Red
    exit 1
}

# Veritabanı bağlantı bilgileri
Write-Host "`n🔧 Veritabanı Bağlantı Bilgileri:" -ForegroundColor Yellow
$host = "localhost"
$port = "5432"
$database = "proforma_fatura_db"
$username = "postgres"

Write-Host "Host: $host" -ForegroundColor White
Write-Host "Port: $port" -ForegroundColor White
Write-Host "Database: $database" -ForegroundColor White
Write-Host "Username: $username" -ForegroundColor White

# Şifre girişi
Write-Host "`n🔐 PostgreSQL şifrenizi girin:" -ForegroundColor Yellow
$password = Read-Host -AsSecureString "Password"
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
$plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

# Veritabanı oluşturma
Write-Host "`n🗂️ Veritabanı oluşturuluyor..." -ForegroundColor Yellow

$createDbCommand = "CREATE DATABASE $database;"
$env:PGPASSWORD = $plainPassword

try {
    psql -h $host -p $port -U $username -d postgres -c $createDbCommand 2>$null
    Write-Host "✅ Veritabanı oluşturuldu: $database" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Veritabanı zaten mevcut olabilir, devam ediliyor..." -ForegroundColor Yellow
}

# SQL dosyasını çalıştırma
Write-Host "`n📋 Tablolar oluşturuluyor..." -ForegroundColor Yellow

if (Test-Path "database_setup.sql") {
    try {
        psql -h $host -p $port -U $username -d $database -f "database_setup.sql"
        Write-Host "✅ Tablolar başarıyla oluşturuldu!" -ForegroundColor Green
    } catch {
        Write-Host "❌ Tablo oluşturma hatası!" -ForegroundColor Red
        Write-Host "Hata detayı: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "❌ database_setup.sql dosyası bulunamadı!" -ForegroundColor Red
    Write-Host "Lütfen SQL dosyasının bu script ile aynı dizinde olduğundan emin olun." -ForegroundColor White
    exit 1
}

# Bağlantı testi
Write-Host "`n🔍 Bağlantı testi yapılıyor..." -ForegroundColor Yellow

try {
    $testQuery = "SELECT COUNT(*) as table_count FROM information_schema.tables WHERE table_schema = 'public';"
    $result = psql -h $host -p $port -U $username -d $database -t -c $testQuery 2>$null
    $tableCount = $result.Trim()
    
    Write-Host "✅ Bağlantı başarılı! Tablo sayısı: $tableCount" -ForegroundColor Green
} catch {
    Write-Host "❌ Bağlantı testi başarısız!" -ForegroundColor Red
    exit 1
}

# Özet bilgiler
Write-Host "`n📊 KURULUM TAMAMLANDI!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host "🗄️ Veritabanı: $database" -ForegroundColor White
Write-Host "🔗 Host: $host:$port" -ForegroundColor White
Write-Host "👤 Kullanıcı: $username" -ForegroundColor White
Write-Host "📋 Tablo Sayısı: $tableCount" -ForegroundColor White

Write-Host "`n🧪 Test Kullanıcısı:" -ForegroundColor Yellow
Write-Host "Email: admin@example.com" -ForegroundColor White
Write-Host "Şifre: 12345678" -ForegroundColor White

Write-Host "`n📝 Sonraki Adımlar:" -ForegroundColor Yellow
Write-Host "1. Flutter uygulamasında PostgreSQL bağlantısını yapılandırın" -ForegroundColor White
Write-Host "2. API servislerini geliştirin" -ForegroundColor White
Write-Host "3. Veri senkronizasyonunu sağlayın" -ForegroundColor White

Write-Host "`n✅ Kurulum tamamlandı! Flutter uygulamanızı çalıştırabilirsiniz." -ForegroundColor Green

# Şifreyi temizle
$env:PGPASSWORD = "" 
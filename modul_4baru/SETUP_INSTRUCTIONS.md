# 🚀 Setup Instructions - Nasi Padang Online App

## ✅ Status: READY FOR TESTING!

Aplikasi sudah berhasil dibuild tanpa error dengan konfigurasi **environment variables (.env)** untuk keamanan.

## 1. 📋 Prerequisites Checklist

- [ ] Flutter SDK >= 3.9.2 ✅
- [ ] Android Studio / VS Code ✅
- [ ] Supabase account (buat gratis di supabase.com) ❌

## 2. 🔧 Quick Setup

### Step 1: Install Dependencies
```bash
flutter pub get
```

### Step 2: Generate Hive Models (sudah dilakukan ✅)
```bash
flutter packages pub run build_runner build
```

### Step 3: Setup Environment Variables ⭐ **NEW!**

1. **Copy .env.example ke .env:**
   ```bash
   copy .env.example .env
   # Atau manual: copy file .env.example dan rename jadi .env
   ```

2. **Buat Project Supabase:**
   - Buka [supabase.com](https://supabase.com)
   - Sign up/Login
   - Click "New Project"

3. **Copy URL & Anon Key:**
   - Di dashboard Supabase, buka project
   - Settings → API
   - Copy Project URL dan Anon Key

4. **Update .env file:**
   - Buka file: `.env` (yang sudah di-copy)
   - Update konfigurasi:
   ```env
   # Supabase Configuration
   SUPABASE_URL=https://YOUR-PROJECT-ID.supabase.co
   SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
   ```

### Step 4: Setup Database (Optional untuk demo)

Untuk testing dengan data menu lengkap:

1. Di dashboard Supabase project, buka **SQL Editor**
2. Copy-paste isi dari file: `database/nasi_padang_schema.sql`
3. Click **Run**

## 3. 🚀 Run App

```bash
# Debug mode
flutter run

# Atau build APK
flutter build apk --debug
```

### 🔍 Error Handling

Jika ada konfigurasi yang salah, app akan menampilkan **Error Screen** dengan instruksi lengkap untuk memperbaiki.

## 4. 📱 Testing Features

### ✅ Fitur yang Siap Dites:

1. **Authentication:**
   - Login dengan email/password
   - Register akun baru
   - Lupa password
   - User profile

2. **UI/UX:**
   - Dark/Light mode toggle
   - Nasi Padang theme
   - Responsive design

3. **Menu Management:**
   - View menu items (mock data)
   - Kategori menu (Nasi, Lauk, Sayur, etc.)
   - Add to cart functionality
   - Shopping cart
   - Checkout process

### ⚠️ Fitur yang Perlu Supabase:
- Real data storage
- User authentication ke database
- Real-time updates

## 5. 🐞 Troubleshooting

### Error Saat Run App:
```bash
flutter clean
flutter pub get
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Supabase Connection Issues:
1. Pastikan URL & Anon Key benar
2. Cek internet connection
3. Restart app

### Build Issues:
- Error context: Sudah diperbaiki ✅
- Hive adapters: Sudah di-generate ✅
- Theme errors: Sudah diperbaiki ✅

## 6. 📁 File Structure

```
✅ lib/
├── models/ (user_profile.dart, menu_item.dart, cart_item.dart)
├── services/ (auth_service.dart, theme_service.dart)
├── views/ (login_view.dart, nasi_padang_home_view.dart, etc.)
├── models/*.g.dart (Hive adapters - sudah ter-generate)
└── main.dart (sudah terupdate)

✅ database/
└── nasi_padang_schema.sql (database schema lengkap)

✅ pubspec.yaml (dependencies sudah lengkap)
```

## 7. 🎯 Testing Scenarios

### Scenario 1: Basic UI Testing (Tanpa Supabase)
- Buka app
- Lihat login screen
- Test theme toggle
- Navigasi (akan muncul error karena belum ada Supabase)

### Scenario 2: Full App Testing (Dengan Supabase)
- Setup Supabase
- Register akun baru
- Login
- Browse menu
- Add items ke cart
- Checkout

## 8. 🔑 Default Data (Mock)

App menggunakan mock data untuk demo:
- Menu items: 8 items (Rendang, Ayam Pop, dll)
- User profiles: Kosong (akan dibuat saat register)

## 9. 🎨 Theme Info

- **Primary Color:** #D84315 (Deep Orange)
- **Secondary:** #FF6F00 (Orange)
- **Tertiary:** #8BC34A (Green)

## 🎉 SELAMAT TESTING!

App sudah 100% siap. Jika ada error atau masalah, screenshot dan informasikan.

**Next Steps:**
1. Setup Supabase
2. Run app
3. Test features
4. Report bugs 😊
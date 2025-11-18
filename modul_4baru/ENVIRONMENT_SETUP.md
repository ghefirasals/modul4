# 🔐 Environment Configuration Guide

## Overview

Aplikasi Nasi Padang Online menggunakan **environment variables** untuk mengelola konfigurasi sensitif seperti Supabase credentials. Ini meningkatkan keamanan dan memudahkan deployment di berbagai environment (development, staging, production).

## 📁 File Structure

```
project/
├── .env                  # 🔒 PRIVATE - credentials sebenarnya (di-ignore git)
├── .env.example          # 📄 PUBLIC - template untuk copy
├── .env.production       # 🔒 PRIVATE - production credentials (optional)
├── .env.staging          # 🔒 PRIVATE - staging credentials (optional)
└── lib/config/
    └── environment.dart  # 📱 Environment reader & validator
```

## 🚀 Quick Setup

### 1. Copy Environment File
```bash
# Copy template ke file konfigurasi
copy .env.example .env

# Atau manual:
# 1. Buka .env.example
# 2. Copy semua isi
# 3. Paste ke file baru bernama .env
```

### 2. Fill Configuration
Edit file `.env`:
```env
# Supabase Configuration
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key

# App Configuration
APP_NAME=Nasi Padang Online
APP_VERSION=1.0.0
APP_ENV=development
DEBUG_MODE=true
```

### 3. Get Supabase Credentials

1. Buka [supabase.com](https://supabase.com)
2. Pilih project Anda
3. Settings → API
4. Copy:
   - **Project URL**
   - **anon public** Key

### 4. Restart App
```bash
flutter run
```

## 🔧 Environment Variables

### Required Variables
| Variable | Description | Example |
|----------|-------------|---------|
| `SUPABASE_URL` | Supabase project URL | `https://abc123.supabase.co` |
| `SUPABASE_ANON_KEY` | Supabase anon key | `eyJhbGciOiJIUzI1NiIs...` |

### Optional Variables
| Variable | Default | Description |
|----------|---------|-------------|
| `APP_NAME` | `Nasi Padang Online` | App display name |
| `APP_VERSION` | `1.0.0` | App version |
| `APP_ENV` | `development` | Environment type |
| `DEBUG_MODE` | `true` | Enable debug logging |

## 🌍 Environment Types

### Development (.env)
```env
APP_ENV=development
DEBUG_MODE=true
SUPABASE_URL=https://your-dev-project.supabase.co
```

### Staging (.env.staging)
```env
APP_ENV=staging
DEBUG_MODE=false
SUPABASE_URL=https://your-staging-project.supabase.co
```

### Production (.env.production)
```env
APP_ENV=production
DEBUG_MODE=false
SUPABASE_URL=https://your-prod-project.supabase.co
```

## 🛡️ Security Features

### 1. Automatic Validation
App akan menolak start jika Supabase credentials tidak valid:
```dart
if (supabaseUrl.isEmpty || supabaseUrl == 'https://YOUR-PROJECT-ID.supabase.co') {
  throw Exception('⚠️ SUPABASE_URL tidak dikonfigurasi!');
}
```

### 2. Error Screen
Jika konfigurasi salah, app menampilkan error screen dengan instruksi:
- 🔧 Cara memperbaiki
- 📖 Link ke dokumentasi
- ⚠️ Error messages yang jelas

### 3. Debug Logging
Hanya di development mode:
```dart
// Console output
🔧 Environment Configuration:
   App Name: Nasi Padang Online
   Supabase URL: https://***.supabase.co
   Supabase Key: eyJhbGciOiJ...
```

## 🔄 How It Works

### 1. Loading Environment
```dart
// main.dart
await Environment.init();          // Load .env file
Environment.printConfig();         // Debug output
```

### 2. Using Environment
```dart
// lib/config/environment.dart
final supabaseUrl = Environment.supabaseUrl;
final supabaseKey = Environment.supabaseAnonKey;
```

### 3. Fallback Support
```dart
// Jika .env tidak ada, fallback ke .env.example
await dotenv.load(fileName: ".env.example");
```

## 🚦 Deployment

### Development
```bash
flutter run
# Uses .env file
```

### Production Build
```bash
# Copy production environment
copy .env.production .env

flutter build apk --release
# Uses production credentials
```

## 📱 Android Configuration

Jika error di Android, tambahkan ke `android/app/build.gradle`:
```gradle
android {
    defaultConfig {
        //...
        manifestPlaceholders = [
            'appAuthRedirectScheme': 'io.supabase.nasipadang'
        ]
    }
}
```

## 🔍 Troubleshooting

### Common Issues

1. **"SUPABASE_URL not configured"**
   - Copy .env.example ke .env
   - Isi dengan Supabase URL Anda
   - Restart app

2. **"Environment file not found"**
   - Pastikan file .env ada di root project
   - Check file permissions

3. **Build error**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

### Debug Commands
```bash
# Check environment loading
flutter run --debug

# Check current config
# (Look at console output when app starts)
```

## 📄 .gitignore

File .env otomatis di-ignore untuk security:
```gitignore
# Environment variables
.env
.env.local
.env.production
.env.staging
```

## ✅ Best Practices

1. **NEVER** commit .env file ke version control
2. **ALWAYS** use .env.example sebagai template
3. **UPDATE** .env.example saat menambah variables baru
4. **TEST** environment loading sebelum deployment
5. **ROTATE** keys secara rutin untuk production

## 🎯 Benefits

✅ **Security**: Credentials tidak di version control
✅ **Flexibility**: Easy configuration per environment
✅ **Maintainability**: Centralized configuration
✅ **Error Handling**: Clear error messages
✅ **Debug Support**: Development logging

---

**📞 Need Help?** Check `SETUP_INSTRUCTIONS.md` for complete setup guide!
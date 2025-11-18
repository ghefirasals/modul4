# Cara Setup Notes Functionality

## Langkah 1: Database Setup

1. **Run SQL Schema Utama**
   - Buka file `database/nasi_padang_schema.sql`
   - Copy dan paste semua content ke Supabase SQL Editor
   - Run script tersebut

2. **Run Additional Notes Setup**
   - Buka file `database/notes_setup.sql`
   - Copy dan paste semua content ke Supabase SQL Editor
   - Run script tersebut

## Langkah 2: Fix Database Policies (IMPORTANT!)

**Sebelum setup storage, jalankan fix ini dulu:**

1. **Run Fix untuk Policy Issues**
   - Buka file `database/fix_user_profiles_policy.sql`
   - Copy dan paste semua content ke Supabase SQL Editor
   - Run script tersebut

Ini akan memperbaiki:
- Infinite recursion di user_profiles policies
- Error column 'email' not found
- Permission issues dengan storage

## Langkah 3: Storage Bucket Setup

### Cara 1: Via Supabase Dashboard (Recommended)
1. Login ke Supabase Dashboard: https://supabase.com/dashboard
2. Pilih project kamu
3. Go to **Storage** di sidebar
4. Click **New bucket**
5. Masukkan nama: `note-images`
6. Atur settings:
   - Public bucket: **Yes**
   - File size limit: 5MB
   - Allowed MIME types: `image/*`

### Cara 2: Via SQL (Jika dashboard tidak bisa)
```sql
-- Run ini di Supabase SQL Editor
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'note-images',
  'note-images',
  true,
  5242880, -- 5MB in bytes
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
);
```

## Langkah 3: Verify Configuration

### Test Database Connection
```sql
-- Test jika table notes sudah ada
SELECT COUNT(*) FROM notes;

-- Test jika user_profiles sudah ada
SELECT COUNT(*) FROM user_profiles;

-- Test jika storage bucket sudah ada
SELECT COUNT(*) FROM storage.buckets WHERE name = 'note-images';
```

### Test Permissions
```sql
-- Test RLS policies
SELECT * FROM pg_policies WHERE tablename = 'notes';
SELECT * FROM pg_policies WHERE tableoid = 'storage.objects'::regclass;
```

## Langkah 4: Test di Aplikasi

1. **Restart aplikasi**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Login dengan user yang valid**
   - Pastikan kamu sudah login
   - Check console untuk error messages

3. **Test Create Note**
   - Click tombol + untuk add note
   - Masukkan title dan content
   - Click "Add"
   - Lihat console untuk debug messages

## Common Issues & Solutions

### Issue 1: "Storage bucket not found"
**Solution:** Buat storage bucket `note-images` via Supabase Dashboard

### Issue 2: "Permission denied"
**Solution:** Run `database/notes_setup.sql` untuk setup RLS policies

### Issue 3: "User profile not found"
**Solution:** Logout dan login lagi, atau check auth configuration

### Issue 4: Images not uploading
**Solutions:**
- Check storage bucket settings
- Verify file size < 5MB
- Check file format (jpg, png, gif, webp)

### Issue 5: Note not saving
**Solutions:**
- Check internet connection
- Verify Supabase credentials di `.env`
- Check console logs untuk specific error

## Debug Tips

1. **Enable verbose logging** - Check console output untuk detail error
2. **Test dengan gambar kecil** - Coba dengan file < 1MB
3. **Test tanpa gambar** - Coba create note tanpa images dulu
4. **Check network** - Pastikan internet connection stabil

## Error Messages & Meanings

| Error Message | Cause | Solution |
|---------------|-------|----------|
| "Storage bucket not found" | Bucket `note-images` belum dibuat | Create bucket via Supabase Dashboard |
| "Permission denied" | RLS policies belum setup | Run `notes_setup.sql` |
| "User profile not found" | User profile belum ada | Logout/login atau check auth |
| "Network error" | No internet connection | Check connection |
| "File too large" | Image > 5MB | Use smaller image |

## Support

Jika masih ada error:
1. Check console output untuk detail error
2. Pastikan semua SQL script sudah di-run
3. Verify Supabase configuration di `.env` file
4. Test dengan step-by-step approach
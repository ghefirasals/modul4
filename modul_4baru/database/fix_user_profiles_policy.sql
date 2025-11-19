-- Fix infinite recursion and other issues with user_profiles policies

-- Drop existing problematic policies
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;

-- Create simplified, non-recursive policies
CREATE POLICY "Users can view own profile" ON user_profiles
FOR SELECT
USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON user_profiles
FOR UPDATE
USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON user_profiles
FOR INSERT
WITH CHECK (auth.uid() = id);

-- Also fix any issues with auth.users references
-- Make sure we can access the necessary auth information

-- Create a helper function to check admin status without recursion
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT COALESCE(is_admin, false)
  FROM user_profiles
  WHERE id = auth.uid()
$$;

-- Fix notes policies to avoid recursion
DROP POLICY IF EXISTS "Users can manage own notes" ON notes;

CREATE POLICY "Users can manage own notes" ON notes
FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Fix storage policies to avoid recursion
DROP POLICY IF EXISTS "Users can upload note images" ON storage.objects;
DROP POLICY IF EXISTS "Users can read own note images" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own note images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own note images" ON storage.objects;

-- Create better storage policies
CREATE POLICY "Users can manage note images" ON storage.objects
FOR ALL
USING (
  bucket_id = 'note-images' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Grant necessary permissions
GRANT ALL ON user_profiles TO authenticated;
GRANT ALL ON notes TO authenticated;
GRANT ALL ON storage.objects TO authenticated;
GRANT USAGE ON ALL SEQUENCES TO authenticated;
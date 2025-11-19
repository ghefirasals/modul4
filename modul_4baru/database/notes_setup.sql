-- Additional setup for Notes functionality
-- Run this script in your Supabase SQL Editor after running the main schema

-- Create storage bucket for note images
-- Note: This might need to be created manually via Supabase Dashboard
-- Go to: Storage -> Create bucket -> name it "note-images"

-- Storage policies for note-images bucket
-- First, create the bucket manually, then run these policies

-- Policy: Users can upload images to their own folder
CREATE POLICY "Users can upload note images" ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = 'note-images' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy: Users can read their own images
CREATE POLICY "Users can read own note images" ON storage.objects
FOR SELECT
USING (
  bucket_id = 'note-images' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy: Users can update their own images
CREATE POLICY "Users can update own note images" ON storage.objects
FOR UPDATE
USING (
  bucket_id = 'note-images' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy: Users can delete their own images
CREATE POLICY "Users can delete own note images" ON storage.objects
FOR DELETE
USING (
  bucket_id = 'note-images' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Grant access to storage
GRANT ALL ON storage.objects TO authenticated;

-- Fix for notes table RLS policy - make it more permissive for authenticated users
DROP POLICY IF EXISTS "Users can manage own notes" ON notes;

CREATE POLICY "Users can manage own notes" ON notes
FOR ALL
USING (auth.uid() = user_id);

-- Grant proper permissions
GRANT ALL ON notes TO authenticated;
GRANT USAGE ON ALL SEQUENCES TO authenticated;

-- Create function to check if user profile exists
CREATE OR REPLACE FUNCTION check_user_profile()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if user profile exists, if not create one
  IF NOT EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid()) THEN
    INSERT INTO user_profiles (id, username, full_name, created_at, updated_at)
    VALUES (
      auth.uid(),
      'User_' || left(auth.uid()::text, 8),
      COALESCE(
        raw_user_meta_data('full_name'),
        raw_user_meta_data('name'),
        'New User'
      ),
      NOW(),
      NOW()
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to automatically create user profile when creating a note
DROP TRIGGER IF EXISTS ensure_user_profile_for_notes ON notes;
CREATE TRIGGER ensure_user_profile_for_notes
BEFORE INSERT ON notes
FOR EACH ROW
EXECUTE FUNCTION check_user_profile();
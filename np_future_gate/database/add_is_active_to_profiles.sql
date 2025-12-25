-- Add is_active column to profiles table
-- Default value is false for new accounts
-- Migration created: 2025-12-25

-- Add the is_active column with default value false
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT false;

-- Add comment to explain the column
COMMENT ON COLUMN public.profiles.is_active IS 'Indicates whether the user account is active. Defaults to false on creation.';

-- Optional: Create an index for better query performance when filtering by is_active
CREATE INDEX IF NOT EXISTS idx_profiles_is_active ON public.profiles(is_active);

-- Update existing records to have is_active = true (assuming existing users should be active)
-- You can comment this out if you want existing users to also have is_active = false
UPDATE public.profiles 
SET is_active = true 
WHERE is_active = false;

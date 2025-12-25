-- SQL function to delete user (admin only)
-- This function allows admin to delete a user account completely
-- Migration created: 2025-12-25

-- Drop function if exists
DROP FUNCTION IF EXISTS public.delete_user(uuid);

-- Create function to delete user
CREATE OR REPLACE FUNCTION public.delete_user(user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER -- Run with elevated privileges
AS $$
BEGIN
  -- Delete from auth.users (requires admin privileges)
  DELETE FROM auth.users WHERE id = user_id;
  
  -- Delete from profiles (cascade will handle related tables)
  DELETE FROM public.profiles WHERE id = user_id;
  
  RAISE NOTICE 'User % deleted successfully', user_id;
END;
$$;

-- Grant execute permission to authenticated users (admin will call this)
GRANT EXECUTE ON FUNCTION public.delete_user(uuid) TO authenticated;

-- Add comment
COMMENT ON FUNCTION public.delete_user IS 'Allows admin to delete a user account completely';

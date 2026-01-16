-- Migration: Add INSERT policy for notifications table
-- Created: 2026-01-16
-- Description: Allow authenticated users to create system notifications

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Authenticated users can create notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can create system notifications" ON public.notifications;
DROP POLICY IF EXISTS "Allow insert notifications" ON public.notifications;

-- Policy: Allow authenticated users to create notifications
-- Simple policy - any authenticated user can create notifications
CREATE POLICY "Allow insert notifications"
ON public.notifications
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() IS NOT NULL
);

-- Grant INSERT permission to authenticated users
GRANT INSERT ON public.notifications TO authenticated;
GRANT USAGE ON SEQUENCE notifications_id_seq TO authenticated;

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Migration completed: INSERT policy added to notifications table';
    RAISE NOTICE 'Policy allows any authenticated user to create notifications';
END $$;

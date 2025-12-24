-- ============================================
-- SQL Script: Add Admin Permissions to RLS Policies
-- Description: Update policies to allow admin role full access
-- ============================================

-- Helper function to check if current user is admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- TABLE: jobs
-- ============================================

-- Drop and recreate: Users can view own jobs (+ Admin can view all)
DROP POLICY IF EXISTS "Users can view own jobs" ON public.jobs;
CREATE POLICY "Users can view own jobs"
ON public.jobs
FOR SELECT
TO public
USING (
  (auth.uid() = creator_id) -- Owner can view
  OR 
  public.is_admin() -- Admin can view all
);

-- Drop and recreate: Users can update own jobs (+ Admin can update all)
DROP POLICY IF EXISTS "Users can update own jobs" ON public.jobs;
CREATE POLICY "Users can update own jobs"
ON public.jobs
FOR UPDATE
TO public
USING (
  (auth.uid() = creator_id) -- Owner can update
  OR 
  public.is_admin() -- Admin can update all
);

-- ============================================
-- TABLE: school_partnership_jobs
-- ============================================

-- Drop and recreate: Schools can view own partnership jobs (+ Admin can view all)
DROP POLICY IF EXISTS "Schools can view own partnership jobs" ON public.school_partnership_jobs;
CREATE POLICY "Schools can view own partnership jobs"
ON public.school_partnership_jobs
FOR SELECT
TO public
USING (
  (auth.uid() = school_id) -- School owner can view
  OR 
  (auth.uid() = company_id) -- Company can view
  OR 
  public.is_admin() -- Admin can view all
);

-- Drop and recreate: Schools can update own partnership jobs (+ Admin can update all)
DROP POLICY IF EXISTS "Schools can update own partnership jobs before company review" ON public.school_partnership_jobs;
CREATE POLICY "Schools can update own partnership jobs before company review"
ON public.school_partnership_jobs
FOR UPDATE
TO public
USING (
  (
    (auth.uid() = school_id) -- School owner can update
    AND (company_status = 'pending' OR company_status IS NULL) -- Before company review
  )
  OR 
  public.is_admin() -- Admin can always update
);

-- ============================================
-- Additional helpful policies for admin
-- ============================================

-- Admin can delete jobs
DROP POLICY IF EXISTS "Admin can delete jobs" ON public.jobs;
CREATE POLICY "Admin can delete jobs"
ON public.jobs
FOR DELETE
TO public
USING (public.is_admin());

-- Admin can delete partnership jobs
DROP POLICY IF EXISTS "Admin can delete partnership jobs" ON public.school_partnership_jobs;
CREATE POLICY "Admin can delete partnership jobs"
ON public.school_partnership_jobs
FOR DELETE
TO public
USING (public.is_admin());

-- ============================================
-- Verification Queries
-- ============================================

-- Run these to verify the policies are created correctly:
/*
SELECT schemaname, tablename, policyname, roles, cmd, qual
FROM pg_policies
WHERE tablename IN ('jobs', 'school_partnership_jobs')
ORDER BY tablename, policyname;
*/

COMMENT ON FUNCTION public.is_admin() IS 'Helper function to check if the current authenticated user has admin role';

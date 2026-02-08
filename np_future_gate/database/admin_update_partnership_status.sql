-- ============================================
-- Admin Update admin_status in school_partnership_jobs
-- ============================================
-- This policy allows admin to update admin_status column specifically
-- Admin can review and approve/reject partnership jobs

-- Drop existing policy if it exists
DROP POLICY IF EXISTS "Admin can update admin_status" ON public.school_partnership_jobs;

-- Create new policy for admin to update admin_status
CREATE POLICY "Admin can update admin_status"
ON public.school_partnership_jobs
FOR UPDATE
TO public
USING (
  public.is_admin() -- Only admin can use this policy
)
WITH CHECK (
  public.is_admin() -- Only admin can update
);

-- Note: This policy works alongside the existing "Schools can update own partnership jobs before company review" policy
-- Admin can update anytime, while schools can only update when company_status is pending

-- ============================================
-- Usage Example:
-- ============================================
-- UPDATE school_partnership_jobs 
-- SET admin_status = 'approved', 
--     admin_reviewed_at = now()
-- WHERE id = 'some-uuid';

-- ============================================
-- Verification:
-- ============================================
-- To verify policies are working:
-- SELECT * FROM pg_policies WHERE tablename = 'school_partnership_jobs';

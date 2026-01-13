-- Policy cho phép school xem interview schedules của các job họ được phép xem

-- Drop existing policies if any
DROP POLICY IF EXISTS "Schools can view interviews for their partnership jobs" ON interview_schedules;

-- Cho phép school đọc interview schedules của partnership jobs
CREATE POLICY "Schools can view interviews for their partnership jobs"
ON interview_schedules
FOR SELECT
USING (
  -- Check if the job is a partnership job that belongs to this school
  EXISTS (
    SELECT 1 
    FROM school_partnership_jobs spj
    INNER JOIN profiles p ON p.id = auth.uid()
    WHERE spj.id = interview_schedules.job_id
      AND spj.school_id = p.id
      AND p.role = 'school'
  )
);

-- Verify policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'interview_schedules'
ORDER BY policyname;

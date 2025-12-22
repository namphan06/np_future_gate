-- Migration: Support partnership jobs in interview_schedules
-- Remove FK constraint to allow job_id to reference either jobs or school_partnership_jobs
-- Keep job_id NOT NULL, rely on application logic and RLS policies

-- Step 1: Drop existing foreign key constraint
-- This allows job_id to reference either jobs or school_partnership_jobs table
ALTER TABLE interview_schedules 
DROP CONSTRAINT IF EXISTS interview_schedules_job_id_fkey;

-- Step 2: Keep job_id as NOT NULL (required)
-- No changes needed - job_id remains NOT NULL

-- Step 3: Add index on job_id for performance (if not exists)
CREATE INDEX IF NOT EXISTS idx_interview_schedules_job_id 
ON interview_schedules(job_id);

-- Notes:
-- - job_id is NOT NULL and can contain UUIDs from either:
--   * jobs table (for regular job interviews)
--   * school_partnership_jobs table (for partnership job interviews)
-- - Foreign key constraint is removed to allow this flexibility
-- - Application logic ensures job_id references valid records
-- - RLS policies control access based on employer_id/company_id
-- - To find which table a job_id belongs to, application can query both tables

COMMENT ON COLUMN interview_schedules.job_id IS 
'Job ID (NOT NULL) - references either jobs table or school_partnership_jobs table. Application determines the source table.';

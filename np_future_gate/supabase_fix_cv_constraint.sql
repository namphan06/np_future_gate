-- Drop the unique constraint on mcv column in cv_templates table
-- This allows multiple CVs to share the same template code (e.g. 'CV001')
alter table public.cv_templates drop constraint if exists cv_templates_mcv_key;

-- Optional: Add an index on mcv for faster lookups if needed, but not unique
create index if not exists cv_templates_mcv_idx on public.cv_templates (mcv);

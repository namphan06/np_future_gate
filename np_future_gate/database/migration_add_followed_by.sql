-- Add column to distinguish who is following whom
ALTER TABLE public.company_followers 
ADD COLUMN followed_by text CHECK (followed_by IN ('candidate', 'employer'));

-- Update existing rows (assuming all current are candidate -> employer)
UPDATE public.company_followers 
SET followed_by = 'candidate' 
WHERE followed_by IS NULL;

-- Make it not null after update
ALTER TABLE public.company_followers 
ALTER COLUMN followed_by SET NOT NULL;

-- Drop old unique constraint
ALTER TABLE public.company_followers 
DROP CONSTRAINT IF EXISTS company_followers_unique;

-- Add new unique constraint including followed_by
ALTER TABLE public.company_followers 
ADD CONSTRAINT company_followers_unique UNIQUE (candidate_id, employer_id, followed_by);

-- Update RLS Policies

-- Drop old policies
DROP POLICY IF EXISTS "Users can insert their own follow." ON public.company_followers;
DROP POLICY IF EXISTS "Users can delete their own follow." ON public.company_followers;

-- Create new policies
CREATE POLICY "Users can insert their own follow." ON public.company_followers
  FOR INSERT WITH CHECK (
    (followed_by = 'candidate' AND auth.uid() = candidate_id) OR
    (followed_by = 'employer' AND auth.uid() = employer_id)
  );

CREATE POLICY "Users can delete their own follow." ON public.company_followers
  FOR DELETE USING (
    (followed_by = 'candidate' AND auth.uid() = candidate_id) OR
    (followed_by = 'employer' AND auth.uid() = employer_id)
  );

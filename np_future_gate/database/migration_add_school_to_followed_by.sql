-- Thêm 'school' vào check constraint và update RLS policies

-- 1. Drop constraint cũ
ALTER TABLE public.company_followers 
DROP CONSTRAINT IF EXISTS company_followers_followed_by_check;

-- 2. Add constraint mới với 'candidate', 'employer', và 'school'
ALTER TABLE public.company_followers 
ADD CONSTRAINT company_followers_followed_by_check 
CHECK (followed_by IN ('candidate', 'employer', 'school'));

-- 3. Update RLS Policies để hỗ trợ school

-- Drop old policies
DROP POLICY IF EXISTS "Users can insert their own follow." ON public.company_followers;
DROP POLICY IF EXISTS "Users can delete their own follow." ON public.company_followers;

-- Create new policies với school support
CREATE POLICY "Users can insert their own follow." ON public.company_followers
  FOR INSERT WITH CHECK (
    (followed_by = 'candidate' AND auth.uid() = candidate_id) OR
    (followed_by = 'employer' AND auth.uid() = employer_id) OR
    (followed_by = 'school' AND auth.uid() = candidate_id)
  );

CREATE POLICY "Users can delete their own follow." ON public.company_followers
  FOR DELETE USING (
    (followed_by = 'candidate' AND auth.uid() = candidate_id) OR
    (followed_by = 'employer' AND auth.uid() = employer_id) OR
    (followed_by = 'school' AND auth.uid() = candidate_id)
  );

-- Enable moddatetime extension if not already enabled
CREATE EXTENSION IF NOT EXISTS moddatetime SCHEMA extensions;

-- Create table for managing partnerships between Schools and Companies
CREATE TABLE IF NOT EXISTS public.school_company_partnerships (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    school_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    
    -- Partnership status
    -- 'pending': School requested, waiting for Company
    -- 'accepted': Active partnership
    -- 'rejected': Company rejected the request
    -- 'cancelled': Partnership ended
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'cancelled')),
    
    -- Permissions
    -- If true, jobs posted by this school for this company DO NOT need 'company_status' approval.
    -- They will be automatically set to 'accepted' (or equivalent) for the company side.
    bypass_job_approval BOOLEAN DEFAULT false,
    
    -- Posting Limits
    -- 'unlimited': No limit
    -- 'month': Limit per calendar month
    -- 'year': Limit per calendar year
    post_limit_period TEXT DEFAULT 'unlimited' CHECK (post_limit_period IN ('unlimited', 'month', 'year')),
    
    -- The actual limit number. If period is 'unlimited', this is ignored.
    post_limit_count INTEGER DEFAULT NULL,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    
    -- Unique constraint: A school and company can only have one partnership record
    UNIQUE(school_id, company_id)
);

-- Enable Row Level Security
ALTER TABLE public.school_company_partnerships ENABLE ROW LEVEL SECURITY;

-- Policies

-- 1. Schools can view their own partnerships
CREATE POLICY "Schools can view own partnerships" 
ON public.school_company_partnerships FOR SELECT 
TO authenticated 
USING (auth.uid() = school_id);

-- 2. Companies can view their own partnerships
CREATE POLICY "Companies can view own partnerships" 
ON public.school_company_partnerships FOR SELECT 
TO authenticated 
USING (auth.uid() = company_id);

-- 3. Schools can create (request) partnerships
CREATE POLICY "Schools can request partnerships" 
ON public.school_company_partnerships FOR INSERT 
TO authenticated 
WITH CHECK (
    auth.uid() = school_id AND 
    status = 'pending'
);

-- 4. Companies can update partnerships (Accept/Reject, Set Limits)
-- Only for records where they are the company_id
CREATE POLICY "Companies can update own partnerships" 
ON public.school_company_partnerships FOR UPDATE 
TO authenticated 
USING (auth.uid() = company_id);

-- 5. Admins should have full access (handled via service_role or specific admin policies if implemented)

-- Trigger to automatically update 'updated_at'
CREATE TRIGGER handle_updated_at 
BEFORE UPDATE ON public.school_company_partnerships
FOR EACH ROW EXECUTE PROCEDURE moddatetime (updated_at);

-- Comments for documentation
COMMENT ON TABLE public.school_company_partnerships IS 'Manages formal partnerships between Schools and Companies, including permissions and posting limits.';
COMMENT ON COLUMN public.school_company_partnerships.bypass_job_approval IS 'If try, School can post jobs for this Company without explicit approval for each job.';
COMMENT ON COLUMN public.school_company_partnerships.post_limit_period IS 'Time period for job posting limits (month, year, unlimited).';

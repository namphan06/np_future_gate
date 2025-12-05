-- Create user_job_activities table
create table public.user_job_activities (
  id uuid not null default gen_random_uuid (),
  user_id uuid not null references auth.users (id) on delete cascade,
  job_id uuid not null references public.jobs (id) on delete cascade,
  is_saved boolean not null default false,
  is_applied boolean not null default false,
  cv_id uuid null references public.cv_templates (id) on delete set null,
  application_status text null, -- 'pending', 'reviewed', 'rejected', 'accepted'
  applied_at timestamp with time zone null,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint user_job_activities_pkey primary key (id),
  constraint user_job_activities_user_job_unique unique (user_id, job_id)
);

-- Enable RLS
alter table public.user_job_activities enable row level security;

-- Policies
create policy "Users can view their own activities"
  on public.user_job_activities for select
  using (auth.uid() = user_id);

create policy "Users can insert their own activities"
  on public.user_job_activities for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own activities"
  on public.user_job_activities for update
  using (auth.uid() = user_id);

-- Optional: Allow employers to view activities related to their jobs?
-- This might be complex if jobs table doesn't have employer_id directly accessible or requires join.
-- For now, we keep it simple. Employers usually check 'jobs' table 'applicants' column or we can add a policy later.

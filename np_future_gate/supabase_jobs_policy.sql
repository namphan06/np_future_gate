-- Enable RLS on jobs table if not already enabled
alter table public.jobs enable row level security;

-- Policy to allow anyone (authenticated or anonymous) to view active and approved jobs
create policy "Anyone can view active approved jobs"
  on public.jobs for select
  using (
    is_active = true 
    and status = 'approved'
  );

-- Policy to allow employers to view their own jobs (regardless of status)
create policy "Employers can view their own jobs"
  on public.jobs for select
  using (
    auth.uid() = creator_id
  );

-- Policy to allow employers to insert their own jobs
create policy "Employers can insert their own jobs"
  on public.jobs for insert
  with check (
    auth.uid() = creator_id
  );

-- Policy to allow employers to update their own jobs
create policy "Employers can update their own jobs"
  on public.jobs for update
  using (
    auth.uid() = creator_id
  );

-- Policy to allow employers to delete their own jobs
create policy "Employers can delete their own jobs"
  on public.jobs for delete
  using (
    auth.uid() = creator_id
  );

-- Allow employers to view applications for their jobs
create policy "Employers can view applications for their jobs"
  on public.user_job_activities for select
  using (
    exists (
      select 1 from public.jobs
      where jobs.id = user_job_activities.job_id
      and jobs.creator_id = auth.uid()
    )
  );

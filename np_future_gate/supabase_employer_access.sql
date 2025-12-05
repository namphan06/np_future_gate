-- Policy to allow employers to view CVs of candidates who applied to their jobs
create policy "Employers can view applicant CVs"
on public.cv_templates
for select
using (
  exists (
    select 1
    from public.jobs j
    cross join jsonb_array_elements(j.applicants) as app
    where j.creator_id = auth.uid() -- The viewer is the employer
    and (app->>'cv_id')::uuid = cv_templates.id -- The CV matches
  )
);

-- Policy to allow employers to view Profiles of candidates who applied to their jobs
create policy "Employers can view applicant profiles"
on public.profiles
for select
using (
  exists (
    select 1
    from public.jobs j
    cross join jsonb_array_elements(j.applicants) as app
    where j.creator_id = auth.uid() -- The viewer is the employer
    and (app->>'user_id')::uuid = profiles.id -- The Profile matches
  )
);

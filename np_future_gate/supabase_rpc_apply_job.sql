-- Function to handle job application securely
-- This function bypasses RLS to allow candidates to update the 'applicants' array of a job
create or replace function public.apply_to_job(
  p_job_id uuid,
  p_user_id uuid,
  p_cv_id uuid
)
returns void
language plpgsql
security definer -- Run as owner (bypass RLS)
as $$
declare
  v_applicants jsonb;
  v_new_applicant jsonb;
begin
  -- 1. Get current applicants
  select applicants into v_applicants
  from public.jobs
  where id = p_job_id;

  if v_applicants is null then
    v_applicants := '[]'::jsonb;
  end if;

  -- 2. Check if already applied
  -- We check if the user_id exists in the JSON array
  if exists (
    select 1
    from jsonb_array_elements(v_applicants) as app
    where (app->>'user_id')::uuid = p_user_id
  ) then
    raise exception 'You have already applied for this job';
  end if;

  -- 3. Construct new applicant object
  v_new_applicant := jsonb_build_object(
    'user_id', p_user_id,
    'cv_id', p_cv_id,
    'applied_at', now(),
    'status', 'pending'
  );

  -- 4. Update the job
  update public.jobs
  set applicants = v_applicants || v_new_applicant
  where id = p_job_id;

  -- 5. Update or Insert into user_job_activities
  -- This part might still be subject to RLS if we didn't use security definer, 
  -- but since we are in a security definer function, we are god.
  -- However, usually user_job_activities RLS allows users to insert/update their own rows, 
  -- so we could leave this to the client OR do it here for atomicity.
  -- Let's do it here to ensure consistency.
  
  insert into public.user_job_activities (user_id, job_id, is_applied, cv_id, application_status, applied_at)
  values (p_user_id, p_job_id, true, p_cv_id, 'pending', now())
  on conflict (user_id, job_id) do update
  set 
    is_applied = true,
    cv_id = p_cv_id,
    application_status = 'pending',
    applied_at = now();

end;
$$;

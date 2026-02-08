-- Policy to allow anyone to view CVs if the CV is in a profile's cv_ids array AND that profile has security = true
-- This allows schools, employers, and others to view CVs of users who made their profile public

create policy "Public CVs viewable by all"
on public.cv_templates
for select
using (
  exists (
    select 1
    from public.profiles p
    where p.metadata->'cv_ids' ? cv_templates.id::text -- CV ID is in profile's cv_ids array
    and (p.metadata->>'security')::boolean = true -- Profile is public
  )
);

-- Note: profiles already has policy "Profiles are viewable by everyone" 
-- so no need to add another policy for security = true

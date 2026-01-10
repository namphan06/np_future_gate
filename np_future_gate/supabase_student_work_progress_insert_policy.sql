-- Cho phép ứng viên tự tạo bản ghi tiến độ (khi ứng tuyển)
create policy "Candidates can insert own progress"
on public.student_work_progress for insert
to authenticated
with check ( auth.uid() = user_id );

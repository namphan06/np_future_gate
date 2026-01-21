# RLS Policy cho Employer xem đơn ứng tuyển

## Vấn đề
Employer không thể xem đơn ứng tuyển vào job của họ vì RLS policy trong bảng `user_job_activities` chỉ cho phép user xem activity của chính mình.

## Giải pháp
Chạy SQL sau trong Supabase SQL Editor:

```sql
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
```

## Các bước thực hiện
1. Mở Supabase Dashboard
2. Vào SQL Editor
3. Copy và paste đoạn SQL trên
4. Click "Run" để thực thi
5. Refresh app để thấy dữ liệu

## File SQL
Policy SQL đã được lưu tại: `database/employer_view_applications_policy.sql`

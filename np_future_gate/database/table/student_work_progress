-- Tạo bảng theo dõi quá trình làm việc/thực tập của ứng viên
create table public.student_work_progress (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),

  -- Các khóa ngoại liên kết user
  user_id uuid references public.profiles(id) on delete cascade not null,    -- Ứng viên
  school_id uuid references public.profiles(id) on delete set null,          -- Nhà trường quản lý
  company_id uuid references public.profiles(id) on delete set null,         -- Công ty thực tập/làm việc

  -- Thông tin cơ bản
  applied_at timestamp with time zone default now(), -- Thời điểm bắt đầu/ứng tuyển
  position text,                                     -- Vị trí công việc (VD: Thực tập sinh Flutter)
  work_duration text,                                -- Thời gian làm việc (VD: 3 tháng, Full-time)
  evaluator_name text,                               -- Tên người đánh giá (Mentor/Quản lý)

  -- Cột JSON: Lộ trình làm việc (Danh sách động)
  -- Cấu trúc mẫu:
  -- [
  --   { "task": "Nghiên cứu tài liệu dự án", "result": "Đã hoàn thành", "deadline": "2024-01-01" },
  --   { "task": "Xây dựng màn hình Home", "result": "Đang thực hiện", "deadline": "2024-01-15" }
  -- ]
  work_roadmap jsonb default '[]'::jsonb,

  -- Cột JSON: Đánh giá và điểm số (Danh sách động)
  -- Cấu trúc mẫu:
  -- [
  --   { "criteria": "Thái độ làm việc", "score": 9, "comment": "Tích cực" },
  --   { "criteria": "Kỹ năng chuyên môn", "score": 8, "comment": "Cần cải thiện logic" }
  -- ]
  evaluations jsonb default '[]'::jsonb
);

-- Tạo Index để tìm kiếm nhanh
create index student_work_progress_user_id_idx on public.student_work_progress (user_id);
create index student_work_progress_school_id_idx on public.student_work_progress (school_id);
create index student_work_progress_company_id_idx on public.student_work_progress (company_id);
create index student_work_progress_work_roadmap_gin on public.student_work_progress using gin (work_roadmap);
create index student_work_progress_evaluations_gin on public.student_work_progress using gin (evaluations);

-- Bật tính năng bảo mật Row Level Security (RLS)
alter table public.student_work_progress enable row level security;

-- Policies (Quyền truy cập)

-- 1. Ứng viên xem lộ trình của chính mình
create policy "Candidates can view own progress"
on public.student_work_progress for select
to authenticated
using ( auth.uid() = user_id );

-- 2. Nhà trường xem lộ trình của học sinh mình quản lý
create policy "Schools can view related students progress"
on public.student_work_progress for select
to authenticated
using ( auth.uid() = school_id );

-- 3. Công ty xem và cập nhật lộ trình của nhân viên/thực tập sinh của mình
create policy "Companies can view related interns progress"
on public.student_work_progress for select
to authenticated
using ( auth.uid() = company_id );

create policy "Companies can update related interns progress"
on public.student_work_progress for update
to authenticated
using ( auth.uid() = company_id );

create policy "Companies can insert progress"
on public.student_work_progress for insert
to authenticated
with check ( auth.uid() = company_id );

-- 4. Admin có quyền xem tất cả (nếu cần)
-- create policy "Admins can view all" ...

-- Trigger tự động cập nhật updated_at
create trigger handle_updated_at 
before update on public.student_work_progress
for each row execute procedure moddatetime (updated_at);

-- Cho phép ứng viên tự tạo bản ghi tiến độ (khi ứng tuyển)
create policy "Candidates can insert own progress"
on public.student_work_progress for insert
to authenticated
with check ( auth.uid() = user_id );


-- Comments mô tả
comment on table public.student_work_progress is 'Bảng theo dõi lộ trình làm việc, thực tập và đánh giá ứng viên.';
comment on column public.student_work_progress.work_roadmap is 'Danh sách các đầu việc được giao và kết quả đạt được (JSON).';
comment on column public.student_work_progress.evaluations is 'Danh sách các tiêu chí đánh giá và điểm số tương ứng (JSON).';

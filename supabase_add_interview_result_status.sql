-- =====================================================
-- Migration: Thêm trạng thái kết quả tuyển dụng sau phỏng vấn
-- Description: Thêm cột recruitment_result vào bảng jobs và school_partnership_jobs
--              để nhà tuyển dụng cập nhật quyết định sau phỏng vấn ứng viên
-- Date: 2026-02-05
-- =====================================================

-- 1. Thêm cột recruitment_result vào bảng jobs
ALTER TABLE jobs 
ADD COLUMN IF NOT EXISTS recruitment_result TEXT 
CHECK (recruitment_result IN ('pending', 'accepted', 'rejected'));

-- 2. Thêm cột recruitment_result vào bảng school_partnership_jobs
ALTER TABLE school_partnership_jobs 
ADD COLUMN IF NOT EXISTS recruitment_result TEXT 
CHECK (recruitment_result IN ('pending', 'accepted', 'rejected'));

-- 3. Thêm index cho tìm kiếm nhanh trên bảng jobs
CREATE INDEX IF NOT EXISTS idx_jobs_recruitment_result 
ON jobs(recruitment_result);

-- 4. Thêm index cho tìm kiếm nhanh trên bảng school_partnership_jobs
CREATE INDEX IF NOT EXISTS idx_school_partnership_jobs_recruitment_result 
ON school_partnership_jobs(recruitment_result);

-- 5. Thêm index kết hợp cho employer queries
CREATE INDEX IF NOT EXISTS idx_jobs_creator_recruitment_result 
ON jobs(creator_id, recruitment_result);

-- 6. Thêm index kết hợp cho school queries
CREATE INDEX IF NOT EXISTS idx_school_partnership_jobs_school_recruitment 
ON school_partnership_jobs(school_id, recruitment_result);

-- 7. Comments để giải thích
COMMENT ON COLUMN jobs.recruitment_result IS 
'Kết quả tuyển dụng sau phỏng vấn: pending (đang chờ quyết định), accepted (chấp nhận/đã tuyển), rejected (từ chối/chưa đạt)';

COMMENT ON COLUMN school_partnership_jobs.recruitment_result IS 
'Kết quả tuyển dụng sau phỏng vấn: pending (đang chờ quyết định), accepted (chấp nhận/đã tuyển), rejected (từ chối/chưa đạt)';

-- =====================================================
-- Lưu ý:
-- - Trường này lưu ở cấp độ JOB (công việc)
-- - Để lưu kết quả cho TỪNG ỨNG VIÊN, nên dùng bảng applications
-- - pending: Chưa có quyết định (sau phỏng vấn)
-- - accepted: Đã tuyển ứng viên
-- - rejected: Không tuyển
-- =====================================================

-- Nếu muốn lưu kết quả cho TỪNG ỨNG VIÊN, chạy thêm query này:
-- ALTER TABLE applications 
-- ADD COLUMN IF NOT EXISTS interview_result TEXT 
-- CHECK (interview_result IN ('pending', 'accepted', 'rejected'))
-- DEFAULT 'pending';

-- Query ví dụ:
-- 1. Cập nhật kết quả sau phỏng vấn:
--    UPDATE jobs 
--    SET recruitment_result = 'accepted' 
--    WHERE id = 'job_id';
--
-- 2. Lấy các công việc đã tuyển được người:
--    SELECT * FROM jobs WHERE recruitment_result = 'accepted';
--
-- 3. Lấy các công việc đang chờ tuyển:
--    SELECT * FROM jobs WHERE recruitment_result = 'pending' OR recruitment_result IS NULL;

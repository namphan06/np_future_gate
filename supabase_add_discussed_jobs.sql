-- =========================================
-- Migration: Add discussed_job_ids to conversations
-- Purpose: Lưu lịch sử các job đã trao đổi trong conversation
-- =========================================

-- 1. Thêm cột discussed_job_ids (array of UUIDs)
ALTER TABLE conversations
ADD COLUMN IF NOT EXISTS discussed_job_ids UUID[] DEFAULT ARRAY[]::UUID[];

-- 2. Comment để mô tả
COMMENT ON COLUMN conversations.discussed_job_ids IS 
'Mảng chứa IDs của các jobs đã được trao đổi trong conversation này. Mỗi khi chuyển sang job mới, job_id cũ sẽ được thêm vào đây.';

-- 3. Tạo index để tìm kiếm nhanh (optional)
CREATE INDEX IF NOT EXISTS idx_conversations_discussed_jobs 
ON conversations USING GIN (discussed_job_ids);

-- 4. Migration data: Chuyển job_id hiện tại vào discussed_job_ids nếu có
UPDATE conversations
SET discussed_job_ids = ARRAY[job_id]
WHERE job_id IS NOT NULL 
  AND NOT (job_id = ANY(discussed_job_ids));

-- =========================================
-- Verify Migration
-- =========================================

-- Kiểm tra structure
SELECT 
    column_name, 
    data_type, 
    column_default
FROM information_schema.columns
WHERE table_name = 'conversations' 
  AND column_name = 'discussed_job_ids';

-- Xem dữ liệu sample
SELECT 
    id,
    participant1_id,
    participant2_id,
    job_id AS current_job,
    discussed_job_ids,
    array_length(discussed_job_ids, 1) AS discussed_count
FROM conversations
LIMIT 5;

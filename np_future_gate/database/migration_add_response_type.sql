-- Migration: Thêm cột response_type vào bảng employer_responses

-- Thêm cột response_type
ALTER TABLE public.employer_responses 
ADD COLUMN response_type text NOT NULL DEFAULT 'other' 
CHECK (response_type IN ('accepted', 'rejected', 'interview_invitation', 'other'));

-- Thêm index cho response_type để tối ưu query
CREATE INDEX employer_responses_response_type_idx 
ON public.employer_responses(response_type);

-- Comment giải thích
COMMENT ON COLUMN public.employer_responses.response_type IS 
'Loại phản hồi:
- accepted: Chấp nhận ứng viên
- rejected: Từ chối ứng viên
- interview_invitation: Mời phỏng vấn
- other: Phản hồi khác';

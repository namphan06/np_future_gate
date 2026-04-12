-- Incremental migration: add MBTI question options/answers for existing environments

CREATE TABLE IF NOT EXISTS public.mbti_question_options (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    question_id UUID NOT NULL REFERENCES public.mbti_questions(id) ON DELETE CASCADE,
    option_text TEXT NOT NULL,
    mapped_letter TEXT NOT NULL CHECK (mapped_letter IN ('E', 'I', 'S', 'N', 'T', 'F', 'J', 'P')),
    "order" INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true
);

CREATE INDEX IF NOT EXISTS idx_mbti_question_options_question_order
    ON public.mbti_question_options(question_id, "order");

ALTER TABLE public.mbti_question_options ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view active MBTI question options" ON public.mbti_question_options;
CREATE POLICY "Anyone can view active MBTI question options"
ON public.mbti_question_options FOR SELECT
USING (
    is_active = true
    AND EXISTS (
        SELECT 1
        FROM public.mbti_questions q
        WHERE q.id = question_id
        AND q.is_active = true
    )
);

DROP POLICY IF EXISTS "Admins have full access to MBTI question options" ON public.mbti_question_options;
CREATE POLICY "Admins have full access to MBTI question options"
ON public.mbti_question_options FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'
    )
);

DROP TRIGGER IF EXISTS set_mbti_question_options_updated_at ON public.mbti_question_options;
CREATE TRIGGER set_mbti_question_options_updated_at
    BEFORE UPDATE ON public.mbti_question_options
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

INSERT INTO public.mbti_question_options (question_id, option_text, mapped_letter, "order", is_active)
SELECT q.id, seed.option_text, seed.mapped_letter, seed."order", true
FROM (
    VALUES
        ('Khi bắt đầu một ngày mới, bạn thường nạp năng lượng bằng cách nào?', 'Từ tương tác với người khác, hoạt động nhóm', 'E', 1),
        ('Khi bắt đầu một ngày mới, bạn thường nạp năng lượng bằng cách nào?', 'Từ không gian riêng, tự suy nghĩ/chuẩn bị', 'I', 2),

        ('Trong một buổi gặp đông người, bạn thường đóng vai trò gì?', 'Chủ động mở đầu, kết nối mọi người', 'E', 1),
        ('Trong một buổi gặp đông người, bạn thường đóng vai trò gì?', 'Quan sát trước rồi mới chia sẻ khi cần', 'I', 2),

        ('Khi cần hiểu một vấn đề mới, bạn thiên về dữ kiện cụ thể hay bức tranh tổng thể?', 'Bắt đầu từ dữ kiện cụ thể, ví dụ thực tế', 'S', 1),
        ('Khi cần hiểu một vấn đề mới, bạn thiên về dữ kiện cụ thể hay bức tranh tổng thể?', 'Bắt đầu từ ý tưởng lớn và mô hình tổng thể', 'N', 2),

        ('Bạn thường tin vào kinh nghiệm thực tế hay trực giác ban đầu hơn?', 'Ưu tiên kinh nghiệm thực tế đã kiểm chứng', 'S', 1),
        ('Bạn thường tin vào kinh nghiệm thực tế hay trực giác ban đầu hơn?', 'Ưu tiên trực giác và khả năng mới có thể xảy ra', 'N', 2),

        ('Khi đưa ra quyết định quan trọng, bạn ưu tiên tiêu chí nào trước?', 'Logic, dữ liệu, tính nhất quán', 'T', 1),
        ('Khi đưa ra quyết định quan trọng, bạn ưu tiên tiêu chí nào trước?', 'Tác động đến con người và cảm nhận', 'F', 2),

        ('Khi góp ý cho người khác, bạn thường chọn cách thể hiện thế nào?', 'Trực tiếp, rõ ràng vào vấn đề', 'T', 1),
        ('Khi góp ý cho người khác, bạn thường chọn cách thể hiện thế nào?', 'Mềm mại, ưu tiên giữ hòa khí', 'F', 2),

        ('Bạn thấy thoải mái hơn khi làm việc có kế hoạch rõ ràng hay linh hoạt theo tình huống?', 'Có kế hoạch rõ, mốc cụ thể', 'J', 1),
        ('Bạn thấy thoải mái hơn khi làm việc có kế hoạch rõ ràng hay linh hoạt theo tình huống?', 'Linh hoạt điều chỉnh theo thực tế', 'P', 2),

        ('Khi có deadline gần, bạn thường xử lý tiến độ như thế nào?', 'Chốt kế hoạch sớm và bám sát tiến độ', 'J', 1),
        ('Khi có deadline gần, bạn thường xử lý tiến độ như thế nào?', 'Giữ mở lựa chọn và tăng tốc ở giai đoạn cuối', 'P', 2),

        ('Điều gì khiến bạn cảm thấy hứng thú nhất trong môi trường học tập/làm việc?', 'Môi trường tương tác, trao đổi thường xuyên', 'E', 1),
        ('Điều gì khiến bạn cảm thấy hứng thú nhất trong môi trường học tập/làm việc?', 'Không gian tập trung, làm việc độc lập', 'I', 2),

        ('Khi học một kỹ năng mới, bạn bắt đầu từ đâu?', 'Làm theo hướng dẫn cụ thể, từng bước', 'S', 1),
        ('Khi học một kỹ năng mới, bạn bắt đầu từ đâu?', 'Tự hình dung cách áp dụng sáng tạo', 'N', 2),

        ('Trong mâu thuẫn nhóm, bạn thường ưu tiên giải quyết vấn đề hay cảm xúc trước?', 'Làm rõ vấn đề, tiêu chí và giải pháp trước', 'T', 1),
        ('Trong mâu thuẫn nhóm, bạn thường ưu tiên giải quyết vấn đề hay cảm xúc trước?', 'Xử lý cảm xúc và sự thấu hiểu trước', 'F', 2),

        ('Bạn thường chuẩn bị cho tương lai theo kế hoạch cố định hay để mở nhiều lựa chọn?', 'Lập kế hoạch cố định và theo mốc cụ thể', 'J', 1),
        ('Bạn thường chuẩn bị cho tương lai theo kế hoạch cố định hay để mở nhiều lựa chọn?', 'Để mở nhiều phương án, tùy cơ hội điều chỉnh', 'P', 2)
) AS seed(question_text, option_text, mapped_letter, "order")
JOIN public.mbti_questions q ON q.question_text = seed.question_text
WHERE NOT EXISTS (
    SELECT 1
    FROM public.mbti_question_options o
    WHERE o.question_id = q.id
    AND o.option_text = seed.option_text
);

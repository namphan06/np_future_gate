-- MBTI: Questions, free-text answers, personality groups, and group content sections

CREATE TABLE IF NOT EXISTS public.mbti_questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    question_text TEXT NOT NULL,
    question_dimension TEXT CHECK (question_dimension IN ('EI', 'SN', 'TF', 'JP')),
    placeholder_hint TEXT,
    "order" INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true
);

CREATE TABLE IF NOT EXISTS public.mbti_test_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    result_code TEXT CHECK (result_code ~ '^[A-Z]{4}$')
);

CREATE TABLE IF NOT EXISTS public.mbti_test_answers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    session_id UUID NOT NULL REFERENCES public.mbti_test_sessions(id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES public.mbti_questions(id) ON DELETE RESTRICT,
    answer_text TEXT NOT NULL
);

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

CREATE TABLE IF NOT EXISTS public.mbti_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    code TEXT NOT NULL UNIQUE CHECK (code ~ '^[A-Z]{4}$'),
    name TEXT,
    short_description TEXT,
    image_url TEXT,
    color_hex TEXT,
    is_active BOOLEAN DEFAULT true
);

CREATE TABLE IF NOT EXISTS public.mbti_type_sections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    mbti_type_id UUID NOT NULL REFERENCES public.mbti_types(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    "order" INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true
);

CREATE INDEX IF NOT EXISTS idx_mbti_questions_order ON public.mbti_questions("order");
CREATE INDEX IF NOT EXISTS idx_mbti_test_sessions_user_id ON public.mbti_test_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_mbti_test_answers_session_id ON public.mbti_test_answers(session_id);
CREATE INDEX IF NOT EXISTS idx_mbti_question_options_question_order ON public.mbti_question_options(question_id, "order");
CREATE INDEX IF NOT EXISTS idx_mbti_types_code ON public.mbti_types(code);
CREATE INDEX IF NOT EXISTS idx_mbti_type_sections_type_order ON public.mbti_type_sections(mbti_type_id, "order");

ALTER TABLE public.mbti_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mbti_test_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mbti_test_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mbti_question_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mbti_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mbti_type_sections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active MBTI questions"
ON public.mbti_questions FOR SELECT
USING (is_active = true);

CREATE POLICY "Admins have full access to MBTI questions"
ON public.mbti_questions FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'
    )
);

CREATE POLICY "Users can create own MBTI test sessions"
ON public.mbti_test_sessions FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own MBTI test sessions"
ON public.mbti_test_sessions FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all MBTI test sessions"
ON public.mbti_test_sessions FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'
    )
);

CREATE POLICY "Admins can manage MBTI test sessions"
ON public.mbti_test_sessions FOR ALL
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

CREATE POLICY "Users can create own MBTI answers"
ON public.mbti_test_answers FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.mbti_test_sessions s
        WHERE s.id = session_id
        AND s.user_id = auth.uid()
    )
);

CREATE POLICY "Users can view own MBTI answers"
ON public.mbti_test_answers FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.mbti_test_sessions s
        WHERE s.id = session_id
        AND s.user_id = auth.uid()
    )
);

CREATE POLICY "Admins can view all MBTI answers"
ON public.mbti_test_answers FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'
    )
);

CREATE POLICY "Admins can manage MBTI answers"
ON public.mbti_test_answers FOR ALL
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

CREATE POLICY "Anyone can view active MBTI types"
ON public.mbti_types FOR SELECT
USING (is_active = true);

CREATE POLICY "Admins have full access to MBTI types"
ON public.mbti_types FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'
    )
);

CREATE POLICY "Anyone can view active MBTI type sections"
ON public.mbti_type_sections FOR SELECT
USING (
    is_active = true
    AND EXISTS (
        SELECT 1 FROM public.mbti_types t
        WHERE t.id = mbti_type_id
        AND t.is_active = true
    )
);

CREATE POLICY "Admins have full access to MBTI type sections"
ON public.mbti_type_sections FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'
    )
);

CREATE TRIGGER set_mbti_questions_updated_at
    BEFORE UPDATE ON public.mbti_questions
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_mbti_test_sessions_updated_at
    BEFORE UPDATE ON public.mbti_test_sessions
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_mbti_types_updated_at
    BEFORE UPDATE ON public.mbti_types
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_mbti_question_options_updated_at
    BEFORE UPDATE ON public.mbti_question_options
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_mbti_type_sections_updated_at
    BEFORE UPDATE ON public.mbti_type_sections
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

INSERT INTO public.mbti_questions (question_text, question_dimension, placeholder_hint, "order", is_active)
SELECT seed.question_text, seed.question_dimension, seed.placeholder_hint, seed."order", true
FROM (
    VALUES
        ('Khi bắt đầu một ngày mới, bạn thường nạp năng lượng bằng cách nào?', 'EI', 'Ví dụ: trò chuyện với mọi người, ở một mình, đi dạo... ', 1),
        ('Trong một buổi gặp đông người, bạn thường đóng vai trò gì?', 'EI', 'Mô tả cách bạn tương tác trong nhóm.', 2),
        ('Khi cần hiểu một vấn đề mới, bạn thiên về dữ kiện cụ thể hay bức tranh tổng thể?', 'SN', 'Nêu cách bạn thường tiếp cận thông tin.', 3),
        ('Bạn thường tin vào kinh nghiệm thực tế hay trực giác ban đầu hơn?', 'SN', 'Có thể kể một tình huống gần đây.', 4),
        ('Khi đưa ra quyết định quan trọng, bạn ưu tiên tiêu chí nào trước?', 'TF', 'Ví dụ: logic, hiệu quả, cảm xúc, sự hài hòa...', 5),
        ('Khi góp ý cho người khác, bạn thường chọn cách thể hiện thế nào?', 'TF', 'Mô tả cách nói/viết để người khác dễ tiếp nhận.', 6),
        ('Bạn thấy thoải mái hơn khi làm việc có kế hoạch rõ ràng hay linh hoạt theo tình huống?', 'JP', 'Nêu phong cách làm việc bạn thấy hiệu quả nhất.', 7),
        ('Khi có deadline gần, bạn thường xử lý tiến độ như thế nào?', 'JP', 'Ví dụ: chia nhỏ việc, làm nước rút, điều chỉnh kế hoạch...', 8),
        ('Điều gì khiến bạn cảm thấy hứng thú nhất trong môi trường học tập/làm việc?', 'EI', 'Chia sẻ điều tạo động lực cho bạn mỗi ngày.', 9),
        ('Khi học một kỹ năng mới, bạn bắt đầu từ đâu?', 'SN', 'Ví dụ: tài liệu chi tiết, thử ngay, xem tổng quan...', 10),
        ('Trong mâu thuẫn nhóm, bạn thường ưu tiên giải quyết vấn đề hay cảm xúc trước?', 'TF', 'Mô tả cách bạn cân bằng hai yếu tố này.', 11),
        ('Bạn thường chuẩn bị cho tương lai theo kế hoạch cố định hay để mở nhiều lựa chọn?', 'JP', 'Nêu cách bạn lên kế hoạch cho 3-6 tháng tới.', 12)
) AS seed(question_text, question_dimension, placeholder_hint, "order")
WHERE NOT EXISTS (
    SELECT 1
    FROM public.mbti_questions q
    WHERE q.question_text = seed.question_text
);

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

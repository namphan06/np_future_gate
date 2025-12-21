-- ============================================
-- SCHEMA CHO HỆ THỐNG CHAT
-- Hỗ trợ chat giữa: Admin, Nhà tuyển dụng, Ứng viên
-- ============================================

-- Bảng lưu trữ danh sách các cuộc hội thoại/phòng chat
CREATE TABLE IF NOT EXISTS conversations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Thông tin người tham gia
    participant1_id UUID NOT NULL,
    participant1_type VARCHAR(20) NOT NULL CHECK (participant1_type IN ('admin', 'employer', 'candidate')),
    
    participant2_id UUID NOT NULL,
    participant2_type VARCHAR(20) NOT NULL CHECK (participant2_type IN ('admin', 'employer', 'candidate')),
    
    -- Thông tin liên quan (nếu chat về một job cụ thể)
    job_id UUID,
    application_id UUID,
    
    -- Tin nhắn cuối cùng để hiển thị preview
    last_message TEXT,
    last_message_at TIMESTAMP WITH TIME ZONE,
    last_message_sender_id UUID,
    
    -- Trạng thái cuộc hội thoại
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'archived', 'blocked')),
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Đảm bảo không tạo trùng conversation giữa 2 người
    CONSTRAINT unique_conversation UNIQUE (participant1_id, participant2_id)
);

-- Index để tìm kiếm nhanh conversations của một user
CREATE INDEX idx_conversations_participant1 ON conversations(participant1_id);
CREATE INDEX idx_conversations_participant2 ON conversations(participant2_id);
CREATE INDEX idx_conversations_last_message_at ON conversations(last_message_at DESC);
CREATE INDEX idx_conversations_job_id ON conversations(job_id) WHERE job_id IS NOT NULL;

-- Bảng lưu trữ tin nhắn
CREATE TABLE IF NOT EXISTS messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    
    -- Người gửi
    sender_id UUID NOT NULL,
    sender_type VARCHAR(20) NOT NULL CHECK (sender_type IN ('admin', 'employer', 'candidate', 'school')),
    
    -- Nội dung tin nhắn
    message_type VARCHAR(20) DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file', 'system')),
    content TEXT NOT NULL,
    
    -- Nếu là file/image
    attachment_url TEXT,
    attachment_name TEXT,
    attachment_size INTEGER,
    
    -- Trạng thái
    is_edited BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index cho tin nhắn
CREATE INDEX idx_messages_conversation ON messages(conversation_id, created_at DESC);
CREATE INDEX idx_messages_sender ON messages(sender_id);

-- Bảng theo dõi trạng thái đọc tin nhắn
CREATE TABLE IF NOT EXISTS message_read_status (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    
    -- User và message cuối cùng đã đọc
    user_id UUID NOT NULL,
    user_type VARCHAR(20) NOT NULL CHECK (user_type IN ('admin', 'employer', 'candidate')),
    
    last_read_message_id UUID REFERENCES messages(id) ON DELETE SET NULL,
    last_read_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Đảm bảo mỗi user chỉ có 1 read status per conversation
    CONSTRAINT unique_read_status UNIQUE (conversation_id, user_id)
);

-- Index cho read status
CREATE INDEX idx_read_status_conversation ON message_read_status(conversation_id);
CREATE INDEX idx_read_status_user ON message_read_status(user_id);

-- Bảng theo dõi trạng thái typing (optional - cho real-time)
CREATE TABLE IF NOT EXISTS typing_status (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    
    user_id UUID NOT NULL,
    user_type VARCHAR(20) NOT NULL CHECK (user_type IN ('admin', 'employer', 'candidate' , 'school')),
    
    is_typing BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Đảm bảo mỗi user chỉ có 1 typing status per conversation
    CONSTRAINT unique_typing_status UNIQUE (conversation_id, user_id)
);

-- Index cho typing status
CREATE INDEX idx_typing_status_conversation ON typing_status(conversation_id);

-- ============================================
-- FUNCTIONS & TRIGGERS
-- ============================================

-- Function để tự động update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger cho conversations
CREATE TRIGGER update_conversations_updated_at
    BEFORE UPDATE ON conversations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger cho messages
CREATE TRIGGER update_messages_updated_at
    BEFORE UPDATE ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function để tự động cập nhật last_message trong conversations
CREATE OR REPLACE FUNCTION update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE conversations
    SET 
        last_message = NEW.content,
        last_message_at = NEW.created_at,
        last_message_sender_id = NEW.sender_id,
        updated_at = NOW()
    WHERE id = NEW.conversation_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger để update last_message khi có tin nhắn mới
CREATE TRIGGER update_last_message_trigger
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_conversation_last_message();

-- Function để lấy số tin nhắn chưa đọc
CREATE OR REPLACE FUNCTION get_unread_count(
    p_conversation_id UUID,
    p_user_id UUID
)
RETURNS INTEGER AS $$
DECLARE
    v_last_read_at TIMESTAMP WITH TIME ZONE;
    v_unread_count INTEGER;
BEGIN
    -- Lấy thời gian đọc tin nhắn cuối cùng
    SELECT last_read_at INTO v_last_read_at
    FROM message_read_status
    WHERE conversation_id = p_conversation_id
    AND user_id = p_user_id;
    
    -- Nếu chưa có record, lấy tất cả tin nhắn
    IF v_last_read_at IS NULL THEN
        SELECT COUNT(*) INTO v_unread_count
        FROM messages
        WHERE conversation_id = p_conversation_id
        AND sender_id != p_user_id
        AND is_deleted = FALSE;
    ELSE
        -- Đếm tin nhắn sau thời điểm đọc cuối
        SELECT COUNT(*) INTO v_unread_count
        FROM messages
        WHERE conversation_id = p_conversation_id
        AND sender_id != p_user_id
        AND created_at > v_last_read_at
        AND is_deleted = FALSE;
    END IF;
    
    RETURN COALESCE(v_unread_count, 0);
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_read_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE typing_status ENABLE ROW LEVEL SECURITY;

-- RLS Policies cho conversations
-- User chỉ có thể xem conversations mà họ tham gia
CREATE POLICY "Users can view their own conversations"
    ON conversations FOR SELECT
    USING (
        auth.uid() = participant1_id OR 
        auth.uid() = participant2_id
    );

-- User có thể tạo conversation mới (nếu họ là một trong hai participants)
CREATE POLICY "Users can create conversations"
    ON conversations FOR INSERT
    WITH CHECK (
        auth.uid() = participant1_id OR 
        auth.uid() = participant2_id
    );

-- User có thể update conversation của họ
CREATE POLICY "Users can update their conversations"
    ON conversations FOR UPDATE
    USING (
        auth.uid() = participant1_id OR 
        auth.uid() = participant2_id
    );

-- RLS Policies cho messages
-- User chỉ có thể xem messages trong conversations của họ
CREATE POLICY "Users can view messages in their conversations"
    ON messages FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM conversations
            WHERE conversations.id = messages.conversation_id
            AND (conversations.participant1_id = auth.uid() OR conversations.participant2_id = auth.uid())
        )
    );

-- User có thể gửi tin nhắn trong conversations của họ
CREATE POLICY "Users can send messages in their conversations"
    ON messages FOR INSERT
    WITH CHECK (
        sender_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM conversations
            WHERE conversations.id = conversation_id
            AND (conversations.participant1_id = auth.uid() OR conversations.participant2_id = auth.uid())
        )
    );

-- User có thể update/delete tin nhắn của chính họ
CREATE POLICY "Users can update their own messages"
    ON messages FOR UPDATE
    USING (sender_id = auth.uid());

CREATE POLICY "Users can delete their own messages"
    ON messages FOR DELETE
    USING (sender_id = auth.uid());

-- RLS Policies cho message_read_status
CREATE POLICY "Users can view their own read status"
    ON message_read_status FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own read status"
    ON message_read_status FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own read status"
    ON message_read_status FOR UPDATE
    USING (user_id = auth.uid());

-- RLS Policies cho typing_status
CREATE POLICY "Users can view typing status in their conversations"
    ON typing_status FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM conversations
            WHERE conversations.id = typing_status.conversation_id
            AND (conversations.participant1_id = auth.uid() OR conversations.participant2_id = auth.uid())
        )
    );

CREATE POLICY "Users can manage their own typing status"
    ON typing_status FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- ============================================
-- HELPER VIEWS
-- ============================================

-- View để lấy danh sách conversations với thông tin đầy đủ
CREATE OR REPLACE VIEW conversation_list_view AS
SELECT 
    c.id,
    c.participant1_id,
    c.participant1_type,
    c.participant2_id,
    c.participant2_type,
    c.job_id,
    c.application_id,
    c.last_message,
    c.last_message_at,
    c.last_message_sender_id,
    c.status,
    c.created_at,
    c.updated_at,
    -- Đếm tổng số tin nhắn
    (SELECT COUNT(*) FROM messages WHERE conversation_id = c.id AND is_deleted = FALSE) as total_messages
FROM conversations c;

-- ============================================
-- SAMPLE DATA (Optional - for testing)
-- ============================================

-- Uncomment để thêm dữ liệu mẫu
/*
-- Tạo conversation mẫu giữa employer và candidate
INSERT INTO conversations (id, participant1_id, participant1_type, participant2_id, participant2_type, status)
VALUES 
    ('00000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'employer', '22222222-2222-2222-2222-222222222222', 'candidate', 'active'),
    ('00000000-0000-0000-0000-000000000002', '33333333-3333-3333-3333-333333333333', 'admin', '22222222-2222-2222-2222-222222222222', 'candidate', 'active');

-- Thêm messages mẫu
INSERT INTO messages (conversation_id, sender_id, sender_type, content, message_type)
VALUES 
    ('00000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'employer', 'Xin chào, tôi quan tâm đến hồ sơ của bạn!', 'text'),
    ('00000000-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', 'candidate', 'Cảm ơn bạn! Tôi rất hứng thú với vị trí này.', 'text');
*/

-- Add 'school' to conversation type constraints
ALTER TABLE conversations DROP CONSTRAINT IF EXISTS conversations_participant1_type_check;
ALTER TABLE conversations ADD CONSTRAINT conversations_participant1_type_check 
    CHECK (participant1_type IN ('admin', 'employer', 'candidate', 'school'));

ALTER TABLE conversations DROP CONSTRAINT IF EXISTS conversations_participant2_type_check;
ALTER TABLE conversations ADD CONSTRAINT conversations_participant2_type_check 
    CHECK (participant2_type IN ('admin', 'employer', 'candidate', 'school'));

-- Add 'school' to message_read_status constraint
ALTER TABLE message_read_status DROP CONSTRAINT IF EXISTS message_read_status_user_type_check;
ALTER TABLE message_read_status ADD CONSTRAINT message_read_status_user_type_check 
    CHECK (user_type IN ('admin', 'employer', 'candidate', 'school'));

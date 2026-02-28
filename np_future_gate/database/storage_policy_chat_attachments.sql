-- Storage Policies for bucket: chat_attachments
-- Bucket này dùng để lưu ảnh và file đính kèm trong tin nhắn chat

-- ⚠️ Tạo bucket trên Supabase Dashboard:
-- Storage → New Bucket → Name: "chat_attachments" → Public bucket: ON

-- Policy 1: Cho phép authenticated users upload files
CREATE POLICY "Authenticated users can upload chat files"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'chat_attachments'
);

-- Policy 2: Cho phép tất cả users xem files (public)
CREATE POLICY "Anyone can view chat files"
ON storage.objects FOR SELECT
TO public
USING (
  bucket_id = 'chat_attachments'
);

-- Policy 3: Cho phép users xóa files của chính họ
CREATE POLICY "Users can delete own chat files"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'chat_attachments' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

/*
Cấu trúc folder trong bucket:
chat_attachments/
  ├── {user_id}/
  │   ├── {conversation_id}/
  │   │   ├── 1709123456789_photo.jpg
  │   │   ├── 1709123456790_file.pdf
  │   │   └── ...
  │   └── ...
  └── ...

Khi upload file:
- Path: {user_id}/{conversation_id}/filename.ext
- VD: "550e8400-.../conv-123-.../1709123456789_photo.jpg"
*/

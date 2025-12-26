-- Storage Policies for bucket: email_request
-- Bucket này dùng để lưu file đính kèm trong employer_responses

-- Policy 1: Cho phép authenticated users upload files
CREATE POLICY "Authenticated users can upload files"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'email_request' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy 2: Cho phép users xem files của chính họ
CREATE POLICY "Users can view their own files"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'email_request' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy 3: Cho phép users update files của chính họ
CREATE POLICY "Users can update their own files"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'email_request' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy 4: Cho phép users xóa files của chính họ
CREATE POLICY "Users can delete their own files"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'email_request' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy 5: Cho phép public đọc files (nếu cần share link)
-- Uncomment nếu muốn public access
-- CREATE POLICY "Public can view files"
-- ON storage.objects FOR SELECT
-- TO public
-- USING (bucket_id = 'email_request');

/*
Cấu trúc folder trong bucket:
email_request/
  ├── {employer_id}/
  │   ├── file1.pdf
  │   ├── file2.jpg
  │   └── ...
  └── {another_employer_id}/
      └── ...

Khi upload file:
- Path: {employer_id}/filename.ext
- VD: "550e8400-e29b-41d4-a716-446655440000/offer_letter.pdf"
*/

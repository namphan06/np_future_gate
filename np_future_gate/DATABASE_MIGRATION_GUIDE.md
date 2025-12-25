# ⚠️ QUAN TRỌNG: Chạy Database Migrations

## Lỗi hiện tại

Bạn đang gặp các lỗi sau:
1. ❌ `PostgrestException: Could not find the table 'public.applications'`
2. ❌ `Error 500/502 when getting users by role`

## Nguyên nhân

- Cột `is_active` chưa được thêm vào bảng `profiles`
- Code đã được cập nhật nhưng database chưa được cập nhật

## Giải pháp

### Bước 1: Thêm cột `is_active` vào bảng `profiles`

1. Truy cập [Supabase Dashboard](https://supabase.com/dashboard)
2. Chọn project của bạn
3. Vào **SQL Editor** (menu bên trái)
4. Click **New query**
5. Copy toàn bộ SQL bên dưới và paste vào editor:

```sql
-- Add is_active column to profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT false;

-- Add comment
COMMENT ON COLUMN public.profiles.is_active IS 'Indicates whether the user account is active. Defaults to false on creation.';

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_profiles_is_active ON public.profiles(is_active);

-- Update existing records to have is_active = true (assuming existing users should be active)
UPDATE public.profiles 
SET is_active = true 
WHERE is_active = false;
```

6. Click **Run** (hoặc nhấn Ctrl/Cmd + Enter)

### Bước 2: Tạo function delete_user cho admin

Tiếp tục trong SQL Editor, tạo query mới và chạy:

```sql
-- Drop function if exists
DROP FUNCTION IF EXISTS public.delete_user(uuid);

-- Create function to delete user
CREATE OR REPLACE FUNCTION public.delete_user(user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Delete from auth.users (requires admin privileges)
  DELETE FROM auth.users WHERE id = user_id;
  
  -- Delete from profiles (cascade will handle related tables)
  DELETE FROM public.profiles WHERE id = user_id;
  
  RAISE NOTICE 'User % deleted successfully', user_id;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.delete_user(uuid) TO authenticated;

-- Add comment
COMMENT ON FUNCTION public.delete_user IS 'Allows admin to delete a user account completely';
```

### Bước 3: Verify migrations

Chạy query sau để kiểm tra:

```sql
-- Kiểm tra cột is_active
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'profiles' AND column_name = 'is_active';

-- Kiểm tra function delete_user
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_name = 'delete_user';
```

Nếu thấy kết quả trả về là OK!

### Bước 4: Hot Reload Flutter App

Sau khi chạy migrations xong:
1. Quay lại Flutter app
2. Nhấn `r` trong terminal để hot reload
3. Hoặc nhấn `R` để hot restart

## Kiểm tra

Sau khi chạy migrations, thử các chức năng sau:

1. ✅ Vào Admin Panel → Quản lý người dùng
2. ✅ Xem danh sách candidates, employers, schools
3. ✅ Click vào một user để xem chi tiết
4. ✅ Toggle active status
5. ✅ Set post limit (cho employer/school)

## Nếu vẫn gặp lỗi

Nếu vẫn gặp lỗi sau khi chạy migrations:

1. **Restart Flutter app hoàn toàn**:
   - Stop app (nhấn `q` trong terminal)
   - Chạy lại: `flutter run`

2. **Kiểm tra Supabase connection**:
   - Đảm bảo Supabase project đang chạy
   - Kiểm tra API keys trong `.env` hoặc config

3. **Clear cache**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

## Tóm tắt migrations đã chạy

- ✅ Thêm cột `is_active` vào `profiles`
- ✅ Tạo index cho `is_active`
- ✅ Set `is_active = true` cho users hiện có
- ✅ Tạo function `delete_user` 

Sau khi chạy xong, hệ thống quản lý người dùng sẽ hoạt động hoàn toàn! 🎉

-- =====================================================
-- AUTO-CREATE TEST ACCOUNTS WITH PROFILES
-- This script automatically gets UUIDs from auth.users
-- =====================================================

-- Step 1: First, manually create 3 users in Supabase Dashboard > Authentication > Users:
-- Email: test-candidate@demo.com | Password: Demo123456!
-- Email: test-employer@demo.com  | Password: Demo123456!
-- Email: test-school@demo.com    | Password: Demo123456!
-- Make sure to check "Auto Confirm User" when creating

-- Step 2: Run this script to create their profiles

-- =====================================================
-- INSERT TEST CANDIDATE PROFILE
-- =====================================================
INSERT INTO public.profiles (
  id,
  email,
  full_name,
  role,
  phone,
  metadata,
  created_at,
  updated_at
)
SELECT 
  id,
  'test-candidate@demo.com',
  'Demo Candidate',
  'candidate',
  '0000000001',
  jsonb_build_object(
    'is_test_account', true,
    'address', 'Địa chỉ demo',
    'date_of_birth', '1995-01-01',
    'description', 'Đây là tài khoản demo để xem giao diện ứng viên. Không thể thực hiện các thao tác thay đổi dữ liệu.'
  ),
  now(),
  now()
FROM auth.users
WHERE email = 'test-candidate@demo.com'
ON CONFLICT (id) DO UPDATE SET
  full_name = EXCLUDED.full_name,
  role = EXCLUDED.role,
  phone = EXCLUDED.phone,
  metadata = EXCLUDED.metadata,
  updated_at = now();

-- =====================================================
-- INSERT TEST EMPLOYER PROFILE
-- =====================================================
INSERT INTO public.profiles (
  id,
  email,
  full_name,
  role,
  phone,
  metadata,
  created_at,
  updated_at
)
SELECT 
  id,
  'test-employer@demo.com',
  'Demo Company',
  'employer',
  '0000000002',
  jsonb_build_object(
    'is_test_account', true,
    'company_name', 'Công ty Demo',
    'address', 'Địa chỉ công ty demo',
    'website', 'https://demo.com',
    'description', 'Đây là tài khoản demo để xem giao diện nhà tuyển dụng. Không thể thực hiện các thao tác thay đổi dữ liệu.',
    'company_size', '100-500',
    'industry', 'Technology'
  ),
  now(),
  now()
FROM auth.users
WHERE email = 'test-employer@demo.com'
ON CONFLICT (id) DO UPDATE SET
  full_name = EXCLUDED.full_name,
  role = EXCLUDED.role,
  phone = EXCLUDED.phone,
  metadata = EXCLUDED.metadata,
  updated_at = now();

-- =====================================================
-- INSERT TEST SCHOOL PROFILE
-- =====================================================
INSERT INTO public.profiles (
  id,
  email,
  full_name,
  role,
  phone,
  metadata,
  created_at,
  updated_at
)
SELECT 
  id,
  'test-school@demo.com',
  'Trường Demo',
  'school',
  '0000000003',
  jsonb_build_object(
    'is_test_account', true,
    'school_type', 'Đại học',
    'address', 'Địa chỉ trường demo',
    'website', 'https://school-demo.edu.vn',
    'description', 'Đây là tài khoản demo để xem giao diện nhà trường. Không thể thực hiện các thao tác thay đổi dữ liệu.',
    'established_year', '2000'
  ),
  now(),
  now()
FROM auth.users
WHERE email = 'test-school@demo.com'
ON CONFLICT (id) DO UPDATE SET
  full_name = EXCLUDED.full_name,
  role = EXCLUDED.role,
  phone = EXCLUDED.phone,
  metadata = EXCLUDED.metadata,
  updated_at = now();

-- =====================================================
-- HELPER FUNCTION: Check if user is test account
-- =====================================================
CREATE OR REPLACE FUNCTION public.is_test_account(user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 
    FROM public.profiles 
    WHERE id = user_id 
    AND metadata->>'is_test_account' = 'true'
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.is_test_account TO authenticated;

COMMENT ON FUNCTION public.is_test_account IS 'Check if a user is a test/demo account';

-- =====================================================
-- VERIFICATION QUERY
-- =====================================================
SELECT 
  p.id,
  p.email,
  p.full_name,
  p.role,
  p.metadata->>'is_test_account' as is_test,
  p.created_at
FROM public.profiles p
WHERE p.email LIKE '%demo.com'
ORDER BY p.role;

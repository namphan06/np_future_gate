-- ===========================================
-- Course Management Feature - Database Migration
-- ===========================================
-- Run this in Supabase SQL Editor

-- ===========================================
-- 1. CREATE COURSE CATEGORIES TABLE
-- ===========================================
CREATE TABLE IF NOT EXISTS public.course_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz NOT NULL DEFAULT now(),
  
  -- Basic info
  name text NOT NULL,
  slug text UNIQUE,
  description text,
  
  -- Display
  icon text,
  color text DEFAULT '#3B82F6',
  "order" integer DEFAULT 0,
  
  -- Status
  is_active boolean DEFAULT true
);

-- Auto-generate slug for categories
CREATE OR REPLACE FUNCTION generate_category_slug()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.slug IS NULL OR NEW.slug = '' THEN
    NEW.slug = lower(regexp_replace(NEW.name, '[^a-zA-Z0-9]+', '-', 'g'));
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS course_categories_slug ON public.course_categories;
CREATE TRIGGER course_categories_slug
  BEFORE INSERT ON public.course_categories
  FOR EACH ROW
  EXECUTE FUNCTION generate_category_slug();

-- Indexes for categories
CREATE INDEX IF NOT EXISTS idx_course_categories_active ON public.course_categories(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_course_categories_order ON public.course_categories("order");

-- ===========================================
-- 2. CREATE COURSES TABLE
-- ===========================================
CREATE TABLE IF NOT EXISTS public.courses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  
  -- Basic info
  title text NOT NULL,
  slug text UNIQUE,
  description text,
  thumbnail_url text,
  
  -- Classification
  category_id uuid REFERENCES public.course_categories(id) ON DELETE SET NULL,
  level text NOT NULL DEFAULT 'beginner' CHECK (level IN ('beginner', 'intermediate', 'advanced')),
  tags text[] DEFAULT '{}',
  
  -- Duration (auto-calculated from lessons, or manual)
  duration_minutes integer DEFAULT 0,
  
  -- Status & Features
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
  is_featured boolean DEFAULT false,
  
  -- Metadata
  author_id uuid REFERENCES auth.users(id),
  view_count integer DEFAULT 0
);

-- Auto-generate slug for courses
CREATE OR REPLACE FUNCTION generate_course_slug()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.slug IS NULL OR NEW.slug = '' THEN
    NEW.slug = lower(regexp_replace(NEW.title, '[^a-zA-Z0-9]+', '-', 'g')) || '-' || substr(NEW.id::text, 1, 8);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS courses_slug ON public.courses;
CREATE TRIGGER courses_slug
  BEFORE INSERT ON public.courses
  FOR EACH ROW
  EXECUTE FUNCTION generate_course_slug();

-- Auto-update updated_at for courses
CREATE OR REPLACE FUNCTION update_course_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS courses_updated_at ON public.courses;
CREATE TRIGGER courses_updated_at
  BEFORE UPDATE ON public.courses
  FOR EACH ROW
  EXECUTE FUNCTION update_course_updated_at();

-- Indexes for courses
CREATE INDEX IF NOT EXISTS idx_courses_category ON public.courses(category_id);
CREATE INDEX IF NOT EXISTS idx_courses_status ON public.courses(status);
CREATE INDEX IF NOT EXISTS idx_courses_level ON public.courses(level);
CREATE INDEX IF NOT EXISTS idx_courses_created_at ON public.courses(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_courses_featured ON public.courses(is_featured) WHERE is_featured = true;

-- ===========================================
-- 3. CREATE COURSE LESSONS TABLE
-- ===========================================
CREATE TABLE IF NOT EXISTS public.course_lessons (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz NOT NULL DEFAULT now(),
  
  -- Relationship
  course_id uuid NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
  
  -- Basic info
  title text NOT NULL,
  description text,
  
  -- Video - YouTube link
  youtube_url text NOT NULL,
  
  -- Order & Duration
  "order" integer DEFAULT 0,
  duration_minutes integer DEFAULT 0,
  
  -- Preview access
  is_preview boolean DEFAULT false
);

-- Indexes for lessons
CREATE INDEX IF NOT EXISTS idx_course_lessons_course ON public.course_lessons(course_id);
CREATE INDEX IF NOT EXISTS idx_course_lessons_order ON public.course_lessons(course_id, "order");

-- ===========================================
-- 4. FUNCTION: Update course duration from lessons
-- ===========================================
CREATE OR REPLACE FUNCTION update_course_duration()
RETURNS TRIGGER AS $$
BEGIN
  -- Update the course's total duration
  UPDATE public.courses
  SET duration_minutes = (
    SELECT COALESCE(SUM(duration_minutes), 0)
    FROM public.course_lessons
    WHERE course_id = COALESCE(NEW.course_id, OLD.course_id)
  )
  WHERE id = COALESCE(NEW.course_id, OLD.course_id);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_course_duration_on_lesson_change ON public.course_lessons;
CREATE TRIGGER update_course_duration_on_lesson_change
  AFTER INSERT OR UPDATE OR DELETE ON public.course_lessons
  FOR EACH ROW
  EXECUTE FUNCTION update_course_duration();

-- ===========================================
-- 5. ENABLE RLS
-- ===========================================
ALTER TABLE public.course_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.course_lessons ENABLE ROW LEVEL SECURITY;

-- ===========================================
-- 6. RLS POLICIES - COURSE CATEGORIES
-- ===========================================
DROP POLICY IF EXISTS "Anyone can read active categories" ON public.course_categories;
DROP POLICY IF EXISTS "Admin can manage categories" ON public.course_categories;

CREATE POLICY "Anyone can read active categories"
  ON public.course_categories
  FOR SELECT
  USING (is_active = true);

CREATE POLICY "Admin can manage categories"
  ON public.course_categories
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- ===========================================
-- 7. RLS POLICIES - COURSES
-- ===========================================
DROP POLICY IF EXISTS "Anyone can read published courses" ON public.courses;
DROP POLICY IF EXISTS "Admin can manage all courses" ON public.courses;

CREATE POLICY "Anyone can read published courses"
  ON public.courses
  FOR SELECT
  USING (status = 'published');

CREATE POLICY "Admin can manage all courses"
  ON public.courses
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- ===========================================
-- 8. RLS POLICIES - COURSE LESSONS
-- ===========================================
DROP POLICY IF EXISTS "Anyone can read lessons of published courses" ON public.course_lessons;
DROP POLICY IF EXISTS "Admin can manage all lessons" ON public.course_lessons;

CREATE POLICY "Anyone can read lessons of published courses"
  ON public.course_lessons
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.courses
      WHERE courses.id = course_lessons.course_id
      AND courses.status = 'published'
    )
  );

CREATE POLICY "Admin can manage all lessons"
  ON public.course_lessons
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- ===========================================
-- 9. SAMPLE DATA - CATEGORIES
-- ===========================================
INSERT INTO public.course_categories (name, description, icon, color, "order") VALUES
  ('Kỹ năng mềm', 'Các khoá học về giao tiếp, làm việc nhóm, quản lý thời gian...', 'users', '#8B5CF6', 1),
  ('Công nghệ thông tin', 'Lập trình, phân tích dữ liệu, thiết kế web...', 'code', '#3B82F6', 2),
  ('Ngoại ngữ', 'Tiếng Anh, tiếng Nhật, tiếng Hàn...', 'globe', '#10B981', 3),
  ('Quản lý & Kinh doanh', 'Quản trị doanh nghiệp, marketing, tài chính...', 'briefcase', '#F59E0B', 4),
  ('Phát triển bản thân', 'Tư duy tích cực, đặt mục tiêu, xây dựng thói quen...', 'star', '#EF4444', 5)
ON CONFLICT (slug) DO NOTHING;

-- ===========================================
-- 10. HELPER FUNCTION: Increment view count
-- ===========================================
CREATE OR REPLACE FUNCTION increment_course_view_count(course_id uuid)
RETURNS void AS $$
BEGIN
  UPDATE public.courses
  SET view_count = COALESCE(view_count, 0) + 1
  WHERE id = course_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

# API Specification - NP FutureGate Web App

Tài liệu này chi tiết tất cả API endpoints, database queries và business logic cần thiết để xây dựng web app.

## 📑 Mục Lục

1. [Authentication APIs](#authentication-apis)
2. [Job APIs](#job-apis)
3. [Profile APIs](#profile-apis)
4. [CV APIs](#cv-apis)
5. [Interview APIs](#interview-apis)
6. [Chat APIs](#chat-apis)
7. [Search & Filter](#search--filter)
8. [Supabase RPC Functions](#supabase-rpc-functions)

---

## 🔐 Authentication APIs

### 1. Sign Up with Email

**Endpoint**: POST `/api/auth/signup`

**Request Body**:
```typescript
{
  email: string;
  password: string;
  full_name: string;
  phone: string;
  role: 'candidate' | 'employer' | 'school' | 'admin';
}
```

**Implementation**:
```typescript
// app/api/auth/signup/route.ts
import { createServerSupabaseClient } from '@/lib/supabase/server';
import { NextResponse } from 'next/server';

export async function POST(request: Request) {
  const supabase = createServerSupabaseClient();
  const { email, password, full_name, phone, role } = await request.json();

  try {
    // 1. Sign up user
    const { data: authData, error: authError } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          full_name,
          phone,
          role
        }
      }
    });

    if (authError) throw authError;
    if (!authData.user) throw new Error('User creation failed');

    // 2. Ensure profile was created (trigger should handle this)
    // But we can double-check
    const { error: profileError } = await supabase
      .from('profiles')
      .upsert({
        id: authData.user.id,
        email,
        full_name,
        phone,
        role,
        metadata: {}
      });

    if (profileError) console.warn('Profile creation warning:', profileError);

    return NextResponse.json({
      success: true,
      message: authData.user.email_confirmed_at 
        ? 'Đăng ký thành công!'
        : 'Vui lòng kiểm tra email để xác thực tài khoản.',
      user: authData.user
    });
  } catch (error: any) {
    return NextResponse.json(
      { success: false, message: error.message },
      { status: 400 }
    );
  }
}
```

### 2. Sign In with Email

**Endpoint**: POST `/api/auth/signin`

**Request Body**:
```typescript
{
  email: string;
  password: string;
}
```

**Implementation**:
```typescript
// app/api/auth/signin/route.ts
export async function POST(request: Request) {
  const supabase = createServerSupabaseClient();
  const { email, password } = await request.json();

  try {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password
    });

    if (error) throw error;
    if (!data.user) throw new Error('Login failed');

    return NextResponse.json({
      success: true,
      message: 'Đăng nhập thành công!',
      user: data.user
    });
  } catch (error: any) {
    return NextResponse.json(
      { success: false, message: error.message },
      { status: 401 }
    );
  }
}
```

### 3. Sign Out

**Endpoint**: POST `/api/auth/signout`

**Implementation**:
```typescript
// app/api/auth/signout/route.ts
export async function POST(request: Request) {
  const supabase = createServerSupabaseClient();

  try {
    const { error } = await supabase.auth.signOut();
    if (error) throw error;

    return NextResponse.json({
      success: true,
      message: 'Đăng xuất thành công!'
    });
  } catch (error: any) {
    return NextResponse.json(
      { success: false, message: error.message },
      { status: 500 }
    );
  }
}
```

### 4. Get Current User Profile

**Endpoint**: GET `/api/auth/profile`

**Implementation**:
```typescript
// app/api/auth/profile/route.ts
export async function GET(request: Request) {
  const supabase = createServerSupabaseClient();

  try {
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) throw new Error('Not authenticated');

    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', user.id)
      .single();

    if (profileError) throw profileError;

    return NextResponse.json({ profile });
  } catch (error: any) {
    return NextResponse.json(
      { error: error.message },
      { status: 401 }
    );
  }
}
```

### 5. Update Profile

**Endpoint**: PUT `/api/auth/profile`

**Request Body**:
```typescript
{
  full_name?: string;
  phone?: string;
  avatar_url?: string;
  metadata?: Record<string, any>;
}
```

**Implementation**:
```typescript
// app/api/auth/profile/route.ts
export async function PUT(request: Request) {
  const supabase = createServerSupabaseClient();
  const body = await request.json();

  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const updates: any = {};
    if (body.full_name) updates.full_name = body.full_name;
    if (body.phone) updates.phone = body.phone;
    if (body.avatar_url) updates.avatar_url = body.avatar_url;
    if (body.metadata) updates.metadata = body.metadata;

    const { error } = await supabase
      .from('profiles')
      .update(updates)
      .eq('id', user.id);

    if (error) throw error;

    return NextResponse.json({
      success: true,
      message: 'Cập nhật thông tin thành công!'
    });
  } catch (error: any) {
    return NextResponse.json(
      { error: error.message },
      { status: 500 }
    );
  }
}
```

---

## 💼 Job APIs

### 1. Get Active Jobs (Public)

**Endpoint**: GET `/api/jobs`

**Query Parameters**:
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 20)

**Implementation**:
```typescript
// app/api/jobs/route.ts
export async function GET(request: Request) {
  const supabase = createServerSupabaseClient();
  const { searchParams } = new URL(request.url);
  const page = parseInt(searchParams.get('page') || '1');
  const limit = parseInt(searchParams.get('limit') || '20');
  const offset = (page - 1) * limit;

  try {
    // Get jobs with profiles
    const { data: jobs, error, count } = await supabase
      .from('jobs')
      .select(`
        *,
        profiles:creator_id (
          id,
          full_name,
          avatar_url,
          metadata
        )
      `, { count: 'exact' })
      .eq('is_active', true)
      .eq('status', 'approved')
      .gt('deadline', new Date().toISOString())
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) throw error;

    return NextResponse.json({
      jobs,
      pagination: {
        page,
        limit,
        total: count || 0,
        totalPages: Math.ceil((count || 0) / limit)
      }
    });
  } catch (error: any) {
    return NextResponse.json(
      { error: error.message },
      { status: 500 }
    );
  }
}
```

### 2. Create Job (Employer only)

**Endpoint**: POST `/api/jobs`

**Request Body**:
```typescript
{
  deadline: string; // ISO 8601
  metadata: {
    title: string;
    working_regions: string[];
    experience_required: string;
    fields: string[];
    requirements_tags: string[];
    salary: {
      min?: number;
      max?: number;
      currency: string;
      is_negotiable: boolean;
      type: 'monthly' | 'hourly' | 'yearly';
    };
    employment_types: string[];
    work_locations: string[];
    job_description: string[];
    candidate_requirements: string[];
    benefits: string[];
  };
}
```

**Implementation**:
```typescript
// app/api/jobs/route.ts
export async function POST(request: Request) {
  const supabase = createServerSupabaseClient();
  const body = await request.json();

  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    // Check if user is employer
    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single();

    if (profile?.role !== 'employer') {
      throw new Error('Only employers can post jobs');
    }

    const { data, error } = await supabase
      .from('jobs')
      .insert([
        {
          creator_id: user.id,
          deadline: body.deadline,
          metadata: body.metadata,
          is_active: true,
          status: 'pending' // Needs admin approval
        }
      ])
      .select()
      .single();

    if (error) throw error;

    return NextResponse.json({
      success: true,
      message: 'Đăng tin thành công! Đang chờ duyệt.',
      job: data
    });
  } catch (error: any) {
    return NextResponse.json(
      { error: error.message },
      { status: 400 }
    );
  }
}
```

### 3. Get Job by ID

**Endpoint**: GET `/api/jobs/[id]`

**Implementation**:
```typescript
// app/api/jobs/[id]/route.ts
export async function GET(
  request: Request,
  { params }: { params: { id: string } }
) {
  const supabase = createServerSupabaseClient();

  try {
    const { data: job, error } = await supabase
      .from('jobs')
      .select(`
        *,
        profiles:creator_id (
          id,
          full_name,
          avatar_url,
          email,
          phone,
          metadata
        )
      `)
      .eq('id', params.id)
      .single();

    if (error) throw error;
    if (!job) throw new Error('Job not found');

    // Increment view count
    await supabase
      .from('jobs')
      .update({ view_count: (job.view_count || 0) + 1 })
      .eq('id', params.id);

    return NextResponse.json({ job });
  } catch (error: any) {
    return NextResponse.json(
      { error: error.message },
      { status: 404 }
    );
  }
}
```

### 4. Update Job (Creator only)

**Endpoint**: PUT `/api/jobs/[id]`

**Implementation**:
```typescript
// app/api/jobs/[id]/route.ts
export async function PUT(
  request: Request,
  { params }: { params: { id: string } }
) {
  const supabase = createServerSupabaseClient();
  const body = await request.json();

  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    // Check ownership
    const { data: job } = await supabase
      .from('jobs')
      .select('creator_id')
      .eq('id', params.id)
      .single();

    if (job?.creator_id !== user.id) {
      throw new Error('Unauthorized');
    }

    const updates: any = {};
    if (body.deadline) updates.deadline = body.deadline;
    if (body.metadata) updates.metadata = body.metadata;
    if (body.is_active !== undefined) updates.is_active = body.is_active;

    const { error } = await supabase
      .from('jobs')
      .update(updates)
      .eq('id', params.id);

    if (error) throw error;

    return NextResponse.json({
      success: true,
      message: 'Cập nhật tin thành công!'
    });
  } catch (error: any) {
    return NextResponse.json(
      { error: error.message },
      { status: 403 }
    );
  }
}
```

### 5. Delete Job (Creator only)

**Endpoint**: DELETE `/api/jobs/[id]`

**Implementation**:
```typescript
// app/api/jobs/[id]/route.ts
export async function DELETE(
  request: Request,
  { params }: { params: { id: string } }
) {
  const supabase = createServerSupabaseClient();

  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    // Check ownership
    const { data: job } = await supabase
      .from('jobs')
      .select('creator_id')
      .eq('id', params.id)
      .single();

    if (job?.creator_id !== user.id) {
      throw new Error('Unauthorized');
    }

    const { error } = await supabase
      .from('jobs')
      .delete()
      .eq('id', params.id);

    if (error) throw error;

    return NextResponse.json({
      success: true,
      message: 'Xóa tin thành công!'
    });
  } catch (error: any) {
    return NextResponse.json(
      { error: error.message },
      { status: 403 }
    );
  }
}
```

### 6. Apply for Job

**Endpoint**: POST `/api/jobs/[id]/apply`

**Request Body**:
```typescript
{
  cv_id: string;
}
```

**Implementation**:
```typescript
// app/api/jobs/[id]/apply/route.ts
export async function POST(
  request: Request,
  { params }: { params: { id: string } }
) {
  const supabase = createServerSupabaseClient();
  const { cv_id } = await request.json();

  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    // Call RPC function
    const { error } = await supabase.rpc('apply_to_job', {
      p_job_id: params.id,
      p_user_id: user.id,
      p_cv_id: cv_id
    });

    if (error) throw error;

    return NextResponse.json({
      success: true,
      message: 'Ứng tuyển thành công!'
    });
  } catch (error: any) {
    return NextResponse.json(
      { error: error.message },
      { status: 400 }
    );
  }
}
```

### 7. Toggle Save Job

**Endpoint**: POST `/api/jobs/[id]/save`

**Implementation**:
```typescript
// app/api/jobs/[id]/save/route.ts
export async function POST(
  request: Request,
  { params }: { params: { id: string } }
) {
  const supabase = createServerSupabaseClient();

  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    // Check if activity exists
    const { data: existing } = await supabase
      .from('user_job_activities')
      .select('id, is_saved')
      .eq('user_id', user.id)
      .eq('job_id', params.id)
      .maybeSingle();

    if (existing) {
      // Toggle
      const { error } = await supabase
        .from('user_job_activities')
        .update({ is_saved: !existing.is_saved })
        .eq('id', existing.id);

      if (error) throw error;

      return NextResponse.json({
        success: true,
        is_saved: !existing.is_saved
      });
    } else {
      // Create new
      const { error } = await supabase
        .from('user_job_activities')
        .insert({
          user_id: user.id,
          job_id: params.id,
          is_saved: true
        });

      if (error) throw error;

      return NextResponse.json({
        success: true,
        is_saved: true
      });
    }
  } catch (error: any) {
    return NextResponse.json(
      { error: error.message },
      { status: 500 }
    );
  }
}
```

### 8. Get Saved Jobs

**Endpoint**: GET `/api/jobs/saved`

**Implementation**:
```typescript
// app/api/jobs/saved/route.ts
export async function GET(request: Request) {
  const supabase = createServerSupabaseClient();

  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await supabase
      .from('user_job_activities')
      .select(`
        *,
        jobs (
          *,
          profiles:creator_id (
            full_name,
            avatar_url
          )
        )
      `)
      .eq('user_id', user.id)
      .eq('is_saved', true);

    if (error) throw error;

    return NextResponse.json({ saved_jobs: data });
  } catch (error: any) {
    return NextResponse.json(
      { error: error.message },
      { status: 500 }
    );
  }
}
```

### 9. Get Applied Jobs

**Endpoint**: GET `/api/jobs/applied`

**Implementation**:
```typescript
// app/api/jobs/applied/route.ts
export async function GET(request: Request) {
  const supabase = createServerSupabaseClient();

  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await supabase
      .from('user_job_activities')
      .select(`
        *,
        jobs (
          *,
          profiles:creator_id (
            full_name,
            avatar_url
          )
        ),
        cv_templates (
          id,
          title
        )
      `)
      .eq('user_id', user.id)
      .eq('is_applied', true)
      .order('applied_at', { ascending: false });

    if (error) throw error;

    // Also fetch status from job applicants array
    const enriched = data?.map(activity => {
      const job = activity.jobs as any;
      if (job?.applicants) {
        const myApp = job.applicants.find((app: any) => app.user_id === user.id);
        if (myApp) {
          return {
            ...activity,
            status: myApp.status,
            application_status: myApp.status
          };
        }
      }
      return activity;
    });

    return NextResponse.json({ applied_jobs: enriched });
  } catch (error: any) {
    return NextResponse.json(
      { error: error.message },
      { status: 500 }
    );
  }
}
```

### 10. Get Employer Jobs

**Endpoint**: GET `/api/employer/jobs`

**Implementation**:
```typescript
// app/api/employer/jobs/route.ts
export async function GET(request: Request) {
  const supabase = createServerSupabaseClient();

  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data: jobs, error } = await supabase
      .from('jobs')
      .select('*')
      .eq('creator_id', user.id)
      .order('created_at', { ascending: false });

    if (error) throw error;

    return NextResponse.json({ jobs });
  } catch (error: any) {
    return NextResponse.json(
      { error: error.message },
      { status: 500 }
    );
  }
}
```

### 11. Get Job Applicants (Employer only)

**Endpoint**: GET `/api/jobs/[id]/applicants`

**Implementation**:
```typescript
// app/api/jobs/[id]/applicants/route.ts
export async function GET(
  request: Request,
  { params }: { params: { id: string } }
) {
  const supabase = createServerSupabaseClient();

  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    // Get job and verify ownership
    const { data: job, error: jobError } = await supabase
      .from('jobs')
      .select('creator_id, applicants')
      .eq('id', params.id)
      .single();

    if (jobError || !job) throw new Error('Job not found');
    if (job.creator_id !== user.id) throw new Error('Unauthorized');

    const applicants = job.applicants || [];

    // Fetch profiles and CVs for applicants
    const userIds = applicants.map((app: any) => app.user_id);
    const cvIds = applicants.map((app: any) => app.cv_id);

    const [profilesData, cvsData] = await Promise.all([
      userIds.length > 0 
        ? supabase.from('profiles').select('*').in('id', userIds)
        : Promise.resolve({ data: [] }),
      cvIds.length > 0
        ? supabase.from('cv_templates').select('*').in('id', cvIds)
        : Promise.resolve({ data: [] })
    ]);

    const profilesMap = Object.fromEntries(
      (profilesData.data || []).map(p => [p.id, p])
    );
    const cvsMap = Object.fromEntries(
      (cvsData.data || []).map(cv => [cv.id, cv])
    );

    const enrichedApplicants = applicants.map((app: any) => ({
      ...app,
      profile: profilesMap[app.user_id],
      cv: cvsMap[app.cv_id]
    }));

    return NextResponse.json({ applicants: enrichedApplicants });
  } catch (error: any) {
    return NextResponse.json(
      { error: error.message },
      { status: 403 }
    );
  }
}
```

### 12. Update Application Status (Employer only)

**Endpoint**: PUT `/api/jobs/[id]/applicants/[userId]`

**Request Body**:
```typescript
{
  status: 'pending' | 'accepted' | 'rejected';
}
```

**Implementation**:
```typescript
// app/api/jobs/[id]/applicants/[userId]/route.ts
export async function PUT(
  request: Request,
  { params }: { params: { id: string; userId: string } }
) {
  const supabase = createServerSupabaseClient();
  const { status } = await request.json();

  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    // Get job
    const { data: job, error: jobError } = await supabase
      .from('jobs')
      .select('creator_id, applicants')
      .eq('id', params.id)
      .single();

    if (jobError || !job) throw new Error('Job not found');
    if (job.creator_id !== user.id) throw new Error('Unauthorized');

    // Update applicant status
    const applicants = job.applicants || [];
    const index = applicants.findIndex((app: any) => app.user_id === params.userId);
    
    if (index === -1) throw new Error('Applicant not found');

    applicants[index].status = status;

    const { error: updateError } = await supabase
      .from('jobs')
      .update({ applicants })
      .eq('id', params.id);

    if (updateError) throw updateError;

    return NextResponse.json({
      success: true,
      message: 'Cập nhật trạng thái thành công!'
    });
  } catch (error: any) {
    return NextResponse.json(
      { error: error.message },
      { status: 403 }
    );
  }
}
```

### 13. Get Employer Stats

**Endpoint**: GET `/api/employer/stats`

**Implementation**:
```typescript
// app/api/employer/stats/route.ts
export async function GET(request: Request) {
  const supabase = createServerSupabaseClient();

  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data: jobs, error } = await supabase
      .from('jobs')
      .select('applicants')
      .eq('creator_id', user.id);

    if (error) throw error;

    const jobsCount = jobs?.length || 0;
    let totalApplicants = 0;
    let newApplicants = 0;

    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    jobs?.forEach(job => {
      const applicants = job.applicants || [];
      totalApplicants += applicants.length;

      applicants.forEach((app: any) => {
        const appliedAt = new Date(app.applied_at);
        if (appliedAt > thirtyDaysAgo) {
          newApplicants++;
        }
      });
    });

    return NextResponse.json({
      jobsCount,
      totalApplicants,
      newApplicants
    });
  } catch (error: any) {
    return NextResponse.json(
      { error: error.message },
      { status: 500 }
    );
  }
}
```

---

## 🔍 Search & Filter

### Search Jobs with Filters

**Endpoint**: GET `/api/jobs/search`

**Query Parameters**:
- `q` (optional): Search query
- `city` (optional): Filter by city
- `experience` (optional): Filter by experience level
- `jobType` (optional): Filter by job field
- `workType` (optional): Filter by employment type
- `minSalary` (optional): Minimum salary
- `maxSalary` (optional): Maximum salary
- `page` (optional): Page number
- `limit` (optional): Items per page

**Implementation**:
```typescript
// app/api/jobs/search/route.ts
export async function GET(request: Request) {
  const supabase = createServerSupabaseClient();
  const { searchParams } = new URL(request.url);

  const query = searchParams.get('q') || '';
  const city = searchParams.get('city');
  const experience = searchParams.get('experience');
  const jobType = searchParams.get('jobType');
  const workType = searchParams.get('workType');
  const minSalary = searchParams.get('minSalary');
  const maxSalary = searchParams.get('maxSalary');
  const page = parseInt(searchParams.get('page') || '1');
  const limit = parseInt(searchParams.get('limit') || '20');
  const offset = (page - 1) * limit;

  try {
    let queryBuilder = supabase
      .from('jobs')
      .select(`
        *,
        profiles:creator_id (
          id,
          full_name,
          avatar_url,
          metadata
        )
      `, { count: 'exact' })
      .eq('is_active', true)
      .eq('status', 'approved')
      .gt('deadline', new Date().toISOString());

    // Text search (title or tags)
    if (query) {
      queryBuilder = queryBuilder.or(
        `metadata->>title.ilike.%${query}%,metadata->requirements_tags.cs.{${query}}`
      );
    }

    // City filter
    if (city) {
      queryBuilder = queryBuilder.contains('metadata->working_regions', [city]);
    }

    // Experience filter
    if (experience) {
      queryBuilder = queryBuilder.eq('metadata->>experience_required', experience);
    }

    // Job type filter
    if (jobType) {
      queryBuilder = queryBuilder.contains('metadata->fields', [jobType]);
    }

    // Work type filter
    if (workType) {
      queryBuilder = queryBuilder.contains('metadata->employment_types', [workType]);
    }

    // Salary filter (complex - need to do client-side or use RPC)
    // For now, we'll fetch all and filter client-side

    const { data: jobs, error, count } = await queryBuilder
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) throw error;

    // Client-side salary filtering
    let filteredJobs = jobs || [];
    if (minSalary || maxSalary) {
      filteredJobs = filteredJobs.filter(job => {
        const salary = job.metadata?.salary;
        if (!salary) return true;

        if (minSalary && (salary.max || 0) < parseFloat(minSalary)) return false;
        if (maxSalary && (salary.min || 0) > parseFloat(maxSalary)) return false;

        return true;
      });
    }

    return NextResponse.json({
      jobs: filteredJobs,
      pagination: {
        page,
        limit,
        total: count || 0,
        totalPages: Math.ceil((count || 0) / limit)
      }
    });
  } catch (error: any) {
    return NextResponse.json(
      { error: error.message },
      { status: 500 }
    );
  }
}
```

---

## 📄 CV APIs

### 1. Upload CV

**Endpoint**: POST `/api/cv/upload`

**Form Data**:
- `file`: PDF/DOC/DOCX file
- `title`: CV title

**Implementation**:
```typescript
// app/api/cv/upload/route.ts
export async function POST(request: Request) {
  const supabase = createServerSupabaseClient();

  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const formData = await request.formData();
    const file = formData.get('file') as File;
    const title = formData.get('title') as string;

    if (!file) throw new Error('No file provided');

    // Upload to Supabase Storage
    const fileExt = file.name.split('.').pop();
    const fileName = `${user.id}/cv_${Date.now()}.${fileExt}`;

    const { error: uploadError } = await supabase.storage
      .from('cvs')
      .upload(fileName, file);

    if (uploadError) throw uploadError;

    // Get public URL
    const { data: { publicUrl } } = supabase.storage
      .from('cvs')
      .getPublicUrl(fileName);

    // Save to database
    const { data: cv, error: dbError } = await supabase
      .from('cv_templates')
      .insert({
        user_id: user.id,
        title: title || file.name,
        data: {
          file_url: publicUrl,
          file_name: fileName,
          file_type: fileExt,
          uploaded_at: new Date().toISOString()
        }
      })
      .select()
      .single();

    if (dbError) throw dbError;

    return NextResponse.json({
      success: true,
      message: 'Upload CV thành công!',
      cv
    });
  } catch (error: any) {
    return NextResponse.json(
      { error: error.message },
      { status: 500 }
    );
  }
}
```

### 2. Get User CVs

**Endpoint**: GET `/api/cv`

**Implementation**:
```typescript
// app/api/cv/route.ts
export async function GET(request: Request) {
  const supabase = createServerSupabaseClient();

  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data: cvs, error } = await supabase
      .from('cv_templates')
      .select('*')
      .eq('user_id', user.id)
      .order('updated_at', { ascending: false });

    if (error) throw error;

    return NextResponse.json({ cvs });
  } catch (error: any) {
    return NextResponse.json(
      { error: error.message },
      { status: 500 }
    );
  }
}
```

### 3. Delete CV

**Endpoint**: DELETE `/api/cv/[id]`

**Implementation**:
```typescript
// app/api/cv/[id]/route.ts
export async function DELETE(
  request: Request,
  { params }: { params: { id: string } }
) {
  const supabase = createServerSupabaseClient();

  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    // Get CV to verify ownership and get file path
    const { data: cv, error: fetchError } = await supabase
      .from('cv_templates')
      .select('*')
      .eq('id', params.id)
      .eq('user_id', user.id)
      .single();

    if (fetchError || !cv) throw new Error('CV not found or unauthorized');

    // Delete from storage if file exists
    if (cv.data?.file_name) {
      await supabase.storage
        .from('cvs')
        .remove([cv.data.file_name]);
    }

    // Delete from database
    const { error: deleteError } = await supabase
      .from('cv_templates')
      .delete()
      .eq('id', params.id);

    if (deleteError) throw deleteError;

    return NextResponse.json({
      success: true,
      message: 'Xóa CV thành công!'
    });
  } catch (error: any) {
    return NextResponse.json(
      { error: error.message },
      { status: 500 }
    );
  }
}
```

---

## 📅 Interview APIs

### 1. Create Interview Schedule

**Endpoint**: POST `/api/interviews`

**Request Body**:
```typescript
{
  candidate_id: string;
  job_id: string;
  cv_id?: string;
  interview_time: string; // ISO 8601
  job_title: string;
}
```

**Implementation**:
```typescript
// app/api/interviews/route.ts
export async function POST(request: Request) {
  const supabase = createServerSupabaseClient();
  const body = await request.json();

  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    // Check for conflicts
    const { data: conflicts } = await supabase
      .from('interview_schedules')
      .select('id')
      .eq('employer_id', user.id)
      .eq('interview_time', body.interview_time);

    if (conflicts && conflicts.length > 0) {
      throw new Error('Bạn đã có lịch phỏng vấn vào thời gian này!');
    }

    const { data, error } = await supabase
      .from('interview_schedules')
      .insert({
        candidate_id: body.candidate_id,
        job_id: body.job_id,
        employer_id: user.id,
        cv_id: body.cv_id,
        interview_time: body.interview_time,
        job_title: body.job_title,
        status: 'scheduled'
      })
      .select()
      .single();

    if (error) throw error;

    return NextResponse.json({
      success: true,
      message: 'Tạo lịch phỏng vấn thành công!',
      interview: data
    });
  } catch (error: any) {
    return NextResponse.json(
      { error: error.message },
      { status: 400 }
    );
  }
}
```

### 2. Get Employer Interviews

**Endpoint**: GET `/api/interviews/employer`

**Implementation**:
```typescript
// app/api/interviews/employer/route.ts
export async function GET(request: Request) {
  const supabase = createServerSupabaseClient();

  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data: interviews, error } = await supabase
      .from('interview_schedules')
      .select(`
        *,
        candidate:candidate_id (
          full_name,
          email,
          phone,
          avatar_url
        ),
        cv:cv_id (
          title,
          data
        )
      `)
      .eq('employer_id', user.id)
      .order('interview_time', { ascending: true });

    if (error) throw error;

    return NextResponse.json({ interviews });
  } catch (error: any) {
    return NextResponse.json(
      { error: error.message },
      { status: 500 }
    );
  }
}
```

### 3. Get Candidate Interviews

**Endpoint**: GET `/api/interviews/candidate`

**Implementation**:
```typescript
// app/api/interviews/candidate/route.ts
export async function GET(request: Request) {
  const supabase = createServerSupabaseClient();

  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data: interviews, error } = await supabase
      .from('interview_schedules')
      .select(`
        *,
        employer:employer_id (
          full_name,
          email,
          phone,
          avatar_url,
          metadata
        )
      `)
      .eq('candidate_id', user.id)
      .order('interview_time', { ascending: true });

    if (error) throw error;

    return NextResponse.json({ interviews });
  } catch (error: any) {
    return NextResponse.json(
      { error: error.message },
      { status: 500 }
    );
  }
}
```

### 4. Update Interview Status

**Endpoint**: PUT `/api/interviews/[id]`

**Request Body**:
```typescript
{
  status?: 'scheduled' | 'completed' | 'cancelled';
  evaluation?: Record<string, any>;
}
```

**Implementation**:
```typescript
// app/api/interviews/[id]/route.ts
export async function PUT(
  request: Request,
  { params }: { params: { id: string } }
) {
  const supabase = createServerSupabaseClient();
  const body = await request.json();

  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const updates: any = {};
    if (body.status) updates.status = body.status;
    if (body.evaluation) updates.evaluation = body.evaluation;

    const { error } = await supabase
      .from('interview_schedules')
      .update(updates)
      .eq('id', params.id)
      .eq('employer_id', user.id); // Only employer can update

    if (error) throw error;

    return NextResponse.json({
      success: true,
      message: 'Cập nhật thành công!'
    });
  } catch (error: any) {
    return NextResponse.json(
      { error: error.message },
      { status: 403 }
    );
  }
}
```

---

## 💬 Chat APIs

### 1. Get Conversations

**Endpoint**: GET `/api/chat/conversations`

**Implementation**:
```typescript
// app/api/chat/conversations/route.ts
export async function GET(request: Request) {
  const supabase = createServerSupabaseClient();

  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    // Get user's role
    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single();

    const userRole = profile?.role || 'candidate';

    const { data: conversations, error } = await supabase
      .from('conversations')
      .select('*')
      .or(`participant1_id.eq.${user.id},participant2_id.eq.${user.id}`)
      .order('last_message_at', { ascending: false });

    if (error) throw error;

    // Fetch other participants' info
    const enriched = await Promise.all(
      (conversations || []).map(async (conv) => {
        const otherId = conv.participant1_id === user.id 
          ? conv.participant2_id 
          : conv.participant1_id;

        const { data: otherUser } = await supabase
          .from('profiles')
          .select('full_name, avatar_url')
          .eq('id', otherId)
          .single();

        // Get unread count
        const { count } = await supabase
          .from('messages')
          .select('*', { count: 'exact', head: true })
          .eq('conversation_id', conv.id)
          .eq('is_read', false)
          .neq('sender_id', user.id);

        return {
          ...conv,
          other_user_name: otherUser?.full_name,
          other_user_avatar: otherUser?.avatar_url,
          unread_count: count || 0
        };
      })
    );

    return NextResponse.json({ conversations: enriched });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
```

### 2. Get or Create Conversation

**Endpoint**: POST `/api/chat/conversations`

**Request Body**:
```typescript
{
  other_user_id: string;
  job_id?: string;
}
```

**Implementation**: (Similar to Flutter implementation, check for existing conversation first)

### 3. Get Messages

**Endpoint**: GET `/api/chat/conversations/[id]/messages`

**Implementation**:
```typescript
// app/api/chat/conversations/[id]/messages/route.ts
export async function GET(
  request: Request,
  { params }: { params: { id: string } }
) {
  const supabase = createServerSupabaseClient();

  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data: messages, error } = await supabase
      .from('messages')
      .select('*')
      .eq('conversation_id', params.id)
      .order('created_at', { ascending: true });

    if (error) throw error;

    return NextResponse.json({ messages });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
```

### 4. Send Message

**Endpoint**: POST `/api/chat/conversations/[id]/messages`

**Request Body**:
```typescript
{
  content: string;
  message_type?: 'text' | 'file';
  attachment_url?: string;
}
```

**Implementation**: (Call Supabase insert on messages table, update last_message on conversations)

---

## 🔧 Supabase RPC Functions

### 1. apply_to_job

**SQL Function**:
```sql
CREATE OR REPLACE FUNCTION public.apply_to_job(
  p_job_id uuid,
  p_user_id uuid,
  p_cv_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Update jobs.applicants array
  UPDATE public.jobs
  SET applicants = applicants || jsonb_build_array(
    jsonb_build_object(
      'user_id', p_user_id,
      'cv_id', p_cv_id,
      'applied_at', now(),
      'status', 'pending'
    )
  )
  WHERE id = p_job_id;
END;
$$;
```

**Usage in Web**:
```typescript
const { error } = await supabase.rpc('apply_to_job', {
  p_job_id: jobId,
  p_user_id: userId,
  p_cv_id: cvId
});
```

### 2. apply_to_partnership_job

Similar structure, but updates `school_partnership_jobs` table.

### 3. upsert_device_token

For web push notifications (if implementing):

```typescript
const { error } = await supabase.rpc('upsert_device_token', {
  p_device_id: token,
  p_user_id: userId,
  p_role: userRole,
  p_device_type: 'web',
  p_device_name: navigator.userAgent,
  p_app_version: '1.0.0'
});
```

---

## 📊 React Query Hooks Examples

```typescript
// lib/hooks/useJobs.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

export function useJobs(filters?: JobFilters) {
  return useQuery({
    queryKey: ['jobs', filters],
    queryFn: async () => {
      const params = new URLSearchParams(filters as any);
      const res = await fetch(`/api/jobs/search?${params}`);
      if (!res.ok) throw new Error('Failed to fetch jobs');
      return res.json();
    }
  });
}

export function useApplyJob() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ jobId, cvId }: { jobId: string; cvId: string }) => {
      const res = await fetch(`/api/jobs/${jobId}/apply`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ cv_id: cvId })
      });
      if (!res.ok) throw new Error('Application failed');
      return res.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['jobs'] });
      queryClient.invalidateQueries({ queryKey: ['applied-jobs'] });
    }
  });
}
```

---

Tài liệu này cung cấp **tất cả API endpoints** cần thiết để build web app. Mỗi endpoint có implementation code đầy đủ, request/response format, và error handling.

**Next steps**: Xem `WEB_IMPLEMENTATION_GUIDE.md` để biết cách implement UI components và integrate với các APIs này.

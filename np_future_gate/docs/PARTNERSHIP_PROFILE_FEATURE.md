# Partnership Jobs - Company & School Profile Feature

## 📋 Implementation Checklist

### 1. **Hiển thị Company trong Partnership Job Card**

**Location:** `content_management_page_admin.dart` - `_buildJobCard()`

**Changes needed:**
```dart
// For partnership jobs, fetch BOTH school and company info
if (type == 'school_partnership') {
  final schoolId = job['school_id'];
  final companyId = job['company_id'];
  
  // Display both in header:
  // 🟣 School1 → Company1  [Liên kết]
}
```

**UI Design:**
```
┌────────────────────────────────────┐
│ 🏫 School Name → 🏢 Company Name  │
│ ⏰ 2 giờ trước              [Liên kết] │
├────────────────────────────────────┤
│ Senior Flutter Developer           │
│ ...                                │
└────────────────────────────────────┘
```

---

### 2. **Job Detail Dialog - Add Profile Links**

**Location:** `content_management_page_admin.dart` - `_showJobDetail()`

**Add section after header:**
```dart
// Partnership info section
if (isPartnership) {
  _buildPartnershipInfoSection(
    schoolId: job['school_id'],
    companyId: job['company_id'],
  ),
}
```

**UI Design:**
```
┌─────────────────────────────────┐
│ Chi tiết việc làm            ✕  │
├─────────────────────────────────┤
│                                 │
│ 📋 Thông tin liên kết          │
│ ┌─────────────────────────────┐│
│ │ 🏫 School Name              ││
│ │ Xem profile →               ││
│ └─────────────────────────────┘│
│ ┌─────────────────────────────┐│
│ │ 🏢 Company Name             ││
│ │ Xem profile →               ││
│ └─────────────────────────────┘│
│                                 │
│ 📋 Senior Flutter Developer     │
│ ...                             │
└─────────────────────────────────┘
```

---

### 3. **Create Helper Functions**

#### 3.1 Fetch Partnership Info
```dart
Future<Map<String, dynamic>> _getPartnershipInfo(String jobId) async {
  final job = await _supabase
      .from('school_partnership_jobs')
      .select('school_id, company_id')
      .eq('id', jobId)
      .single();
      
  final schoolInfo = await _getCreatorInfo(job['school_id']);
  final companyInfo = await _getCreatorInfo(job['company_id']);
  
  return {
    'school': schoolInfo,
    'company': companyInfo,
  };
}
```

#### 3.2 Build Partnership Info Widget
```dart
Widget _buildPartnershipInfoSection({
  required String schoolId,
  required String companyId,
}) {
  return FutureBuilder<Map<String, dynamic>>(
    future: _getBothProfiles(schoolId, companyId),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return CircularProgressIndicator();
      }
      
      final school = snapshot.data!['school'];
      final company = snapshot.data!['company'];
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thông tin liên kết', style: boldStyle),
          SizedBox(height: 12),
          
          // School card
          _buildProfileCard(
            name: school['name'],
            icon: Icons.school,
            color: Colors.green,
            onTap: () => _navigateToUserDetail(schoolId),
          ),
          
          SizedBox(height: 12),
          
          // Company card
          _buildProfileCard(
            name: company['name'],
            icon: Icons.business,
            color: Colors.blue,
            onTap: () => _navigateToUserDetail(companyId),
          ),
        ],
      );
    },
  );
}
```

#### 3.3 Profile Card Widget
```dart
Widget _buildProfileCard({
  required String name,
  required IconData icon,
  required Color color,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    ),
  );
}
```

#### 3.4 Navigate to User Detail
```dart
void _navigateToUserDetail(String userId) async {
  // Reuse existing UserDetailScreen
  final profile = await _supabase
      .from('profiles')
      .select()
      .eq('id', userId)
      .single();
      
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => UserDetailScreen(
        user: Profile.fromJson(profile),
      ),
    ),
  );
}
```

---

### 4. **Update Job Card Header**

**For Partnership Jobs:**
```dart
// Old header shows only school
Row(
  children: [
    Icon(school),
    Text('School Name'),
    Badge('Liên kết'),
  ],
)

// New header shows school → company
Row(
  children: [
    Icon(school),
    Text('School Name'),
    Icon(arrow_forward, size: 14),
    Icon(business),
    Text('Company Name'),
    Badge('Liên kết'),
  ],
)
```

---

### 5. **Database Queries Needed**

```sql
-- Get partnership with both profiles
SELECT 
  spj.*,
  school.full_name as school_name,
  school.metadata->>'school_name' as school_display_name,
  company.full_name as company_name,
  company.metadata->>'company_name' as company_display_name
FROM school_partnership_jobs spj
LEFT JOIN profiles school ON spj.school_id = school.id
LEFT JOIN profiles company ON spj.company_id = company.id
WHERE spj.id = ?
```

---

## 🎨 UI Improvements

### Partnership Job Badge Enhancement
```dart
// Show both entities in badge
Container(
  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Colors.green.shade400, Colors.purple.shade400],
    ),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Row(
    children: [
      Icon(Icons.handshake, size: 12, color: Colors.white),
      SizedBox(width: 4),
      Text('Liên kết', style: whiteTextStyle),
    ],
  ),
)
```

---

## 📝 Implementation Steps

1. ✅ Update `_buildJobCard()` to show company for partnership
2. ✅ Add `_getPartnershipInfo()` helper
3. ✅ Create `_buildPartnershipInfoSection()` widget
4. ✅ Create `_buildProfileCard()` widget
5. ✅ Add `_navigateToUserDetail()` navigation
6. ✅ Update job detail dialog to include partnership section
7. ✅ Test with real partnership jobs
8. ✅ Add loading states
9. ✅ Add error handling

---

## 🚀 Quick Implementation (Simplified)

If you want quick implementation, add this to job detail:

```dart
// In _showJobDetail(), after title:
if (isPartnership) {
  const SizedBox(height: 16),
  Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.purple.shade50,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.handshake, color: Colors.purple),
            SizedBox(width: 8),
            Text('Liên kết doanh nghiệp', 
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        SizedBox(height: 12),
        FutureBuilder(
          future: _supabase.from('profiles')
              .select('full_name, metadata')
              .eq('id', job['school_id'])
              .single(),
          builder: (context, schoolSnap) {
            return ListTile(
              leading: Icon(Icons.school, color: Colors.green),
              title: Text(schoolSnap.data?['metadata']
                  ['school_name'] ?? 'N/A'),
              trailing: IconButton(
                icon: Icon(Icons.arrow_forward),
                onPressed: () => _navigateToUserDetail(
                    job['school_id']),
              ),
            );
          },
        ),
        FutureBuilder(
          future: _supabase.from('profiles')
              .select('full_name, metadata')
              .eq('id', job['company_id'])
              .single(),
          builder: (context, companySnap) {
            return ListTile(
              leading: Icon(Icons.business, color: Colors.blue),
              title: Text(companySnap.data?['metadata']
                  ['company_name'] ?? 'N/A'),
              trailing: IconButton(
                icon: Icon(Icons.arrow_forward),
                onPressed: () => _navigateToUserDetail(
                    job['company_id']),
              ),
            );
          },
        ),
      ],
    ),
  ),
}
```

---

## ⚠️ Important Notes

1. Import `UserDetailScreen` vào content management
2. Tận dụng existing profile fetch logic
3. Reuse `UserDetailScreen` để xem chi tiết
4. Add loading indicators khi fetch profiles
5. Handle errors gracefully

---

## 📱 Expected UX Flow

1. User clicks "Chi tiết" on partnership job
2. Modal shows with partnership section at top
3. User sees both School and Company cards
4. User clicks arrow on School → Navigate to UserDetailScreen(school)
5. User clicks arrow on Company → Navigate to UserDetailScreen(company)
6. In UserDetailScreen, user can see full stats, activities, etc.

---

**Next Session:** Implement these changes step by step! 🚀

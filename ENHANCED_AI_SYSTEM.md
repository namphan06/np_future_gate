# 🤖 Enhanced AI System - Documentation

## Tổng quan

Hệ thống AI thông minh có khả năng:
1. **Phân loại câu hỏi** (Intent Detection) - Nhận diện ý định người dùng
2. **Lấy dữ liệu từ Supabase** - Dựa trên context và role
3. **Hiển thị data với UI đẹp** - Chart, list, card tùy theo loại data
4. **Phân quyền theo role** - Employer, Student, School có queries khác nhau

---

## 📁 Cấu trúc Files

### 1. **Models** (`lib/core/models/`)

#### `ai_intent_model.dart`
- `AIIntent`: Định nghĩa một intent (ý định) người dùng
  - `id`: Unique identifier
  - `keywords`: Từ khóa để match
  - `patterns`: Mẫu câu hỏi
  - `requiredRoles`: Role được phép sử dụng
  - `actionType`: 'data_query' hoặc 'general_chat'
  - `queryConfig`: Cấu hình query Supabase

- `IntentAnalysisResult`: Kết quả phân tích câu hỏi
- `AIResponseWithData`: Response từ AI kèm data

### 2. **Services** (`lib/core/services/`)

#### `ai_intent_service.dart`
**Chức năng:** Phân tích câu hỏi và tìm intent phù hợp

**Methods:**
- `analyzeUserQuery(query, userRole)`: Phân tích câu hỏi
- `_calculateMatchScore()`: Tính điểm match với intent
- `_extractParameters()`: Trích xuất params (today, status, etc.)
- `getIntentsByRole()`: Lấy intents theo role

**Intent Matching Algorithm:**
```
Score = (keyword_matches * 0.3) + (pattern_matches * 0.4) + (bonus * 0.2)
Threshold = 0.6 (60% confidence)
```

#### `enhanced_ai_service.dart`
**Chức năng:** Kết hợp AI với data từ Supabase

**Workflow:**
```
User Query
    ↓
Analyze Intent → Confidence >= 60%?
    ↓ Yes                    ↓ No
Data Query              General Chat
    ↓                           ↓
Fetch from Supabase     Mistral AI
    ↓                           ↓
Format with AI          Response
    ↓                           ↓
Return with Chart Type  Return Text
```

### 3. **Repositories** (`lib/core/repositories/`)

#### `ai_data_repository.dart`
**Chức năng:** Lấy dữ liệu từ Supabase theo Intent

**Queries được implement:**

**EMPLOYER:**
- `employer_applications_today`: Ứng viên ứng tuyển hôm nay
- `employer_job_status`: Tình trạng tin (pending/approved/rejected)
- `employer_expired_jobs`: Tin hết hạn
- `employer_active_jobs`: Tin còn hạn
- `employer_interviews`: Tất cả lịch phỏng vấn
- `employer_upcoming_interviews`: Lịch phỏng vấn 7 ngày tới
- `employer_partnership_requests`: Yêu cầu liên kết

**STUDENT:**
- `student_applied_jobs`: Công việc đã ứng tuyển
- `student_interviews`: Lịch phỏng vấn của tôi
- `student_recommended_jobs`: Gợi ý công việc

**SCHOOL:**
- `school_partners`: Doanh nghiệp liên kết
- `school_partnership_jobs`: Công việc từ đối tác

---

## 🎯 Cách hoạt động

### Ví dụ 1: Employer hỏi "Có ứng viên nào ứng tuyển hôm nay không?"

```dart
1. Intent Service:
   - Detect keywords: ["ứng viên", "ứng tuyển", "hôm nay"]
   - Match intent: employer_applications_today (confidence: 0.9)
   - Extract params: {time_filter: 'today'}

2. Data Repository:
   - Query: applications WHERE employer_id = user AND created_at >= today
   - Include: student profile, job info
   - Return: 5 applications

3. Enhanced AI Service:
   - Prompt AI: "Người dùng hỏi về ứng viên. Có 5 kết quả."
   - AI response: "Bạn có 5 ứng viên ứng tuyển hôm nay..."
   - Chart type: 'application_list'

4. UI renders: List of applications with candidate info
```

### Ví dụ 2: Student hỏi "Cho tôi viết CV"

```dart
1. Intent Service:
   - No keywords match data queries
   - Confidence: 0.2 (< threshold)
   - Result: General chat

2. Mistral AI:
   - Process query normally
   - Response: "Để viết CV tốt, bạn nên..."

3. UI renders: Text response only
```

---

## 🔧 Cách sử dụng

### Integration vào Chatbot Screen

```dart
import 'package:np_future_gate/core/services/enhanced_ai_service.dart';
import 'package:np_future_gate/core/models/ai_intent_model.dart';

class ChatbotScreen extends StatefulWidget {
  // ... existing code ...
  
  final EnhancedAIService _aiService = EnhancedAIService();
  
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    
    // Get current user info
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final userRole = await _getUserRole(); // 'employer', 'student', 'school'
    
    setState(() => _isLoading = true);
    
    try {
      // Process with enhanced AI
      final response = await _aiService.processUserQuery(
        query: message,
        userId: userId,
        userRole: userRole,
      );
      
      if (response.data != null) {
        // Có data → hiển thị với chart
        _addDataMessage(response.message, response.chartType!, response.data!);
      } else {
        // Không có data → hiển thị text bình thường
        _addMessage(response.message, isUser: false);
      }
    } catch (e) {
      _addMessage('Xin lỗi, đã có lỗi xảy ra.', isUser: false);
    }
    
    setState(() => _isLoading = false);
  }
}
```

---

## 🎨 UI Components cho Data

### Chart Types

1. **`application_list`**: Danh sách ứng viên với avatar, name, skills
2. **`interview_list`**: Lịch phỏng vấn dạng timeline/calendar
3. **`job_list`**: Danh sách công việc với company logo
4. **`job_stats`**: Thống kê (pie chart, bar chart)
5. **`card_list`**: Card view cho partnerships

### Example Widget

```dart
Widget _buildDataMessage(String message, String chartType, List data) {
  return Column(
    children: [
      // AI message
      _buildMessageBubble(ChatMessage(text: message, isUser: false)),
      
      // Data visualization
      if (chartType == 'application_list')
        _buildApplicationList(data),
      else if (chartType == 'interview_list')
        _buildInterviewList(data),
      // ... other types
    ],
  );
}
```

---

## 🚀 Mở rộng

### Thêm Intent mới

1. Thêm vào `_getDefaultIntents()` trong `ai_intent_service.dart`
2. Implement query trong `ai_data_repository.dart`
3. (Optional) Thêm UI component cho chart type

### Cải thiện Intent Detection

- Thêm keywords vào intent
- Thêm patterns (mẫu câu)
- Điều chỉnh scoring algorithm
- Sử dụng ML model (future)

### Optimization

- Cache intents trong memory
- Cache common queries
- Implement full-text search
- Add analytics

---

## 📊 Performance

- Intent analysis: < 50ms
- Supabase query: 100-500ms (depends on data)
- AI response: 1-3s
- **Total**: ~2-4s per query

---

## ✅ Testing

```dart
// Test intent detection
final intentService = AIIntentService();
await intentService.loadIntents();

final result = await intentService.analyzeUserQuery(
  'Có bao nhiêu ứng viên ứng tuyển hôm nay?',
  'employer',
);

expect(result.matchedIntent?.id, 'employer_applications_today');
expect(result.confidence, greaterThan(0.6));
```

---

## 🎯 Roadmap

- [ ] Add more intents (statistics, reports, etc.)
- [ ] Machine learning for better intent detection
- [ ] Voice input support
- [ ] Multi-language support
- [ ] Advanced data visualization
- [ ] Export data to PDF/Excel
- [ ] Scheduled queries (daily/weekly reports)

---

**Created by:** NP FutureGate Team
**Last updated:** Feb 2, 2026

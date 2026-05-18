# Data Test - CV Analysis Logs

Thư mục này chứa dữ liệu test từ quá trình phân tích CV.

## Cấu trúc log file

Mỗi lần phân tích CV sẽ tạo 1 file JSON trong thư mục `analysis_logs` của app (trên thiết bị).

### Đường dẫn trên thiết bị:
- **Android**: `/data/data/com.example.np_future_gate/app_flutter/analysis_logs/`
- **iOS**: `Documents/analysis_logs/`

### Format file JSON:

```json
{
  "timestamp": "2025-01-20T10:30:00.000",
  "source": "ML Kit OCR (file_url) | Structured Data (fallback) | ML Kit OCR (camera scan)",
  "job_data": {
    "raw_text": "Tiêu đề: Flutter Developer\nMô tả: ...\nYêu cầu: ...",
    "title": ""
  },
  "cv_data": {
    "extracted_text": "Nội dung CV được trích xuất bằng ML Kit OCR...",
    "text_length": 1500,
    "file_url": "https://supabase.co/storage/...",
    "raw_metadata_keys": ["id", "title", "data", "file_url"]
  },
  "ai_result": {
    "overall_score": 75.0,
    "semantic_similarity": 0.72,
    "keyword_match_score": 68.0,
    "matching_summary": "Ứng viên có kinh nghiệm phù hợp...",
    "matching_points": ["Có kinh nghiệm Flutter 2 năm", "Biết Dart"],
    "missing_points": ["Thiếu kinh nghiệm CI/CD"],
    "parsed_data": {
      "name": "Nguyễn Văn A",
      "skills": "Flutter, Dart, Firebase",
      "experience": "2 năm",
      "education": "CNTT - ĐH Bách Khoa"
    }
  }
}
```

## Pipeline xử lý

```
CV File (PDF/Image) 
    ↓
[ML Kit OCR - On Device]
    ↓ (extracted text)
[Mistral AI - Cloud]
    ↓ (analysis JSON)
[CVMatchingResult]
    ↓
[Save Log + Display UI]
```

## Lưu ý
- File PDF được render thành ảnh từng trang (pdfx) rồi mới OCR
- File ảnh (JPG/PNG) được OCR trực tiếp bằng ML Kit
- Nếu OCR thất bại → fallback sang structured data từ Supabase
- Log được lưu tự động mỗi lần phân tích thành công

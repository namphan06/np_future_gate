import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'mistral_service.dart';
import '../models/job_model.dart';

/// Model cho kết quả phân tích độ phù hợp của CV
class CVMatchingResult {
  final double overallScore; // 0-100
  final double semanticSimilarity; // Kết quả từ SentenceTransformer
  final double keywordMatchScore; // Kết quả từ LLM Matching
  final String matchingSummary;
  final List<String> matchingPoints;
  final List<String> missingPoints;
  final Map<String, dynamic> parsedData; // Dữ liệu sau khi qua PaddleOCR & LLM

  CVMatchingResult({
    required this.overallScore,
    required this.semanticSimilarity,
    required this.keywordMatchScore,
    required this.matchingSummary,
    required this.matchingPoints,
    required this.missingPoints,
    required this.parsedData,
  });

  factory CVMatchingResult.fromMock(double baseScore) {
    return CVMatchingResult(
      overallScore: baseScore,
      semanticSimilarity: baseScore * 0.9 / 100,
      keywordMatchScore: baseScore,
      matchingSummary: 'Hệ thống đang chạy chế độ giả lập do không kết nối được Server AI...',
      matchingPoints: ['Vui lòng kiểm tra server Python', 'Đảm bảo port 8000 đã mở'],
      missingPoints: ['Kết nối API thất bại'],
      parsedData: {"Status": "Mô phỏng"},
    );
  }
}

class AIMatchingService {
  final MistralService _mistralService = MistralService();
  
  // CẤU HÌNH ĐỊA CHỈ IP SERVER TẠI ĐÂY:
  static const String _pythonApiUrl = 'http://192.168.0.105:8000/analyze_cv';

  Future<CVMatchingResult> analyzeCVMatching({
    required Map<String, dynamic> cvData,
    required JobModel job,
  }) async {
    final String? fileUrl = cvData['file_url'];
    
    print('🚀 Đang bắt đầu phân tích AI...');
    print('🔗 Server AI URL: $_pythonApiUrl');
    
    // Ưu tiên xử lý bằng AI Backend thật (PaddleOCR)
    if (fileUrl != null && fileUrl.isNotEmpty) {
      try {
        print('📂 Đang tải CV từ: $fileUrl');
        return await _analyzeWithRealEngine(fileUrl, job);
      } catch (e) {
        print('❌ Lỗi kết nối AI Backend: $e');
        debugPrint('⚠️ Không thể kết nối AI Backend thật: $e');
      }
    }

    // Fallback: Sử dụng dữ liệu cấu trúc (nếu có) hoặc LLM phân tích văn bản cơ bản
    return await _analyzeStructuredCV(cvData, job);
  }

  Future<CVMatchingResult> _analyzeWithRealEngine(String fileUrl, JobModel job) async {
    try {
      final jobDesc = job.metadata.jobDescription.join('\n');
      final jobReq = job.metadata.candidateRequirements.join('\n');

      // 1. Tải file CV
      final responseFile = await http.get(Uri.parse(fileUrl)).timeout(const Duration(seconds: 10));
      if (responseFile.statusCode != 200) throw Exception("Tải file thất bại");

      // 2. Gửi tới Python Backend
      var request = http.MultipartRequest('POST', Uri.parse(_pythonApiUrl));
      request.fields['job_description'] = jobDesc;
      request.fields['requirements'] = jobReq;
      request.files.add(http.MultipartFile.fromBytes('cv_file', responseFile.bodyBytes, filename: 'cv.pdf'));

      var streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return CVMatchingResult(
          overallScore: (result['overall_score'] as num).toDouble(),
          semanticSimilarity: (result['semantic_similarity'] as num).toDouble(),
          keywordMatchScore: (result['keyword_match_score'] as num).toDouble(),
          matchingSummary: result['summary'] ?? '',
          matchingPoints: List<String>.from(result['matching_points'] ?? []),
          missingPoints: List<String>.from(result['missing_points'] ?? []),
          parsedData: result['parsed_data'] ?? {},
        );
      } else {
        throw Exception("Server trả về mã ${response.statusCode}");
      }
    } catch (e) {
      debugPrint('Error in RealEngine: $e');
      rethrow; // Ném lỗi để analyzeCVMatching biết và fallback
    }
  }

  Future<CVMatchingResult> _analyzeStructuredCV(Map<String, dynamic> cvData, JobModel job) async {
    final data = cvData['data'] ?? cvData;
    final cvContent = _convertStructuredCVToText(data);
    final jobContent = _convertJobToText(job);

    // Nếu không có nội dung thật (do lỗi server hoặc file upload chưa parse)
    final bool isLowData = cvContent.contains('N/A') && cvContent.length < 100;

    final prompt = '''
    PHÂN TÍCH ĐỘ PHÙ HỢP CV
    
    [THÔNG TIN CV]
    $cvContent
    ${cvData['file_url'] != null ? "(Lưu ý: Đây là file upload, nội dung trích xuất thô từ metadata)" : ""}
    
    [MÔ TẢ CÔNG VIỆC]
    $jobContent
    
    QUY TẮC:
    1. Trả về JSON duy nhất.
    2. Nếu dữ liệu CV quá ít/thiếu (N/A), hãy đặt overall_score < 20 và thông báo người dùng kiểm tra kết nối AI Server.
    
    JSON: { "overall_score": 0-100, "semantic_similarity": 0-1, "llm_matching_score": 0-100, "summary": "...", "matching_points": [], "missing_points": [], "parsed_cv_overview": {} }
    ''';

    try {
      final response = await _mistralService.sendMessage(prompt);
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).stringMatch(response);
      if (jsonMatch != null) {
        final result = jsonDecode(jsonMatch);
        return CVMatchingResult(
          overallScore: (result['overall_score'] as num).toDouble(),
          semanticSimilarity: (result['semantic_similarity'] as num).toDouble(),
          keywordMatchScore: (result['llm_matching_score'] as num).toDouble(),
          matchingSummary: isLowData ? "⚠️ Cảnh báo: Không thể kết nối Server AI để trích xuất dữ liệu thật từ CV. Kết quả bên dưới chỉ dựa trên thông tin sơ bộ." : (result['summary'] ?? ''),
          matchingPoints: List<String>.from(result['matching_points'] ?? []),
          missingPoints: List<String>.from(result['missing_points'] ?? []),
          parsedData: {
            ...(result['parsed_cv_overview'] ?? {}),
            "Status": isLowData ? "Mô phỏng (Lỗi kết nối AI Backend)" : "Thành công"
          },
        );
      }
    } catch (e) {
      debugPrint('Fallback AI Error: $e');
    }
    return CVMatchingResult.fromMock(10.0); // 10% nếu hoàn toàn thất bại
  }

  /// So sánh hai hoặc nhiều CV với nhau để chọn người tốt nhất
  Future<String> compareCVs({
    required List<Map<String, dynamic>> cvsData,
    required JobModel job,
  }) async {
    final jobContent = _convertJobToText(job);
    final List<String> cvLabels = [];
    final List<String> cvTexts = [];

    for (int i = 0; i < cvsData.length; i++) {
        final data = cvsData[i]['data'] ?? cvsData[i];
        cvLabels.add("Ứng viên ${i + 1} (${cvsData[i]['title'] ?? 'N/A'})");
        cvTexts.add(_convertStructuredCVToText(data));
    }

    final prompt = '''
    HÃY SO SÁNH CÁC ỨNG VIÊN DỰA TRÊN DỮ LIỆU THẬT
    Vị trí: ${job.metadata.title}.
    
    [JOB REQUIREMENTS]
    $jobContent
    
    [CANDIDATES DATA]
    ${List.generate(cvsData.length, (i) => "[${cvLabels[i]}]\n${cvTexts[i]}").join("\n\n")}
    
    Hãy đưa ra bảng so sánh chi tiết và Ranking người phù hợp nhất.
    Định dạng phản hồi: Markdown chuyên nghiệp.
    ''';

    return await _mistralService.sendMessage(prompt);
  }

  String _convertStructuredCVToText(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    
    // Find Name
    String name = data['full_name'] ?? 
                  data['name'] ?? 
                  data['personal_info']?['full_name'] ?? 
                  data['data']?['personal_info']?['full_name'] ?? 
                  'N/A';
    buffer.writeln("Họ tên: $name");

    // Find Headline/Title
    String title = data['title'] ?? 
                   data['headline'] ?? 
                   data['personal_info']?['title'] ?? 
                   'N/A';
    buffer.writeln("Tiêu đề: $title");
    
    // Find Experiences
    final experiences = data['experiences'] as List? ?? 
                        data['data']?['experiences'] as List? ?? 
                        [];
    buffer.writeln("Kinh nghiệm:");
    for (var exp in experiences) {
      if (exp is Map) {
        buffer.writeln("- ${exp['position'] ?? exp['title'] ?? ''} tại ${exp['company'] ?? ''} (${exp['duration'] ?? ''})");
      }
    }

    // Find Skills
    final skills = data['skills'] as List? ?? 
                   data['data']?['skills'] as List? ?? 
                   data['skills_tags'] as List? ??
                   [];
    
    String skillsText = skills.map((s) {
      if (s is Map) return s['name'] ?? s['title'] ?? '';
      return s.toString();
    }).where((s) => s.isNotEmpty).join(', ');
    
    buffer.writeln("Kỹ năng: ${skillsText.isEmpty ? 'N/A' : skillsText}");
    
    return buffer.toString();
  }

  String _convertJobToText(JobModel job) {
    final meta = job.metadata;
    return '''
    Tiêu đề: ${meta.title}
    Mô tả: ${meta.jobDescription.join('. ')}
    Yêu cầu: ${meta.candidateRequirements.join('. ')}
    Kỹ năng: ${meta.requirementsTags.join(', ')}
    Kinh nghiệm: ${meta.experienceRequired}
    ''';
  }
}

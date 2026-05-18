import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'mistral_service.dart';
import 'mlkit_ocr_service.dart';
import '../models/job_model.dart';

/// Model cho kết quả phân tích độ phù hợp của CV
class CVMatchingResult {
  final double overallScore; // 0-100
  final double semanticSimilarity; // Kết quả từ SentenceTransformer
  final double keywordMatchScore; // Kết quả từ LLM Matching
  final String matchingSummary;
  final List<String> matchingPoints;
  final List<String> missingPoints;
  final Map<String, dynamic> parsedData; // Dữ liệu sau khi qua OCR & LLM

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

  Map<String, dynamic> toJson() {
    return {
      'overall_score': overallScore,
      'semantic_similarity': semanticSimilarity,
      'keyword_match_score': keywordMatchScore,
      'matching_summary': matchingSummary,
      'matching_points': matchingPoints,
      'missing_points': missingPoints,
      'parsed_data': parsedData,
    };
  }
}

class AIMatchingService {
  final MistralService _mistralService = MistralService();
  final MLKitOcrService _mlkitService = MLKitOcrService();

  Future<CVMatchingResult> analyzeCVMatching({
    required Map<String, dynamic> cvData,
    required JobModel job,
  }) async {
    final String? fileUrl = cvData['file_url'] ?? cvData['data']?['file_url'];
    
    debugPrint('🚀 Đang bắt đầu phân tích AI...');
    
    // Ưu tiên xử lý bằng ML Kit OCR (on-device)
    if (fileUrl != null && fileUrl.isNotEmpty) {
      try {
        debugPrint('📂 Đang tải CV từ: $fileUrl');
        return await _analyzeWithMLKit(fileUrl, job, cvData);
      } catch (e) {
        debugPrint('❌ Lỗi ML Kit OCR: $e');
        debugPrint('⚠️ Fallback sang structured data...');
      }
    }

    // Fallback: Sử dụng dữ liệu cấu trúc (nếu có) + LLM phân tích
    return await _analyzeStructuredCV(cvData, job);
  }

  /// Phân tích CV bằng ML Kit OCR (hỗ trợ cả ảnh và PDF)
  Future<CVMatchingResult> _analyzeWithMLKit(
    String fileUrl, 
    JobModel job,
    Map<String, dynamic> cvData,
  ) async {
    debugPrint('🔍 Using ML Kit (on-device) for OCR analysis...');

    // ML Kit service tự động phát hiện ảnh/PDF và xử lý phù hợp
    final ocrResult = await _mlkitService.extractTextFromUrl(fileUrl);

    if (!ocrResult.success) {
      throw Exception(ocrResult.error ?? 'ML Kit OCR failed');
    }

    final extractedText = ocrResult.text;
    if (extractedText.isEmpty) {
      throw Exception('Không trích xuất được văn bản');
    }

    debugPrint('✅ ML Kit extracted ${extractedText.length} chars (${ocrResult.pageCount} pages)');

    // Phân tích với Mistral AI
    final jobDesc = job.metadata.jobDescription.join('\n');
    final jobReq = job.metadata.candidateRequirements.join('\n');

    final prompt = '''
HÃY PHÂN TÍCH ĐỘ PHÙ HỢP CỦA CV VỚI CÔNG VIỆC

[VĂN BẢN CV TRÍCH XUẤT TỪ ML KIT OCR]
$extractedText

[YÊU CẦU CÔNG VIỆC]
Vị trí: ${job.metadata.title}
Mô tả: $jobDesc
Yêu cầu: $jobReq
Kỹ năng yêu cầu: ${job.metadata.requirementsTags.join(', ')}
Kinh nghiệm: ${job.metadata.experienceRequired}
Lĩnh vực: ${job.metadata.fields.join(', ')}

NHIỆM VỤ:
1. Đánh giá độ phù hợp (0-100).
2. Tính semantic similarity (0-1).
3. Tính keyword matching score (0-100).
4. Tóm tắt nhận xét (Tiếng Việt).
5. Liệt kê điểm mạnh (matching_points).
6. Liệt kê điểm còn thiếu (missing_points).
7. Trích xuất thông tin chính từ CV (parsed_data).

TRẢ VỀ JSON DUY NHẤT:
{
  "overall_score": number,
  "semantic_similarity": number,
  "keyword_match_score": number,
  "summary": "string",
  "matching_points": ["string"],
  "missing_points": ["string"],
  "parsed_data": {"name": "", "skills": "", "experience": "", "education": ""}
}
''';

    final aiResponse = await _mistralService.sendMessage(prompt);
    final jsonMatch = RegExp(r'\{.*\}', dotAll: true).stringMatch(aiResponse);

    if (jsonMatch != null) {
      final result = jsonDecode(jsonMatch);
      final cvResult = CVMatchingResult(
        overallScore: (result['overall_score'] as num).toDouble(),
        semanticSimilarity: (result['semantic_similarity'] as num).toDouble(),
        keywordMatchScore: (result['keyword_match_score'] as num).toDouble(),
        matchingSummary: result['summary'] ?? '',
        matchingPoints: List<String>.from(result['matching_points'] ?? []),
        missingPoints: List<String>.from(result['missing_points'] ?? []),
        parsedData: {
          ...(result['parsed_data'] ?? {}),
          'OCR Engine': 'Google ML Kit (On-device)',
          'Pages': ocrResult.pageCount,
        },
      );

      // Lưu log data test
      await _saveAnalysisLog(
        jobData: _convertJobToText(job),
        extractedCVText: extractedText,
        cvRawData: cvData,
        aiResult: cvResult,
        source: 'ML Kit OCR (file_url)',
      );

      return cvResult;
    } else {
      throw Exception('AI response was not valid JSON');
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
        final cvResult = CVMatchingResult(
          overallScore: (result['overall_score'] as num).toDouble(),
          semanticSimilarity: (result['semantic_similarity'] as num).toDouble(),
          keywordMatchScore: (result['llm_matching_score'] as num).toDouble(),
          matchingSummary: isLowData 
              ? "⚠️ Cảnh báo: Không thể trích xuất dữ liệu thật từ CV. Kết quả bên dưới chỉ dựa trên thông tin sơ bộ." 
              : (result['summary'] ?? ''),
          matchingPoints: List<String>.from(result['matching_points'] ?? []),
          missingPoints: List<String>.from(result['missing_points'] ?? []),
          parsedData: {
            ...(result['parsed_cv_overview'] ?? {}),
            "Status": isLowData ? "Dữ liệu hạn chế (structured data)" : "Thành công",
            "OCR Engine": "Structured Data (fallback)",
          },
        );

        // Lưu log data test
        await _saveAnalysisLog(
          jobData: jobContent,
          extractedCVText: cvContent,
          cvRawData: cvData,
          aiResult: cvResult,
          source: 'Structured Data (fallback)',
        );

        return cvResult;
      }
    } catch (e) {
      debugPrint('Fallback AI Error: $e');
    }
    return CVMatchingResult.fromMock(10.0);
  }

  /// Phân tích CV từ ảnh scan bằng ML Kit + Mistral AI
  /// Dùng cho nhà tuyển dụng scan CV ảnh trực tiếp
  Future<CVMatchingResult> analyzeCVFromImage({
    required File imageFile,
    required JobModel job,
  }) async {
    try {
      debugPrint('📸 Scanning CV image with ML Kit...');

      // Step 1: OCR với ML Kit
      final ocrResult = await _mlkitService.extractTextFromFile(imageFile);

      if (!ocrResult.success) {
        throw Exception(ocrResult.error ?? 'ML Kit OCR thất bại');
      }

      final extractedText = ocrResult.text;
      if (extractedText.isEmpty) {
        throw Exception('Không trích xuất được văn bản từ ảnh CV');
      }

      debugPrint('✅ ML Kit extracted ${extractedText.length} chars from scanned image');

      // Step 2: Phân tích với Mistral AI
      final result = await analyzeCVFromExtractedText(
        extractedText: extractedText,
        job: job,
      );

      // Lưu log
      await _saveAnalysisLog(
        jobData: _convertJobToText(job),
        extractedCVText: extractedText,
        cvRawData: {'source': 'camera_scan', 'image_path': imageFile.path},
        aiResult: result,
        source: 'ML Kit OCR (camera scan)',
      );

      return result;
    } catch (e) {
      debugPrint('❌ Error in analyzeCVFromImage: $e');
      rethrow;
    }
  }

  /// Phân tích CV từ text đã trích xuất sẵn (ML Kit đã xử lý trước)
  Future<CVMatchingResult> analyzeCVFromExtractedText({
    required String extractedText,
    required JobModel job,
  }) async {
    if (extractedText.isEmpty) {
      return CVMatchingResult.fromMock(0);
    }

    final jobDesc = job.metadata.jobDescription.join('\n');
    final jobReq = job.metadata.candidateRequirements.join('\n');

    final prompt = '''
HÃY PHÂN TÍCH ĐỘ PHÙ HỢP CỦA CV VỚI CÔNG VIỆC

[NỘI DUNG CV]
$extractedText

[THÔNG TIN CÔNG VIỆC]
Vị trí: ${job.metadata.title}
Mô tả: $jobDesc
Yêu cầu: $jobReq
Kỹ năng: ${job.metadata.requirementsTags.join(', ')}
Kinh nghiệm: ${job.metadata.experienceRequired}
Lĩnh vực: ${job.metadata.fields.join(', ')}

TRẢ VỀ JSON DUY NHẤT:
{
  "overall_score": number (0-100),
  "semantic_similarity": number (0-1),
  "keyword_match_score": number (0-100),
  "summary": "nhận xét tiếng Việt chi tiết",
  "matching_points": ["điểm phù hợp"],
  "missing_points": ["điểm thiếu"],
  "parsed_data": {"name": "", "skills": "", "experience": "", "education": ""}
}
''';

    try {
      final aiResponse = await _mistralService.sendMessage(prompt);
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).stringMatch(aiResponse);

      if (jsonMatch != null) {
        final result = jsonDecode(jsonMatch);
        return CVMatchingResult(
          overallScore: (result['overall_score'] as num).toDouble(),
          semanticSimilarity: (result['semantic_similarity'] as num).toDouble(),
          keywordMatchScore: (result['keyword_match_score'] as num).toDouble(),
          matchingSummary: result['summary'] ?? '',
          matchingPoints: List<String>.from(result['matching_points'] ?? []),
          missingPoints: List<String>.from(result['missing_points'] ?? []),
          parsedData: {
            ...(result['parsed_data'] ?? {}),
            'OCR Engine': 'Google ML Kit (On-device)',
          },
        );
      }
    } catch (e) {
      debugPrint('❌ Error analyzeCVFromExtractedText: $e');
    }

    return CVMatchingResult.fromMock(10.0);
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

  // ============================================================
  // LOGGING - Lưu dữ liệu phân tích vào file để debug/test
  // ============================================================

  /// Lưu log phân tích vào thư mục documents của app
  Future<void> _saveAnalysisLog({
    required String jobData,
    required String extractedCVText,
    required Map<String, dynamic> cvRawData,
    required CVMatchingResult aiResult,
    required String source,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${dir.path}/analysis_logs');
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final logFile = File('${logDir.path}/analysis_$timestamp.json');

      final logData = {
        'timestamp': DateTime.now().toIso8601String(),
        'source': source,
        'job_data': {
          'raw_text': jobData,
          'title': cvRawData['job_title'] ?? '',
        },
        'cv_data': {
          'extracted_text': extractedCVText,
          'text_length': extractedCVText.length,
          'file_url': cvRawData['file_url'] ?? cvRawData['data']?['file_url'] ?? '',
          'raw_metadata_keys': (cvRawData['data'] as Map?)?.keys.toList() ?? cvRawData.keys.toList(),
        },
        'ai_result': aiResult.toJson(),
      };

      await logFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(logData),
      );

      debugPrint('📝 Analysis log saved: ${logFile.path}');
    } catch (e) {
      debugPrint('⚠️ Could not save analysis log: $e');
    }
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

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
        buffer.writeln(
            "- ${exp['position'] ?? exp['title'] ?? ''} tại ${exp['company'] ?? ''} (${exp['duration'] ?? ''})");
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
Lĩnh vực: ${meta.fields.join(', ')}
''';
  }
}

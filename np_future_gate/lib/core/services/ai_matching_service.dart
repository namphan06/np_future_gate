import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'mistral_service.dart';
import 'mlkit_ocr_service.dart';
import '../models/job_model.dart';

// ================================================================
// MODELS
// ================================================================

class CVMatchingResult {
  final double overallScore;
  final double semanticSimilarity;
  final double keywordMatchScore;
  final String matchingSummary;
  final List<String> matchingPoints;
  final List<String> missingPoints;
  final Map<String, dynamic> parsedData;

  CVMatchingResult({
    required this.overallScore,
    required this.semanticSimilarity,
    required this.keywordMatchScore,
    required this.matchingSummary,
    required this.matchingPoints,
    required this.missingPoints,
    required this.parsedData,
  });

  factory CVMatchingResult.fromMock(double s) => CVMatchingResult(
    overallScore: s, semanticSimilarity: s / 100, keywordMatchScore: s,
    matchingSummary: 'Không thể phân tích.', matchingPoints: [], missingPoints: ['Lỗi AI'],
    parsedData: {'Status': 'Mock'},
  );

  Map<String, dynamic> toJson() => {
    'overall_score': overallScore, 'semantic_similarity': semanticSimilarity,
    'keyword_match_score': keywordMatchScore, 'matching_summary': matchingSummary,
    'matching_points': matchingPoints, 'missing_points': missingPoints, 'parsed_data': parsedData,
  };
}

class CVComparisonResult {
  final String jobTitle;
  final List<CandidateScore> candidates;
  final String recommendation;
  final String comparisonNotes;

  CVComparisonResult({required this.jobTitle, required this.candidates, required this.recommendation, this.comparisonNotes = ''});

  factory CVComparisonResult.fromJson(Map<String, dynamic> json, List<String> names) {
    final list = json['candidates'] as List? ?? [];
    final candidates = <CandidateScore>[];
    for (int i = 0; i < list.length; i++) {
      final c = list[i] as Map<String, dynamic>;
      candidates.add(CandidateScore(
        name: _s(c['name']) ?? (i < names.length ? names[i] : 'Ứng viên ${i+1}'),
        rank: (c['rank'] as num?)?.toInt() ?? (i+1),
        skillsScore: (c['skills_score'] as num?)?.toDouble() ?? 0,
        experienceScore: (c['experience_score'] as num?)?.toDouble() ?? 0,
        educationScore: (c['education_score'] as num?)?.toDouble() ?? 0,
        overallScore: (c['overall_score'] as num?)?.toDouble() ?? 0,
        potentialScore: (c['potential_score'] as num?)?.toDouble() ?? 0,
        strengths: _sl(c['strengths']), weaknesses: _sl(c['weaknesses']),
        summary: _s(c['summary']) ?? '',
      ));
    }
    candidates.sort((a, b) => a.rank.compareTo(b.rank));
    return CVComparisonResult(
      jobTitle: _s(json['job_title']) ?? '', candidates: candidates,
      recommendation: _s(json['recommendation']) ?? '', comparisonNotes: _s(json['comparison_notes']) ?? '',
    );
  }

  static String? _s(dynamic v) { if (v == null) return null; if (v is String) return v; if (v is List) return v.join('. '); return v.toString(); }
  static List<String> _sl(dynamic v) { if (v is List) return v.map((e) => e.toString()).toList(); if (v is String) return [v]; return []; }
}

class CandidateScore {
  final String name; final int rank;
  final double skillsScore, experienceScore, educationScore, overallScore, potentialScore;
  final List<String> strengths, weaknesses; final String summary;
  CandidateScore({required this.name, required this.rank, required this.skillsScore, required this.experienceScore, required this.educationScore, required this.overallScore, required this.potentialScore, required this.strengths, required this.weaknesses, required this.summary});
}

// ================================================================
// SERVICE
// ================================================================

class AIMatchingService {
  final MistralService _mistralService = MistralService();
  final MLKitOcrService _mlkitService = MLKitOcrService();

  /// Phân tích CV - tự phân biệt upload vs structured
  Future<CVMatchingResult> analyzeCVMatching({
    required Map<String, dynamic> cvData,
    required JobModel job,
  }) async {
    final String? fileUrl = cvData['file_url'] ?? cvData['data']?['file_url'];
    final String cvType = (cvData['type'] ?? '').toString();
    final bool isUpload = cvType == 'upload' || (fileUrl != null && fileUrl.isNotEmpty);

    debugPrint('🚀 Phân tích AI - Type: ${isUpload ? "UPLOAD" : "STRUCTURED"}');

    if (isUpload && fileUrl != null && fileUrl.isNotEmpty) {
      // LUỒNG 1: CV Upload → OCR → AI
      try {
        return await _analyzeUploadCV(fileUrl, job);
      } catch (e) {
        debugPrint('❌ Upload CV analysis failed: $e');
        return CVMatchingResult.fromMock(5);
      }
    } else {
      // LUỒNG 2: CV App → Structured → AI
      return await _analyzeStructuredCV(cvData, job);
    }
  }

  // ================================================================
  // LUỒNG 1: UPLOAD CV (OCR)
  // ================================================================

  Future<CVMatchingResult> _analyzeUploadCV(String fileUrl, JobModel job) async {
    final ocrResult = await _mlkitService.extractTextFromUrl(fileUrl);
    if (!ocrResult.success || ocrResult.text.isEmpty) {
      throw Exception(ocrResult.error ?? 'OCR trống');
    }
    debugPrint('✅ OCR: ${ocrResult.text.length} chars');

    final prompt = _buildAnalysisPrompt(ocrResult.text, job);
    final result = await _callAIAndParse(prompt);
    if (result != null) {
      final r = CVMatchingResult(
        overallScore: (result['overall_score'] as num).toDouble(),
        semanticSimilarity: (result['semantic_similarity'] as num).toDouble(),
        keywordMatchScore: (result['keyword_match_score'] as num).toDouble(),
        matchingSummary: result['summary']?.toString() ?? '',
        matchingPoints: List<String>.from(result['matching_points'] ?? []),
        missingPoints: List<String>.from(result['missing_points'] ?? []),
        parsedData: {...(result['parsed_data'] is Map ? result['parsed_data'] : {}), 'Source': 'OCR Upload'},
      );
      _printLog('upload_ocr', job, ocrResult.text, r);
      return r;
    }
    throw Exception('AI không trả về kết quả hợp lệ');
  }

  // ================================================================
  // LUỒNG 2: STRUCTURED CV (App)
  // ================================================================

  Future<CVMatchingResult> _analyzeStructuredCV(Map<String, dynamic> cvData, JobModel job) async {
    final nested = cvData['data'];
    final data = nested is Map<String, dynamic> ? nested : cvData;
    final cvText = _buildStructuredText(data);

    if (cvText.length < 30) return CVMatchingResult.fromMock(5);
    debugPrint('📋 Structured: ${cvText.length} chars');

    final prompt = _buildAnalysisPrompt(cvText, job);
    final result = await _callAIAndParse(prompt);
    if (result != null) {
      final score = result['overall_score'] ?? result['llm_matching_score'] ?? 0;
      final r = CVMatchingResult(
        overallScore: (score as num).toDouble(),
        semanticSimilarity: ((result['semantic_similarity'] ?? 0) as num).toDouble(),
        keywordMatchScore: ((result['keyword_match_score'] ?? result['llm_matching_score'] ?? 0) as num).toDouble(),
        matchingSummary: result['summary']?.toString() ?? '',
        matchingPoints: List<String>.from(result['matching_points'] ?? []),
        missingPoints: List<String>.from(result['missing_points'] ?? []),
        parsedData: {...(result['parsed_data'] is Map ? result['parsed_data'] : result['parsed_cv_overview'] is Map ? result['parsed_cv_overview'] : {}), 'Source': 'Structured'},
      );
      _printLog('structured', job, cvText, r);
      return r;
    }
    return CVMatchingResult.fromMock(10);
  }

  // ================================================================
  // SCAN CV (camera)
  // ================================================================

  Future<CVMatchingResult> analyzeCVFromImage({required File imageFile, required JobModel job}) async {
    final ocr = await _mlkitService.extractTextFromFile(imageFile);
    if (!ocr.success || ocr.text.isEmpty) throw Exception(ocr.error ?? 'OCR trống');
    return await analyzeCVFromExtractedText(extractedText: ocr.text, job: job);
  }

  Future<CVMatchingResult> analyzeCVFromExtractedText({required String extractedText, required JobModel job}) async {
    if (extractedText.isEmpty) return CVMatchingResult.fromMock(0);
    final prompt = _buildAnalysisPrompt(extractedText, job);
    final result = await _callAIAndParse(prompt);
    if (result != null) {
      return CVMatchingResult(
        overallScore: (result['overall_score'] as num).toDouble(),
        semanticSimilarity: ((result['semantic_similarity'] ?? 0) as num).toDouble(),
        keywordMatchScore: ((result['keyword_match_score'] ?? 0) as num).toDouble(),
        matchingSummary: result['summary']?.toString() ?? '',
        matchingPoints: List<String>.from(result['matching_points'] ?? []),
        missingPoints: List<String>.from(result['missing_points'] ?? []),
        parsedData: {...(result['parsed_data'] is Map ? result['parsed_data'] : {}), 'Source': 'Scan'},
      );
    }
    return CVMatchingResult.fromMock(10);
  }

  // ================================================================
  // SO SÁNH ỨNG VIÊN
  // ================================================================

  Future<String> compareCVs({required List<Map<String, dynamic>> cvsData, required JobModel job}) async {
    final texts = await _getAllCVTexts(cvsData);
    final prompt = 'SO SÁNH ỨNG VIÊN cho vị trí ${job.metadata.title}.\n\n[YÊU CẦU]\n${_jobText(job)}\n\n${texts.asMap().entries.map((e) => "[Ứng viên ${e.key+1}]\n${e.value}").join("\n\n")}\n\nĐưa ra bảng so sánh và ranking. Trả lời Markdown tiếng Việt.';
    return await _mistralService.sendIsolatedMessage(prompt);
  }

  Future<CVComparisonResult> compareCVsStructured({
    required List<Map<String, dynamic>> cvsData,
    required List<String> candidateNames,
    required JobModel job,
  }) async {
    final texts = await _getAllCVTexts(cvsData);
    final prompt = '''SO SÁNH ỨNG VIÊN VÀ TRẢ VỀ JSON

[YÊU CẦU CÔNG VIỆC]
${_jobText(job)}

[ỨNG VIÊN]
${texts.asMap().entries.map((e) => "[${candidateNames[e.key]}]\n${e.value}").join("\n\n")}

Đánh giá 5 tiêu chí (0-100): skills_score, experience_score, education_score, overall_score, potential_score.

TRẢ VỀ JSON:
{"job_title": "${job.metadata.title}", "candidates": [{"name": "", "rank": 1, "skills_score": 0, "experience_score": 0, "education_score": 0, "overall_score": 0, "potential_score": 0, "strengths": [], "weaknesses": [], "summary": ""}], "recommendation": "", "comparison_notes": ""}''';

    try {
      final result = await _callAIAndParse(prompt);
      if (result != null) return CVComparisonResult.fromJson(result, candidateNames);
    } catch (e) {
      debugPrint('❌ compareCVsStructured: $e');
    }
    return CVComparisonResult(jobTitle: job.metadata.title, candidates: candidateNames.map((n) => CandidateScore(name: n, rank: 0, skillsScore: 0, experienceScore: 0, educationScore: 0, overallScore: 0, potentialScore: 0, strengths: [], weaknesses: [], summary: 'Lỗi')).toList(), recommendation: 'Lỗi phân tích');
  }

  // ================================================================
  // CORE: Gọi AI và parse JSON (có retry)
  // ================================================================

  Future<Map<String, dynamic>?> _callAIAndParse(String prompt) async {
    final response = await _mistralService.sendIsolatedMessage(prompt);

    // Thử parse trực tiếp
    try {
      final r = jsonDecode(response);
      if (r is Map<String, dynamic>) return r;
    } catch (_) {}

    // Sanitize và tìm JSON
    final clean = _sanitize(response);
    final start = clean.indexOf('{');
    final end = clean.lastIndexOf('}');
    if (start >= 0 && end > start) {
      try {
        final r = jsonDecode(clean.substring(start, end + 1));
        if (r is Map<String, dynamic>) return r;
      } catch (e) {
        debugPrint('⚠️ JSON parse fail: $e');
      }
    }
    return null;
  }

  // ================================================================
  // HELPERS
  // ================================================================

  String _buildAnalysisPrompt(String cvText, JobModel job) => '''
PHÂN TÍCH ĐỘ PHÙ HỢP CV VỚI CÔNG VIỆC.

[CV]
$cvText

[CÔNG VIỆC]
${_jobText(job)}

Trả về JSON duy nhất:
{"overall_score": 0-100, "semantic_similarity": 0.0-1.0, "keyword_match_score": 0-100, "summary": "nhận xét tiếng Việt", "matching_points": ["điểm phù hợp"], "missing_points": ["điểm thiếu"], "parsed_data": {"name": "", "skills": "", "experience": "", "education": ""}}''';

  String _jobText(JobModel job) {
    final m = job.metadata;
    return 'Vị trí: ${m.title}\nMô tả: ${m.jobDescription.join('. ')}\nYêu cầu: ${m.candidateRequirements.join('. ')}\nKỹ năng: ${m.requirementsTags.join(', ')}\nKinh nghiệm: ${m.experienceRequired}\nLĩnh vực: ${m.fields.join(', ')}';
  }

  Future<List<String>> _getAllCVTexts(List<Map<String, dynamic>> cvsData) async {
    final texts = <String>[];
    for (final cv in cvsData) {
      final url = cv['file_url'] ?? cv['data']?['file_url'];
      final type = (cv['type'] ?? '').toString();
      if ((type == 'upload' || (url != null && url.toString().isNotEmpty)) && url != null) {
        try {
          final ocr = await _mlkitService.extractTextFromUrl(url);
          if (ocr.success && ocr.text.isNotEmpty) { texts.add(ocr.text); continue; }
        } catch (_) {}
      }
      final nested = cv['data'];
      texts.add(_buildStructuredText(nested is Map<String, dynamic> ? nested : cv));
    }
    return texts;
  }

  String _buildStructuredText(Map<String, dynamic> d) {
    final b = StringBuffer();
    final info = d['personal_info'] as Map? ?? {};
    b.writeln('Họ tên: ${info['full_name'] ?? d['full_name'] ?? d['name'] ?? 'N/A'}');
    final t = (info['title'] ?? d['headline'] ?? '').toString();
    if (t.isNotEmpty && !t.endsWith('.pdf')) b.writeln('Vị trí: $t');
    if ((info['email'] ?? '').toString().isNotEmpty) b.writeln('Email: ${info['email']}');
    if ((info['phone'] ?? '').toString().isNotEmpty) b.writeln('SĐT: ${info['phone']}');
    final sum = (d['summary'] ?? '').toString();
    if (sum.isNotEmpty) b.writeln('\nGiới thiệu: $sum');
    final exps = d['experiences'] as List? ?? [];
    if (exps.isNotEmpty) { b.writeln('\nKinh nghiệm:'); for (final e in exps) { if (e is Map) { b.writeln('- ${e['position'] ?? ''} tại ${e['company'] ?? ''} (${e['duration'] ?? ''})'); if ((e['description'] ?? '').toString().isNotEmpty) b.writeln('  ${e['description']}'); } } }
    final edus = d['education'] as List? ?? [];
    if (edus.isNotEmpty) { b.writeln('\nHọc vấn:'); for (final e in edus) { if (e is Map) b.writeln('- ${e['degree'] ?? ''} - ${e['school'] ?? ''} (${e['year'] ?? ''})'); } }
    final skills = d['skills'] as List? ?? [];
    if (skills.isNotEmpty) { final s = skills.map((x) => x is Map ? '${x['name'] ?? ''}' : x.toString()).where((x) => x.isNotEmpty).join(', '); if (s.isNotEmpty) b.writeln('\nKỹ năng: $s'); }
    final certs = d['certifications'] as List? ?? [];
    if (certs.isNotEmpty) { b.writeln('\nChứng chỉ:'); for (final c in certs) { if (c is Map) b.writeln('- ${c['name'] ?? ''} (${c['issuer'] ?? ''})'); } }
    final projs = d['projects'] as List? ?? [];
    if (projs.isNotEmpty) { b.writeln('\nDự án:'); for (final p in projs) { if (p is Map) b.writeln('- ${p['name'] ?? ''} | ${p['role'] ?? p['position'] ?? ''}'); } }
    return b.toString();
  }

  String _sanitize(String s) {
    final b = StringBuffer();
    bool inStr = false, esc = false;
    for (int i = 0; i < s.length; i++) {
      final c = s[i]; final code = c.codeUnitAt(0);
      if (esc) { b.write(c); esc = false; continue; }
      if (c == '\\' && inStr) { esc = true; b.write(c); continue; }
      if (c == '"') { inStr = !inStr; b.write(c); continue; }
      if (inStr && code < 32) { b.write(code == 10 ? '\\n' : code == 13 ? '\\r' : code == 9 ? '\\t' : ' '); }
      else { b.write(c); }
    }
    return b.toString();
  }

  void _printLog(String src, JobModel job, String text, CVMatchingResult r) {
    debugPrint('╔══ 📝 [$src] ${job.metadata.title} ══');
    debugPrint('║ Score: ${r.overallScore}% | Text: ${text.length} chars');
    debugPrint('║ ✅ ${r.matchingPoints.join(' | ')}');
    debugPrint('║ ❌ ${r.missingPoints.join(' | ')}');
    debugPrint('╚══════════════════════════════════════');
  }
}

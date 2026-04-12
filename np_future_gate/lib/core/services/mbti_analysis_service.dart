import 'dart:convert';

import '../models/mbti_model.dart';
import 'mistral_service.dart';

class MBTIAnalysisService {
  final MistralService _mistralService = MistralService();

  Future<MBTIAnalysisResult> analyzeWithAI({
    required List<MBTIAnsweredQuestion> answeredQuestions,
    required String gender,
  }) async {
    final fallbackCode = _calculateByMappedLetters(answeredQuestions);
    final answersForPrompt = answeredQuestions
        .map(
          (item) => {
            'question': item.question.questionText,
            'dimension': item.question.questionDimension,
            'answer': item.selectedOption.optionText,
            'mapped_letter': item.selectedOption.mappedLetter,
          },
        )
        .toList();

    final prompt =
        '''
Bạn là chuyên gia MBTI.
Dưới đây là câu trả lời của người dùng cho bài test MBTI (chọn giữa 2 option mỗi câu) và giới tính:
- Giới tính: $gender
- Dữ liệu trả lời (JSON): ${jsonEncode(answersForPrompt)}

Nhiệm vụ:
1) Suy luận nhóm MBTI phù hợp nhất cho người dùng.
2) Trả về DUY NHẤT một JSON hợp lệ theo mẫu:
{
  "result_code": "ISTP",
  "reasoning": "Giải thích ngắn gọn 2-3 câu bằng tiếng Việt"
}

Yêu cầu:
- result_code phải là 1 trong 16 mã MBTI chuẩn gồm 4 chữ cái in hoa.
- Không thêm bất kỳ văn bản nào ngoài JSON.
''';

    try {
      final response = await _mistralService.sendMessage(prompt);
      final jsonRegex = RegExp(r'\{[\s\S]*\}');
      final jsonString = jsonRegex.stringMatch(response);
      if (jsonString == null) {
        return MBTIAnalysisResult(
          resultCode: fallbackCode,
          reasoning: 'Kết quả được tính theo lựa chọn của bạn.',
        );
      }

      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final aiCode = (decoded['result_code'] ?? '').toString().toUpperCase();
      final reasoning = decoded['reasoning']?.toString();

      if (RegExp(r'^[A-Z]{4}$').hasMatch(aiCode)) {
        return MBTIAnalysisResult(resultCode: aiCode, reasoning: reasoning);
      }

      return MBTIAnalysisResult(
        resultCode: fallbackCode,
        reasoning: reasoning ?? 'Kết quả được tính theo lựa chọn của bạn.',
      );
    } catch (_) {
      return MBTIAnalysisResult(
        resultCode: fallbackCode,
        reasoning: 'Kết quả được tính theo lựa chọn của bạn.',
      );
    }
  }

  String calculateByMappedLetters(
    List<MBTIAnsweredQuestion> answeredQuestions,
  ) {
    return _calculateByMappedLetters(answeredQuestions);
  }

  String _calculateByMappedLetters(
    List<MBTIAnsweredQuestion> answeredQuestions,
  ) {
    final letterCount = <String, int>{
      'E': 0,
      'I': 0,
      'S': 0,
      'N': 0,
      'T': 0,
      'F': 0,
      'J': 0,
      'P': 0,
    };

    for (final item in answeredQuestions) {
      final letter = item.selectedOption.mappedLetter.toUpperCase();
      if (letterCount.containsKey(letter)) {
        letterCount[letter] = (letterCount[letter] ?? 0) + 1;
      }
    }

    final ei = (letterCount['E'] ?? 0) >= (letterCount['I'] ?? 0) ? 'E' : 'I';
    final sn = (letterCount['S'] ?? 0) >= (letterCount['N'] ?? 0) ? 'S' : 'N';
    final tf = (letterCount['T'] ?? 0) >= (letterCount['F'] ?? 0) ? 'T' : 'F';
    final jp = (letterCount['J'] ?? 0) >= (letterCount['P'] ?? 0) ? 'J' : 'P';

    return '$ei$sn$tf$jp';
  }
}

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:np_future_gate/core/services/mistral_service.dart';

class MIAnalysisService {
  final MistralService _mistralService = MistralService();

  Future<String> analyzeResults(Map<String, int> scores) async {
    final prompt = '''
Bạn là chuyên gia tâm lý học và hướng nghiệp, chuyên về Trí thông minh đa dạng (Multiple Intelligences - MI).
Dưới đây là kết quả bài test MI của một người dùng (thang điểm 5 cho mỗi câu hỏi, điểm số hiển thị là tổng điểm của từng loại):
${scores.toString()}

Ký hiệu các loại trí thông minh:
- LI: Linguistic (Ngôn ngữ)
- LO: Logical-Mathematical (Logic/Toán)
- SP: Spatial (Không gian)
- BO: Bodily-Kinesthetic (Vận động cơ thể)
- MU: Musical (Âm nhạc)
- IE: Interpersonal (Tương tác xã hội)
- IA: Intrapersonal (Nội tâm)
- NA: Naturalist (Thiên nhiên)
- EX: Existential (Triết học/Hiện sinh)

Nhiệm vụ của bạn:
Hãy tạo một bản báo cáo phân tích chi tiết, chuyên nghiệp và truyền cảm hứng dựa trên điểm số trên.
Cấu trúc bản báo cáo phải bao gồm 3 phần chính và được định dạng bằng Markdown (để hiển thị đẹp trên ứng dụng):

1. **Điểm mạnh & Điểm yếu**:
   - Phân tích sâu các loại trí thông minh có điểm cao nhất (Điểm mạnh). Giải thích tố chất này giúp gì trong cuộc sống và công việc.
   - Nhận diện các loại có điểm thấp hơn (Điểm yếu) một cách nhẹ nhàng, coi đó là những lĩnh vực cần cải thiện hoặc phối hợp.

2. **Tư duy & Sáng tạo**:
   - Mô tả phong cách tư duy của người này dựa trên sự kết hợp giữa các loại trí thông minh (ví dụ: tư duy bằng ngôn từ, tư duy bằng hình ảnh, hay tư duy trừu tượng).
   - Đưa ra cách thức kích hoạt sức sáng tạo tốt nhất cho người này (môi trường làm việc, công cụ hỗ trợ).

3. **Tiêu chí công việc & Lãnh đạo**:
   - Đưa ra các tiêu chí công việc phù hợp (ví dụ: cần môi trường đối thoại, cần tiếp xúc thiên nhiên, cần sự tĩnh lặng...).
   - Đánh giá tiềm năng lãnh đạo (thang điểm 1-5) và phong cách lãnh đạo đặc trưng.

**Yêu cầu về văn phong**:
- Sử dụng ngôn ngữ tiếng Việt lưu loát, giàu hình ảnh và mang tính khích lệ (tương tự ví dụ được cung cấp).
- Không liệt kê khô khan, hãy viết thành các đoạn văn mạch lạc.
- Sử dụng icon/emoji để tăng tính sinh động.

Dưới đây là ví dụ về phong cách viết (hãy bắt chước văn phong này nhưng nội dung dựa trên điểm số thực tế):
"Với tố chất xử lý ngôn ngữ, bạn thường thể hiện khả năng ăn nói tốt, được mọi người nhận định là người rất hoạt ngôn và hay chia sẻ..."
"Dòng suy nghĩ của bạn sẽ được khơi thông khi ở trong bối cảnh của một cuộc đối thoại..."

**Yêu cầu kỹ thuật quan trọng**:
- Hãy phản hồi **DUY NHẤT** một khối JSON hợp lệ. Không thêm văn bản giải thích ngoài khối JSON.
- Các giá trị trong JSON phải được trình bày dưới dạng HTML (sử dụng các thẻ <p>, <ul>, <li>, <strong>...) để hiển thị đẹp.
- Đảm bảo các ký tự xuống dòng bên trong giá trị chuỗi phải được escape đúng cách (sử dụng \n) hoặc viết trên cùng một dòng để không làm hỏng định dạng JSON.
- Key của JSON là: "strengths_weaknesses", "thinking_creative", "job_criteria".

JSON format:
{
  "strengths_weaknesses": "...",
  "thinking_creative": "...",
  "job_criteria": "..."
}
''';

    try {
      final response = await _mistralService.sendMessage(prompt);
      
      // Extract JSON using Regex in case AI adds extra text
      final jsonRegex = RegExp(r'\{[\s\S]*\}');
      final match = jsonRegex.stringMatch(response);
      
      if (match != null) {
        return match;
      }
      
      return response; // Fallback
    } catch (e) {
      debugPrint('Error analyzing MI results: $e');
      return jsonEncode({
        'strengths_weaknesses': 'Không thể phân tích kết quả vào lúc này. Lỗi: $e',
        'thinking_creative': 'Vui lòng thử lại sau.',
        'job_criteria': 'Vui lòng thử lại sau.'
      });
    }
  }
}

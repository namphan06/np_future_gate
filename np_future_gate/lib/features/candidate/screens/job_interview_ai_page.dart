import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:np_future_gate/core/models/job_model.dart';
import 'package:np_future_gate/core/services/mistral_service.dart';
import 'package:np_future_gate/core/theme/app_colors.dart';
import 'package:np_future_gate/core/theme/app_gradients.dart';
import 'package:np_future_gate/core/theme/app_text_styles.dart';
import 'package:np_future_gate/shared/widgets/inputs/speech_text_field.dart';

class JobInterviewAIPage extends StatefulWidget {

  const JobInterviewAIPage({super.key, required this.job});
  final JobModel job;

  @override
  State<JobInterviewAIPage> createState() => _JobInterviewAIPageState();
}

class _JobInterviewAIPageState extends State<JobInterviewAIPage> {
  final MistralService _mistralService = MistralService();
  final PageController _pageController = PageController();
  final List<TextEditingController> _answerControllers = [];
  
  bool _isGeneratingQuestions = true;
  bool _isAnalyzing = false;
  List<String> _questions = [];
  int _currentStep = 0; // 0: Questions, 1: Analysis Results
  Map<String, dynamic>? _structuredFeedback;

  @override
  void initState() {
    super.initState();
    _generateQuestions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _answerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _generateQuestions() async {
    setState(() {
      _isGeneratingQuestions = true;
      _questions = [];
    });

    final meta = widget.job.metadata;
    final prompt = '''
Dựa trên thông tin tuyển dụng dưới đây, hãy tạo ra 10 câu hỏi phỏng vấn chuyên sâu để đánh giá năng lực ứng viên.
Câu hỏi cần bao quát: Kỹ năng chuyên môn, kinh nghiệm thực tế, cách xử lý tình huống và thái độ làm việc.

Tên công việc: ${meta.title}
Mô tả công việc: ${meta.jobDescription.join(', ')}
Yêu cầu ứng viên: ${meta.candidateRequirements.join(', ')}
Kỹ năng yêu cầu: ${meta.requirementsTags.join(', ')}

Yêu cầu định dạng phản hồi: Chỉ trả về mảng JSON chứa 10 chuỗi câu hỏi. Không giải thích thêm.
Ví dụ: ["Câu hỏi 1", "Câu hỏi 2", ...]
''';

    try {
      final response = await _mistralService.sendMessage(prompt);
      // Trích xuất JSON từ response của AI
      final jsonMatch = RegExp(r'\[.*\]', dotAll: true).stringMatch(response);
      if (jsonMatch != null) {
        final List<dynamic> decoded = jsonDecode(jsonMatch);
        _questions = decoded.map((e) => e.toString()).toList();
        for (int i = 0; i < _questions.length; i++) {
          _answerControllers.add(TextEditingController());
        }
      } else {
        throw Exception('Không thể phân tích câu hỏi từ AI');
      }
    } catch (e) {
      debugPrint('Error generating questions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tạo câu hỏi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingQuestions = false);
      }
    }
  }

  Future<void> _analyzeAnswers() async {
    setState(() => _isAnalyzing = true);

    final List<Map<String, String>> interviewData = [];
    for (int i = 0; i < _questions.length; i++) {
      interviewData.add({
        'question': _questions[i],
        'answer': _answerControllers[i].text,
      });
    }

    final prompt = '''
Bạn là chuyên gia nhân sự cao cấp tại NP FutureGate. Hãy đánh giá phần trả lời phỏng vấn của ứng viên cho vị trí: ${widget.job.metadata.title}.

Dữ liệu phỏng vấn:
${jsonEncode(interviewData)}

Hãy phân tích và đưa ra phản hồi chi tiết theo định dạng JSON sau:
{
  "overall_score": (số từ 0-100),
  "summary": "Tóm tắt ngắn gọn năng lực ứng viên",
  "strengths": ["Điểm mạnh 1", "Điểm mạnh 2", ...],
  "weaknesses": ["Điểm cần cải thiện 1", "Điểm cần cải thiện 2", ...],
  "recommendations": "Lời khuyên cuối cùng cho ứng viên",
  "detailed_analysis": [
    {"aspect": "Chuyên môn", "score": 80, "comment": "..."},
    {"aspect": "Kỹ năng mềm", "score": 75, "comment": "..."},
    {"aspect": "Thái độ", "score": 90, "comment": "..."}
  ]
}

Chỉ trả về JSON, không kèm văn bản thừa.
''';

    try {
      final response = await _mistralService.sendMessage(prompt);
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).stringMatch(response);
      if (jsonMatch != null) {
        setState(() {
          _structuredFeedback = jsonDecode(jsonMatch);
          _currentStep = 1;
        });
      } else {
        throw Exception('Không thể phân tích kết quả đánh giá');
      }
    } catch (e) {
      debugPrint('Error analyzing answers: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi đánh giá: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _currentStep == 0 ? 'Phỏng vấn AI' : 'Kết quả đánh giá',
          style: AppTextStyles.h6.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_currentStep == 0 && !_isGeneratingQuestions)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  'Câu ${(_pageController.hasClients ? _pageController.page?.toInt() ?? 0 : 0) + 1}/${_questions.length}',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_isGeneratingQuestions) {
      return _buildLoadingState('AI đang chuẩn bị bộ câu hỏi phù hợp cho bạn...');
    }

    if (_isAnalyzing) {
      return _buildLoadingState('AI đang phân tích câu trả lời của bạn...');
    }

    if (_currentStep == 0) {
      return PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _questions.length,
        itemBuilder: (context, index) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppGradients.blueToGreen.colors
                          .map((c) => c.withValues(alpha: 0.05))
                          .toList(),
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Câu hỏi:',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _questions[index],
                        style: AppTextStyles.h5.copyWith(height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Câu trả lời của bạn:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                SpeechTextField(
                  controller: _answerControllers[index],
                  maxLines: 8,
                  hint: 'Nhập nội dung câu trả lời...',
                ),
              ],
            ),
          );
        },
      );
    }

    return _buildAnalysisResult();
  }

  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 6,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResult() {
    if (_structuredFeedback == null) return const SizedBox.shrink();

    final score = _structuredFeedback!['overall_score'] as int;
    final strengths = List<String>.from(_structuredFeedback!['strengths'] ?? []);
    final weaknesses = List<String>.from(_structuredFeedback!['weaknesses'] ?? []);
    final detailed = List<dynamic>.from(_structuredFeedback!['detailed_analysis'] ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppGradients.purpleToBlue,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: score / 100,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 8,
                      ),
                    ),
                    Text(
                      '$score',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Điểm tổng thể',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getScoreMessage(score),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          _buildInfoSection('Tóm tắt đánh giá', _structuredFeedback!['summary'], Icons.analytics_outlined),
          
          const SizedBox(height: 24),
          _buildBulletSection('Điểm mạnh', strengths, Icons.check_circle_outline, Colors.green),
          
          const SizedBox(height: 24),
          _buildBulletSection('Cần cải thiện', weaknesses, Icons.error_outline, Colors.orange),
          
          const SizedBox(height: 24),
          _buildDetailedAnalysis(detailed),
          
          const SizedBox(height: 24),
          _buildInfoSection('Lời khuyên', _structuredFeedback!['recommendations'], Icons.lightbulb_outline),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String content, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primaryBlue, size: 20),
            const SizedBox(width: 8),
            Text(title, style: AppTextStyles.h6.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        Text(content, style: AppTextStyles.bodyMedium.copyWith(height: 1.6)),
      ],
    );
  }

  Widget _buildBulletSection(String title, List<String> items, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(title, style: AppTextStyles.h6.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              Expanded(child: Text(item, style: AppTextStyles.bodyMedium)),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildDetailedAnalysis(List<dynamic> detailed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bar_chart, color: AppColors.primaryBlue, size: 20),
            const SizedBox(width: 8),
            Text('Phân tích chi tiết', style: AppTextStyles.h6.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        ...detailed.map((item) {
          final aspectScore = (item['score'] as num).toInt();
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item['aspect'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('$aspectScore%', style: TextStyle(color: _getScoreColor(aspectScore), fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: aspectScore / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor(aspectScore)),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(item['comment'], style: AppTextStyles.bodySmall),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _getScoreMessage(int score) {
    if (score >= 90) return 'Xuất sắc! Bạn rất tiềm năng.';
    if (score >= 80) return 'Rất tốt! Bạn đáp ứng tốt yêu cầu.';
    if (score >= 70) return 'Khá tốt! Hãy tự tin hơn.';
    if (score >= 50) return 'Trung bình. Bạn cần chuẩn bị kỹ hơn.';
    return 'Cần cố gắng nhiều hơn.';
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  Widget _buildBottomBar() {
    if (_isGeneratingQuestions || _isAnalyzing) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(20).copyWith(bottom: MediaQuery.of(context).padding.bottom + 10),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: () {
            if (_currentStep == 0) {
              final currentPage = _pageController.page?.toInt() ?? 0;
              if (currentPage < _questions.length - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                setState(() {}); // Update step indicator
              } else {
                _analyzeAnswers();
              }
            } else {
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
          ),
          child: Text(
            _currentStep == 1 
                ? 'Hoàn thành' 
                : (_pageController.hasClients && _pageController.page?.toInt() == _questions.length - 1 
                    ? 'Gửi câu trả lời' 
                    : 'Tiếp theo'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:np_future_gate/core/models/mbti_model.dart';
import 'package:np_future_gate/core/repositories/auth_repository.dart';
import 'package:np_future_gate/core/repositories/mbti_repository.dart';
import 'package:np_future_gate/core/services/mbti_analysis_service.dart';
import 'package:np_future_gate/core/theme/app_main_colors.dart';
import 'package:np_future_gate/features/candidate/screens/mbti_result_screen.dart';

class MBTIQuestionScreen extends StatefulWidget {
  const MBTIQuestionScreen({super.key});

  @override
  State<MBTIQuestionScreen> createState() => _MBTIQuestionScreenState();
}

class _MBTIQuestionScreenState extends State<MBTIQuestionScreen> {
  final MBTIRepository _repository = MBTIRepository();
  final AuthRepository _authRepository = AuthRepository();
  final MBTIAnalysisService _analysisService = MBTIAnalysisService();

  bool _isLoading = true;
  bool _isSubmitting = false;
  List<MBTIQuestion> _questions = [];
  final Map<String, MBTIQuestionOption> _answers = {};

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final questions = await _repository.getActiveQuestionsWithOptions();
    if (!mounted) {
      return;
    }

    setState(() {
      _questions = questions;
      _isLoading = false;
    });
  }

  void _onOptionSelected(MBTIQuestion question, MBTIQuestionOption option) {
    setState(() {
      _answers[question.id] = option;
    });
  }

  Future<void> _submit() async {
    if (_answers.length < _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bạn cần trả lời đủ ${_questions.length} câu. Hiện tại: ${_answers.length}/${_questions.length}.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final selectedGender = await _showGenderDialog();
    if (selectedGender == null || selectedGender.isEmpty) {
      return;
    }

    final answeredQuestions = _questions
        .map(
          (question) => MBTIAnsweredQuestion(
            question: question,
            selectedOption: _answers[question.id]!,
          ),
        )
        .toList();

    setState(() {
      _isSubmitting = true;
    });

    final analysis = await _analysisService.analyzeWithAI(
      answeredQuestions: answeredQuestions,
      gender: selectedGender,
    );

    final allTypes = await _repository.getActiveTypes();
    MBTIType? resultType;
    for (final type in allTypes) {
      if (type.code.toUpperCase() == analysis.resultCode.toUpperCase()) {
        resultType = type;
        break;
      }
    }

    resultType ??= allTypes.isNotEmpty
        ? allTypes.first
        : MBTIType(
            id: 'fallback',
            code: analysis.resultCode,
            name: 'Đang cập nhật',
            shortDescription: 'Chưa có nội dung chi tiết cho nhóm này.',
          );

    final userId = _authRepository.currentUser?.id;
    if (userId != null) {
      await _repository.saveTestResult(
        userId: userId,
        resultCode: resultType.code,
        answeredQuestions: answeredQuestions,
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MBTIResultScreen(
          resultType: resultType!,
          allTypes: allTypes,
          reasoning: analysis.reasoning,
        ),
      ),
    );
  }

  Future<String?> _showGenderDialog() async {
    String selected = 'Nam';

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Chọn giới tính'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<String>(
                    selected: {selected},
                    showSelectedIcon: true,
                    segments: const [
                      ButtonSegment<String>(value: 'Nam', label: Text('Nam')),
                      ButtonSegment<String>(value: 'Nữ', label: Text('Nữ')),
                    ],
                    onSelectionChanged: (values) {
                      setDialogState(() => selected = values.first);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppMainColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Xác nhận'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bài trắc nghiệm MBTI',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppMainColors.primary),
            )
          : _questions.isEmpty
          ? const Center(child: Text('Chưa có câu hỏi MBTI.'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    itemCount: _questions.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildHeader();
                      }

                      final question = _questions[index - 1];
                      final selectedOption = _answers[question.id];
                      return _buildQuestionCard(
                        index: index,
                        question: question,
                        selectedOption: selectedOption,
                      );
                    },
                  ),
                ),
                _buildBottomBar(),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE4EC)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hướng dẫn làm bài MBTI',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Chọn phương án phù hợp nhất với bạn ở mỗi câu. Hoàn thành tất cả câu hỏi, sau đó chọn giới tính để AI phân tích nhóm MBTI.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF4B5565),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard({
    required int index,
    required MBTIQuestion question,
    required MBTIQuestionOption? selectedOption,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$index. ${question.questionText}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          ...question.options.map((option) {
            final isSelected = selectedOption?.id == option.id;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _onOptionSelected(question, option),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppMainColors.primary.withValues(alpha: 0.08)
                        : const Color(0xFFF7F9FC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppMainColors.primary
                          : const Color(0xFFDDE4EE),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: isSelected ? AppMainColors.primary : Colors.grey,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          option.optionText,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final progress = _questions.isEmpty
        ? 0.0
        : _answers.length / _questions.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tiến độ: ${_answers.length}/${_questions.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: progress,
                    color: AppMainColors.primary,
                    borderRadius: BorderRadius.circular(10),
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE2E8F0),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppMainColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Hoàn thành',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

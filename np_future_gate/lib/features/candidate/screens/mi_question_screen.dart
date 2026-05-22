import 'package:flutter/material.dart';
import 'package:np_future_gate/core/models/mi_model.dart';
import 'package:np_future_gate/core/repositories/auth_repository.dart';
import 'package:np_future_gate/core/repositories/mi_repository.dart';
import 'package:np_future_gate/core/theme/app_main_colors.dart';
import 'package:np_future_gate/features/candidate/screens/mi_result_screen.dart';

class MIQuestionScreen extends StatefulWidget {
  const MIQuestionScreen({super.key});

  @override
  State<MIQuestionScreen> createState() => _MIQuestionScreenState();
}

class _MIQuestionScreenState extends State<MIQuestionScreen> {
  final MIRepository _miRepository = MIRepository();
  final AuthRepository _authRepository = AuthRepository();
  
  List<MIQuestion> _questions = [];
  final Map<String, int> _answers = {}; // questionId -> score
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final questions = await _miRepository.getActiveQuestions();
    setState(() {
      _questions = questions;
      _isLoading = false;
    });
  }

  void _onAnswered(String questionId, int score) {
    setState(() {
      _answers[questionId] = score;
    });
  }

  Future<void> _submit() async {
    if (_answers.length < _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng hoàn thành tất cả ${_questions.length} câu hỏi. Hiện tại đã làm ${_answers.length} câu.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Calculate scores per type
    final Map<String, int> typeScores = {
      'LI': 0, 'LO': 0, 'SP': 0, 'BO': 0, 'MU': 0, 'IE': 0, 'IA': 0, 'NA': 0, 'EX': 0
    };

    for (var question in _questions) {
      final score = _answers[question.id] ?? 0;
      typeScores[question.intelligenceType] = (typeScores[question.intelligenceType] ?? 0) + score;
    }

    final userId = _authRepository.currentUser?.id;
    if (userId == null) return;

    final result = MIResult(
      scores: typeScores,
      createdAt: DateTime.now(),
    );

    // Navigate to result screen which will handle AI analysis and saving
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MIResultScreen(result: result),
      ),
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
          'Bài trắc nghiệm đa trí thông minh MI',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: _questions.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildHeader();
                      }
                      final question = _questions[index - 1];
                      return _buildQuestionCard(question, index);
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
      margin: const EdgeInsets.only(bottom: 30),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hướng dẫn làm bài test đa trí thông minh MI',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Text(
            'Bạn hãy đọc những mệnh đề dưới đây và nhận định về độ chính xác của những mệnh đề đó với bản thân mình, từ 1 (Hoàn toàn sai) đến 5 (Hoàn toàn đúng).',
            style: TextStyle(color: Colors.grey.shade700, height: 1.5),
          ),
          const SizedBox(height: 16),
          _buildScaleGuide(),
        ],
      ),
    );
  }

  Widget _buildScaleGuide() {
    final scales = [
      '1 - Hoàn toàn sai',
      '2 - Thường là sai',
      '3 - Không rõ ràng',
      '4 - Đôi lúc đúng',
      '5 - Hoàn toàn đúng',
    ];
    return Column(
      children: scales.map((s) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(s, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildQuestionCard(MIQuestion question, int index) {
    final selectedScore = _answers[question.id];
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$index. ${question.questionText}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (i) {
                final score = i + 1;
                final isSelected = selectedScore == score;
                return InkWell(
                  onTap: () => _onAnswered(question.id, score),
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? AppMainColors.primary : Colors.white,
                      border: Border.all(
                        color: isSelected ? AppMainColors.primary : Colors.grey.shade300,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$score',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final progress = _questions.isEmpty ? 0.0 : _answers.length / _questions.length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tiến độ: ${(_answers.length)}/${_questions.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppMainColors.primary),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppMainColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Xác nhận', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

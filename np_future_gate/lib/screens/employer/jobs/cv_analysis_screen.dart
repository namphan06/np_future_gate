import 'package:flutter/material.dart';
import '../../../core/models/job_model.dart';
import '../../../core/services/ai_matching_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';

class CVAnalysisScreen extends StatefulWidget {
  final JobModel job;
  final Map<String, dynamic> cvData;
  final String applicantName;

  const CVAnalysisScreen({
    super.key,
    required this.job,
    required this.cvData,
    required this.applicantName,
  });

  @override
  State<CVAnalysisScreen> createState() => _CVAnalysisScreenState();
}

class _CVAnalysisScreenState extends State<CVAnalysisScreen> {
  final AIMatchingService _aiService = AIMatchingService();
  bool _isLoading = true;
  CVMatchingResult? _result;

  @override
  void initState() {
    super.initState();
    _analyze();
  }

  Future<void> _analyze() async {
    setState(() => _isLoading = true);
    try {
      final res = await _aiService.analyzeCVMatching(
        cvData: widget.cvData,
        job: widget.job,
      );
      setState(() {
        _result = res;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi phân tích: $e')));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Phân tích độ phù hợp AI', 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading ? _buildLoading() : _buildContent(),
    );
  }

  Widget _buildLoading() {
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
          const Text(
            'Pipeline AI đang hoạt động...\n(PaddleOCR -> LLM Matching -> Similarity)',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_result == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppGradients.blueToGreen,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 90,
                          height: 90,
                          child: CircularProgressIndicator(
                            value: _result!.overallScore / 100,
                            strokeWidth: 10,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        Text(
                          '${_result!.overallScore.toInt()}%',
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.applicantName,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Điểm phù hợp tổng thể',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.white24),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSmallStat('Semantic', '${(_result!.semanticSimilarity * 100).toInt()}%'),
                    _buildSmallStat('Keyword', '${_result!.keywordMatchScore.toInt()}%'),
                    _buildSmallStat('Pipeline', 'PaddleOCR'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          
          _buildSectionTitle('Tóm tắt mức độ phù hợp', Icons.analytics_outlined),
          const SizedBox(height: 12),
          Text(_result!.matchingSummary, style: const TextStyle(fontSize: 15, height: 1.6)),

          const SizedBox(height: 24),
          _buildBulletSection('Điểm tương đồng (Matching Points)', _result!.matchingPoints, Icons.check_circle, Colors.green),

          const SizedBox(height: 24),
          _buildBulletSection('Yếu tố còn thiếu (Missing Requirements)', _result!.missingPoints, Icons.cancel, Colors.red),

          const SizedBox(height: 32),
          _buildSectionTitle('Dữ liệu trích xuất (Parsed Data)', Icons.data_usage),
          const SizedBox(height: 12),
          _buildParsedData(_result!.parsedData),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSmallStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryBlue, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title, 
            style: AppTextStyles.h6.copyWith(fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildBulletSection(String title, List<String> items, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title, icon),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.arrow_forward_ios, size: 12, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(item, style: const TextStyle(fontSize: 14))),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildParsedData(Map<String, dynamic> data) {
    if (data.isEmpty) return const Text('Không có dữ liệu trích xuất chi tiết.');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: data.entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  e.key, 
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  e.value.toString(), 
                  textAlign: TextAlign.right, 
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }
}

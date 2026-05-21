import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:np_future_gate/core/models/mi_model.dart';
import 'package:np_future_gate/core/services/mi_analysis_service.dart';
import 'package:np_future_gate/core/theme/app_main_colors.dart';

class MIResultScreen extends StatefulWidget {
  
  const MIResultScreen({super.key, required this.result});
  final MIResult result;

  @override
  State<MIResultScreen> createState() => _MIResultScreenState();
}

class _MIResultScreenState extends State<MIResultScreen> with SingleTickerProviderStateMixin {
  final MIAnalysisService _analysisService = MIAnalysisService();
  
  late TabController _tabController;
  bool _isAnalyzing = true;
  Map<String, dynamic>? _analysisData;
  late MIResult _currentResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentResult = widget.result;
    _startAnalysis();
  }

  Future<void> _startAnalysis() async {
    try {
      final analysisJson = await _analysisService.analyzeResults(_currentResult.scores);
      final decodedData = jsonDecode(analysisJson);
      
      setState(() {
        _analysisData = decodedData;
        _isAnalyzing = false;
        _currentResult = MIResult(
          scores: _currentResult.scores,
          analysis: analysisJson,
          createdAt: _currentResult.createdAt,
        );
      });
    } catch (e) {
      debugPrint('Error in MI analysis: $e');
      setState(() {
        _isAnalyzing = false;
        _analysisData = {
          'strengths_weaknesses': 'Đã có lỗi xảy ra khi phân tích kết quả. Vui lòng thử lại sau.',
          'thinking_creative': 'Lỗi dữ liệu.',
          'job_criteria': 'Lỗi dữ liệu.'
        };
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Kết quả trắc nghiệm MI',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildRadarChartSection(),
            _buildAnalysisTabs(),
          ],
        ),
      ),
    );
  }

  Widget _buildRadarChartSection() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'KẾT QUẢ TRẮC NGHIỆM ĐA TRÍ THÔNG MINH MI',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3142)),
          ),
          const SizedBox(height: 30),
          AspectRatio(
            aspectRatio: 1.3,
            child: RadarChart(
              RadarChartData(
                dataSets: [
                  RadarDataSet(
                    fillColor: AppMainColors.primary.withValues(alpha: 0.2),
                    borderColor: AppMainColors.primary,
                    entryRadius: 3,
                    dataEntries: _getRadarEntries(),
                    borderWidth: 2,
                  ),
                ],
                radarShape: RadarShape.polygon,
                radarBorderData: const BorderSide(color: Colors.transparent),
                gridBorderData: BorderSide(color: Colors.grey.shade300, width: 1),
                tickBorderData: const BorderSide(color: Colors.transparent),
                ticksTextStyle: const TextStyle(color: Colors.transparent),
                getTitle: (index, angle) {
                  final labels = ['IA', 'IE', 'LO', 'LI', 'SP', 'BO', 'MU', 'NA', 'EX'];
                  return RadarChartTitle(
                    text: labels[index],
                    angle: angle,
                  );
                },
                titleTextStyle: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  List<RadarEntry> _getRadarEntries() {
    final keys = ['IA', 'IE', 'LO', 'LI', 'SP', 'BO', 'MU', 'NA', 'EX'];
    
    // Find max score for normalization if needed, but assuming max possible score 
    // depends on number of questions per category.
    // Assuming max score per category is around 30-40 based on common MI tests.
    return keys.map((key) {
      final score = widget.result.scores[key] ?? 0;
      return RadarEntry(value: score.toDouble());
    }).toList();
  }

  Widget _buildAnalysisTabs() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppMainColors.primary,
            unselectedLabelColor: Colors.grey.shade500,
            indicatorColor: AppMainColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'Điểm mạnh & Điểm yếu'),
              Tab(text: 'Tư duy & Sáng tạo'),
              Tab(text: 'Tiêu chí công việc'),
            ],
          ),
          SizedBox(
            height: 600, // Adjust or use Expanded in a different structure
            child: _isAnalyzing
                ? _buildLoadingState()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTabContent(_analysisData?['strengths_weaknesses'] ?? ''),
                      _buildTabContent(_analysisData?['thinking_creative'] ?? ''),
                      _buildTabContent(_analysisData?['job_criteria'] ?? ''),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppMainColors.primary),
          SizedBox(height: 20),
          Text(
            'AI đang phân tích kết quả của bạn...',
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(String htmlContent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: HtmlWidget(
        htmlContent,
        textStyle: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF4A4A4A)),
      ),
    );
  }
}

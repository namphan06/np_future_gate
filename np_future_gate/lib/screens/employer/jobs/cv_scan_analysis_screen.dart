import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:np_future_gate/core/models/job_model.dart';
import 'package:np_future_gate/core/services/ai_matching_service.dart';
import 'package:np_future_gate/core/services/mlkit_ocr_service.dart';
import 'package:np_future_gate/core/theme/app_colors.dart';
import 'package:np_future_gate/core/theme/app_gradients.dart';

/// Màn hình scan CV bằng ML Kit và phân tích AI
/// Dành cho nhà tuyển dụng: chụp/chọn ảnh CV → OCR → AI phân tích độ phù hợp
class CVScanAnalysisScreen extends StatefulWidget {

  const CVScanAnalysisScreen({
    super.key,
    required this.job,
    this.applicantName,
  });
  final JobModel job;
  final String? applicantName;

  @override
  State<CVScanAnalysisScreen> createState() => _CVScanAnalysisScreenState();
}

class _CVScanAnalysisScreenState extends State<CVScanAnalysisScreen> {
  final MLKitOcrService _ocrService = MLKitOcrService();
  final AIMatchingService _aiService = AIMatchingService();
  final ImagePicker _picker = ImagePicker();

  // State
  final List<File> _selectedImages = [];
  String _extractedText = '';
  bool _isExtracting = false;
  bool _isAnalyzing = false;
  CVMatchingResult? _analysisResult;

  /// Chọn ảnh từ camera
  Future<void> _pickFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImages.add(File(pickedFile.path));
          _extractedText = '';
          _analysisResult = null;
        });
      }
    } catch (e) {
      _showError('Lỗi chụp ảnh: $e');
    }
  }

  /// Chọn ảnh từ thư viện
  Future<void> _pickFromGallery() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 90,
      );
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(pickedFiles.map((f) => File(f.path)));
          _extractedText = '';
          _analysisResult = null;
        });
      }
    } catch (e) {
      _showError('Lỗi chọn ảnh: $e');
    }
  }

  /// Xóa ảnh đã chọn
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _extractedText = '';
      _analysisResult = null;
    });
  }

  /// Trích xuất text từ tất cả ảnh đã chọn bằng ML Kit
  Future<void> _extractText() async {
    if (_selectedImages.isEmpty) {
      _showError('Vui lòng chọn ít nhất 1 ảnh CV');
      return;
    }

    setState(() {
      _isExtracting = true;
      _extractedText = '';
    });

    try {
      final StringBuffer combinedText = StringBuffer();

      for (int i = 0; i < _selectedImages.length; i++) {
        final result = await _ocrService.extractTextFromFile(_selectedImages[i]);
        if (result.success) {
          if (combinedText.isNotEmpty && _selectedImages.length > 1) {
            combinedText.write('\n\n--- Trang ${i + 1} ---\n\n');
          }
          combinedText.write(result.text);
        } else {
          debugPrint('⚠️ Trang ${i + 1} không trích xuất được: ${result.error}');
        }
      }

      if (combinedText.isEmpty) {
        _showError('Không trích xuất được văn bản từ ảnh. Hãy thử chụp rõ hơn.');
      } else {
        setState(() {
          _extractedText = combinedText.toString();
        });
      }
    } catch (e) {
      _showError('Lỗi trích xuất: $e');
    } finally {
      setState(() => _isExtracting = false);
    }
  }

  /// Phân tích CV với AI (Mistral)
  Future<void> _analyzeWithAI() async {
    if (_extractedText.isEmpty) {
      _showError('Vui lòng trích xuất văn bản trước');
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final result = await _aiService.analyzeCVFromExtractedText(
        extractedText: _extractedText,
        job: widget.job,
      );

      setState(() {
        _analysisResult = result;
      });
    } catch (e) {
      _showError('Lỗi phân tích AI: $e');
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  /// Trích xuất + Phân tích 1 bước
  Future<void> _extractAndAnalyze() async {
    await _extractText();
    if (_extractedText.isNotEmpty) {
      await _analyzeWithAI();
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Chọn nguồn ảnh CV',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt, color: AppColors.primaryBlue),
                ),
                title: const Text('Chụp ảnh CV'),
                subtitle: const Text('Sử dụng camera để chụp CV'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromCamera();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.green),
                ),
                title: const Text('Chọn từ thư viện'),
                subtitle: const Text('Chọn nhiều ảnh CV (nhiều trang)'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Scan & Phân tích CV',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_selectedImages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
              onPressed: () {
                setState(() {
                  _selectedImages.clear();
                  _extractedText = '';
                  _analysisResult = null;
                });
              },
              tooltip: 'Xóa tất cả',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Job Info Card
            _buildJobInfoCard(),
            const SizedBox(height: 16),

            // Image Selection Area
            _buildImageSelectionArea(),
            const SizedBox(height: 16),

            // Selected Images Preview
            if (_selectedImages.isNotEmpty) ...[
              _buildImagePreview(),
              const SizedBox(height: 16),
            ],

            // Action Buttons
            _buildActionButtons(),
            const SizedBox(height: 16),

            // Extracted Text Preview
            if (_extractedText.isNotEmpty) ...[
              _buildExtractedTextCard(),
              const SizedBox(height: 16),
            ],

            // Analysis Result
            if (_analysisResult != null) ...[
              _buildAnalysisResult(),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildJobInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.work_outline, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.job.metadata.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.applicantName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Ứng viên: ${widget.applicantName}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Kỹ năng: ${widget.job.metadata.requirementsTags.take(3).join(', ')}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSelectionArea() {
    return InkWell(
      onTap: _showImageSourceDialog,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.document_scanner_outlined,
              size: 48,
              color: AppColors.primaryBlue.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            const Text(
              'Chụp hoặc chọn ảnh CV',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hỗ trợ nhiều trang - ML Kit nhận diện on-device',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.photo_library_outlined, size: 18),
              const SizedBox(width: 8),
              Text(
                'Ảnh đã chọn (${_selectedImages.length})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedImages[index],
                          width: 90,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Trang ${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Nút chính: Scan & Phân tích
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (_isExtracting || _isAnalyzing || _selectedImages.isEmpty)
                ? null
                : _extractAndAnalyze,
            icon: _isExtracting || _isAnalyzing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(
              _isExtracting
                  ? 'Đang trích xuất văn bản...'
                  : _isAnalyzing
                      ? 'AI đang phân tích...'
                      : 'Scan & Phân tích CV',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Nút phụ: Chỉ trích xuất text
        if (_selectedImages.isNotEmpty && _extractedText.isEmpty)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isExtracting ? null : _extractText,
              icon: const Icon(Icons.text_fields),
              label: const Text('Chỉ trích xuất văn bản'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        // Nút phân tích lại nếu đã có text
        if (_extractedText.isNotEmpty && _analysisResult == null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _analyzeWithAI,
              icon: const Icon(Icons.psychology),
              label: const Text('Phân tích với AI'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildExtractedTextCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.text_snippet, size: 18, color: Colors.green),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Văn bản trích xuất (ML Kit)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_extractedText.length} ký tự',
                  style: TextStyle(fontSize: 11, color: Colors.green.shade700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: SelectableText(
                _extractedText,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResult() {
    final result = _analysisResult!;

    return Column(
      children: [
        // Score Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppGradients.blueToGreen,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.3),
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
                          value: result.overallScore / 100,
                          strokeWidth: 10,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      Text(
                        '${result.overallScore.toInt()}%',
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
                        Text(
                          widget.applicantName ?? 'Ứng viên',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
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
                  _buildSmallStat('Semantic', '${(result.semanticSimilarity * 100).toInt()}%'),
                  _buildSmallStat('Keyword', '${result.keywordMatchScore.toInt()}%'),
                  _buildSmallStat('Engine', 'ML Kit'),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Summary
        _buildSection(
          'Tóm tắt nhận xét',
          Icons.analytics_outlined,
          child: Text(
            result.matchingSummary,
            style: const TextStyle(fontSize: 14, height: 1.6),
          ),
        ),

        const SizedBox(height: 16),

        // Matching Points
        if (result.matchingPoints.isNotEmpty)
          _buildSection(
            'Điểm phù hợp',
            Icons.check_circle,
            iconColor: Colors.green,
            child: Column(
              children: result.matchingPoints
                  .map((point) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check, size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(point, style: const TextStyle(fontSize: 14)),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),

        const SizedBox(height: 16),

        // Missing Points
        if (result.missingPoints.isNotEmpty)
          _buildSection(
            'Yếu tố còn thiếu',
            Icons.cancel,
            iconColor: Colors.red,
            child: Column(
              children: result.missingPoints
                  .map((point) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.close, size: 16, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(point, style: const TextStyle(fontSize: 14)),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),

        const SizedBox(height: 16),

        // Parsed Data
        if (result.parsedData.isNotEmpty)
          _buildSection(
            'Dữ liệu trích xuất',
            Icons.data_usage,
            child: Column(
              children: result.parsedData.entries
                  .map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(
                                e.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.value.toString(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildSmallStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildSection(String title, IconData icon,
      {Color iconColor = const Color(0xFF2196F3), required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

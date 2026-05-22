import 'package:flutter/material.dart';

import 'package:np_future_gate/core/models/mbti_model.dart';
import 'package:np_future_gate/core/repositories/mbti_repository.dart';
import 'package:np_future_gate/core/theme/app_main_colors.dart';

class MBTITypeDetailScreen extends StatefulWidget {

  const MBTITypeDetailScreen({
    super.key,
    required this.type,
    this.allTypes = const [],
  });
  final MBTIType type;
  final List<MBTIType> allTypes;

  @override
  State<MBTITypeDetailScreen> createState() => _MBTITypeDetailScreenState();
}

class _MBTITypeDetailScreenState extends State<MBTITypeDetailScreen> {
  final MBTIRepository _repository = MBTIRepository();
  late MBTIType _displayType;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _displayType = widget.type;
    _loadTypeDetail();
  }

  Future<void> _loadTypeDetail() async {
    final latest = await _repository.getTypeDetailById(widget.type.id);
    if (!mounted) {
      return;
    }

    setState(() {
      if (latest != null) {
        _displayType = latest;
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sectionItems = _displayType.sections;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_displayType.code} - ${_displayType.name ?? ''}',
          style: const TextStyle(
            color: AppMainColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _buildImageCard(),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDCE4EC)),
                  ),
                  child: Text(
                    _displayType.shortDescription ??
                        'Đang cập nhật mô tả nhóm MBTI.',
                    style: const TextStyle(fontSize: 16, height: 1.55),
                  ),
                ),
                const SizedBox(height: 16),
                if (sectionItems.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDCE4EC)),
                    ),
                    child: const Text(
                      'Nhóm này chưa có các đầu mục chi tiết trong bảng dữ liệu `mbti_type_sections`.',
                      style: TextStyle(fontSize: 15, color: Color(0xFF4B5565)),
                    ),
                  )
                else
                  ...sectionItems.map(_buildSectionCard),
                if (widget.allTypes.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.grid_view_rounded),
                    label: const Text('Quay lại danh sách 16 nhóm'),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildImageCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 16 / 8,
        child: _displayType.imageUrl == null || _displayType.imageUrl!.isEmpty
            ? Container(
                color: const Color(0xFFE9F5EE),
                alignment: Alignment.center,
                child: Text(
                  _displayType.code,
                  style: const TextStyle(
                    color: AppMainColors.primary,
                    fontSize: 46,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : Image.network(
                _displayType.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFE9F5EE),
                  alignment: Alignment.center,
                  child: Text(
                    _displayType.code,
                    style: const TextStyle(
                      color: AppMainColors.primary,
                      fontSize: 46,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionCard(MBTITypeSection section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D2433),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            section.content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Color(0xFF364152),
            ),
          ),
        ],
      ),
    );
  }
}

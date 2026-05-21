import 'package:flutter/material.dart';
import 'package:np_future_gate/core/enums/job_fields.dart';
import 'package:np_future_gate/core/models/cv_model.dart';
import 'package:np_future_gate/core/models/job_model.dart';
import 'package:np_future_gate/core/services/ai_matching_service.dart';
import 'package:np_future_gate/widgets/speech_text_field.dart';

/// Enhanced CV Selection Screen with search and filters
class CVSelectionScreen extends StatefulWidget {

  const CVSelectionScreen({
    super.key,
    required this.cvs,
    required this.onCVSelected,
    this.targetJob,
  });
  final List<CVModel> cvs;
  final Function(String cvId) onCVSelected;
  final JobModel? targetJob;

  @override
  State<CVSelectionScreen> createState() => _CVSelectionScreenState();
}

class _CVSelectionScreenState extends State<CVSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedField;
  String? _selectedType;
  List<CVModel> _filteredCVs = [];
  
  final AIMatchingService _matchingService = AIMatchingService();
  final Map<String, CVMatchingResult> _scores = {};

  @override
  void initState() {
    super.initState();
    _filteredCVs = widget.cvs;
    _searchController.addListener(_filterCVs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCVs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCVs = widget.cvs.where((cv) {
        // Search filter
        final matchesSearch = cv.name.toLowerCase().contains(query) ||
            (cv.data['description']?.toString().toLowerCase().contains(query) ?? false);

        // Field filter
        final matchesField = _selectedField == null ||
            cv.data['typeField'] == _selectedField ||
            cv.data['personal_info']?['field'] == _selectedField;

        // Type filter
        final matchesType = _selectedType == null ||
            cv.data['type'] == _selectedType ||
            cv.data['mcv'] == _selectedType;

        return matchesSearch && matchesField && matchesType;
      }).toList();
    });
  }

  Future<void> _calculateSingleScore(CVModel cv) async {
    if (widget.targetJob == null) return;
    
    // Set a temporary loading state for this CV if we wanted, 
    // but for now let's just use the global state or just do it.
    
    try {
      final result = await _matchingService.analyzeCVMatching(
        cvData: cv.data,
        job: widget.targetJob!,
      );
      if (mounted) {
        setState(() {
          _scores[cv.id] = result;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi phân tích: $e')),
        );
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedField = null;
      _selectedType = null;
      _filteredCVs = widget.cvs;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = _selectedField != null || _selectedType != null;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[50]!,
              Colors.white,
              Colors.blue[50]!.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Main Content
              Column(
                children: [
                  // Custom Header Section
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Clear Button Row
                        Row(
                          children: [
                            const SizedBox(width: 52), // Space for back button
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Chọn CV Ứng Tuyển',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Chọn CV phù hợp nhất với công việc',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (hasActiveFilters)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _clearFilters,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.clear_all, size: 18, color: Colors.blue[700]),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Xóa lọc',
                                            style: TextStyle(
                                              color: Colors.blue[700],
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Search Bar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: SpeechTextField(
                            controller: _searchController,
                            hint: 'Tìm kiếm CV theo tên, mô tả...',
                            prefixIcon: Icons.search,
                            onChanged: (value) => setState(() {}),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Filters Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildFilterChip(
                                label: _selectedType ?? 'Loại CV',
                                icon: Icons.category_outlined,
                                isSelected: _selectedType != null,
                                onTap: () => _showTypeFilter(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildFilterChip(
                                label: _selectedField ?? 'Lĩnh vực',
                                icon: Icons.work_outline,
                                isSelected: _selectedField != null,
                                onTap: () => _showFieldFilter(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Results Count
                  if (_filteredCVs.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[100]!),
                        ),
                        child: Text(
                          '${_filteredCVs.length} CV',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                  // CV List
                  Expanded(
                    child: _filteredCVs.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                            itemCount: _filteredCVs.length,
                            itemBuilder: (context, index) {
                              final cv = _filteredCVs[index];
                              return _buildCVCard(cv);
                            },
                          ),
                  ),
                ],
              ),
              
              // Floating Back Button
              Positioned(
                top: 20,
                left: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(Icons.arrow_back, size: 24, color: Colors.blue[700]),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[700] : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? Colors.blue[700]! : Colors.grey[200]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, size: 18, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCVCard(CVModel cv) {
    final type = cv.data['mcv'] ?? cv.data['type'] ?? 'unknown';
    final field = cv.data['typeField'] ?? cv.data['personal_info']?['field'];
    final description = cv.data['description']?.toString();
    final tags = cv.data['tags'] as List<dynamic>?;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onCVSelected(cv.id),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // CV Icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getTypeColor(type).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getTypeIcon(type),
                        color: _getTypeColor(type),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Title and Type
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cv.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _getTypeColor(type).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _getTypeLabel(type),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _getTypeColor(type),
                                  ),
                                ),
                              ),
                              if (field != null) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.circle, size: 4, color: Colors.grey),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    field,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Arrow Icon
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                  ],
                ),
                
                // Description
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                // Tags
                if (tags != null && tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          tag.toString(),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                
                // Match Score Section
                if (widget.targetJob != null) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _buildMatchScoreRow(cv),
                ],

                // Updated Date
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(cv.updatedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            Text(
              'Không tìm thấy CV',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thử thay đổi bộ lọc hoặc tạo CV mới',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showTypeFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lọc theo loại CV',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildFilterOption('Tất cả', null, 'type'),
              _buildFilterOption('CV Tải lên', 'upload', 'type'),
              _buildFilterOption('CV Mẫu 1', 'CV1', 'type'),
              _buildFilterOption('CV Mẫu 2', 'CV2', 'type'),
            ],
          ),
        );
      },
    );
  }

  void _showFieldFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lọc theo lĩnh vực',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        _buildFilterOption('Tất cả', null, 'field'),
                        ...JobField.valuesList.map((field) {
                          return _buildFilterOption(field, field, 'field');
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterOption(String label, String? value, String filterType) {
    final isSelected = filterType == 'type'
        ? _selectedType == value
        : _selectedField == value;

    return ListTile(
      title: Text(label),
      trailing: isSelected ? Icon(Icons.check, color: Colors.blue[700]) : null,
      selected: isSelected,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: () {
        setState(() {
          if (filterType == 'type') {
            _selectedType = value;
          } else {
            _selectedField = value;
          }
          _filterCVs();
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _buildMatchScoreRow(CVModel cv) {
    final score = _scores[cv.id];
    
    if (score == null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 16, color: Colors.purple[300]),
              const SizedBox(width: 8),
              Text(
                'Chưa phân tích độ phù hợp',
                style: TextStyle(fontSize: 13, color: Colors.grey[500], fontStyle: FontStyle.italic),
              ),
            ],
          ),
          TextButton(
            onPressed: () => _calculateSingleScore(cv),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Phân tích ngay'),
          ),
        ],
      );
    }

    final overallScore = score.overallScore;
    Color scoreColor = Colors.red;
    if (overallScore >= 75) {
      scoreColor = Colors.green;
    } else if (overallScore >= 50) {
      scoreColor = Colors.orange;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 18, color: Colors.purple[700]),
                const SizedBox(width: 8),
                Text(
                  'Độ phù hợp AI:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.purple[900]),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scoreColor.withValues(alpha: 0.5)),
              ),
              child: Text(
                '${overallScore.toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: scoreColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: overallScore / 100,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
          borderRadius: BorderRadius.circular(4),
          minHeight: 6,
        ),
        if (score.matchingSummary.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            score.matchingSummary,
            style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.4),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  String _getTypeLabel(String type) {
    switch (type.toUpperCase()) {
      case 'UPLOAD':
        return 'CV Tải lên';
      case 'CV1':
        return 'Mẫu 1';
      case 'CV2':
        return 'Mẫu 2';
      default:
        return type;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'UPLOAD':
        return Icons.cloud_upload;
      case 'CV1':
      case 'CV2':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'UPLOAD':
        return Colors.green;
      case 'CV1':
        return Colors.blue;
      case 'CV2':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} phút trước';
      }
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

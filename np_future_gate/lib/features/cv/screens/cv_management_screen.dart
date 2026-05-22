import 'package:flutter/material.dart';
import 'package:np_future_gate/core/services/cv_supabase_service.dart';
import 'package:np_future_gate/features/cv/screens/cv_input/cv1_input_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_input/cv2_input_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_input/cv3_input_screen.dart';
import 'package:np_future_gate/features/cv/screens/cv_setting/cv_display_manager.dart';
import 'package:np_future_gate/features/cv/screens/cv_upload_screen.dart';
import 'package:np_future_gate/shared/widgets/inputs/speech_text_field.dart';

/// CV Management Screen - Quản lý danh sách CV của người dùng
class CVManagementScreen extends StatefulWidget {
  const CVManagementScreen({super.key});

  @override
  State<CVManagementScreen> createState() => _CVManagementScreenState();
}

class _CVManagementScreenState extends State<CVManagementScreen> {
  final CVSupabaseService _cvService = CVSupabaseService();
  List<Map<String, dynamic>> _cvList = [];
  List<Map<String, dynamic>> _filteredCVList = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  final String _searchText = '';
  final Set<String> _selectedTags = {};

  @override
  void initState() {
    super.initState();
    _loadCVs();
    _searchController.addListener(_filterCVs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _allTags {
    final tags = <String>{};
    for (var cv in _cvList) {
      if (cv['tags'] != null) {
        for (var tag in cv['tags']) {
          tags.add(tag.toString());
        }
      }
    }
    return tags.toList()..sort();
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> _loadCVs() async {
    setState(() => _isLoading = true);
    try {
      final cvs = await _cvService.getMyCVs();
      setState(() {
        _cvList = cvs;
        _filteredCVList = cvs; // Initialize filtered list
      });
      debugPrint('Loaded ${cvs.length} CVs');
      debugPrint('All loaded CVs: $cvs');
    } catch (e) {
      _showError('Không thể tải danh sách CV: $e');
      debugPrint('Error loading CVs: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterCVs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCVList = _cvList.where((cv) {
        final title = (cv['title'] ?? '').toString().toLowerCase();
        final tags = (cv['tags'] as List<dynamic>?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];
        
        final matchesQuery = title.contains(query) || tags.any((t) => t.contains(query));
        final matchesTags = _selectedTags.isEmpty || tags.any((t) => _selectedTags.contains(t)); // Simplified tag filter

        return matchesQuery && matchesTags;
      }).toList();
    });
  }

  Future<void> _deleteCV(String cvId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa CV'),
        content: Text('Bạn có chắc chắn muốn xóa CV "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _cvService.deleteCV(cvId);
      _showSuccess('Đã xóa CV thành công');
      _loadCVs();
    } catch (e) {
      _showError('Không thể xóa CV: $e');
      debugPrint('Error deleting CV: $e');
    }
  }

  Future<void> _editCV(String cvId) async {
    try {
      final cvData = await _cvService.getCVData(cvId);
      if (cvData == null) {
        _showError('Không thể tải dữ liệu CV');
        return;
      }

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => CVDisplayManager.buildEditWidget(cvId, cvData),
        ),
      ).then((_) => _loadCVs());
    } catch (e) {
      _showError('Không thể mở CV: $e');
      debugPrint('Error opening CV: $e');
    }
  }

  Future<void> _viewCV(Map<String, dynamic> cv) async {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => CVDisplayManager.buildViewWidget(context, cv),
      ),
    );
  }

  void _showCreateOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tạo CV Mới',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.article, color: Colors.blue),
              title: const Text('CV Mẫu 1 (Cơ bản)'),
              subtitle: const Text('Phù hợp cho sinh viên, người mới đi làm'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const CV1InputScreen()),
                ).then((_) => _loadCVs());
              },
            ),
            ListTile(
              leading: const Icon(Icons.article, color: Colors.indigo),
              title: const Text('CV Mẫu 2 (Hiện đại)'),
              subtitle: const Text('Thiết kế 2 cột, phù hợp cho người có kinh nghiệm'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const CV2InputScreen()),
                ).then((_) => _loadCVs());
              },
            ),
            ListTile(
              leading: const Icon(Icons.code, color: Colors.black87),
              title: const Text('CV Mẫu 3 (IT / Kỹ thuật)'),
              subtitle: const Text('Chuyên biệt cho lập trình viên, kỹ sư phần mềm'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const CV3InputScreen()),
                ).then((_) => _loadCVs());
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file, color: Colors.orange),
              title: const Text('Tải lên CV có sẵn'),
              subtitle: const Text('Upload file PDF hoặc ảnh'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CVUploadScreen()),
                ).then((res) {
                  if (res == true) _loadCVs();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  /* 
   * Replaced by CVUploadScreen
   * 
  void _showUploadDialog() {
    // ...
  }

  Future<void> _createUploadedCV(String title, String url) async {
    // ...
  }
  */

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue[50]!, Colors.white],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Custom Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quản lý CV',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Danh sách CV đã tạo của bạn',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SpeechTextField(
                      controller: _searchController,
                      hint: 'Tìm kiếm CV... (hoặc nói)',
                      prefixIcon: Icons.search,
                      maxLines: 1,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Tag Filters
                if (_allTags.isNotEmpty)
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _buildFilterChip('Tất cả', _selectedTags.isEmpty, isAll: true),
                        const SizedBox(width: 8),
                        ..._allTags.map((tag) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildFilterChip(tag, _selectedTags.contains(tag)),
                        )),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Modern Tabs - Segmented Control Style
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: TabBar(
                      labelColor: Colors.blue[700],
                      unselectedLabelColor: Colors.grey.shade600,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        letterSpacing: 0.2,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      tabs: const [
                        Tab(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.description_outlined, size: 18),
                                SizedBox(width: 6),
                                Text('CV Chung'),
                              ],
                            ),
                          ),
                        ),
                        Tab(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.work_outline, size: 18),
                                SizedBox(width: 4),
                                Text('Lĩnh vực'),
                              ],
                            ),
                          ),
                        ),
                        Tab(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.upload_file_outlined, size: 18),
                                SizedBox(width: 6),
                                Text('Upload'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Tab Views
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                          children: [
                            _buildGeneralTab(),
                            _buildDomainTab(),
                            _buildUploadTab(),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showCreateOptions,
          tooltip: 'Tạo CV mới',
          backgroundColor: Colors.blue[600],
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, {bool isAll = false}) {
    return GestureDetector(
      onTap: () {
        if (isAll) {
          setState(() {
            _selectedTags.clear();
          });
        } else {
          _toggleTag(label);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // Tab 1: CV Chung (All General CVs)
  Widget _buildGeneralTab() {
    final generalCVs = _filteredCVList.where((cv) {
      final type = cv['type'] ?? 'general';
      final title = (cv['title'] ?? '').toLowerCase();
      final searchMatch = _searchText.isEmpty || title.contains(_searchText.toLowerCase());
      
      // Tag filtering
      final tags = List<String>.from(cv['tags'] ?? []);
      final tagMatch = _selectedTags.isEmpty || tags.any((t) => _selectedTags.contains(t));

      return type == 'general' && searchMatch && tagMatch;
    }).toList();

    if (generalCVs.isEmpty) {
      return _buildEmptyState('Chưa có CV chung nào');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: generalCVs.length,
      itemBuilder: (context, index) => _buildCVCard(generalCVs[index]),
    );
  }

  // Tab 2: Theo lĩnh vực (By Domain)
  Widget _buildDomainTab() {
    return _DomainCVList(
      cvList: _cvList,
      searchText: _searchText,
      selectedTags: _selectedTags, // Pass selected tags
      onView: _viewCV,
      onEdit: (id) => _editCV(id),
      onDelete: (id, title) => _deleteCV(id, title),
    );
  }

  // Tab 3: Upload (Uploaded CVs)
  Widget _buildUploadTab() {
    final uploadedCVs = _cvList.where((cv) {
      final type = cv['type'];
      final title = (cv['title'] ?? '').toLowerCase();
      final searchMatch = _searchText.isEmpty || title.contains(_searchText.toLowerCase());
      
      // Tag filtering (Uploads might not have tags, but if they do)
      final tags = List<String>.from(cv['tags'] ?? []);
      final tagMatch = _selectedTags.isEmpty || tags.any((t) => _selectedTags.contains(t));

      return type == 'upload' && searchMatch && tagMatch;
    }).toList();

    return Column(
      children: [
        Expanded(
          child: uploadedCVs.isEmpty
              ? _buildEmptyState('Chưa có CV nào được tải lên')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: uploadedCVs.length,
                  itemBuilder: (context, index) => _buildCVCard(uploadedCVs[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildCVCard(Map<String, dynamic> cv) {
    final title = cv['title'] ?? 'Untitled CV';
    final mcv = cv['mcv'] ?? 'CV001';
    final tags = List<String>.from(cv['tags'] ?? []);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          _viewCV(cv);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Template: $mcv',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    onSelected: (action) {
                      if (action == 'view') {
                        _viewCV(cv);
                      } else if (action == 'edit') {
                        _editCV(cv['id']);
                      } else if (action == 'delete') {
                        _deleteCV(cv['id'], title);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, size: 20),
                            SizedBox(width: 8),
                            Text('Xem'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Sửa'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Xóa', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (tags.isNotEmpty)
                Wrap(
                  spacing: 6,
                  children: tags.map((tag) {
                    return Chip(
                      label: Text(
                        tag,
                        style: const TextStyle(fontSize: 11),
                      ),
                      backgroundColor: Colors.blue[100],
                      labelStyle: TextStyle(color: Colors.blue[900]),
                      padding: EdgeInsets.zero,
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DomainCVList extends StatefulWidget {

  const _DomainCVList({
    required this.cvList,
    required this.searchText,
    required this.selectedTags,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });
  final List<Map<String, dynamic>> cvList;
  final String searchText;
  final Set<String> selectedTags;
  final Function(Map<String, dynamic>) onView;
  final Function(String) onEdit;
  final Function(String, String) onDelete;

  @override
  State<_DomainCVList> createState() => _DomainCVListState();
}

class _DomainCVListState extends State<_DomainCVList> {
  String? _selectedCategory;
  final List<String> _categories = [
    'Công nghệ',
    'Kinh doanh',
    'Thiết kế',
    'Marketing',
    'Kỹ thuật',
    'Khác',
  ];

  @override
  Widget build(BuildContext context) {
    final filteredCVs = widget.cvList.where((cv) {
      final type = cv['type'] ?? 'general';
      // Filter strictly by type 'field'
      if (type != 'field') return false;

      // Filter by category
      if (_selectedCategory != null) {
        final typeField = cv['typeField'];
        // Strict filtering: Only show CVs that explicitly match the selected field via typeField
        if (typeField != _selectedCategory) return false;
      }

      // Filter by search (Title OR Tags)
      if (widget.searchText.isNotEmpty) {
        final query = widget.searchText.toLowerCase();
        final title = (cv['title'] ?? '').toLowerCase();
        final tags = List<String>.from(cv['tags'] ?? []).map((e) => e.toLowerCase()).toList();
        
        final titleMatch = title.contains(query);
        final tagMatch = tags.any((t) => t.contains(query));
        
        if (!titleMatch && !tagMatch) return false;
      }

      // Filter by tags
      final tags = List<String>.from(cv['tags'] ?? []);
      if (widget.selectedTags.isNotEmpty) {
        if (!tags.any((t) => widget.selectedTags.contains(t))) return false;
      }

      return true;
    }).toList();

    return Column(
      children: [
        // Category Filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryChip('Tất cả', _selectedCategory == null),
                const SizedBox(width: 8),
                ..._categories.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildCategoryChip(cat, _selectedCategory == cat),
                  );
                }),
              ],
            ),
          ),
        ),

        // List
        Expanded(
          child: filteredCVs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Không tìm thấy CV lĩnh vực nào',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: filteredCVs.length,
                  itemBuilder: (context, index) {
                    final cv = filteredCVs[index];
                    return _buildCVCard(cv);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label == 'Tất cả' ? null : label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey[300]!,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildCVCard(Map<String, dynamic> cv) {
    final title = cv['title'] ?? 'Untitled CV';
    final mcv = cv['mcv'] ?? 'CV001';
    final tags = List<String>.from(cv['tags'] ?? []);
    final typeField = cv['typeField'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            widget.onView(cv);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.description, color: Colors.green[700]),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
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
                              Text(
                                'Template: $mcv',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (typeField != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                                  ),
                                  child: Text(
                                    typeField,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton(
                      onSelected: (action) {
                        if (action == 'view') {
                          widget.onView(cv);
                        } else if (action == 'edit') {
                          widget.onEdit(cv['id']);
                        } else if (action == 'delete') {
                          widget.onDelete(cv['id'], title);
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.visibility, size: 20),
                              SizedBox(width: 8),
                              Text('Xem'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Sửa'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Xóa', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.blue[100]!),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

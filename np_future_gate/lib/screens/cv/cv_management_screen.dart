import 'package:flutter/material.dart';
import '../../core/services/cv_supabase_service.dart';
import 'cv_setting/cv_display_manager.dart';
import 'cv_input/cv1_input_screen.dart';
import 'cv_input/cv2_input_screen.dart';
import 'cv_input/cv3_input_screen.dart';

/// CV Management Screen - Quản lý danh sách CV của người dùng
class CVManagementScreen extends StatefulWidget {
  const CVManagementScreen({Key? key}) : super(key: key);

  @override
  State<CVManagementScreen> createState() => _CVManagementScreenState();
}

class _CVManagementScreenState extends State<CVManagementScreen> {
  final CVSupabaseService _cvService = CVSupabaseService();
  List<Map<String, dynamic>> _cvList = [];
  bool _isLoading = false;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadCVs();
  }

  Future<void> _loadCVs() async {
    setState(() => _isLoading = true);
    try {
      final cvs = await _cvService.getMyCVs();
      setState(() => _cvList = cvs);
      debugPrint('Loaded ${cvs.length} CVs');
    } catch (e) {
      _showError('Không thể tải danh sách CV: $e');
      debugPrint('Error loading CVs: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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
                _showUploadDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadDialog() {
    final titleController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Upload CV'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Tên CV'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(labelText: 'Đường dẫn file (URL)'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Lưu ý: Hiện tại chỉ hỗ trợ lưu đường dẫn file.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty || urlController.text.isEmpty) {
                return;
              }
              Navigator.pop(ctx);
              await _createUploadedCV(titleController.text, urlController.text);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _createUploadedCV(String title, String url) async {
    setState(() => _isLoading = true);
    try {
      final cvData = {
        'title': title,
        'type': 'upload',
        'mcv': null, // No template code for uploads
        'file_url': url,
        'data': {}, // Empty data structure
      };
      await _cvService.createCV(cvData);
      _showSuccess('Đã upload CV thành công');
      _loadCVs();
    } catch (e) {
      _showError('Lỗi khi upload CV: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

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
        appBar: AppBar(
          title: const Text('Quản lý CV'),
          elevation: 0,
          backgroundColor: Colors.blue[700],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'CV Chung'),
              Tab(text: 'Theo lĩnh vực'),
              Tab(text: 'Upload'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (value) => setState(() => _searchText = value),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm CV...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: _searchText.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _searchText = ''),
                        )
                      : null,
                ),
              ),
            ),

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
        floatingActionButton: FloatingActionButton(
          onPressed: _showCreateOptions,
          tooltip: 'Tạo CV mới',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  // Tab 1: CV Chung (All General CVs)
  Widget _buildGeneralTab() {
    final generalCVs = _cvList.where((cv) {
      final type = cv['type'] ?? 'general';
      final title = (cv['title'] ?? '').toLowerCase();
      final searchMatch = _searchText.isEmpty || title.contains(_searchText.toLowerCase());
      return type == 'general' && searchMatch;
    }).toList();

    if (generalCVs.isEmpty) {
      return _buildEmptyState('Chưa có CV chung nào');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: generalCVs.length,
      itemBuilder: (context, index) => _buildCVCard(generalCVs[index]),
    );
  }

  // Tab 2: Theo lĩnh vực (By Domain)
  Widget _buildDomainTab() {
    return _DomainCVList(
      cvList: _cvList,
      searchText: _searchText,
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
      return type == 'upload' && searchMatch;
    }).toList();

    return Column(
      children: [
        // Removed Upload Button as requested
        const SizedBox(height: 16),
        Expanded(
          child: uploadedCVs.isEmpty
              ? _buildEmptyState('Chưa có CV nào được tải lên')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
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
  final List<Map<String, dynamic>> cvList;
  final String searchText;
  final Function(Map<String, dynamic>) onView;
  final Function(String) onEdit;
  final Function(String, String) onDelete;

  const _DomainCVList({
    Key? key,
    required this.cvList,
    required this.searchText,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

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

      // Filter by search
      if (widget.searchText.isNotEmpty) {
        final title = (cv['title'] ?? '').toLowerCase();
        if (!title.contains(widget.searchText.toLowerCase())) return false;
      }

      return true;
    }).toList();

    return Column(
      children: [
        // Category Filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: const Text('Tất cả'),
                    selected: _selectedCategory == null,
                    onSelected: (_) => setState(() => _selectedCategory = null),
                  ),
                ),
                ...(_categories.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(cat),
                      selected: _selectedCategory == cat,
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                    ),
                  );
                }).toList()),
              ],
            ),
          ),
        ),

        // List
        Expanded(
          child: filteredCVs.isEmpty
              ? Center(
                  child: Text(
                    'Không tìm thấy CV lĩnh vực nào',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
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

  Widget _buildCVCard(Map<String, dynamic> cv) {
    final title = cv['title'] ?? 'Untitled CV';
    final mcv = cv['mcv'] ?? 'CV001';
    final tags = List<String>.from(cv['tags'] ?? []);
    final typeField = cv['typeField'];

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          widget.onView(cv);
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
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.orange.withOpacity(0.5)),
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

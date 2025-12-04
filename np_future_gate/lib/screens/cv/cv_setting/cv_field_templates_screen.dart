import 'package:flutter/material.dart';
import 'cv_metadata.dart';
import '../cv_input/cv1_input_screen.dart';
import '../cv_input/cv3_input_screen.dart';

class CVFieldCategory {
  final String name;
  final IconData icon;
  final Color color;
  final List<String> relatedTags; // Tags to filter by

  CVFieldCategory(this.name, this.icon, this.color, this.relatedTags);
}

class CVFieldTemplatesScreen extends StatefulWidget {
  const CVFieldTemplatesScreen({super.key});

  @override
  State<CVFieldTemplatesScreen> createState() => _CVFieldTemplatesScreenState();
}

class _CVFieldTemplatesScreenState extends State<CVFieldTemplatesScreen> {
  String? _selectedCategoryName;
  String _searchQuery = '';
  final Set<String> _selectedTags = {};

  final List<CVFieldCategory> _categories = [
    CVFieldCategory('Công nghệ', Icons.computer, Colors.blue, ['Technical', 'Developer', 'Senior', 'Junior']),
    CVFieldCategory('Kinh doanh', Icons.business, Colors.green, ['Professional', 'Manager', 'Sales', 'B2B']),
    CVFieldCategory('Marketing', Icons.campaign, Colors.orange, ['Creative', 'Modern', 'Social Media', 'Content']),
    CVFieldCategory('Thiết kế', Icons.palette, Colors.purple, ['Designer', 'Creative', 'UI/UX', 'Art']),
    CVFieldCategory('Tài chính', Icons.attach_money, Colors.teal, ['Professional', 'Analyst', 'Banking']),
    CVFieldCategory('Y tế', Icons.health_and_safety, Colors.red, ['Professional', 'Doctor', 'Nurse']), 
  ];

  @override
  void initState() {
    super.initState();
    CVRegistry.initialize();
  }

  List<CVMetadata> get _filteredTemplates {
    if (_selectedCategoryName == null) return [];
    
    final category = _categories.firstWhere((c) => c.name == _selectedCategoryName);
    
    // Strict filtering by typeField only
    var templates = CVRegistry.getAll().where((cv) {
      return cv.typeField == category.name;
    }).toList();

    if (_searchQuery.isNotEmpty) {
      templates = templates.where((t) =>
          t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.description.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Filter by Selected Tags
    if (_selectedTags.isNotEmpty) {
      templates = templates.where((t) =>
          t.tags.any((tag) => _selectedTags.contains(tag.label))
      ).toList();
    }
    
    return templates;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.orange[50]!, Colors.white],
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
                      onTap: () {
                        if (_selectedCategoryName != null) {
                          setState(() => _selectedCategoryName = null);
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedCategoryName ?? 'Mẫu CV Theo Lĩnh Vực',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedCategoryName == null 
                                ? 'Chọn chuyên ngành phù hợp với bạn'
                                : 'Danh sách mẫu CV cho $_selectedCategoryName',
                            style: const TextStyle(
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

              // Content
              Expanded(
                child: _selectedCategoryName == null
                    ? _buildCategoryGrid()
                    : _buildTemplateList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: _categories.length,
      itemBuilder: (ctx, i) => _buildCategoryCard(_categories[i]),
    );
  }

  Widget _buildTemplateList() {
    final category = _categories.firstWhere((c) => c.name == _selectedCategoryName);

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm trong $_selectedCategoryName...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.orange[400]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),

        // Tag Filters
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildFilterChip('Tất cả', _selectedTags.isEmpty, isAll: true),
              const SizedBox(width: 8),
              ...category.relatedTags.map((tag) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildFilterChip(tag, _selectedTags.contains(tag)),
              )),
            ],
          ),
        ),

        const SizedBox(height: 20),
        Expanded(
          child: _filteredTemplates.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có mẫu phù hợp',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: _filteredTemplates.length,
                  itemBuilder: (ctx, i) => _buildTemplateCard(_filteredTemplates[i]),
                ),
        ),
      ],
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
          color: isSelected ? Colors.orange : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey[300]!,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
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

  Widget _buildCategoryCard(CVFieldCategory category) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: category.color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedCategoryName = category.name),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(category.icon, size: 32, color: category.color),
              ),
              const SizedBox(height: 12),
              Text(
                category.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${category.relatedTags.length} tags',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateCard(CVMetadata t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (t.mcv == 'CV001') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CV1InputScreen()),
              );
            } else if (t.mcv == 'CV003') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CV3InputScreen()),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đang phát triển mẫu: ${t.title}')),
              );
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(t.icon, color: Colors.orange[600], size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            t.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: t.tags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: tag.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: tag.color.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (tag.icon != null) ...[
                          Icon(tag.icon, size: 12, color: tag.color),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          tag.label,
                          style: TextStyle(
                            fontSize: 11,
                            color: tag.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

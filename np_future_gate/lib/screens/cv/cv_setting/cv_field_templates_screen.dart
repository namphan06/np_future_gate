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

  final List<CVFieldCategory> _categories = [
    CVFieldCategory('Công nghệ', Icons.computer, Colors.blue, ['Technical', 'Developer']),
    CVFieldCategory('Kinh doanh', Icons.business, Colors.green, ['Professional', 'All Industries']),
    CVFieldCategory('Marketing', Icons.campaign, Colors.orange, ['Creative', 'Modern']),
    CVFieldCategory('Thiết kế', Icons.palette, Colors.purple, ['Designer', 'Creative']),
    CVFieldCategory('Tài chính', Icons.attach_money, Colors.teal, ['Professional']),
    CVFieldCategory('Y tế', Icons.health_and_safety, Colors.red, ['Professional']), // Fallback
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
    final templates = CVRegistry.getAll().where((cv) {
      return cv.typeField == category.name;
    }).toList();

    if (_searchQuery.isEmpty) return templates;
    
    return templates.where((t) =>
        t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        t.description.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mẫu CV Theo Lĩnh Vực'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (_selectedCategoryName == null) ...[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Chọn lĩnh vực của bạn',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: _categories.length,
                itemBuilder: (ctx, i) => _buildCategoryCard(_categories[i]),
              ),
            ),
          ] else ...[
            Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => setState(() => _selectedCategoryName = null),
                  ),
                  Expanded(
                    child: Text(
                      _selectedCategoryName!,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm trong $_selectedCategoryName...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
            Expanded(
              child: _filteredTemplates.isEmpty 
                ? const Center(child: Text("Chưa có mẫu phù hợp cho lĩnh vực này"))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredTemplates.length,
                    itemBuilder: (ctx, i) => _buildTemplateCard(_filteredTemplates[i]),
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryCard(CVFieldCategory category) {
    return InkWell(
      onTap: () => setState(() => _selectedCategoryName = category.name),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
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
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(CVMetadata t) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
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
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(t.icon, color: Colors.blue, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: t.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: tag.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: tag.color.withOpacity(0.3)),
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
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

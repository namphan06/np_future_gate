import 'package:flutter/material.dart';
import 'package:np_future_gate/screens/cv/cv_input/cv2_input_screen.dart';
import 'cv_metadata.dart';
import '../cv_input/cv1_input_screen.dart';
import '../cv_management_screen.dart';

/// Screen showing general CV templates
class CVGeneralTemplatesScreen extends StatefulWidget {
  const CVGeneralTemplatesScreen({super.key});

  @override
  State<CVGeneralTemplatesScreen> createState() => _CVGeneralTemplatesScreenState();
}

class _CVGeneralTemplatesScreenState extends State<CVGeneralTemplatesScreen> {
  String _searchQuery = '';
  List<CVMetadata> _templates = [];

  @override
  void initState() {
    super.initState();
    CVRegistry.initialize(); // Ensure registry is initialized
    _templates = CVRegistry.getAll();
  }

  List<CVMetadata> get _filteredTemplates {
    if (_searchQuery.isEmpty) return _templates;
    return _templates.where((t) =>
        t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        t.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        t.tags.any((tag) => tag.label.toLowerCase().contains(_searchQuery.toLowerCase()))
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mẫu CV Chung'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.manage_search),
            tooltip: 'Quản lý CV',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CVManagementScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên, mô tả hoặc thẻ...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredTemplates.length,
              itemBuilder: (ctx, i) => _buildCard(_filteredTemplates[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(CVMetadata t) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          if (t.mcv == 'CV001') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CV1InputScreen()),
            );
          } else if (t.mcv == 'CV002') {
            // Navigate to CV2 input screen when implemented
           Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CV2InputScreen()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Đang phát triển mẫu: ${t.title}')),
            );
          }
        },
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.description,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: t.tags.map((tag) => Chip(
                  label: Text(
                    tag.label,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  backgroundColor: tag.color,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

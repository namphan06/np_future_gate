import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/job_model.dart';
import '../../../core/models/profile_model.dart';
import '../../../core/theme/app_main_colors.dart';

class JobSelectionDialog extends StatefulWidget {
  final Profile candidate;

  const JobSelectionDialog({super.key, required this.candidate});

  @override
  State<JobSelectionDialog> createState() => _JobSelectionDialogState();
}

class _JobSelectionDialogState extends State<JobSelectionDialog> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<JobModel> _jobs = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Bạn chưa đăng nhập';
        });
        return;
      }

      // Fetch jobs created by this employer
      // We don't strictly need 'profiles' join if we just want the job details
      // But if JobModel.fromJson expects it for creatorName, we keep it.
      // However, if the relation is broken, it might fail. 
      // Let's try fetching without profiles first if possible, or keep it if we are sure.
      // Given the user said "not showing", let's try to be robust.
      
      final response = await Supabase.instance.client
          .from('jobs')
          .select('*')
          .eq('creator_id', userId)
          // .eq('is_active', true) // Temporarily comment out is_active to see if that's the issue
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      
      setState(() {
        _jobs = data.map((e) => JobModel.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading jobs: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi tải công việc: $e';
      });
    }
  }

  List<JobModel> get _filteredJobs {
    if (_searchQuery.isEmpty) return _jobs;
    final query = _searchQuery.toLowerCase();
    return _jobs.where((job) {
      final title = job.metadata.title.toLowerCase();
      final fields = job.metadata.fields.map((e) => e.toLowerCase()).toList();
      final tags = job.metadata.requirementsTags.map((e) => e.toLowerCase()).toList();
      
      return title.contains(query) || 
             fields.any((f) => f.contains(query)) || 
             tags.any((t) => t.contains(query));
    }).toList();
  }

  Future<void> _onJobSelected(JobModel job) async {
    // Placeholder for future action
    Navigator.pop(context); // Close dialog
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã chọn công việc: ${job.metadata.title}'),
        backgroundColor: AppMainColors.primary,
      ),
    );
  }

  // Helper method removed as it was only used for email dialog
  // Widget _buildDetailRow(String label, String value) { ... }



  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chọn công việc',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Tìm theo tên, lĩnh vực...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                      : _filteredJobs.isEmpty
                          ? Center(
                              child: Text(
                                _jobs.isEmpty 
                                    ? 'Bạn chưa đăng công việc nào' 
                                    : 'Không tìm thấy công việc phù hợp',
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredJobs.length,
                              itemBuilder: (context, index) {
                                final job = _filteredJobs[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(12),
                                    title: Text(
                                      job.metadata.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          job.metadata.fields.join(', '),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Lương: ${job.metadata.salary.min != null ? '${job.metadata.salary.min} - ${job.metadata.salary.max} triệu' : 'Thỏa thuận'}',
                                          style: TextStyle(color: Colors.green.shade700, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    trailing: ElevatedButton(
                                      onPressed: () => _onJobSelected(job),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppMainColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('Chọn'),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

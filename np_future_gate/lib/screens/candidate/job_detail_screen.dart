import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/job_model.dart';
import '../../../core/repositories/job_repository.dart';
import '../../../core/services/cv_supabase_service.dart';
import '../../../core/theme/app_main_colors.dart';

class JobDetailScreen extends StatefulWidget {
  final JobModel job;

  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final JobRepository _jobRepository = JobRepository();
  final CVSupabaseService _cvService = CVSupabaseService();
  
  bool _isSaved = false;
  bool _isApplying = false;
  bool _hasApplied = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _checkIfSaved();
    _checkIfApplied();
  }

  Future<void> _checkIfApplied() async {
    if (_currentUserId == null) return;
    final hasApplied = await _jobRepository.hasApplied(_currentUserId!, widget.job.id!);
    if (mounted) {
      setState(() {
        _hasApplied = hasApplied;
      });
    }
  }

  Future<void> _checkIfSaved() async {
    if (_currentUserId == null) return;
    final savedIds = await _jobRepository.getSavedJobIds(_currentUserId!);
    if (mounted) {
      setState(() {
        _isSaved = savedIds.contains(widget.job.id);
      });
    }
  }

  Future<void> _toggleSave() async {
    if (_currentUserId == null) return;
    try {
      await _jobRepository.toggleSaveJob(_currentUserId!, widget.job.id!);
      setState(() => _isSaved = !_isSaved);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isSaved ? 'Job saved' : 'Job unsaved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _showApplyDialog() async {
    if (_currentUserId == null) return;

    try {
      final cvs = await _cvService.getUserCVs(_currentUserId!);
      
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Apply for Job'),
          content: SizedBox(
            width: double.maxFinite,
            child: cvs.isEmpty
                ? const Text('You need to create a CV first.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: cvs.length,
                    itemBuilder: (context, index) {
                      final cv = cvs[index];
                      return ListTile(
                        title: Text(cv.name),
                        subtitle: Text(cv.updatedAt.toString().split(' ')[0]),
                        onTap: () => _applyForJob(cv.id),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading CVs: $e')),
      );
    }
  }

  Future<void> _applyForJob(String cvId) async {
    Navigator.pop(context); // Close dialog
    setState(() => _isApplying = true);

    try {
      await _jobRepository.applyForJob(widget.job.id!, _currentUserId!, cvId);
      if (mounted) {
        setState(() {
          _hasApplied = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error applying: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = widget.job.metadata;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40), // Space for back button
                        
                        // Header: Logo & Company Name
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                  image: widget.job.creatorAvatarUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(widget.job.creatorAvatarUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: widget.job.creatorAvatarUrl == null
                                    ? Center(
                                        child: Text(
                                          meta.title.isNotEmpty ? meta.title[0].toUpperCase() : 'J',
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: AppMainColors.primary,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              if (widget.job.creatorName != null)
                                Text(
                                  widget.job.creatorName!,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              const SizedBox(height: 8),
                              Text(
                                meta.title,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    meta.workingRegions.isNotEmpty ? meta.workingRegions.first : 'Toàn quốc',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Key Info Tags
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildTag(
                              Icons.monetization_on_outlined,
                              meta.salary.isNegotiable
                                  ? 'Thỏa thuận'
                                  : '${meta.salary.min ?? 0} - ${meta.salary.max ?? 0} ${meta.salary.currency}',
                              Colors.green.shade700,
                              Colors.green.shade50,
                            ),
                            if (meta.employmentTypes.isNotEmpty)
                              _buildTag(
                                Icons.business_center_outlined,
                                meta.employmentTypes.first,
                                Colors.orange.shade700,
                                Colors.orange.shade50,
                              ),
                            if (meta.experienceRequired.isNotEmpty)
                              _buildTag(
                                Icons.work_history_outlined,
                                meta.experienceRequired,
                                Colors.blue.shade700,
                                Colors.blue.shade50,
                              ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Requirements Tags
                        if (meta.requirementsTags.isNotEmpty) ...[
                          const Text(
                            'Kỹ năng yêu cầu',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: meta.requirementsTags.map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 32),
                        ],

                        // Description Sections
                        _buildSection('Mô tả công việc', meta.jobDescription),
                        _buildSection('Yêu cầu ứng viên', meta.candidateRequirements),
                        _buildSection('Quyền lợi', meta.benefits),
                        
                        const SizedBox(height: 100), // Space for bottom bar
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Back Button & Save Button
            Positioned(
              top: 10,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCircleButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildCircleButton(
                    icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: _isSaved ? AppMainColors.primary : Colors.black87,
                    onTap: _toggleSave,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isApplying ? null : _showApplyDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppMainColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isApplying
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      _hasApplied ? 'Ứng tuyển lại' : 'Ứng tuyển ngay',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(IconData icon, String text, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Expanded(child: Text(item, style: const TextStyle(fontSize: 16, height: 1.5))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

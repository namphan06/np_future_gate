import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/job_model.dart';
import '../../../core/repositories/job_repository.dart';
import '../../../core/services/cv_supabase_service.dart';
import '../../../core/theme/app_main_colors.dart';
import '../../../core/models/cv_model.dart';

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
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _checkIfSaved();
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
      await _jobRepository.toggleSaveJob(_currentUserId!, widget.job.id!, !_isSaved);
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
      appBar: AppBar(
        title: Text(meta.title),
        actions: [
          IconButton(
            icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border),
            color: _isSaved ? AppMainColors.primary : null,
            onPressed: _toggleSave,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.business, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meta.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        meta.workingRegions.join(', '),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Salary & Type
            Row(
              children: [
                _buildTag(Icons.monetization_on, 
                  meta.salary.isNegotiable 
                    ? 'Negotiable' 
                    : '${meta.salary.min} - ${meta.salary.max} ${meta.salary.currency}'),
                const SizedBox(width: 12),
                _buildTag(Icons.work, meta.employmentTypes.join(', ')),
              ],
            ),
            const SizedBox(height: 24),

            // Description
            _buildSection('Job Description', meta.jobDescription),
            _buildSection('Requirements', meta.candidateRequirements),
            _buildSection('Benefits', meta.benefits),
            
            const SizedBox(height: 80), // Space for bottom button
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isApplying ? null : _showApplyDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppMainColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isApplying
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Apply Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppMainColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppMainColors.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: AppMainColors.primary,
              fontWeight: FontWeight.w500,
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

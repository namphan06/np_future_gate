import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/job_model.dart';
import '../../../core/repositories/job_repository.dart';
import '../../../core/enums/vietnam_provinces.dart';
import '../../../core/enums/job_fields.dart';
import '../../../core/enums/employment_types.dart';
import '../../../core/enums/experience_levels.dart';
import '../../../core/theme/app_main_colors.dart';

class EditJobScreen extends StatefulWidget {
  final JobModel? job;

  const EditJobScreen({super.key, this.job});

  @override
  State<EditJobScreen> createState() => _EditJobScreenState();
}

class _EditJobScreenState extends State<EditJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _jobRepository = JobRepository();
  bool _isLoading = false;

  // Controllers
  final _titleController = TextEditingController();
  // final _experienceController = TextEditingController(); // Removed in favor of dropdown
  final _salaryMinController = TextEditingController();
  final _salaryMaxController = TextEditingController();

  // State variables
  DateTime? _deadline;
  bool _isActive = true;
  bool _isNegotiable = false;
  String? _selectedExperience;
  List<String> _workingRegions = [];
  List<String> _fields = [];
  List<String> _employmentTypes = [];
  List<String> _workLocations = [];
  List<String> _jobDescription = [];
  List<String> _candidateRequirements = [];
  List<String> _benefits = [];
  List<String> _requirementsTags = [];

  @override
  void initState() {
    super.initState();
    if (widget.job != null) {
      _initData();
    }
  }

  void _initData() {
    final job = widget.job!;
    final meta = job.metadata;

    _titleController.text = meta.title;
    _selectedExperience = meta.experienceRequired;
    _salaryMinController.text = meta.salary.min?.toString() ?? '';
    _salaryMaxController.text = meta.salary.max?.toString() ?? '';
    
    _deadline = job.deadline;
    _isActive = job.isActive;
    _isNegotiable = meta.salary.isNegotiable;
    
    _workingRegions = List.from(meta.workingRegions);
    _fields = List.from(meta.fields);
    _employmentTypes = List.from(meta.employmentTypes);
    _workLocations = List.from(meta.workLocations);
    _jobDescription = List.from(meta.jobDescription);
    _candidateRequirements = List.from(meta.candidateRequirements);
    _benefits = List.from(meta.benefits);
    _requirementsTags = List.from(meta.requirementsTags);
  }

  Future<void> _saveJob() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      final salary = JobSalary(
        min: double.tryParse(_salaryMinController.text),
        max: double.tryParse(_salaryMaxController.text),
        isNegotiable: _isNegotiable,
      );

      final metadata = JobMetadata(
        title: _titleController.text,
        workingRegions: _workingRegions,
        experienceRequired: _selectedExperience ?? '',
        fields: _fields,
        requirementsTags: _requirementsTags,
        salary: salary,
        employmentTypes: _employmentTypes,
        workLocations: _workLocations,
        jobDescription: _jobDescription,
        candidateRequirements: _candidateRequirements,
        benefits: _benefits,
      );

      final job = JobModel(
        id: widget.job?.id,
        creatorId: userId,
        isActive: _isActive,
        deadline: _deadline,
        metadata: metadata,
        applicants: widget.job?.applicants ?? [],
      );

      if (widget.job == null) {
        await _jobRepository.createJob(job);
      } else {
        await _jobRepository.updateJob(job);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving job: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.job == null ? 'Post New Job' : 'Edit Job'),
        actions: [
          IconButton(
            onPressed: _saveJob,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.check),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('Basic Information'),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Job Title'),
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            
            _buildMultiSelect(
              title: 'Working Regions',
              items: _workingRegions,
              options: VietnamProvince.valuesList,
              onChanged: (val) => setState(() => _workingRegions = val),
            ),
            
            const SizedBox(height: 16),
            _buildMultiSelect(
              title: 'Fields',
              items: _fields,
              options: JobField.valuesList,
              onChanged: (val) => setState(() => _fields = val),
            ),

            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedExperience != null && ExperienceLevel.valuesList.contains(_selectedExperience) 
                  ? _selectedExperience 
                  : null,
              decoration: const InputDecoration(labelText: 'Experience Required'),
              items: ExperienceLevel.valuesList.map((e) {
                return DropdownMenuItem(value: e, child: Text(e));
              }).toList(),
              onChanged: (val) => setState(() => _selectedExperience = val),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Salary & Employment'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _salaryMinController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Min Salary'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _salaryMaxController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Max Salary'),
                  ),
                ),
              ],
            ),
            CheckboxListTile(
              title: const Text('Negotiable'),
              value: _isNegotiable,
              onChanged: (v) => setState(() => _isNegotiable = v!),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 16),
            _buildMultiSelect(
              title: 'Employment Types',
              items: _employmentTypes,
              options: EmploymentType.valuesList,
              onChanged: (val) => setState(() => _employmentTypes = val),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Details'),
            _buildDynamicList('Work Locations', _workLocations),
            const SizedBox(height: 16),
            _buildDynamicList('Job Description', _jobDescription),
            const SizedBox(height: 16),
            _buildDynamicList('Candidate Requirements', _candidateRequirements),
            const SizedBox(height: 16),
            _buildDynamicList('Benefits', _benefits),
            const SizedBox(height: 16),
            _buildDynamicList('Tags', _requirementsTags),

            const SizedBox(height: 24),
            _buildSectionTitle('Settings'),
            ListTile(
              title: const Text('Application Deadline'),
              subtitle: Text(_deadline?.toString().split(' ')[0] ?? 'Not set'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final now = DateTime.now();
                final initialDate = _deadline ?? now;
                // Ensure firstDate is not after initialDate
                final firstDate = initialDate.isBefore(now) ? initialDate : now;

                final date = await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: firstDate,
                  lastDate: now.add(const Duration(days: 365)),
                );
                if (date != null) setState(() => _deadline = date);
              },
            ),
            SwitchListTile(
              title: const Text('Active Status'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppMainColors.primary,
        ),
      ),
    );
  }

  Widget _buildMultiSelect({
    required String title,
    required List<String> items,
    required List<String> options,
    required Function(List<String>) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: options.map((option) {
            final isSelected = items.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                final newItems = List<String>.from(items);
                if (selected) {
                  newItems.add(option);
                } else {
                  newItems.remove(option);
                }
                onChanged(newItems);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDynamicList(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                _showAddItemDialog(title, (val) {
                  setState(() => items.add(val));
                });
              },
            ),
          ],
        ),
        if (items.isEmpty)
          const Text('No items added', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
        else
          ...items.asMap().entries.map((entry) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('• ${entry.value}'),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                onPressed: () {
                  setState(() => items.removeAt(entry.key));
                },
              ),
            );
          }),
      ],
    );
  }

  void _showAddItemDialog(String title, Function(String) onAdd) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add to $title'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter text...'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onAdd(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

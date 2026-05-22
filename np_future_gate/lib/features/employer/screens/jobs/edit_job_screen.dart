import 'package:flutter/material.dart';
import 'package:np_future_gate/core/enums/employment_types.dart';
import 'package:np_future_gate/core/enums/experience_levels.dart';
import 'package:np_future_gate/core/enums/job_fields.dart';
import 'package:np_future_gate/core/enums/vietnam_provinces.dart';
import 'package:np_future_gate/core/models/job_model.dart';
import 'package:np_future_gate/core/repositories/job_repository.dart';
import 'package:np_future_gate/core/theme/app_main_colors.dart';
import 'package:np_future_gate/shared/widgets/inputs/speech_text_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditJobScreen extends StatefulWidget {

  const EditJobScreen({super.key, this.job});
  final JobModel? job;

  @override
  State<EditJobScreen> createState() => _EditJobScreenState();
}

class _EditJobScreenState extends State<EditJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _jobRepository = JobRepository();
  bool _isLoading = false;

  // Controllers
  final _titleController = TextEditingController();
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
          SnackBar(content: Text('Lỗi khi lưu tin: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initialDate = _deadline ?? now;
    final firstDate = initialDate.isBefore(now) ? initialDate : now;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppMainColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) setState(() => _deadline = date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSectionContainer(
                      title: 'Thông tin cơ bản',
                      icon: Icons.info_outline,
                      children: [
                        _buildTextField(
                          controller: _titleController,
                          label: 'Tiêu đề công việc',
                          hint: 'VD: Senior Flutter Developer',
                          validator: (v) => v?.isEmpty == true ? 'Vui lòng nhập tiêu đề' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildDropdown(
                          label: 'Kinh nghiệm',
                          value: _selectedExperience,
                          items: ExperienceLevel.valuesList,
                          onChanged: (val) => setState(() => _selectedExperience = val),
                        ),
                        const SizedBox(height: 16),
                        _buildMultiSelectField(
                          title: 'Khu vực làm việc',
                          items: _workingRegions,
                          options: VietnamProvince.valuesList,
                          onChanged: (val) => setState(() => _workingRegions = val),
                        ),
                        const SizedBox(height: 16),
                        _buildMultiSelectField(
                          title: 'Lĩnh vực chuyên môn',
                          items: _fields,
                          options: JobField.valuesList,
                          onChanged: (val) => setState(() => _fields = val),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildSectionContainer(
                      title: 'Lương & Hình thức',
                      icon: Icons.monetization_on_outlined,
                      children: [
                         Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _salaryMinController,
                                label: 'Lương tối thiểu',
                                hint: '0',
                                keyboardType: TextInputType.number,
                                enabled: !_isNegotiable,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _salaryMaxController,
                                label: 'Lương tối đa',
                                hint: '0',
                                keyboardType: TextInputType.number,
                                enabled: !_isNegotiable,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          title: const Text('Lương thỏa thuận'),
                          value: _isNegotiable,
                          onChanged: (v) => setState(() {
                            _isNegotiable = v!;
                            if (v) {
                              _salaryMinController.clear();
                              _salaryMaxController.clear();
                            }
                          }),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppMainColors.primary,
                        ),
                        const SizedBox(height: 8),
                        _buildMultiSelectField(
                          title: 'Hình thức làm việc',
                          items: _employmentTypes,
                          options: EmploymentType.valuesList,
                          onChanged: (val) => setState(() => _employmentTypes = val),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _buildSectionContainer(
                      title: 'Chi tiết công việc',
                      icon: Icons.description_outlined,
                      children: [
                        _buildDynamicList('Địa điểm làm việc cụ thể', _workLocations, hint: 'Nhập địa chỉ...'),
                        const SizedBox(height: 24),
                        _buildDynamicList('Mô tả công việc', _jobDescription, isLongText: true, hint: 'Nhập mô tả...'),
                        const SizedBox(height: 24),
                        _buildDynamicList('Yêu cầu ứng viên', _candidateRequirements, isLongText: true, hint: 'Nhập yêu cầu...'),
                        const SizedBox(height: 24),
                        _buildDynamicList('Quyền lợi', _benefits, isLongText: true, hint: 'Nhập quyền lợi...'),
                        const SizedBox(height: 24),
                        _buildDynamicList('Thẻ từ khóa (Tags)', _requirementsTags, hint: 'VD: Flutter, Dart...'),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _buildSectionContainer(
                      title: 'Cài đặt tin',
                      icon: Icons.settings_outlined,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Hạn nộp hồ sơ', style: TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text(
                            _deadline != null 
                              ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}' 
                              : 'Chưa thiết lập',
                            style: TextStyle(color: _deadline != null ? Colors.black87 : Colors.grey),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppMainColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.calendar_today, color: AppMainColors.primary, size: 20),
                          ),
                          onTap: _pickDate,
                        ),
                        const Divider(height: 24),
                        SwitchListTile(
                          title: const Text('Trạng thái hoạt động', style: TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text(
                            _isActive ? 'Tin đang hiển thị với ứng viên' : 'Tin đang bị ẩn',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                          value: _isActive,
                          onChanged: (v) => setState(() => _isActive = v),
                          activeThumbColor: AppMainColors.primary,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.arrow_back_ios_new, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.job == null ? 'Đăng tin tuyển dụng' : 'Chỉnh sửa tin',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _saveJob,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppMainColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Lưu', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContainer({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppMainColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return SpeechTextField(
      controller: controller,
      label: label,
      hint: hint ?? label,
      keyboardType: keyboardType,
      enabled: enabled,
      validator: validator,
      maxLines: 1,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: items.map((e) {
        return DropdownMenuItem(value: e, child: Text(e));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildMultiSelectField({
    required String title,
    required List<String> items,
    required List<String> options,
    required Function(List<String>) onChanged,
  }) {
    final bool isLargeList = options.length > 10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
        const SizedBox(height: 8),
        if (isLargeList)
          InkWell(
            onTap: () => _showMultiSelectDialog(title, items, options, onChanged),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      items.isEmpty ? 'Chọn $title' : items.join(', '),
                      style: TextStyle(
                        color: items.isEmpty ? Colors.grey : Colors.black87,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
                selectedColor: AppMainColors.primary.withValues(alpha: 0.15),
                checkmarkColor: AppMainColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? AppMainColors.primary : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
                backgroundColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppMainColors.primary.withValues(alpha: 0.5) : Colors.transparent,
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  void _showMultiSelectDialog(
    String title,
    List<String> currentItems,
    List<String> options,
    Function(List<String>) onChanged,
  ) {
    final tempItems = List<String>.from(currentItems);
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Chọn $title'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = tempItems.contains(option);
                    return CheckboxListTile(
                      title: Text(option),
                      value: isSelected,
                      activeColor: AppMainColors.primary,
                      onChanged: (val) {
                        setStateDialog(() {
                          if (val == true) {
                            tempItems.add(option);
                          } else {
                            tempItems.remove(option);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () {
                    onChanged(tempItems);
                    Navigator.pop(context);
                  },
                  child: const Text('Xác nhận'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDynamicList(String title, List<String> items, {bool isLongText = false, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
            InkWell(
              onTap: () {
                _showAddItemDialog(title, (val) {
                  setState(() => items.add(val));
                }, isLongText: isLongText, hint: hint);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppMainColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, size: 16, color: AppMainColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'Thêm',
                      style: TextStyle(
                        color: AppMainColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              'Chưa có thông tin',
              style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...items.asMap().entries.map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.circle, size: 8, color: AppMainColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(height: 1.4),
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => items.removeAt(entry.key)),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(Icons.close, size: 18, color: Colors.grey.shade400),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  void _showAddItemDialog(String title, Function(String) onAdd, {bool isLongText = false, String? hint}) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thêm $title'),
        content: SpeechTextField(
          controller: controller,
          hint: hint ?? 'Nhập nội dung... (hoặc nói)',
          maxLines: isLongText ? 3 : 1,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onAdd(controller.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppMainColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }
}

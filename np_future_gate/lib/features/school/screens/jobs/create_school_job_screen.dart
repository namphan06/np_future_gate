import 'package:flutter/material.dart';
import 'package:np_future_gate/core/enums/employment_types.dart';
import 'package:np_future_gate/core/enums/experience_levels.dart';
import 'package:np_future_gate/core/enums/job_fields.dart';
import 'package:np_future_gate/core/enums/vietnam_provinces.dart';
import 'package:np_future_gate/core/models/job_model.dart';
import 'package:np_future_gate/core/repositories/job_repository.dart';
import 'package:np_future_gate/core/theme/app_main_colors.dart';
import 'package:np_future_gate/features/school/screens/partnership/companies_list_screen.dart';
import 'package:np_future_gate/features/school/screens/partnership/select_company_job_screen.dart';
import 'package:np_future_gate/features/school/screens/partnership/select_company_screen.dart';
import 'package:np_future_gate/features/school/screens/school_email_setup_screen.dart';
import 'package:np_future_gate/shared/widgets/inputs/speech_text_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateSchoolJobScreen extends StatefulWidget {

  const CreateSchoolJobScreen({
    super.key,
    required this.isPartnership,
    this.job,
    this.preselectedCompanyId,
    this.preselectedCompanyName,
  });
  final bool isPartnership;
  final JobModel? job; // For editing
  final String? preselectedCompanyId;
  final String? preselectedCompanyName;

  @override
  State<CreateSchoolJobScreen> createState() => _CreateSchoolJobScreenState();
}

class _CreateSchoolJobScreenState extends State<CreateSchoolJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _jobRepository = JobRepository();
  bool _isLoading = false;

  // Controllers
  final _titleController = TextEditingController();
  final _salaryMinController = TextEditingController();
  final _salaryMaxController = TextEditingController();

  // Partnership specific
  String? _selectedCompanyId;
  String? _selectedCompanyName;

  // State variables
  DateTime? _deadline;
  bool _isActive = true;
  bool _isNegotiable = false;
  bool _isIntern = false;
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
    
    // Set preselected company if provided
    if (widget.preselectedCompanyId != null && widget.preselectedCompanyName != null) {
      _selectedCompanyId = widget.preselectedCompanyId;
      _selectedCompanyName = widget.preselectedCompanyName;
    }
    
    if (widget.job != null) {
      _initData();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _salaryMinController.dispose();
    _salaryMaxController.dispose();
    super.dispose();
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
    _isIntern = meta.isIntern;
    
    _workingRegions = List.from(meta.workingRegions);
    _fields = List.from(meta.fields);
    _employmentTypes = List.from(meta.employmentTypes);
    _workLocations = List.from(meta.workLocations);
    _jobDescription = List.from(meta.jobDescription);
    _candidateRequirements = List.from(meta.candidateRequirements);
    _benefits = List.from(meta.benefits);
    _requirementsTags = List.from(meta.requirementsTags);
  }

  void _fillFromCompanyJob(JobModel companyJob) {
    final meta = companyJob.metadata;
    
    // Debug: Print để kiểm tra data
    debugPrint('=== Copying job from company ===');
    debugPrint('Title: ${meta.title}');
    debugPrint('Experience: ${meta.experienceRequired}');
    debugPrint('Employment Types: ${meta.employmentTypes}');
    debugPrint('Fields: ${meta.fields}');
    debugPrint('Working Regions: ${meta.workingRegions}');
    
    setState(() {
      _titleController.text = meta.title;
      _selectedExperience = meta.experienceRequired;
      _salaryMinController.text = meta.salary.min?.toString() ?? '';
      _salaryMaxController.text = meta.salary.max?.toString() ?? '';
      
      _deadline = companyJob.deadline;
      _isNegotiable = meta.salary.isNegotiable;
      _isIntern = meta.isIntern;
      
      _workingRegions = List.from(meta.workingRegions);
      _fields = List.from(meta.fields);
      _employmentTypes = List.from(meta.employmentTypes);
      _workLocations = List.from(meta.workLocations);
      _jobDescription = List.from(meta.jobDescription);
      _candidateRequirements = List.from(meta.candidateRequirements);
      _benefits = List.from(meta.benefits);
      _requirementsTags = List.from(meta.requirementsTags);
    });
    
    // Debug: Print sau khi setState
    debugPrint('After setState:');
    debugPrint('_selectedExperience: $_selectedExperience');
    debugPrint('_employmentTypes: $_employmentTypes');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã tự động điền thông tin từ tin của công ty')),
    );
  }

  Future<void> _saveJob() async {
    if (!_formKey.currentState!.validate()) return;

    // Partnership validation
    if (widget.isPartnership && _selectedCompanyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn công ty liên kết')),
      );
      return;
    }

    // Check school email for partnership jobs
    if (widget.isPartnership) {
      final emailCheck = await _checkSchoolEmail();
      if (!emailCheck) return;
    }

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
        isIntern: _isIntern,
      );

      if (widget.isPartnership) {
        // Save to school_partnership_jobs table
        await _savePartnershipJob(userId, metadata);
      } else {
        // Save to regular jobs table
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
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isPartnership 
              ? 'Đã gửi yêu cầu liên kết đến công ty' 
              : 'Đã lưu tin tuyển dụng'),
          ),
        );
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

  Future<bool> _checkSchoolEmail() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await Supabase.instance.client
          .from('profiles')
          .select('metadata')
          .eq('id', userId)
          .single();

      final metadata = response['metadata'] as Map<String, dynamic>? ?? {};
      final schoolEmail = metadata['school_email'];
      final isVerified = metadata['school_email_verified'] == true;

      if (schoolEmail == null || !isVerified) {
        if (mounted) {
          final shouldNavigate = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  SizedBox(width: 12),
                  Text('Yêu cầu email trường'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schoolEmail == null
                        ? 'Bạn cần đăng ký email trường để tạo tin liên kết doanh nghiệp.'
                        : 'Email trường của bạn chưa được admin xác nhận.',
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Email sẽ hiển thị trên tin tuyển dụng',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppMainColors.primary,
                  ),
                  child: Text(schoolEmail == null ? 'Đăng ký ngay' : 'Xem chi tiết'),
                ),
              ],
            ),
          );

          if (shouldNavigate == true && mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SchoolEmailSetupScreen(),
              ),
            );
          }
        }
        return false;
      }

      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kiểm tra email: $e')),
        );
      }
      return false;
    }
  }

  Future<void> _savePartnershipJob(String schoolId, JobMetadata metadata) async {
    // If editing existing job, just update it
    if (widget.job?.id != null) {
      await Supabase.instance.client
          .from('school_partnership_jobs')
          .update({
            'is_active': _isActive,
            'deadline': _deadline?.toIso8601String(),
            'metadata': metadata.toJson(),
            'company_status': 'pending',
            'admin_status': 'pending',
            'company_reviewed_at': null,
            'admin_reviewed_at': null,
          })
          .eq('id', widget.job!.id!);
      return;
    }
    
    // Below is for creating NEW partnership job
    // 1. Get School Profile for email
    final profileData = await Supabase.instance.client
        .from('profiles')
        .select('metadata')
        .eq('id', schoolId)
        .single();

    final profileMetadata = profileData['metadata'] as Map<String, dynamic>? ?? {};
    final schoolEmail = profileMetadata['school_email'] as String?;
    
    // 2. Check Partnership Status & Limit
    final partnership = await Supabase.instance.client
        .from('school_company_partnerships')
        .select()
        .eq('school_id', schoolId)
        .eq('company_id', _selectedCompanyId!)
        .eq('status', 'accepted')
        .maybeSingle();

    String companyStatus = 'pending';
    String? companyReviewedAt;

    if (partnership != null) {
      final limitPeriod = partnership['post_limit_period'] as String? ?? 'unlimited';
      final limitCount = partnership['post_limit_count'] as int?;
      
      bool isLimitReached = false;

      if (limitPeriod != 'unlimited' && limitCount != null) {
        final DateTime now = DateTime.now();
        DateTime startDate;
        if (limitPeriod == 'month') {
          startDate = DateTime(now.year, now.month, 1);
        } else if (limitPeriod == 'year') {
          startDate = DateTime(now.year, 1, 1);
        } else {
          startDate = DateTime(2000); 
        }

        final jobsResponse = await Supabase.instance.client
            .from('school_partnership_jobs')
            .select('id')
            .eq('school_id', schoolId)
            .eq('company_id', _selectedCompanyId!)
            .gte('created_at', startDate.toIso8601String());
        
        if ((jobsResponse as List).length >= limitCount) {
          isLimitReached = true;
        }
      }

      if (!isLimitReached) {
        // Limit valid -> Auto accept by company
        companyStatus = 'accepted';
        companyReviewedAt = DateTime.now().toIso8601String();
      } else {
        // Limit reached -> Confirm flow
        if (!mounted) return;
        
        final bool? confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Đã đạt giới hạn tin đăng'),
            content: Text(
              'Bạn đã đạt giới hạn ($limitCount tin/${limitPeriod == 'year' ? 'năm' : 'tháng'}) với đối tác này.\n\n'
              'Nếu tiếp tục, tin sẽ cần chờ duyệt và không được tự động chấp nhận.\n'
              'Hoặc bạn có thể gia hạn thêm quyền lợi.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false), // Go to extend
                child: const Text('Gia hạn liên kết'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true), // Continue
                child: const Text('Vẫn tạo tin'),
              ),
            ],
          ),
        );

        if (confirm == null) return; // Cancelled
        
        if (confirm == false) {
          if (mounted) {
             Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CompaniesListScreen()),
            );
          }
          return; // Stop creation
        }
        
        // If confirm == true, proceed with 'pending' companyStatus
      }
    }

    await Supabase.instance.client.from('school_partnership_jobs').insert({
      'school_id': schoolId,
      'company_id': _selectedCompanyId!,
      'company_status': companyStatus,
      'company_reviewed_at': companyReviewedAt,
      'admin_status': 'pending',
      'is_active': _isActive,
      'deadline': _deadline?.toIso8601String(),
      'metadata': metadata.toJson(),
      'applicants': [],
      'view_count': 0,
      'email': schoolEmail,
    });
  }

  Future<void> _selectCompany() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (context) => const SelectCompanyScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedCompanyId = result['id'];
        _selectedCompanyName = result['name'];
      });
    }
  }

  Future<void> _selectCompanyJob() async {
    if (_selectedCompanyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn công ty trước')),
      );
      return;
    }

    final result = await Navigator.push<JobModel>(
      context,
      MaterialPageRoute(
        builder: (context) => SelectCompanyJobScreen(companyId: _selectedCompanyId!),
      ),
    );

    if (result != null) {
      _fillFromCompanyJob(result);
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
                    // Partnership section
                    if (widget.isPartnership) ...[
                      _buildPartnershipSection(),
                      const SizedBox(height: 16),
                    ],

                    // Basic info
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
                    
                    // Salary section
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

                    // Job details
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

                    // Settings
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
                          title: const Text('Công việc thực tập', style: TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text(
                            _isIntern ? 'Đây là vị trí thực tập sinh' : 'Đây là vị trí chính thức',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                          value: _isIntern,
                          onChanged: (v) => setState(() => _isIntern = v),
                          activeThumbColor: Colors.orange,
                          contentPadding: EdgeInsets.zero,
                        ),
                        const Divider(height: 24),
                        SwitchListTile(
                          title: const Text('Trạng thái hoạt động', style: TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text(
                            _isActive ? 'Tin đang hiển thị' : 'Tin đang bị ẩn',
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

  Widget _buildPartnershipSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.purple, Color(0xFF9C27B0)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.handshake, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text(
                'Liên kết doanh nghiệp',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Selected company
          if (_selectedCompanyName != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.business, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Công ty đã chọn:',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedCompanyName!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() {
                      _selectedCompanyId = null;
                      _selectedCompanyName = null;
                    }),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _selectCompany,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.business_outlined, size: 20),
                  label: Text(_selectedCompanyName == null ? 'Chọn công ty' : 'Đổi công ty'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _selectedCompanyId == null ? null : _selectCompanyJob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.purple,
                    disabledBackgroundColor: Colors.white.withValues(alpha: 0.3),
                    disabledForegroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.copy_outlined, size: 20),
                  label: const Text('Sao chép tin'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tin liên kết cần công ty và admin duyệt mới xuất bản',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
              widget.isPartnership 
                ? 'Tạo tin liên kết doanh nghiệp'
                : 'Tạo tin thường',
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
              backgroundColor: widget.isPartnership ? Colors.purple : AppMainColors.primary,
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
                : Text(
                    widget.isPartnership ? 'Gửi yêu cầu' : 'Lưu',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
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
              Icon(icon, color: widget.isPartnership ? Colors.purple : AppMainColors.primary, size: 22),
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
                selectedColor: (widget.isPartnership ? Colors.purple : AppMainColors.primary).withValues(alpha: 0.15),
                checkmarkColor: widget.isPartnership ? Colors.purple : AppMainColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? (widget.isPartnership ? Colors.purple : AppMainColors.primary) : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
                backgroundColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected 
                      ? (widget.isPartnership ? Colors.purple : AppMainColors.primary).withValues(alpha: 0.5) 
                      : Colors.transparent,
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
                      activeColor: widget.isPartnership ? Colors.purple : AppMainColors.primary,
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
                  color: (widget.isPartnership ? Colors.purple : AppMainColors.primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add, size: 16, color: widget.isPartnership ? Colors.purple : AppMainColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Thêm',
                      style: TextStyle(
                        color: widget.isPartnership ? Colors.purple : AppMainColors.primary,
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
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.circle, 
                      size: 8, 
                      color: widget.isPartnership ? Colors.purple : AppMainColors.primary
                    ),
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
              backgroundColor: widget.isPartnership ? Colors.purple : AppMainColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }
}

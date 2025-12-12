import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/models/profile_model.dart';
import '../../core/repositories/auth_repository.dart';
import '../../core/services/cv_supabase_service.dart';
import '../../core/enums/job_fields.dart';
import '../../core/enums/employment_types.dart';

class EditProfileScreen extends StatefulWidget {
  final Profile profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authRepo = AuthRepository();
  final _cvService = CVSupabaseService();
  final _picker = ImagePicker();

  // Controllers
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _workLocationsController;
  late TextEditingController _bioController;

  // State variables
  File? _avatarFile;
  DateTime? _dateOfBirth;
  String? _education;
  List<String> _interestedFields = [];
  List<String> _workTypes = [];
  List<String> _selectedCvIds = [];
  List<Map<String, dynamic>> _experience = [];
  bool _security = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _myCVs = [];
  
  // Tags
  List<String> _tags = [];
  final _tagController = TextEditingController();

  // Predefined lists
  final List<String> _educationOptions = [
    'Trung học phổ thông',
    'Cao đẳng',
    'Đại học',
    'Thạc sĩ',
    'Tiến sĩ',
    'Khác'
  ];

  final List<String> _fieldOptions = JobField.valuesList;

  final List<String> _workTypeOptions = EmploymentType.valuesList;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadMyCVs();
  }

  void _initializeData() {
    final p = widget.profile;
    _fullNameController = TextEditingController(text: p.fullName);
    _phoneController = TextEditingController(text: p.phone);
    _addressController = TextEditingController(text: p.address);
    _workLocationsController = TextEditingController(text: p.workLocations.join(', '));
    _bioController = TextEditingController(text: p.bio);

    _dateOfBirth = p.dateOfBirth;
    
    // Validate education value against options
    if (p.education != null && _educationOptions.contains(p.education)) {
      _education = p.education;
    } else {
      _education = null; // Reset if invalid or not in options
    }

    _interestedFields = List.from(p.interestedFields);
    _workTypes = List.from(p.workTypes);
    _selectedCvIds = List.from(p.cvIds);
    _experience = List.from(p.experience);
    _security = p.security;
    
    if (p.metadata['tags'] != null) {
      _tags = List<String>.from(p.metadata['tags']);
    }
  }

  Future<void> _loadMyCVs() async {
    try {
      final cvs = await _cvService.getMyCVs();
      setState(() {
        _myCVs = cvs;
      });
    } catch (e) {
      debugPrint('Error loading CVs: $e');
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _workLocationsController.dispose();
    _bioController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      print('Opening image picker...');
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      print('Image picker result: ${pickedFile?.path}');
      
      if (pickedFile != null) {
        setState(() {
          _avatarFile = File(pickedFile.path);
        });
      }
    } catch (e, stackTrace) {
      print('Error picking image: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Lỗi chọn ảnh'),
            content: SingleChildScrollView(
              child: SelectableText('Lỗi: $e\n\nStack trace:\n$stackTrace'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
              TextButton(
                onPressed: () {
                  // Copy to clipboard logic could go here
                },
                child: const Text('Sao chép'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? avatarUrl = widget.profile.avatarUrl;

      // Upload new avatar if selected
      if (_avatarFile != null) {
        avatarUrl = await _authRepo.uploadAvatar(_avatarFile!, widget.profile.id);
      }

      // Prepare metadata
      final metadata = {
        'date_of_birth': _dateOfBirth?.toIso8601String(),
        'address': _addressController.text.trim(),
        'work_locations': _workLocationsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'education': _education,
        'bio': _bioController.text.trim(),
        'interested_fields': _interestedFields,
        'work_types': _workTypes,
        'cv_ids': _selectedCvIds,
        'experience': _experience,
        'security': _security,
        'tags': _tags,
      };

      final result = await _authRepo.updateProfile(
        userId: widget.profile.id,
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        avatarUrl: avatarUrl,
        metadata: metadata,
      );

      if (result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật hồ sơ thành công!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true); // Return true to indicate update
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message ?? 'Có lỗi xảy ra'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xảy ra lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Chỉnh sửa hồ sơ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Lưu',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAvatarSection(),
                      const SizedBox(height: 30),
                      
                      _buildSectionCard(
                        title: 'Thông tin cơ bản',
                        children: [
                          _buildTextField('Họ và tên', _fullNameController, validator: (v) => v?.isEmpty == true ? 'Vui lòng nhập họ tên' : null),
                          _buildDatePicker('Ngày sinh', _dateOfBirth, (date) => setState(() => _dateOfBirth = date)),
                          _buildTextField('Số điện thoại', _phoneController, keyboardType: TextInputType.phone),
                          _buildTextField('Địa chỉ', _addressController),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      _buildSectionCard(
                        title: 'Thông tin nghề nghiệp',
                        children: [
                          _buildDropdown('Trình độ học vấn', _education, _educationOptions, (v) => setState(() => _education = v)),
                          _buildTextField('Nơi có thể làm việc', _workLocationsController, hint: 'VD: Hà Nội, TP.HCM'),
                          _buildMultiSelectDialogField(
                            title: 'Lĩnh vực quan tâm',
                            items: _interestedFields,
                            options: _fieldOptions,
                            onChanged: (val) => setState(() => _interestedFields = val),
                          ),
                          _buildMultiSelect('Hình thức làm việc', _workTypeOptions, _workTypes),
                          _buildTagsSection(),
                          _buildTextField('Giới thiệu bản thân (Bio)', _bioController, maxLines: 4),
                        ],
                      ),

                      const SizedBox(height: 20),
                      _buildSectionCard(
                        title: 'Kinh nghiệm làm việc',
                        children: [
                          _buildExperienceList(),
                        ],
                      ),

                      const SizedBox(height: 20),
                      _buildSectionCard(
                        title: 'Hồ sơ đính kèm (CV)',
                        children: [
                          _buildCVSelector(),
                        ],
                      ),

                      const SizedBox(height: 20),
                      _buildSectionCard(
                        title: 'Bảo mật',
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Cho phép tìm kiếm', style: TextStyle(fontWeight: FontWeight.w500)),
                            subtitle: const Text('Hồ sơ của bạn sẽ hiển thị với nhà tuyển dụng'),
                            value: _security,
                            activeThumbColor: Colors.blue,
                            onChanged: (v) => setState(() => _security = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thẻ từ khóa (Tags)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700])),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagController,
                  decoration: InputDecoration(
                    hintText: 'VD: Flutter, Dart...',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  if (_tagController.text.isNotEmpty) {
                    setState(() {
                      _tags.add(_tagController.text.trim());
                      _tagController.clear();
                    });
                  }
                },
                icon: const Icon(Icons.add_circle, color: Colors.blue, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) => Chip(
              label: Text(tag),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() {
                  _tags.remove(tag);
                });
              },
              backgroundColor: Colors.blue.withOpacity(0.1),
              labelStyle: const TextStyle(color: Colors.blue),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[200],
              backgroundImage: _avatarFile != null
                  ? FileImage(_avatarFile!)
                  : (widget.profile.avatarUrl != null
                      ? NetworkImage(widget.profile.avatarUrl!)
                      : null) as ImageProvider?,
              child: (_avatarFile == null && widget.profile.avatarUrl == null)
                  ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700])),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? selectedDate, Function(DateTime) onSelect) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700])),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime(2000),
                firstDate: DateTime(1950),
                lastDate: DateTime.now(),
              );
              if (date != null) onSelect(date);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Text(
                    selectedDate != null ? DateFormat('dd/MM/yyyy').format(selectedDate) : 'Chọn ngày',
                    style: TextStyle(
                      fontSize: 16,
                      color: selectedDate != null ? Colors.black87 : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> options, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700])),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: value,
            icon: const Icon(Icons.keyboard_arrow_down),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildMultiSelect(String label, List<String> options, List<String> selectedValues) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700])),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final isSelected = selectedValues.contains(option);
              return FilterChip(
                label: Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? Colors.blue : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                selectedColor: Colors.blue.withOpacity(0.1),
                backgroundColor: Colors.grey[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? Colors.blue : Colors.grey[300]!,
                  ),
                ),
                showCheckmark: false,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      selectedValues.add(option);
                    } else {
                      selectedValues.remove(option);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiSelectDialogField({
    required String title,
    required List<String> items,
    required List<String> options,
    required Function(List<String>) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700])),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _showMultiSelectDialog(title, items, options, onChanged),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      items.isEmpty ? 'Chọn $title' : items.join(', '),
                      style: TextStyle(
                        color: items.isEmpty ? Colors.grey[400] : Colors.black87,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
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
                      activeColor: Colors.blue,
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
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
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

  Widget _buildExperienceList() {
    return Column(
      children: [
        ..._experience.asMap().entries.map((entry) {
          final index = entry.key;
          final exp = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        exp['company'] ?? 'Công ty',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () => setState(() => _experience.removeAt(index)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(exp['position'] ?? 'Vị trí', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(exp['date'] ?? 'Thời gian', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                if (exp['description'] != null && exp['description'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(exp['description'], style: TextStyle(color: Colors.grey[800], height: 1.4)),
                ],
              ],
            ),
          );
        }),
        
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showAddExperienceDialog,
            icon: const Icon(Icons.add),
            label: const Text('Thêm kinh nghiệm'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: const BorderSide(color: Colors.blue),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddExperienceDialog() {
    final companyCtrl = TextEditingController();
    final positionCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm kinh nghiệm'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: companyCtrl, decoration: const InputDecoration(labelText: 'Công ty', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: positionCtrl, decoration: const InputDecoration(labelText: 'Vị trí', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Thời gian', hintText: 'VD: 01/2022 - Hiện tại', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Mô tả', hintText: 'Gạch đầu dòng công việc...', border: OutlineInputBorder()), maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              if (companyCtrl.text.isNotEmpty) {
                setState(() {
                  _experience.add({
                    'company': companyCtrl.text,
                    'position': positionCtrl.text,
                    'date': dateCtrl.text,
                    'description': descCtrl.text,
                  });
                });
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  Widget _buildCVSelector() {
    if (_myCVs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 12),
            const Expanded(child: Text('Bạn chưa có CV nào. Hãy tạo CV trước.', style: TextStyle(color: Colors.orange))),
          ],
        ),
      );
    }
    return Column(
      children: _myCVs.map((cv) {
        final id = cv['id'].toString();
        final title = cv['title'] ?? 'Untitled CV';
        final isSelected = _selectedCvIds.contains(id);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withOpacity(0.05) : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey[200]!,
            ),
          ),
          child: CheckboxListTile(
            title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            subtitle: Text(cv['mcv'] ?? 'CV Template', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            value: isSelected,
            activeColor: Colors.blue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _selectedCvIds.add(id);
                } else {
                  _selectedCvIds.remove(id);
                }
              });
            },
          ),
        );
      }).toList(),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/profile_model.dart';
import '../../core/repositories/auth_repository.dart';
import '../../core/theme/app_main_colors.dart';
import '../../core/enums/job_fields.dart';
import '../../widgets/speech_text_field.dart';

class EditCompanyProfileScreen extends StatefulWidget {
  const EditCompanyProfileScreen({super.key});

  @override
  State<EditCompanyProfileScreen> createState() => _EditCompanyProfileScreenState();
}

class _EditCompanyProfileScreenState extends State<EditCompanyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authRepository = AuthRepository();
  final _imagePicker = ImagePicker();

  bool _isLoading = false;
  Profile? _profile;
  File? _newAvatarFile;

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _sizeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _websiteController = TextEditingController();
  final _facebookController = TextEditingController();
  final _linkedinController = TextEditingController();
  
  // Fields & Tags
  List<String> _fields = [];
  final _tagController = TextEditingController();
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _authRepository.getCurrentUserProfile();
      if (profile != null) {
        _profile = profile;
        _nameController.text = profile.metadata['company_name'] ?? profile.fullName ?? '';
        _phoneController.text = profile.phone ?? '';
        _sizeController.text = profile.metadata['company_size'] ?? '';
        _descriptionController.text = profile.metadata['description'] ?? '';
        _addressController.text = profile.metadata['address'] ?? '';
        _websiteController.text = profile.metadata['website'] ?? '';
        _facebookController.text = profile.metadata['facebook'] ?? '';
        _linkedinController.text = profile.metadata['linkedin'] ?? '';
        
        if (profile.metadata['fields'] != null) {
          _fields = List<String>.from(profile.metadata['fields']);
        }
        if (profile.metadata['tags'] != null) {
          _tags = List<String>.from(profile.metadata['tags']);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải thông tin: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _newAvatarFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chọn ảnh: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_profile == null) return;

    setState(() => _isLoading = true);

    try {
      String? avatarUrl = _profile!.avatarUrl;

      // Upload new avatar if selected
      if (_newAvatarFile != null) {
        avatarUrl = await _authRepository.uploadAvatar(_newAvatarFile!, _profile!.id);
      }

      // Prepare metadata
      final metadata = Map<String, dynamic>.from(_profile!.metadata);
      metadata['company_name'] = _nameController.text.trim();
      metadata['company_size'] = _sizeController.text.trim();
      metadata['description'] = _descriptionController.text.trim();
      metadata['address'] = _addressController.text.trim();
      metadata['website'] = _websiteController.text.trim();
      metadata['facebook'] = _facebookController.text.trim();
      metadata['linkedin'] = _linkedinController.text.trim();
      metadata['fields'] = _fields;
      metadata['tags'] = _tags;

      // Update profile
      final result = await _authRepository.updateProfile(
        userId: _profile!.id,
        fullName: _nameController.text.trim(), // Sync company name to full_name
        phone: _phoneController.text.trim(),
        avatarUrl: avatarUrl,
        metadata: metadata,
      );

      if (result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật thành công!')),
          );
          Navigator.pop(context, true); // Return true to refresh previous screen
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message ?? 'Cập nhật thất bại')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openMap() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;

    final query = Uri.encodeComponent(address);
    final googleUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');

    if (await canLaunchUrl(googleUrl)) {
      await launchUrl(googleUrl);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở bản đồ')),
        );
      }
    }
  }

  void _shareCompany() {
    final name = _nameController.text;
    final desc = _descriptionController.text;
    final website = _websiteController.text;
    
    String content = 'Công ty: $name\n';
    if (desc.isNotEmpty) content += '$desc\n';
    if (website.isNotEmpty) content += 'Website: $website\n';
    
    Share.share(content, subject: 'Thông tin công ty $name');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin công ty'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareCompany,
          ),
        ],
      ),
      body: _isLoading && _profile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar Section
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(16),
                              image: _newAvatarFile != null
                                  ? DecorationImage(
                                      image: FileImage(_newAvatarFile!),
                                      fit: BoxFit.cover,
                                    )
                                  : (_profile?.avatarUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(_profile!.avatarUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : null),
                            ),
                            child: (_newAvatarFile == null && _profile?.avatarUrl == null)
                                ? const Icon(Icons.business, size: 50, color: Colors.grey)
                                : null,
                          ),
                          Positioned(
                            bottom: -4,
                            right: -4,
                            child: IconButton(
                              onPressed: _pickImage,
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppMainColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildSectionTitle('Thông tin cơ bản'),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Tên công ty',
                      icon: Icons.business,
                      validator: (v) => v?.isEmpty == true ? 'Vui lòng nhập tên công ty' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Số điện thoại',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _sizeController,
                      label: 'Quy mô công ty (số nhân viên)',
                      icon: Icons.people,
                      hint: 'Ví dụ: 50-100 nhân viên',
                    ),

                    const SizedBox(height: 24),
                    _buildMultiSelectField(
                      title: 'Lĩnh vực hoạt động',
                      items: _fields,
                      options: JobField.valuesList,
                      onChanged: (val) => setState(() => _fields = val),
                    ),

                    const SizedBox(height: 24),
                    _buildSectionTitle('Thẻ từ khóa (Tags)'),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _tagController,
                            label: 'Thêm thẻ',
                            icon: Icons.tag,
                            hint: 'Ví dụ: Startup, Product...',
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
                          icon: const Icon(Icons.add_circle, color: AppMainColors.primary, size: 32),
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
                        backgroundColor: AppMainColors.primary.withOpacity(0.1),
                        labelStyle: const TextStyle(color: AppMainColors.primary),
                      )).toList(),
                    ),

                    const SizedBox(height: 24),
                    _buildSectionTitle('Giới thiệu'),
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Mô tả công ty',
                      icon: Icons.description,
                      maxLines: 4,
                    ),

                    const SizedBox(height: 24),
                    _buildSectionTitle('Địa chỉ'),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _addressController,
                            label: 'Địa chỉ trụ sở',
                            icon: Icons.location_on,
                            maxLines: 2,
                          ),
                        ),
                        IconButton(
                          onPressed: _openMap,
                          icon: const Icon(Icons.map, color: AppMainColors.primary),
                          tooltip: 'Xem trên bản đồ',
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    _buildSectionTitle('Liên kết & Mạng xã hội'),
                    _buildTextField(
                      controller: _websiteController,
                      label: 'Website',
                      icon: Icons.language,
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _facebookController,
                      label: 'Facebook',
                      icon: Icons.facebook,
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _linkedinController,
                      label: 'LinkedIn',
                      icon: Icons.work, // Using work icon as LinkedIn alternative
                      keyboardType: TextInputType.url,
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppMainColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Lưu thay đổi',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return SpeechTextField(
      controller: controller,
      label: label,
      hint: hint,
      prefixIcon: icon,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
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
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
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
                selectedColor: AppMainColors.primary.withOpacity(0.15),
                checkmarkColor: AppMainColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? AppMainColors.primary : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
                backgroundColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppMainColors.primary.withOpacity(0.5) : Colors.transparent,
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
}

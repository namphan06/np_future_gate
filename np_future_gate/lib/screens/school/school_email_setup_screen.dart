import 'package:flutter/material.dart';
import 'package:np_future_gate/core/services/supabase_service.dart';
import 'package:np_future_gate/core/theme/app_main_colors.dart';

class SchoolEmailSetupScreen extends StatefulWidget {
  const SchoolEmailSetupScreen({super.key});

  @override
  State<SchoolEmailSetupScreen> createState() => _SchoolEmailSetupScreenState();
}

class _SchoolEmailSetupScreenState extends State<SchoolEmailSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _currentSchoolEmail;
  bool? _isVerified;
  String? _accountEmailDomain;

  @override
  void initState() {
    super.initState();
    _loadCurrentEmail();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentEmail() async {
    setState(() => _isLoading = true);
    try {
      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      final userEmail = SupabaseService.instance.client.auth.currentUser?.email;
      
      if (userId == null || userEmail == null) return;

      // Extract domain from account email
      _accountEmailDomain = '@${userEmail.split('@').last}';

      // Load profile metadata
      final response = await SupabaseService.instance.client
          .from('profiles')
          .select('metadata')
          .eq('id', userId)
          .single();

      final metadata = response['metadata'] as Map<String, dynamic>? ?? {};
      _currentSchoolEmail = metadata['school_email'];
      _isVerified = metadata['school_email_verified'] == true;

      if (_currentSchoolEmail != null) {
        _emailController.text = _currentSchoolEmail!;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải thông tin: $e')),
        );
      }
    }
  }

  Future<void> _saveEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      final schoolEmail = _emailController.text.trim();

      // Load current metadata
      final currentData = await SupabaseService.instance.client
          .from('profiles')
          .select('metadata')
          .eq('id', userId)
          .single();

      final metadata = Map<String, dynamic>.from(currentData['metadata'] as Map<String, dynamic>? ?? {});
      
      // Update school email and reset verification status
      metadata['school_email'] = schoolEmail;
      metadata['school_email_verified'] = false;

      // Save to profiles
      await SupabaseService.instance.client
          .from('profiles')
          .update({'metadata': metadata})
          .eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu email trường. Vui lòng chờ admin xác nhận.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi lưu email: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập đuôi email';
    }

    final domain = value.trim();
    
    // Check must start with @
    if (!domain.startsWith('@')) {
      return 'Đuôi email phải bắt đầu bằng @';
    }

    // Check format: @something.domain
    final domainRegex = RegExp(r'^@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!domainRegex.hasMatch(domain)) {
      return 'Đuôi email không đúng định dạng (VD: @school.edu.vn)';
    }

    // Check domain matches account email
    if (_accountEmailDomain != null && domain != _accountEmailDomain) {
      return 'Đuôi email phải trùng với email tài khoản: $_accountEmailDomain';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Email trường học'),
        backgroundColor: AppMainColors.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppMainColors.primary.withValues(alpha: 0.1),
                            AppMainColors.primary.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppMainColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppMainColors.primary,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Quan trọng',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Nhập đuôi email từ "@" (ví dụ: $_accountEmailDomain)',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Current Status
                    if (_currentSchoolEmail != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Email hiện tại',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _currentSchoolEmail!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isVerified == true
                                        ? Colors.green.withValues(alpha: 0.1)
                                        : Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _isVerified == true
                                            ? Icons.check_circle
                                            : Icons.pending,
                                        size: 16,
                                        color: _isVerified == true
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _isVerified == true
                                            ? 'Đã xác nhận'
                                            : 'Chờ xác nhận',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _isVerified == true
                                              ? Colors.green
                                              : Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Email Input
                    const Text(
                      'Đuôi email trường học',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: _accountEmailDomain ?? '@example.edu.vn',
                        prefixIcon: const Icon(Icons.alternate_email),
                        helperText: 'Nhập từ @ (VD: @school.edu.vn)',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppMainColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: _validateEmail,
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppMainColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Lưu email',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Note
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            color: Colors.amber,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Lưu ý',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '• Đuôi email này sẽ được hiển thị trên tin tuyển dụng liên kết\n'
                                  '• Cần được admin xác nhận trước khi sử dụng\n'
                                  '• Bạn có thể thay đổi đuôi email nhưng cần xác nhận lại',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

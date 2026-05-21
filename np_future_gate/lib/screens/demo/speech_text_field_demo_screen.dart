import 'package:flutter/material.dart';
import 'package:np_future_gate/widgets/speech_text_field.dart';

/// Demo screen to showcase SpeechTextField functionality
class SpeechTextFieldDemoScreen extends StatefulWidget {
  const SpeechTextFieldDemoScreen({super.key});

  @override
  State<SpeechTextFieldDemoScreen> createState() => _SpeechTextFieldDemoScreenState();
}

class _SpeechTextFieldDemoScreenState extends State<SpeechTextFieldDemoScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('✅ Thành công'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tên: ${_nameController.text}'),
              Text('Email: ${_emailController.text}'),
              Text('SĐT: ${_phoneController.text}'),
              Text('Mô tả: ${_descriptionController.text}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('🎤 Demo Speech-to-Text'),
        backgroundColor: Colors.blue[700],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[400]!, Colors.blue[600]!],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.mic, size: 48, color: Colors.white),
                      const SizedBox(height: 12),
                      const Text(
                        'Nhấn vào icon mic 🎤 để nói',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nói đến đâu hiển thị đến đó!\nCó thể dừng và tiếp tục bất cứ lúc nào.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Form Fields
                SpeechTextField(
                  controller: _nameController,
                  label: '👤 Họ và tên',
                  hint: 'Nhập hoặc nói tên của bạn',
                  prefixIcon: Icons.person,
                  validator: (v) => v?.isEmpty ?? true ? 'Vui lòng nhập họ tên' : null,
                  textCapitalization: TextCapitalization.words,
                ),

                const SizedBox(height: 20),

                SpeechTextField(
                  controller: _emailController,
                  label: '📧 Email',
                  hint: 'example@gmail.com',
                  prefixIcon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  textCapitalization: TextCapitalization.none,
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Vui lòng nhập email';
                    if (!v!.contains('@')) return 'Email không hợp lệ';
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                SpeechTextField(
                  controller: _phoneController,
                  label: '📱 Số điện thoại',
                  hint: '09xxxxxxxx',
                  prefixIcon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Vui lòng nhập SĐT';
                    if (v!.length < 10) return 'SĐT phải có ít nhất 10 số';
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                SpeechTextField(
                  controller: _descriptionController,
                  label: '📝 Mô tả về bạn',
                  hint: 'Nói về bản thân, kinh nghiệm, kỹ năng...',
                  prefixIcon: Icons.description,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                ),

                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _submitForm,
                    icon: const Icon(Icons.check_circle, size: 24),
                    label: const Text(
                      'Xem kết quả',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Tips Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.amber[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Mẹo sử dụng',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[900],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTip('1. Nói rõ ràng và không quá nhanh'),
                      _buildTip('2. Đặt con trỏ vào vị trí muốn chèn text'),
                      _buildTip('3. Nhấn mic, nói, sau đó nhấn Dừng'),
                      _buildTip('4. Có thể tiếp tục nói thêm bất cứ lúc nào'),
                      _buildTip('5. Hỗ trợ cả tiếng Việt và tiếng Anh'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Colors.amber[900], fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.amber[900], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

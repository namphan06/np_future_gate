Bước 1: Thêm thư viện vào dự án
Thêm các dòng sau vào file pubspec.yaml trong phần dependencies:

text
image_picker: ^1.0.7
google_mlkit_text_recognition: ^0.13.0
path_provider: ^2.1.3
Sau đó chạy flutter pub get

Bước 2: Cấu hình quyền cho thiết bị
Android - mở file android/app/src/main/AndroidManifest.xml và thêm:

text
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
iOS - mở file ios/Runner/Info.plist và thêm:

text
<key>NSCameraUsageDescription</key>
<string>Ứng dụng cần camera để quét văn bản</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Ứng dụng cần thư viện ảnh để chọn ảnh có chữ</string>
Bước 3: Code theo trình tự các chức năng
Trong file Dart chính (thường là main.dart hoặc màn hình bạn muốn), viết các hàm theo thứ tự:

Hàm chọn ảnh - dùng image_picker để mở camera hoặc thư viện, nhận về đối tượng File ảnh

Hàm xử lý OCR - tạo TextRecognizer, gọi processImage() với ảnh từ bước 1, nhận về đối tượng RecognizedText

Hàm lấy text - gọi .text từ kết quả ở bước 2 để lấy chuỗi văn bản thuần (không còn ảnh)

Hàm ghi file - dùng getApplicationDocumentsDirectory() để lấy đường dẫn, tạo file .md và ghi chuỗi text vào

Hàm hiển thị - tạo giao diện có nút bấm để gọi lần lượt các hàm trên

Bước 4: Build và chạy thử
Chạy lệnh trong terminal:

text
flutter build apk --release
File APK nằm ở build/app/outputs/flutter-apk/app-release.apk. Cài lên điện thoại và test.

🔄 Luồng hoạt động sau khi cài đặt
Mở app → bấm nút Chọn ảnh → chọn ảnh có chữ từ thư viện hoặc chụp mới

Bấm nút Chuyển sang .md → app tự động đọc chữ trong ảnh

App tạo file .md lưu trong bộ nhớ thiết bị

Nội dung file chỉ chứa văn bản đã đọc, không có hình ảnh

main.dart:

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scan Text',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ScanTextScreen(),
    );
  }
}

class ScanTextScreen extends StatefulWidget {
  const ScanTextScreen({super.key});

  @override
  State<ScanTextScreen> createState() => _ScanTextScreenState();
}

class _ScanTextScreenState extends State<ScanTextScreen> {
  File? _selectedImage;
  String _extractedText = '';
  bool _isProcessing = false;
  String _savedFilePath = '';

  final ImagePicker _picker = ImagePicker();

  /// Hàm chọn ảnh từ camera hoặc thư viện
  Future<File?> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  /// Hàm xử lý OCR - nhận diện văn bản từ ảnh
  Future<RecognizedText> _processOCR(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer();
    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);
    await textRecognizer.close();
    return recognizedText;
  }

  /// Hàm lấy text thuần từ kết quả OCR
  String _getTextFromResult(RecognizedText recognizedText) {
    return recognizedText.text;
  }

  /// Hàm ghi file .md
  Future<String> _saveToMarkdownFile(String text) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/extracted_content.md');
    await file.writeAsString(text);
    return file.path;
  }

  /// Xử lý chọn ảnh và hiển thị
  Future<void> _handlePickImage(ImageSource source) async {
    final image = await _pickImage(source);
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _extractedText = '';
        _savedFilePath = '';
      });
    }
  }

  /// Xử lý chuyển đổi ảnh sang .md
  Future<void> _handleConvertToMarkdown() async {
    if (_selectedImage == null) {
      _showSnackBar('Vui lòng chọn ảnh trước');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Bước 1: Xử lý OCR
      final recognizedText = await _processOCR(_selectedImage!);

      // Bước 2: Lấy text thuần
      final text = _getTextFromResult(recognizedText);

      if (text.isEmpty) {
        _showSnackBar('Không tìm thấy văn bản trong ảnh');
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Bước 3: Ghi file .md
      final filePath = await _saveToMarkdownFile(text);

      setState(() {
        _extractedText = text;
        _savedFilePath = filePath;
        _isProcessing = false;
      });

      _showSnackBar('Đã lưu file thành công!');
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showSnackBar('Lỗi: $e');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Hiển thị dialog chọn nguồn ảnh
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh'),
              onTap: () {
                Navigator.pop(context);
                _handlePickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(context);
                _handlePickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Text'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Nút chọn ảnh
            ElevatedButton.icon(
              onPressed: _showImageSourceDialog,
              icon: const Icon(Icons.image),
              label: const Text('Chọn ảnh'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),

            const SizedBox(height: 16),

            // Hiển thị ảnh đã chọn
            if (_selectedImage != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  height: 250,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Nút chuyển sang .md
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _handleConvertToMarkdown,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.text_snippet),
              label: Text(
                  _isProcessing ? 'Đang xử lý...' : 'Chuyển sang .md'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            // Hiển thị đường dẫn file đã lưu
            if (_savedFilePath.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '✅ File đã lưu tại:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _savedFilePath,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Hiển thị văn bản đã trích xuất
            if (_extractedText.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📄 Văn bản trích xuất:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(_extractedText),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

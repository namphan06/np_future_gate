import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdfx/pdfx.dart';
import 'package:path_provider/path_provider.dart';

/// Service sử dụng Google ML Kit để nhận diện văn bản từ ảnh/PDF CV (on-device)
/// Hỗ trợ cả ảnh (JPG, PNG) và PDF (render từng trang thành ảnh rồi OCR)
class MLKitOcrService {
  static final MLKitOcrService _instance = MLKitOcrService._internal();
  factory MLKitOcrService() => _instance;
  MLKitOcrService._internal();

  final ImagePicker _picker = ImagePicker();

  /// Trích xuất text từ file ảnh (File object)
  Future<MLKitOcrResult> extractTextFromFile(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        return MLKitOcrResult.failure('File không tồn tại');
      }

      final inputImage = InputImage.fromFile(imageFile);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

      try {
        final RecognizedText recognizedText =
            await textRecognizer.processImage(inputImage);

        if (recognizedText.text.isEmpty) {
          return MLKitOcrResult.failure('Không tìm thấy văn bản trong ảnh');
        }

        return MLKitOcrResult(
          success: true,
          text: recognizedText.text,
          blocks: recognizedText.blocks
              .map((block) => TextBlockInfo(
                    text: block.text,
                    confidence: block.lines.isNotEmpty
                        ? block.lines
                                .map((l) => l.confidence ?? 0.0)
                                .reduce((a, b) => a + b) /
                            block.lines.length
                        : 0.0,
                  ))
              .toList(),
        );
      } finally {
        await textRecognizer.close();
      }
    } catch (e) {
      debugPrint('❌ MLKit OCR Error: $e');
      return MLKitOcrResult.failure('Lỗi nhận diện văn bản: $e');
    }
  }

  /// Trích xuất text từ file PDF (render từng trang thành ảnh → ML Kit OCR)
  Future<MLKitOcrResult> extractTextFromPdf(File pdfFile) async {
    try {
      if (!await pdfFile.exists()) {
        return MLKitOcrResult.failure('File PDF không tồn tại');
      }

      debugPrint('📄 Opening PDF for OCR: ${pdfFile.path}');
      final document = await PdfDocument.openFile(pdfFile.path);
      final pageCount = document.pagesCount;
      debugPrint('📄 PDF has $pageCount pages');

      final StringBuffer combinedText = StringBuffer();
      final List<TextBlockInfo> allBlocks = [];
      final tempDir = await getTemporaryDirectory();

      for (int i = 1; i <= pageCount; i++) {
        try {
          debugPrint('📄 Processing page $i/$pageCount...');
          final page = await document.getPage(i);
          
          // Render page to image (300 DPI for good OCR quality)
          final pageImage = await page.render(
            width: page.width * 2,
            height: page.height * 2,
            format: PdfPageImageFormat.png,
          );
          await page.close();

          if (pageImage == null) {
            debugPrint('⚠️ Could not render page $i');
            continue;
          }

          // Save rendered image to temp file
          final tempImageFile = File(
              '${tempDir.path}/pdf_page_${i}_${DateTime.now().millisecondsSinceEpoch}.png');
          await tempImageFile.writeAsBytes(pageImage.bytes);

          // OCR the rendered page image
          final result = await extractTextFromFile(tempImageFile);

          // Cleanup temp image
          if (await tempImageFile.exists()) {
            await tempImageFile.delete();
          }

          if (result.success && result.text.isNotEmpty) {
            if (combinedText.isNotEmpty) {
              combinedText.write('\n\n--- Trang $i ---\n\n');
            }
            combinedText.write(result.text);
            allBlocks.addAll(result.blocks);
          }
        } catch (e) {
          debugPrint('⚠️ Error processing page $i: $e');
        }
      }

      await document.close();

      if (combinedText.isEmpty) {
        return MLKitOcrResult.failure(
            'Không trích xuất được văn bản từ PDF ($pageCount trang)');
      }

      debugPrint('✅ PDF OCR complete: ${combinedText.length} chars from $pageCount pages');

      return MLKitOcrResult(
        success: true,
        text: combinedText.toString(),
        blocks: allBlocks,
        pageCount: pageCount,
      );
    } catch (e) {
      debugPrint('❌ PDF OCR Error: $e');
      return MLKitOcrResult.failure('Lỗi xử lý PDF: $e');
    }
  }

  /// Trích xuất text từ URL (tự động phát hiện ảnh hoặc PDF)
  Future<MLKitOcrResult> extractTextFromUrl(String fileUrl) async {
    try {
      debugPrint('📥 Downloading file from: $fileUrl');

      final response =
          await HttpClient().getUrl(Uri.parse(fileUrl)).then((req) => req.close());

      if (response.statusCode != 200) {
        return MLKitOcrResult.failure('Không thể tải file (HTTP ${response.statusCode})');
      }

      final bytes = await consolidateHttpClientResponseBytes(response);
      final tempDir = await getTemporaryDirectory();

      // Detect file type from URL
      final lowerUrl = fileUrl.toLowerCase();
      final isPdf = lowerUrl.endsWith('.pdf');
      final extension = isPdf ? 'pdf' : 'jpg';

      final tempFile = File(
          '${tempDir.path}/mlkit_ocr_${DateTime.now().millisecondsSinceEpoch}.$extension');
      await tempFile.writeAsBytes(bytes);

      try {
        if (isPdf) {
          debugPrint('📄 Detected PDF file, using PDF→Image→OCR pipeline...');
          return await extractTextFromPdf(tempFile);
        } else {
          debugPrint('🖼️ Detected image file, using direct OCR...');
          return await extractTextFromFile(tempFile);
        }
      } finally {
        // Cleanup temp file
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
    } catch (e) {
      debugPrint('❌ MLKit OCR URL Error: $e');
      return MLKitOcrResult.failure('Lỗi tải và xử lý file: $e');
    }
  }

  /// Chọn ảnh từ camera và trích xuất text
  Future<MLKitOcrResult> pickAndExtractFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );

      if (pickedFile == null) {
        return MLKitOcrResult.failure('Không có ảnh được chọn');
      }

      return await extractTextFromFile(File(pickedFile.path));
    } catch (e) {
      return MLKitOcrResult.failure('Lỗi chụp ảnh: $e');
    }
  }

  /// Chọn ảnh từ thư viện và trích xuất text
  Future<MLKitOcrResult> pickAndExtractFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (pickedFile == null) {
        return MLKitOcrResult.failure('Không có ảnh được chọn');
      }

      return await extractTextFromFile(File(pickedFile.path));
    } catch (e) {
      return MLKitOcrResult.failure('Lỗi chọn ảnh: $e');
    }
  }

  /// Chọn nhiều ảnh từ thư viện và trích xuất text (cho CV nhiều trang)
  Future<MLKitOcrResult> pickMultipleAndExtract() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 90,
      );

      if (pickedFiles.isEmpty) {
        return MLKitOcrResult.failure('Không có ảnh được chọn');
      }

      final StringBuffer combinedText = StringBuffer();
      final List<TextBlockInfo> allBlocks = [];

      for (int i = 0; i < pickedFiles.length; i++) {
        final result = await extractTextFromFile(File(pickedFiles[i].path));
        if (result.success) {
          if (combinedText.isNotEmpty) {
            combinedText.write('\n\n--- Trang ${i + 1} ---\n\n');
          }
          combinedText.write(result.text);
          allBlocks.addAll(result.blocks);
        }
      }

      if (combinedText.isEmpty) {
        return MLKitOcrResult.failure(
            'Không trích xuất được văn bản từ các ảnh đã chọn');
      }

      return MLKitOcrResult(
        success: true,
        text: combinedText.toString(),
        blocks: allBlocks,
        pageCount: pickedFiles.length,
      );
    } catch (e) {
      return MLKitOcrResult.failure('Lỗi xử lý nhiều ảnh: $e');
    }
  }
}

/// Kết quả OCR từ ML Kit
class MLKitOcrResult {
  final bool success;
  final String text;
  final String? error;
  final List<TextBlockInfo> blocks;
  final int pageCount;

  MLKitOcrResult({
    required this.success,
    this.text = '',
    this.error,
    this.blocks = const [],
    this.pageCount = 1,
  });

  factory MLKitOcrResult.failure(String error) {
    return MLKitOcrResult(
      success: false,
      error: error,
    );
  }
}

/// Thông tin một block text được nhận diện
class TextBlockInfo {
  final String text;
  final double confidence;

  TextBlockInfo({
    required this.text,
    this.confidence = 0.0,
  });
}

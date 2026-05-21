import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// A beautiful TextField widget with integrated speech-to-text functionality
/// Features:
/// - Real-time voice transcription
/// - Pause and resume
/// - Insert at cursor position
/// - Beautiful animated mic button
/// - Error handling
class SpeechTextField extends StatefulWidget {

  const SpeechTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.enabled = true,
    this.textCapitalization = TextCapitalization.sentences,
    this.focusNode,
    this.onChanged,
    this.decoration,
    this.obscureText = false,
    this.textInputAction,
    this.onEditingComplete,
    this.onSubmitted,
    this.suffixIcon,
  });
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool enabled;
  final TextCapitalization textCapitalization;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final InputDecoration? decoration;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;

  @override
  State<SpeechTextField> createState() => _SpeechTextFieldState();
}

class _SpeechTextFieldState extends State<SpeechTextField> with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;
  String _currentWords = '';
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  int _speechStartPosition = 0;
  String _lastRecognizedWords = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onError: (error) {
          debugPrint('Speech error: $error');
          setState(() => _isListening = false);
          if (error.errorMsg.contains('recognizerNotAvailable')) {
            _showError(
              'Nhận diện giọng nói không khả dụng.\n\n'
              'Vui lòng:\n'
              '1. Cài đặt Google App\n'
              '2. Bật quyền Microphone\n'
              '3. Kết nối Internet'
            );
          } else {
            _showError('Lỗi nhận diện: ${error.errorMsg}');
          }
        },
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
      );
      setState(() {});
    } catch (e) {
      debugPrint('Speech init error: $e');
      setState(() => _speechAvailable = false);
      // if (e.toString().contains('recognizerNotAvailable')) {
      //   _showError(
      //     'Thiết bị không hỗ trợ nhận diện giọng nói.\n\n'
      //     'Giải pháp:\n'
      //     '• Cài đặt/cập nhật Google App\n'
      //     '• Kiểm tra Google Play Services\n'
      //     '• Đảm bảo có kết nối Internet'
      //   );
      // }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      // Check and request permission
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        _showError('Cần cấp quyền microphone để sử dụng tính năng này');
        return;
      }
      await _initSpeech();
      if (!_speechAvailable) {
        _showError('Không thể khởi tạo nhận diện giọng nói');
        return;
      }
    }

    if (_isListening) {
      // Stop listening - finalize current text
      await _speech.stop();
      setState(() {
        _isListening = false;
        _lastRecognizedWords = '';
      });
    } else {
      // Start listening at current cursor position
      _speechStartPosition = widget.controller.selection.baseOffset;
      if (_speechStartPosition < 0) {
        _speechStartPosition = widget.controller.text.length;
      }
      
      setState(() {
        _isListening = true;
        _currentWords = '';
        _lastRecognizedWords = '';
      });
      
      await _speech.listen(
        onResult: (result) {
          // Only process if still listening (prevent duplicate on manual stop)
          if (!_isListening) return;
          
          final recognizedWords = result.recognizedWords;
          
          setState(() {
            _currentWords = recognizedWords;
            
            // Get current text
            final currentText = widget.controller.text;
            
            // Remove previously recognized text if any
            String textBeforeSpeech;
            String textAfterSpeech;
            
            if (_lastRecognizedWords.isNotEmpty) {
              // Remove last recognized portion
              final lastEndPosition = _speechStartPosition + _lastRecognizedWords.length;
              textBeforeSpeech = currentText.substring(0, _speechStartPosition);
              textAfterSpeech = currentText.substring(lastEndPosition);
            } else {
              // First recognition
              textBeforeSpeech = currentText.substring(0, _speechStartPosition);
              textAfterSpeech = currentText.substring(_speechStartPosition);
            }
            
            // Insert new recognized text
            final newText = textBeforeSpeech + recognizedWords + textAfterSpeech;
            final newCursorPosition = _speechStartPosition + recognizedWords.length;
            
            widget.controller.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: newCursorPosition),
            );
            
            // Trigger onChanged callback
            widget.onChanged?.call(newText);
            
            // Update last recognized for next iteration
            _lastRecognizedWords = recognizedWords;
          });
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        // ignore: deprecated_member_use
        partialResults: true, // Real-time results
        localeId: 'vi_VN', // Vietnamese
        // ignore: deprecated_member_use
        cancelOnError: false,
        // ignore: deprecated_member_use
        listenMode: stt.ListenMode.dictation,
      );
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        Stack(
          alignment: Alignment.centerRight,
          children: [
            TextFormField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              maxLines: widget.maxLines,
              keyboardType: widget.keyboardType,
              validator: widget.validator,
              enabled: widget.enabled,
              textCapitalization: widget.textCapitalization,
              onChanged: widget.onChanged,
              obscureText: widget.obscureText,
              textInputAction: widget.textInputAction,
              onEditingComplete: widget.onEditingComplete,
              onFieldSubmitted: widget.onSubmitted,
              decoration: widget.decoration ?? InputDecoration(
                hintText: widget.hint,
                prefixIcon: widget.prefixIcon != null 
                    ? Icon(widget.prefixIcon) 
                    : null,
                suffixIcon: widget.suffixIcon ?? const SizedBox(width: 56), // Space for mic button
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: widget.enabled ? Colors.white : Colors.grey[100],
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: widget.maxLines > 1 ? 16 : 14,
                ),
              ),
            ),
            
            // Mic Button - positioned inside the field
            Positioned(
              right: 8,
              top: widget.maxLines > 1 ? 8 : null,
              bottom: widget.maxLines > 1 ? null : null,
              child: _buildMicButton(),
            ),
          ],
        ),
        
        // Live transcription indicator
        if (_isListening) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentWords.isEmpty 
                        ? 'Đang lắng nghe...' 
                        : 'Đang nhận diện: "$_currentWords"',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _toggleListening,
                  icon: const Icon(Icons.stop, size: 16),
                  label: const Text('Dừng', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red[700],
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMicButton() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _isListening ? _scaleAnimation.value : 1.0,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _isListening
                  ? LinearGradient(
                      colors: [Colors.red[400]!, Colors.red[600]!],
                    )
                  : LinearGradient(
                      colors: [Colors.blue[400]!, Colors.blue[600]!],
                    ),
              boxShadow: [
                BoxShadow(
                  color: (_isListening ? Colors.red : Colors.blue).withValues(alpha: 0.3),
                  blurRadius: _isListening ? 8 : 4,
                  spreadRadius: _isListening ? 1 : 0,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.enabled ? _toggleListening : null,
                borderRadius: BorderRadius.circular(20),
                child: Center(
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

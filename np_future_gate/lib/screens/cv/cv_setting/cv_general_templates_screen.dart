import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'cv_metadata.dart';
import '../cv_template/cv_ui/cv6.dart';
import '../cv_template/cv_ui/cv7.dart';
import '../cv_template/cv_ui/cv8.dart';
import '../cv_template/cv_ui/cv9.dart';
import '../cv_input/cv1_input_screen.dart';
import '../cv_input/cv2_input_screen.dart';
import '../cv_input/cv3_input_screen.dart';
import '../cv_input/cv4_input_screen.dart';
import '../cv_input/cv5_input_screen.dart';
import '../cv_input/cv6_input_screen.dart';
import '../cv_input/cv7_input_screen.dart';
import '../cv_input/cv8_input_screen.dart';
import '../cv_input/cv9_input_screen.dart';
import '../cv_management_screen.dart';

/// Screen showing general CV templates
class CVGeneralTemplatesScreen extends StatefulWidget {
  const CVGeneralTemplatesScreen({super.key});

  @override
  State<CVGeneralTemplatesScreen> createState() => _CVGeneralTemplatesScreenState();
}

class _CVGeneralTemplatesScreenState extends State<CVGeneralTemplatesScreen> {
  String _searchQuery = '';
  final Set<String> _selectedTags = {};
  List<CVMetadata> _templates = [];
  final TextEditingController _searchController = TextEditingController();
  
  // Speech-to-text
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
    CVRegistry.initialize(); // Ensure registry is initialized
    _templates = CVRegistry.getAll();
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onError: (error) {
          debugPrint('Speech error: $error');
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );
    } catch (e) {
      debugPrint('Speech init error: $e');
    }
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) return;
      await _initSpeech();
      if (!_speechAvailable) return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _searchController.text = result.recognizedWords;
            _searchQuery = result.recognizedWords;
          });
        },
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 3),
        localeId: 'vi_VN',
        listenMode: stt.ListenMode.dictation,
      );
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _searchController.dispose();
    super.dispose();
  }

  List<CVMetadata> get _filteredTemplates {
    // Filter only 'general' type templates
    var result = _templates.where((t) => t.type == 'general').toList();

    // Filter by Search Query
    if (_searchQuery.isNotEmpty) {
      result = result.where((t) =>
          t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.description.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Filter by Selected Tags (OR logic: match ANY selected tag)
    if (_selectedTags.isNotEmpty) {
      result = result.where((t) =>
          t.tags.any((tag) => _selectedTags.contains(tag.label))
      ).toList();
    }
    
    return result;
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mẫu CV Chung',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Các mẫu phổ biến phù hợp mọi ngành nghề',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.manage_search, color: Colors.blue),
                      ),
                      tooltip: 'Quản lý CV',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CVManagementScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm mẫu CV...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.search, color: Colors.blue[400]),
                      suffixIcon: IconButton(
                        onPressed: _toggleListening,
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening ? Colors.red : Colors.blue[400],
                        ),
                        tooltip: 'Tìm bằng giọng nói',
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Tag Filter Chips (Horizontal Scroll)
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildFilterChip('Tất cả', _selectedTags.isEmpty, isAll: true),
                    const SizedBox(width: 8),
                    _buildFilterChip('Professional', _selectedTags.contains('Professional')),
                    const SizedBox(width: 8),
                    _buildFilterChip('Creative', _selectedTags.contains('Creative')),
                    const SizedBox(width: 8),
                    _buildFilterChip('Modern', _selectedTags.contains('Modern')),
                    const SizedBox(width: 8),
                    _buildFilterChip('Simple', _selectedTags.contains('Simple')),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // List
              Expanded(
                child: _filteredTemplates.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Không tìm thấy mẫu phù hợp',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: _filteredTemplates.length,
                        itemBuilder: (ctx, i) => _buildEnhancedCard(_filteredTemplates[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, {bool isAll = false}) {
    return GestureDetector(
      onTap: () {
        if (isAll) {
          setState(() {
            _selectedTags.clear();
          });
        } else {
          _toggleTag(label);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedCard(CVMetadata t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (t.mcv == 'CV001') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CV1InputScreen()),
              );
            } else if (t.mcv == 'CV002') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CV2InputScreen()),
              );
            } else if (t.mcv == 'CV003') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CV3InputScreen()),
              );
            } else if (t.mcv == 'CV004') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CV4InputScreen()),
              );
            } else if (t.mcv == 'CV005') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CV5InputScreen()),
              );
            } else if (t.mcv == 'CV006') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CV6InputScreen()),
              );
            } else if (t.mcv == 'CV007') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CV7InputScreen()),
              );
            } else if (t.mcv == 'CV008') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CV8InputScreen()),
              );
            } else if (t.mcv == 'CV009') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CV9InputScreen()),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đang phát triển mẫu: ${t.title}')),
              );
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(t.icon, color: Colors.blue[600], size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            t.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: t.tags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: tag.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: tag.color.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (tag.icon != null) ...[
                          Icon(tag.icon, size: 12, color: tag.color),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          tag.label,
                          style: TextStyle(
                            fontSize: 11,
                            color: tag.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../core/models/course_lesson_model.dart';
import '../../core/theme/app_main_colors.dart';

class LessonVideoScreen extends StatefulWidget {
  final CourseLessonModel lesson;
  final List<CourseLessonModel> allLessons;

  const LessonVideoScreen({
    super.key,
    required this.lesson,
    required this.allLessons,
  });

  @override
  State<LessonVideoScreen> createState() => _LessonVideoScreenState();
}

class _LessonVideoScreenState extends State<LessonVideoScreen> {
  late YoutubePlayerController _controller;
  late CourseLessonModel _currentLesson;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _currentLesson = widget.lesson;
    _initializePlayer();
  }

  void _initializePlayer() {
    final videoId = _currentLesson.youtubeVideoId;
    if (videoId == null) {
      return;
    }

    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        controlsVisibleAtStart: true,
      ),
    );

    _controller.addListener(_handleControllerChange);
  }

  void _handleControllerChange() {
    if (!mounted) return;
    if (_controller.value.isFullScreen != _isFullScreen) {
      setState(() {
        _isFullScreen = _controller.value.isFullScreen;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChange);
    _controller.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  void _playNextLesson() {
    final currentIndex = widget.allLessons.indexWhere((l) => l.id == _currentLesson.id);
    if (currentIndex < widget.allLessons.length - 1) {
      final nextLesson = widget.allLessons[currentIndex + 1];
      _switchLesson(nextLesson);
    }
  }

  void _playPreviousLesson() {
    final currentIndex = widget.allLessons.indexWhere((l) => l.id == _currentLesson.id);
    if (currentIndex > 0) {
      final prevLesson = widget.allLessons[currentIndex - 1];
      _switchLesson(prevLesson);
    }
  }

  void _playLesson(CourseLessonModel lesson) {
    _switchLesson(lesson);
  }

  void _switchLesson(CourseLessonModel lesson) {
    final newVideoId = lesson.youtubeVideoId;
    if (newVideoId == null) return;
    
    setState(() {
      _currentLesson = lesson;
    });
    
    // Load video mới vào controller hiện tại
    _controller.load(newVideoId);
    _controller.play();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentLesson.youtubeVideoId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Lỗi'),
          backgroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'URL video không hợp lệ',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppMainColors.primary,
        bottomActions: [
          CurrentPosition(),
          ProgressBar(
            isExpanded: true,
            colors: ProgressBarColors(
              playedColor: AppMainColors.primary,
              handleColor: AppMainColors.primary,
            ),
          ),
          RemainingDuration(),
          const PlaybackSpeedButton(),
          FullScreenButton(),
        ],
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: _isFullScreen
              ? null
              : AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    _currentLesson.title,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
          body: Column(
            children: [
              // Video player
              player,

              // Lesson content
              if (!_isFullScreen)
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Lesson title
                      Text(
                        _currentLesson.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Meta info
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            _currentLesson.durationText,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Description
                      if (_currentLesson.description != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _currentLesson.description!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Navigation buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: widget.allLessons.first.id == _currentLesson.id
                                  ? null
                                  : _playPreviousLesson,
                              icon: const Icon(Icons.skip_previous),
                              label: const Text('Bài trước'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: widget.allLessons.last.id == _currentLesson.id
                                  ? null
                                  : _playNextLesson,
                              icon: const Icon(Icons.skip_next),
                              label: const Text('Bài sau'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppMainColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // All lessons
                      const Text(
                        'Danh sách bài học',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.allLessons.length,
                        itemBuilder: (context, index) {
                          final lesson = widget.allLessons[index];
                          final isPlaying = lesson.id == _currentLesson.id;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isPlaying 
                                  ? AppMainColors.primary.withOpacity(0.1)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isPlaying 
                                    ? AppMainColors.primary
                                    : Colors.grey.shade200,
                                width: isPlaying ? 2 : 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _playLesson(lesson),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      // Number
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: isPlaying
                                              ? AppMainColors.primary
                                              : AppMainColors.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: isPlaying
                                                  ? Colors.white
                                                  : AppMainColors.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Content
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              lesson.title,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: isPlaying ? FontWeight.w600 : FontWeight.w500,
                                                color: isPlaying
                                                    ? AppMainColors.primary
                                                    : Colors.grey.shade900,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  size: 11,
                                                  color: Colors.grey.shade500,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  lesson.durationText,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Play icon
                                      Icon(
                                        isPlaying ? Icons.pause_circle : Icons.play_circle_outline,
                                        color: isPlaying
                                            ? AppMainColors.primary
                                            : Colors.grey.shade400,
                                        size: 24,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:np_future_gate/core/models/course_lesson_model.dart';
import 'package:np_future_gate/core/models/course_model.dart';
import 'package:np_future_gate/core/repositories/course_repository.dart';
import 'package:np_future_gate/core/theme/app_main_colors.dart';
import 'package:np_future_gate/screens/courses/lesson_video_screen.dart';

class CourseDetailScreen extends StatefulWidget {

  const CourseDetailScreen({
    super.key,
    required this.courseId,
  });
  final String courseId;

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final _courseRepo = CourseRepository();
  CourseModel? _course;
  List<CourseLessonModel> _lessons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final course = await _courseRepo.getCourseDetail(widget.courseId);
    
    if (course != null) {
      final lessons = await _courseRepo.getCourseLessons(course.id);

      setState(() {
        _course = course;
        _lessons = lessons;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _course == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Không tìm thấy khóa học',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Quay lại'),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    // AppBar with thumbnail
                    SliverAppBar(
                      expandedHeight: 220,
                      pinned: true,
                      backgroundColor: Colors.white,
                      leading: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black87),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        background: _course!.thumbnailUrl != null
                            ? Image.network(
                                _course!.thumbnailUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stack) {
                                  return Container(
                                    color: Colors.grey.shade200,
                                    child: Icon(Icons.school, size: 64, color: Colors.grey.shade400),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey.shade200,
                                child: Icon(Icons.school, size: 64, color: Colors.grey.shade400),
                              ),
                      ),
                    ),

                    // Content
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Level badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppMainColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _course!.levelLabel,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppMainColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Title
                            Text(
                              _course!.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Meta info
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  _course!.durationText,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(Icons.play_circle_outline, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  '${_lessons.length} bài học',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(Icons.visibility, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  '${_course!.viewCount}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Description
                            if (_course!.description != null) ...[
                              const Text(
                                'Giới thiệu',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
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
                                  _course!.description!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Tags
                            if (_course!.tags.isNotEmpty) ...[
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _course!.tags.map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      tag,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Lessons
                            const Text(
                              'Nội dung khóa học',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),

                            if (_lessons.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.play_circle_outline,
                                        size: 48,
                                        color: Colors.grey.shade300,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Chưa có bài học',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _lessons.length,
                                itemBuilder: (context, index) {
                                  return _buildLessonItem(_lessons[index], index + 1);
                                },
                              ),

                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      // floatingActionButton: _course != null && _lessons.isNotEmpty
      //     ? FloatingActionButton.extended(
      //         onPressed: () {
      //           // Start with first lesson
      //           _openLesson(_lessons.first);
      //         },
      //         backgroundColor: AppMainColors.primary,
      //         icon: const Icon(Icons.play_arrow),
      //         label: const Text('Bắt đầu học'),
      //       )
      //     : null,
    );
  }

  Widget _buildLessonItem(CourseLessonModel lesson, int number) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openLesson(lesson),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Number
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppMainColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppMainColors.primary,
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
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            lesson.durationText,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          if (lesson.isPreview) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Xem trước',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Play icon
                const Icon(
                  Icons.play_circle_outline,
                  color: AppMainColors.primary,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openLesson(CourseLessonModel lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonVideoScreen(
          lesson: lesson,
          allLessons: _lessons,
        ),
      ),
    );
  }
}

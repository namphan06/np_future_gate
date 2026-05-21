import 'package:flutter/foundation.dart';
import 'package:np_future_gate/core/models/course_category_model.dart';
import 'package:np_future_gate/core/models/course_lesson_model.dart';
import 'package:np_future_gate/core/models/course_model.dart';
import 'package:np_future_gate/core/services/supabase_service.dart';

class CourseRepository {
  final _supabase = SupabaseService.instance.client;

  /// Lấy danh sách categories active
  Future<List<CourseCategoryModel>> getActiveCategories() async {
    try {
      final response = await _supabase
          .from('course_categories')
          .select()
          .eq('is_active', true)
          .order('order', ascending: true);

      return (response as List)
          .map((json) => CourseCategoryModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting categories: $e');
      return [];
    }
  }

  /// Lấy danh sách courses published
  Future<List<CourseModel>> getPublishedCourses({
    String? categoryId,
    String? level,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _supabase
          .from('courses')
          .select();

      // Apply filters
      query = query.eq('status', 'published');

      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.eq('category_id', categoryId);
      }

      if (level != null && level.isNotEmpty) {
        query = query.eq('level', level);
      }

      // Apply ordering and pagination
      final response = await query
          .order('is_featured', ascending: false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => CourseModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting published courses: $e');
      return [];
    }
  }

  /// Lấy courses nổi bật
  Future<List<CourseModel>> getFeaturedCourses({int limit = 5}) async {
    try {
      final response = await _supabase
          .from('courses')
          .select()
          .eq('status', 'published')
          .eq('is_featured', true)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => CourseModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting featured courses: $e');
      return [];
    }
  }

  /// Lấy chi tiết course
  Future<CourseModel?> getCourseDetail(String id) async {
    try {
      final response = await _supabase
          .from('courses')
          .select()
          .eq('id', id)
          .eq('status', 'published')
          .maybeSingle();

      if (response == null) return null;

      // Increment view count
      await _incrementViewCount(id);

      return CourseModel.fromJson(response);
    } catch (e) {
      debugPrint('Error getting course detail: $e');
      return null;
    }
  }

  /// Lấy course theo slug
  Future<CourseModel?> getCourseBySlug(String slug) async {
    try {
      final response = await _supabase
          .from('courses')
          .select()
          .eq('slug', slug)
          .eq('status', 'published')
          .maybeSingle();

      if (response == null) return null;

      // Increment view count
      await _incrementViewCount(response['id'] as String);

      return CourseModel.fromJson(response);
    } catch (e) {
      debugPrint('Error getting course by slug: $e');
      return null;
    }
  }

  /// Lấy danh sách lessons của course
  Future<List<CourseLessonModel>> getCourseLessons(String courseId) async {
    try {
      final response = await _supabase
          .from('course_lessons')
          .select()
          .eq('course_id', courseId)
          .order('order', ascending: true);

      return (response as List)
          .map((json) => CourseLessonModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting course lessons: $e');
      return [];
    }
  }

  /// Lấy lesson detail
  Future<CourseLessonModel?> getLessonDetail(String lessonId) async {
    try {
      final response = await _supabase
          .from('course_lessons')
          .select()
          .eq('id', lessonId)
          .maybeSingle();

      if (response == null) return null;

      return CourseLessonModel.fromJson(response);
    } catch (e) {
      debugPrint('Error getting lesson detail: $e');
      return null;
    }
  }

  /// Tìm kiếm courses
  Future<List<CourseModel>> searchCourses(String keyword) async {
    try {
      final response = await _supabase
          .from('courses')
          .select()
          .eq('status', 'published')
          .or('title.ilike.%$keyword%,description.ilike.%$keyword%')
          .order('created_at', ascending: false)
          .limit(20);

      return (response as List)
          .map((json) => CourseModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error searching courses: $e');
      return [];
    }
  }

  /// Lấy courses liên quan
  Future<List<CourseModel>> getRelatedCourses({
    required String currentCourseId,
    String? categoryId,
    int limit = 4,
  }) async {
    try {
      var query = _supabase
          .from('courses')
          .select()
          .eq('status', 'published')
          .neq('id', currentCourseId);

      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.eq('category_id', categoryId);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => CourseModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting related courses: $e');
      return [];
    }
  }

  /// Tăng view count
  Future<void> _incrementViewCount(String courseId) async {
    try {
      await _supabase.rpc(
        'increment_course_view_count',
        params: {'course_id': courseId},
      );
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
    }
  }
}

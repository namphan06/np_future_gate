import 'package:flutter/foundation.dart';
import 'package:np_future_gate/core/models/career_news_model.dart';
import 'package:np_future_gate/core/services/supabase_service.dart';

/// Repository for Career News
class CareerNewsRepository {
  final _supabase = SupabaseService.instance.client;

  /// Lấy danh sách tin tức published
  Future<List<CareerNewsModel>> getPublishedNews({
    String? category,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _supabase
          .from('career_news')
          .select();

      // Apply filters first
      query = query.eq('status', 'published');
      
      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      // Then ordering and pagination
      final response = await query
          .order('is_pinned', ascending: false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      return (response as List)
          .map((json) => CareerNewsModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting published news: $e');
      return [];
    }
  }

  /// Lấy tin nổi bật
  Future<List<CareerNewsModel>> getFeaturedNews({int limit = 5}) async {
    try {
      final response = await _supabase
          .from('career_news')
          .select()
          .eq('status', 'published')
          .eq('is_featured', true)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => CareerNewsModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting featured news: $e');
      return [];
    }
  }

  /// Lấy chi tiết tin tức
  Future<CareerNewsModel?> getNewsDetail(String id) async {
    try {
      final response = await _supabase
          .from('career_news')
          .select()
          .eq('id', id)
          .eq('status', 'published')
          .maybeSingle();

      if (response == null) return null;

      // Tăng view count
      await _incrementViewCount(id);

      return CareerNewsModel.fromJson(response);
    } catch (e) {
      debugPrint('Error getting news detail: $e');
      return null;
    }
  }

  /// Lấy tin tức theo slug
  Future<CareerNewsModel?> getNewsBySlug(String slug) async {
    try {
      final response = await _supabase
          .from('career_news')
          .select()
          .eq('slug', slug)
          .eq('status', 'published')
          .maybeSingle();

      if (response == null) return null;

      // Tăng view count
      await _incrementViewCount(response['id'] as String);

      return CareerNewsModel.fromJson(response);
    } catch (e) {
      debugPrint('Error getting news by slug: $e');
      return null;
    }
  }

  /// Tìm kiếm tin tức
  Future<List<CareerNewsModel>> searchNews(String keyword) async {
    try {
      final response = await _supabase
          .from('career_news')
          .select()
          .eq('status', 'published')
          .or('title.ilike.%$keyword%,excerpt.ilike.%$keyword%,content.ilike.%$keyword%')
          .order('created_at', ascending: false)
          .limit(20);

      return (response as List)
          .map((json) => CareerNewsModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error searching news: $e');
      return [];
    }
  }

  /// Lấy tin tức liên quan
  Future<List<CareerNewsModel>> getRelatedNews({
    required String currentNewsId,
    required String category,
    int limit = 5,
  }) async {
    try {
      final response = await _supabase
          .from('career_news')
          .select()
          .eq('status', 'published')
          .eq('category', category)
          .neq('id', currentNewsId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => CareerNewsModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting related news: $e');
      return [];
    }
  }

  /// Tăng view count
  Future<void> _incrementViewCount(String newsId) async {
    try {
      await _supabase.rpc(
        'increment_news_view',
        params: {'news_id': newsId},
      );
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
    }
  }

  /// Lấy tất cả categories có tin
  Future<List<String>> getAvailableCategories() async {
    try {
      final response = await _supabase
          .from('career_news')
          .select('category')
          .eq('status', 'published');

      final categories = (response as List)
          .map((item) => item['category'] as String)
          .toSet()
          .toList();

      return categories;
    } catch (e) {
      debugPrint('Error getting categories: $e');
      return [];
    }
  }
}

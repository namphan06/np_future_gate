import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show RangeValues;
import 'package:np_future_gate/core/controllers/base_controller.dart';
import 'package:np_future_gate/core/controllers/pagination_mixin.dart';
import 'package:np_future_gate/core/models/profile_model.dart';
import 'package:np_future_gate/core/repositories/candidate_repository.dart';
import 'package:np_future_gate/core/services/supabase_service.dart';

/// Controller for SearchPageEmployer.
///
/// Handles all business logic for employer candidate search:
/// - Candidate filtering by field, education, location, age range, gender
/// - Paginated candidate search from Supabase
/// - Follow/unfollow operations with optimistic update and rollback
class SearchEmployerController extends BaseController with PaginationMixin<Profile> {
  final CandidateRepository _candidateRepository = CandidateRepository();
  final SupabaseService _supabaseService = SupabaseService.instance;

  // Filter state
  List<String> _selectedFields = [];
  String _selectedEducation = 'Tất cả';
  String _selectedLocation = 'Tất cả';
  RangeValues _ageRange = const RangeValues(18, 60);
  String _selectedGender = 'Tất cả';
  String _searchQuery = '';

  // Follow state
  List<String> _followedCandidateIds = [];

  // All candidates fetched from Supabase (before client-side filtering)
  List<Profile> _allCandidates = [];

  @override
  int get pageSize => 3;

  // --- Filter Getters ---

  /// The currently selected field filters.
  List<String> get selectedFields => _selectedFields;

  /// The currently selected education filter.
  String get selectedEducation => _selectedEducation;

  /// The currently selected location filter.
  String get selectedLocation => _selectedLocation;

  /// The currently selected age range filter.
  RangeValues get ageRange => _ageRange;

  /// The currently selected gender filter.
  String get selectedGender => _selectedGender;

  /// The current search query text.
  String get searchQuery => _searchQuery;

  /// List of followed candidate IDs.
  List<String> get followedCandidateIds => _followedCandidateIds;

  /// The filtered list of candidates based on active filters.
  List<Profile> get candidates => items;

  /// A map representation of all active filters.
  Map<String, dynamic> get activeFilters {
    final filters = <String, dynamic>{};
    if (_selectedFields.isNotEmpty) filters['fields'] = _selectedFields;
    if (_selectedEducation != 'Tất cả') filters['education'] = _selectedEducation;
    if (_selectedLocation != 'Tất cả') filters['location'] = _selectedLocation;
    if (_ageRange.start != 18 || _ageRange.end != 60) {
      filters['ageRange'] = _ageRange;
    }
    if (_selectedGender != 'Tất cả') filters['gender'] = _selectedGender;
    if (_searchQuery.isNotEmpty) filters['searchQuery'] = _searchQuery;
    return filters;
  }

  /// Whether any filter is currently active.
  bool get hasActiveFilters => activeFilters.isNotEmpty;

  /// Checks if a candidate is currently followed.
  bool isFollowing(String candidateId) =>
      _followedCandidateIds.contains(candidateId);

  // --- Initialization ---

  /// Loads the list of followed candidate IDs for the current employer.
  Future<void> loadFollowedCandidates() async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) return;

    try {
      final ids = await _candidateRepository.getFollowedCandidateIds(userId);
      _followedCandidateIds = ids;
      safeNotifyListeners();
    } catch (e) {
      debugPrint('Error loading followed candidates: $e');
    }
  }

  // --- Search & Filter Actions ---

  /// Searches candidates with the given filter parameters.
  ///
  /// Resets pagination and reloads candidates from Supabase,
  /// applying all active filters.
  Future<void> searchCandidates({
    String? field,
    String? education,
    String? location,
    int? minAge,
    int? maxAge,
    String? gender,
  }) async {
    if (field != null && !_selectedFields.contains(field)) {
      _selectedFields = [..._selectedFields, field];
    }
    if (education != null) _selectedEducation = education;
    if (location != null) _selectedLocation = location;
    if (minAge != null || maxAge != null) {
      _ageRange = RangeValues(
        (minAge ?? _ageRange.start.toInt()).toDouble(),
        (maxAge ?? _ageRange.end.toInt()).toDouble(),
      );
    }
    if (gender != null) _selectedGender = gender;

    resetPagination();
    await loadNextPage();
  }

  /// Sets the search query and reloads candidates.
  void setSearchQuery(String query) {
    _searchQuery = query;
    resetPagination();
    loadNextPage();
  }

  /// Sets the selected fields filter.
  void setSelectedFields(List<String> fields) {
    _selectedFields = fields;
    resetPagination();
    loadNextPage();
  }

  /// Sets the education filter.
  void setSelectedEducation(String education) {
    _selectedEducation = education;
    resetPagination();
    loadNextPage();
  }

  /// Sets the location filter.
  void setSelectedLocation(String location) {
    _selectedLocation = location;
    resetPagination();
    loadNextPage();
  }

  /// Sets the age range filter.
  void setAgeRange(RangeValues range) {
    _ageRange = range;
    resetPagination();
    loadNextPage();
  }

  /// Sets the gender filter.
  void setSelectedGender(String gender) {
    _selectedGender = gender;
    resetPagination();
    loadNextPage();
  }

  /// Clears all active filters and reloads candidates.
  void clearFilters() {
    _selectedFields = [];
    _selectedEducation = 'Tất cả';
    _selectedLocation = 'Tất cả';
    _ageRange = const RangeValues(18, 60);
    _selectedGender = 'Tất cả';
    _searchQuery = '';
    resetPagination();
    loadNextPage();
  }

  // --- Follow/Unfollow ---

  /// Toggles follow state for a candidate with optimistic update.
  ///
  /// Immediately updates the local state for responsive UI, then
  /// performs the actual API call. If the API call fails, the local
  /// state is rolled back and an error is set.
  Future<void> toggleFollow(String candidateId) async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) return;

    final wasFollowing = _followedCandidateIds.contains(candidateId);

    // Optimistic update
    if (wasFollowing) {
      _followedCandidateIds.remove(candidateId);
    } else {
      _followedCandidateIds.add(candidateId);
    }
    safeNotifyListeners();

    try {
      if (wasFollowing) {
        await _candidateRepository.unfollowCandidate(userId, candidateId);
      } else {
        await _candidateRepository.followCandidate(userId, candidateId);
      }
    } catch (e) {
      // Rollback on failure
      if (wasFollowing) {
        _followedCandidateIds.add(candidateId);
      } else {
        _followedCandidateIds.remove(candidateId);
      }
      safeNotifyListeners();
      setError('Lỗi cập nhật theo dõi: $e');
    }
  }

  // --- Pagination ---

  /// Fetches a page of candidates from Supabase, applying all active filters.
  ///
  /// The filtering is done client-side after fetching candidates with
  /// role='candidate' from the profiles table, matching the existing
  /// behavior of SearchPageEmployer.
  @override
  Future<List<Profile>> fetchPage(int offset, int limit) async {
    try {
      // Fetch all candidates from Supabase (the existing page uses a stream,
      // but for the controller we use a query-based approach)
      if (offset == 0) {
        final response = await _supabaseService.client
            .from('profiles')
            .select()
            .eq('role', 'candidate');

        _allCandidates = (response as List)
            .map((e) => Profile.fromJson(e))
            .where(_checkFilter)
            .toList();
      }

      // Apply pagination on the filtered list
      final endIndex = (offset + limit).clamp(0, _allCandidates.length);
      if (offset >= _allCandidates.length) {
        return [];
      }
      return _allCandidates.sublist(offset, endIndex);
    } catch (e) {
      debugPrint('Error fetching candidates: $e');
      rethrow;
    }
  }

  /// Checks if a profile passes all active filter criteria.
  ///
  /// Mirrors the filtering logic from the original SearchPageEmployer widget.
  bool _checkFilter(Profile profile) {
    final meta = profile.metadata;

    // 1. Security Check (Must be true)
    if (meta['security'] != true) return false;

    // 2. Search Query (Fields or Tags)
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      final fields = (meta['interested_fields'] as List<dynamic>?)
              ?.map((e) => e.toString().toLowerCase())
              .toList() ??
          [];
      final tags = (meta['tags'] as List<dynamic>?)
              ?.map((e) => e.toString().toLowerCase())
              .toList() ??
          [];

      final bool matchField = fields.any((f) => f.contains(query));
      final bool matchTag = tags.any((t) => t.contains(query));

      if (!matchField && !matchTag) return false;
    }

    // 3. Field filter
    if (_selectedFields.isNotEmpty) {
      final fields = (meta['interested_fields'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final bool match =
          _selectedFields.any((selected) => fields.contains(selected));
      if (!match) return false;
    }

    // 4. Education filter
    if (_selectedEducation != 'Tất cả') {
      if (meta['education'] != _selectedEducation) return false;
    }

    // 5. Location filter
    if (_selectedLocation != 'Tất cả') {
      final locations = (meta['work_locations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final bool matchLoc =
          locations.any((l) => l.toString().contains(_selectedLocation));
      if (!matchLoc) return false;
    }

    // 6. Gender filter
    if (_selectedGender != 'Tất cả') {
      if (meta['gender'] != null && meta['gender'] != _selectedGender) {
        return false;
      }
    }

    // 7. Age filter
    if (profile.dateOfBirth != null) {
      final age = DateTime.now().year - profile.dateOfBirth!.year;
      if (age < _ageRange.start || age > _ageRange.end) return false;
    }

    return true;
  }

  /// Total number of candidates matching the current filters.
  int get totalFilteredCount => _allCandidates.length;
}

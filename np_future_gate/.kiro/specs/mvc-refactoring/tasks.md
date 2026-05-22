# Implementation Plan: MVC Refactoring

## Overview

Refactor the NP_FutureGate Flutter application from its current mixed architecture into a proper MVC architecture. The implementation proceeds in layers: core infrastructure first (BaseController, PaginationMixin, models, utilities), then new controllers, then CV base class consolidation, and finally folder restructuring with import updates.

## Tasks

- [x] 1. Set up core infrastructure and base classes
  - [x] 1.1 Create BaseController abstract class
    - Create `lib/core/controllers/base_controller.dart`
    - Implement `isLoading`, `_isDisposed`, `error` state management
    - Implement `safeNotifyListeners()` that checks `_isDisposed` before calling `notifyListeners()`
    - Implement `dispose()` override that sets `_isDisposed = true`
    - _Requirements: 6.2, 6.3_

  - [x] 1.2 Create PaginationMixin
    - Create `lib/core/controllers/pagination_mixin.dart`
    - Implement `PaginationMixin<T> on BaseController` with `items`, `currentPage`, `hasMore`, `pageSize` state
    - Implement `loadNextPage()` with loading guard, fetch, append, hasMore check
    - Implement `resetPagination()` to clear items and reset page counter
    - Implement abstract `fetchPage(int offset, int limit)` for subclasses
    - _Requirements: 6.1_

  - [x] 1.3 Create shared utility functions
    - Create `lib/core/utils/statistics_utils.dart` with `groupByDay()` and `buildLineChartSpots()` pure functions
    - Create `lib/core/utils/snackbar_utils.dart` with `showAppSnackBar()` function and `SnackBarType` enum
    - _Requirements: 6.4, 6.5_

  - [ ]* 1.4 Write unit tests for BaseController
    - Test `isLoading` toggle and `notifyListeners` calls
    - Test `setError` and `hasError` state
    - Test `safeNotifyListeners` is no-op after `dispose()`
    - _Requirements: 6.2, 6.3_

  - [ ]* 1.5 Write unit tests for PaginationMixin
    - Test page loading increments `currentPage`
    - Test `hasMore` becomes false when page has fewer than `pageSize` items
    - Test `resetPagination` clears all state
    - Test loading guard prevents concurrent `loadNextPage()` calls
    - _Requirements: 6.1_

- [x] 2. Create Model Layer
  - [x] 2.1 Create StatisticsModel
    - Create `lib/core/models/statistics_model.dart`
    - Implement all typed fields: totalUsers, totalJobs, totalApplications, totalInterviews, newUsersInPeriod, newJobsInPeriod, newApplicationsInPeriod, applicationSuccessRate, usersByRole, jobsByStatus
    - Implement `fromJson()` factory with descriptive error on missing required fields
    - Implement `toJson()` and `copyWith()` methods
    - _Requirements: 4.1, 4.5, 4.6_

  - [x] 2.2 Create PartnershipModel
    - Create `lib/core/models/partnership_model.dart`
    - Implement all typed fields: id, schoolId, companyId, status, postLimitCount, postLimitPeriod, createdAt, updatedAt
    - Implement `fromJson()` factory with descriptive error on missing required fields
    - Implement `toJson()` and `copyWith()` methods
    - _Requirements: 4.2, 4.5, 4.6_

  - [x] 2.3 Extract ApplicationModel from JobModel
    - Create `lib/core/models/application_model.dart`
    - Extract JobApplication logic into standalone ApplicationModel with fields: userId, cvId, jobId, appliedAt, status, recruitmentStatus
    - Implement `fromJson()` factory with descriptive error on missing required fields
    - Implement `toJson()` and `copyWith()` methods
    - Update any existing references to JobApplication to use ApplicationModel
    - _Requirements: 4.3, 4.5, 4.6_

  - [ ]* 2.4 Write property test: Model serialization round trip
    - **Property 1: Model serialization round trip**
    - Generate arbitrary StatisticsModel, PartnershipModel, and ApplicationModel instances
    - Assert `fromJson(model.toJson()) == model` for all generated instances
    - Minimum 100 iterations
    - **Validates: Requirements 4.1, 4.2, 4.3, 4.5**

  - [ ]* 2.5 Write property test: Model fromJson error on missing required fields
    - **Property 2: Model fromJson error on missing required fields**
    - Generate JSON maps with at least one required field removed
    - Assert `fromJson()` throws an error containing the missing field name
    - Minimum 100 iterations
    - **Validates: Requirements 4.6**

- [x] 3. Checkpoint - Core infrastructure verification
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 4. Create new Controllers
  - [x] 4.1 Create ReportsAdminController
    - Create `lib/core/controllers/reports_admin_controller.dart`
    - Extend `BaseController`
    - Implement `loadStatistics()` that fetches user/job/application/interview stats from repository
    - Implement `setPeriod(String period)` for period filtering (7, 30, 90, 365 days)
    - Implement `usersByDay`, `jobsByDay`, `applicationsByDay` getters using `groupByDay()` utility
    - Expose `statistics` getter returning `StatisticsModel?`
    - _Requirements: 2.1, 1.1, 1.2_

  - [x] 4.2 Create SearchEmployerController
    - Create `lib/core/controllers/search_employer_controller.dart`
    - Extend `BaseController` with `PaginationMixin<ProfileModel>`
    - Implement `searchCandidates()` with filter parameters (field, education, location, age range, gender)
    - Implement `toggleFollow(String candidateId)` with optimistic update and rollback on failure
    - Implement `clearFilters()` and `hasActiveFilters` getter
    - Override `fetchPage()` for paginated candidate search
    - _Requirements: 2.3, 1.1, 1.2_

  - [x] 4.3 Create InterviewScheduleController
    - Create `lib/core/controllers/interview_schedule_controller.dart`
    - Extend `BaseController`
    - Implement `loadInterviews()` to fetch interviews, candidate profiles, and jobs
    - Implement `setSearchQuery(String query)`, `setStatusFilter(String status)`, `setDateRange(DateTimeRange? range)`
    - Implement `filteredInterviews` getter applying all active filters
    - Implement `groupedByDate` and `groupedByJob` getters
    - _Requirements: 2.5, 1.1, 1.2_

  - [x] 4.4 Create EmployerStatisticsController
    - Create `lib/core/controllers/employer_statistics_controller.dart`
    - Extend `BaseController`
    - Implement job statistics aggregation, application counting by status
    - Implement chart data preparation (applications by month, jobs by field)
    - Implement period selection
    - _Requirements: 2.2, 1.1, 1.2_

  - [ ] 4.5 Verify and extend SearchCandidateController
    - Review existing `lib/core/controllers/search_candidate_controller.dart`
    - Ensure all business logic from SearchPageCandidate widget State is in the controller
    - Extend controller if any search, filtering, pagination, or saved job logic remains in the widget
    - _Requirements: 2.4, 1.4_

  - [ ]* 4.6 Write property test: Candidate filtering correctness
    - **Property 3: Candidate filtering correctness**
    - Generate arbitrary lists of candidate profiles and filter criteria combinations
    - Assert every candidate in filtered result satisfies all active filters
    - Assert no candidate satisfying all criteria is excluded
    - Minimum 100 iterations
    - **Validates: Requirements 2.3**

  - [ ]* 4.7 Write property test: Interview filtering and grouping correctness
    - **Property 4: Interview filtering and grouping correctness**
    - Generate arbitrary lists of interviews with search query, date range, and status filter
    - Assert every interview in filtered result matches query, falls within date range, and has specified status
    - Assert groupedByDate places each interview under its correct date key
    - Minimum 100 iterations
    - **Validates: Requirements 2.5**

  - [ ]* 4.8 Write property test: Pagination correctness
    - **Property 5: Pagination correctness**
    - Generate arbitrary lists of items and page sizes
    - Simulate sequential `loadNextPage()` calls until `hasMore` is false
    - Assert concatenated result contains all original items in order
    - Assert each page has at most `pageSize` items
    - Assert `hasMore` is false only when last page has fewer than `pageSize` items
    - Minimum 100 iterations
    - **Validates: Requirements 6.1**

  - [ ]* 4.9 Write property test: groupByDay preserves all items
    - **Property 6: groupByDay preserves all items**
    - Generate arbitrary lists of timestamped items and valid periods
    - Assert sum of all group counts equals number of items within the period
    - Assert no item within the period is unaccounted for
    - Minimum 100 iterations
    - **Validates: Requirements 6.5**

- [x] 5. Checkpoint - Controllers verification
  - Ensure all tests pass, ask the user if questions arise.

- [x] 6. Create BaseCVInputScreen and refactor CV screens
  - [x] 6.1 Create BaseCVInputScreen abstract class
    - Create `lib/features/cv/screens/base_cv_input_screen.dart`
    - Implement `BaseCVInputScreen` abstract StatefulWidget with optional `cvId` parameter
    - Implement `BaseCVInputScreenState<T>` with shared logic: `initializeData()`, `saveCV()`, `showError()`, `showSuccess()`, loading state, ScrollController, common Scaffold build
    - Define abstract template methods: `getEmptyDataSchema()`, `sectionTitle(String)`, `buildCVPreview()`
    - _Requirements: 3.1, 3.5_

  - [x] 6.2 Refactor CV input screens to extend BaseCVInputScreen
    - Refactor cv1_input_screen.dart through cv19_input_screen.dart to extend `BaseCVInputScreen`
    - Each screen overrides only: `getEmptyDataSchema()`, `sectionTitle()`, `buildCVPreview()`
    - Remove duplicated logic (save, load, error display, scaffold structure) from each screen
    - Verify each screen compiles and retains its unique template behavior
    - _Requirements: 3.2, 3.3, 3.4, 3.6_

  - [ ]* 6.3 Write unit tests for BaseCVInputScreen shared logic
    - Test `initializeData()` loads existing CV or falls back to empty schema
    - Test `saveCV()` calls CVSupabaseService correctly
    - Test error/success message display
    - _Requirements: 3.1, 3.6_

- [x] 7. Wire Controllers to Screens (extract business logic from Views)
  - [x] 7.1 Wire ReportsAdminController to ReportsPageAdmin
    - Replace direct Supabase calls and data transformation in ReportsPageAdmin with ReportsAdminController
    - Provide controller via ChangeNotifierProvider or StatefulWidget lifecycle
    - View reads state via getters, calls controller methods for actions
    - _Requirements: 1.1, 1.2, 1.3, 1.6_

  - [x] 7.2 Wire SearchEmployerController to SearchPageEmployer
    - Replace direct data fetching and filtering logic in SearchPageEmployer with SearchEmployerController
    - Provide controller via ChangeNotifierProvider or StatefulWidget lifecycle
    - View reads candidates, filters state from controller
    - _Requirements: 1.1, 1.2, 1.3, 1.6_

  - [x] 7.3 Wire InterviewScheduleController to InterviewScheduleScreen
    - Replace direct data fetching and filtering in InterviewScheduleScreen with InterviewScheduleController
    - Provide controller via ChangeNotifierProvider or StatefulWidget lifecycle
    - View reads interviews, filtered lists, grouped data from controller
    - _Requirements: 1.1, 1.2, 1.3, 1.6_

  - [x] 7.4 Wire EmployerStatisticsController to EmployerStatisticsScreen
    - Replace direct data fetching and chart preparation in EmployerStatisticsScreen with EmployerStatisticsController
    - Provide controller via ChangeNotifierProvider or StatefulWidget lifecycle
    - _Requirements: 1.1, 1.2, 1.3, 1.6_

  - [x] 7.5 Verify existing controller wiring (HomeCandidateController, HomeEmployerController)
    - Ensure HomeCandidateController and HomeEmployerController are properly wired
    - Verify no business logic remains in their corresponding screen widgets
    - _Requirements: 1.3, 1.5_

- [x] 8. Checkpoint - Controller wiring verification
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 9. Folder restructuring and import updates
  - [x] 9.1 Create feature-based folder structure
    - Create directory structure: `lib/features/{auth,candidate,employer,admin,school,cv,interview,chat,ai,notification}/{screens,controllers,widgets}/`
    - Create `lib/shared/widgets/{buttons,cards,dialogs,inputs,layouts}/`
    - Ensure `lib/core/{config,controllers,enums,models,repositories,services,theme,utils}/` directories exist
    - _Requirements: 5.1, 5.2, 5.3_

  - [x] 9.2 Move screen files to feature-based structure
    - Move admin screens to `lib/features/admin/screens/`
    - Move candidate screens to `lib/features/candidate/screens/`
    - Move employer screens to `lib/features/employer/screens/`
    - Move CV screens to `lib/features/cv/screens/`
    - Move interview screens to `lib/features/interview/screens/`
    - Move auth screens to `lib/features/auth/screens/`
    - Move chat screens to `lib/features/chat/screens/`
    - Move AI screens to `lib/features/ai/screens/`
    - Move notification screens to `lib/features/notification/screens/`
    - Move school screens to `lib/features/school/screens/`
    - Update all import statements across the project
    - _Requirements: 5.1, 5.6, 7.1_

  - [x] 9.3 Move controller files to feature-based structure
    - Move feature-specific controllers from `lib/core/controllers/` to their respective `lib/features/{feature}/controllers/` directories
    - Keep BaseController and PaginationMixin in `lib/core/controllers/`
    - Update all import statements
    - _Requirements: 5.1, 5.6, 7.1_

  - [x] 9.4 Move shared widgets to lib/shared/widgets/
    - Identify reusable widgets used across multiple features
    - Move them to appropriate subdirectories in `lib/shared/widgets/`
    - Update all import statements
    - _Requirements: 5.3, 5.6, 7.1_

  - [x] 9.5 Clean up test and demo directories
    - Remove `lib/testmail/` directory, relocate test-related code to project-level `test/` directory
    - Remove `lib/screens/test/` and `lib/screens/demo/` directories, move to `dev_tools/` at project root
    - _Requirements: 5.4, 5.5_

- [x] 10. Final checkpoint - Full project verification
  - Ensure all tests pass, ask the user if questions arise.
  - Run `flutter analyze` to verify no compilation errors
  - Verify all import statements are correct after restructuring
  - _Requirements: 7.4, 7.5, 7.6_

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation after each major phase
- Property tests validate universal correctness properties from the design document
- Unit tests validate specific examples and edge cases
- The folder restructuring (task 9) is intentionally last to minimize merge conflicts during controller creation
- All controllers use Dart's `ChangeNotifier` pattern consistent with the existing codebase
- Property-based tests use the `fast_check` Dart library as specified in the design

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2", "1.3"] },
    { "id": 1, "tasks": ["1.4", "1.5", "2.1", "2.2", "2.3"] },
    { "id": 2, "tasks": ["2.4", "2.5", "4.1", "4.2", "4.3", "4.4", "4.5"] },
    { "id": 3, "tasks": ["4.6", "4.7", "4.8", "4.9", "6.1"] },
    { "id": 4, "tasks": ["6.2", "6.3"] },
    { "id": 5, "tasks": ["7.1", "7.2", "7.3", "7.4", "7.5"] },
    { "id": 6, "tasks": ["9.1"] },
    { "id": 7, "tasks": ["9.2", "9.3", "9.4", "9.5"] }
  ]
}
```

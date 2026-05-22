# Requirements Document

## Introduction

Tài liệu yêu cầu cho việc tái cấu trúc (refactoring) dự án Flutter NP_FutureGate theo kiến trúc MVC chuẩn. Mục tiêu chính: tách business logic khỏi UI screens, tạo đầy đủ model layer, loại bỏ code trùng lặp, và sắp xếp lại cấu trúc file/folder rõ ràng.

## Glossary

- **Controller**: Lớp chứa business logic, kế thừa ChangeNotifier, chịu trách nhiệm xử lý dữ liệu và trạng thái cho View
- **View**: Widget Flutter chỉ chứa code hiển thị UI, không trực tiếp gọi Repository hoặc Service
- **Model**: Lớp dữ liệu (data class) với fromJson/toJson, đại diện cho một entity trong hệ thống
- **Repository**: Lớp truy cập dữ liệu từ Supabase, trả về Model objects
- **Service**: Lớp xử lý logic nghiệp vụ phức tạp (AI, OCR, notification, payment)
- **Screen**: Một trang UI hoàn chỉnh trong ứng dụng Flutter
- **Refactoring_Engine**: Hệ thống quy trình tái cấu trúc code của dự án

## Requirements

### Requirement 1: Tách Business Logic khỏi UI Screens

**User Story:** As a developer, I want all business logic separated from UI screens into dedicated controllers, so that the codebase follows MVC architecture and is easier to maintain and test.

#### Acceptance Criteria

1. WHEN a Screen contains direct Supabase queries, repository calls, or data transformation logic (filtering, sorting, mapping, aggregation of data models), THE Refactoring_Engine SHALL extract that logic into a corresponding Controller class located in the `core/controllers/` directory
2. THE Controller SHALL extend ChangeNotifier, expose data state through getters, and manage loading and error states with dedicated boolean or enum getters (e.g., `isLoading`, `hasError`)
3. THE View SHALL only call Controller methods for user-initiated actions and read Controller state for display, while retaining UI-only concerns such as animations, scroll position, and layout logic within the View
4. WHEN a Screen currently imports supabase_flutter directly for data operations, THE Refactoring_Engine SHALL replace those imports with Controller dependencies, and the Controller SHALL access data through Repository or Service classes rather than direct Supabase client calls
5. IF a Screen contains more than 50 lines of logic that is not widget-building code (defined as code that does not return or configure a Widget, including but not limited to: database queries, data mapping, business rule evaluation, and state mutation), THEN THE Refactoring_Engine SHALL create a dedicated Controller for that Screen
6. WHEN a Controller is created for a Screen, THE Refactoring_Engine SHALL provide the Controller to the View using a state management mechanism (ChangeNotifierProvider or manual instantiation with disposal in the StatefulWidget lifecycle)
7. IF the extraction of business logic into a Controller causes a compilation error or a failing existing test, THEN THE Refactoring_Engine SHALL revert the extraction for that Screen and report the failure with the affected file name and error description

### Requirement 2: Tạo Controllers cho các Screens thiếu Controller

**User Story:** As a developer, I want every screen that handles data to have a dedicated controller, so that business logic is consistently separated across the entire app.

#### Acceptance Criteria

1. THE Refactoring_Engine SHALL create a Controller for ReportsPageAdmin that extends ChangeNotifier and exposes public methods for statistics loading (user stats, job stats, application stats, interview stats), data grouping by day, and period filtering (7, 30, 90, 365 days)
2. THE Refactoring_Engine SHALL create a Controller for EmployerStatisticsScreen that extends ChangeNotifier and exposes public methods for job statistics aggregation, application counting by status (pending, accepted, rejected), chart data preparation (applications by month, jobs by field), and period selection
3. THE Refactoring_Engine SHALL create a Controller for SearchPageEmployer that extends ChangeNotifier and exposes public methods for candidate filtering (by field, education, location, age range, gender), pagination logic (3 items per page with page navigation), and follow/unfollow operations with optimistic update and rollback on failure
4. THE Refactoring_Engine SHALL verify that the existing SearchCandidateController in lib/core/controllers/search_candidate_controller.dart covers all business logic currently in SearchPageCandidate, and extend it if any logic (search, filtering, pagination, saved job management) remains in the widget's State class
5. THE Refactoring_Engine SHALL create a Controller for InterviewScheduleScreen that extends ChangeNotifier and exposes public methods for interview data loading (interviews, candidate profiles, jobs), filtering (by search query, date range, and status: All/Scheduled/Completed/Postponed), and grouping interviews by date and job title
6. WHEN a new Controller is created, THE Refactoring_Engine SHALL place the Controller file in the lib/core/controllers/ directory using snake_case naming convention matching the pattern {screen_name}_controller.dart
7. WHEN a new Controller is created, THE Refactoring_Engine SHALL ensure the Controller contains no Flutter widget imports (only dart:foundation or package:flutter/foundation.dart for ChangeNotifier), and that all Supabase queries and data transformation logic are moved out of the Screen's State class into the Controller

### Requirement 3: Giảm Code Trùng lặp trong CV Input Screens bằng Base Class

**User Story:** As a developer, I want the shared logic across CV input screens extracted into a base class while keeping individual screen files, so that common code is reused but each CV template retains flexibility for future customization.

#### Acceptance Criteria

1. THE Refactoring_Engine SHALL create a BaseCVInputScreen abstract class that contains shared logic including: data initialization from CVSupabaseService (load existing or fallback to empty schema), save/update operations via CVSupabaseService, error message display via SnackBar, success message display via SnackBar, loading state management with CircularProgressIndicator, ScrollController setup, and the common Scaffold build structure with save action in AppBar
2. WHEN a CV input screen (cv1 through cv19) contains a method whose body is functionally identical to the corresponding method in at least 2 other CV input screens, THE Refactoring_Engine SHALL move that method into BaseCVInputScreen as a concrete or template-method implementation
3. THE Refactoring_Engine SHALL keep each individual CV input screen file (cv1_input_screen.dart through cv19_input_screen.dart) as a separate class extending BaseCVInputScreen
4. THE individual CV input screen SHALL override only template-specific members: the empty data schema method (returning the Map with template-specific fields and mcv code), the section title mapping (returning localized titles for that template's supported sections), and the CV preview widget builder (returning the corresponding CvN widget)
5. WHEN a future CV template requires unique form behavior, THE individual CV input screen SHALL be able to override any base class method without affecting other templates, and the base class SHALL NOT use final or non-virtual methods for any behavior that varies across templates
6. WHEN the refactoring is complete, THE Refactoring_Engine SHALL verify that each refactored CV input screen (cv1 through cv19) produces the same runtime widget tree and navigation behavior as its pre-refactoring version, with no change to user-visible functionality

### Requirement 4: Tạo đầy đủ Model Layer

**User Story:** As a developer, I want all data entities represented as proper Dart model classes with serialization, so that data handling is type-safe and consistent.

#### Acceptance Criteria

1. THE Refactoring_Engine SHALL create a StatisticsModel class containing at minimum the following typed fields: totalUsers (int), totalJobs (int), totalApplications (int), totalInterviews (int), newUsersInPeriod (int), newJobsInPeriod (int), newApplicationsInPeriod (int), applicationSuccessRate (double), usersByRole (Map<String, int>), and jobsByStatus (Map<String, int>)
2. THE Refactoring_Engine SHALL create a PartnershipModel class containing at minimum the following typed fields: id (String), schoolId (String), companyId (String), status (String constrained to 'pending', 'approved', or 'rejected'), postLimitCount (int), and postLimitPeriod (String constrained to 'month' or 'year')
3. THE Refactoring_Engine SHALL extract the existing JobApplication class from job_model.dart into a standalone ApplicationModel file that represents job application data independently, containing at minimum: userId, cvId, appliedAt, status, recruitmentStatus, and jobId fields
4. WHEN a Repository or Controller uses Map<String, dynamic> for structured data with a consistent set of keys that appears in 2 or more distinct files, THE Refactoring_Engine SHALL replace that Map with a typed Model class
5. THE Refactoring_Engine SHALL ensure every newly created Model class includes a factory constructor fromJson(Map<String, dynamic>) that provides default values for nullable fields, a method toJson() returning Map<String, dynamic>, and a copyWith method covering all fields of that Model
6. IF a fromJson factory constructor receives a JSON map missing a required field (a field with no default value), THEN THE Model SHALL throw a descriptive error indicating which field is missing

### Requirement 5: Chuẩn hóa cấu trúc thư mục

**User Story:** As a developer, I want a consistent and logical folder structure, so that files are easy to find and the project scales well.

#### Acceptance Criteria

1. THE Refactoring_Engine SHALL organize screens by feature module following the pattern: lib/features/{feature_name}/screens/, lib/features/{feature_name}/controllers/, lib/features/{feature_name}/widgets/ where feature_name corresponds to: auth, candidate, employer, admin, school, cv, interview, chat, ai, notification
2. THE Refactoring_Engine SHALL keep shared code in lib/core/ with subdirectories: models/, repositories/, services/, theme/, utils/, enums/, config/
3. THE Refactoring_Engine SHALL keep shared widgets in lib/shared/widgets/ with subdirectories for widget categories (buttons/, cards/, dialogs/, inputs/, layouts/)
4. THE Refactoring_Engine SHALL remove the lib/testmail/ directory and relocate test-related code to the project-level test/ directory
5. THE Refactoring_Engine SHALL remove the lib/screens/test/ and lib/screens/demo/ directories from production code, moving them to a dev_tools/ directory at the project root
6. WHEN a file is moved to a new location, THE Refactoring_Engine SHALL update all import statements referencing that file across the entire project to reflect the new path

### Requirement 6: Tái sử dụng Logic chung

**User Story:** As a developer, I want common patterns extracted into reusable utilities, so that the same logic is not duplicated across multiple files.

#### Acceptance Criteria

1. WHEN 2 or more Screens implement pagination logic with the same method signature (fetch page by offset/limit, update list, track hasMore flag), THE Refactoring_Engine SHALL extract pagination into a reusable PaginationMixin or utility class that exposes loadNextPage(), reset(), and hasMore state
2. WHEN 2 or more Screens implement loading state management using the same setState pattern (isLoading flag toggle, try/catch with error capture, mounted check before setState), THE Refactoring_Engine SHALL extract this into a base Controller class that encapsulates isLoading, error, and safe state-update methods
3. THE Refactoring_Engine SHALL create a BaseController class extending ChangeNotifier that provides: a boolean isLoading getter with a protected setter that calls notifyListeners, an error property for storing failure information, a safeNotifyListeners method that checks _isDisposed before calling notifyListeners, and a dispose override that sets _isDisposed to true
4. WHEN 2 or more Screens display SnackBar messages using the same construction pattern (background color by type, duration, optional action button), THE Refactoring_Engine SHALL extract message display into a shared utility function that accepts message text, type (success, error, info), and optional action parameters
5. WHEN statistics screens (ReportsPageAdmin, EmployerStatisticsScreen, SchoolStatisticsScreen) share groupByDay logic (grouping records by date field within a period) and line chart data-point generation (mapping day-grouped counts to chart spot lists), THE Refactoring_Engine SHALL extract these into lib/core/utils/statistics_utils.dart as pure functions: groupByDay(items, dateField, periodStart, periodDays) returning a list of day-count maps, and buildLineChartSpots(dayCountList) returning a list of chart-compatible coordinate points
6. WHEN the Refactoring_Engine extracts logic into a shared utility, THE Refactoring_Engine SHALL verify that each Screen previously containing the duplicated logic compiles without error and produces the same observable output when using the extracted utility
7. IF an extracted utility introduces a compilation error or behavioral change in any consuming Screen, THEN THE Refactoring_Engine SHALL revert the extraction for that Screen and report the conflict

### Requirement 7: Đảm bảo tính tương thích sau Refactoring

**User Story:** As a developer, I want the refactored code to maintain all existing functionality, so that users experience no regressions.

#### Acceptance Criteria

1. WHEN the Refactoring_Engine moves or renames a file, THE Refactoring_Engine SHALL update all import statements referencing that file across the project, including application source files, test files, and barrel export files
2. THE Refactoring_Engine SHALL preserve all existing public API signatures of widgets and screens, including constructor parameter names and types, public method names and return types, and publicly exposed state fields
3. WHEN a Controller is extracted from a Screen, THE Controller SHALL expose public methods and observable state properties with the same names, parameter types, and return types that the Screen previously handled internally, such that all call sites compile and behave identically without modification
4. IF a refactoring introduces a compilation error, THEN THE Refactoring_Engine SHALL attempt to resolve the error within a maximum of 3 resolution attempts before reverting the current refactoring step to its pre-refactoring state
5. THE Refactoring_Engine SHALL ensure the project compiles without errors after each individual file-level or component-level refactoring operation is complete
6. IF the Refactoring_Engine cannot resolve a compilation error within the allowed attempts, THEN THE Refactoring_Engine SHALL revert all changes from the current refactoring step and report the unresolved error to the developer

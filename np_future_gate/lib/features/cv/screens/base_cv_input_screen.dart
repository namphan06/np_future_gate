import 'package:flutter/material.dart';
import 'package:np_future_gate/core/services/cv_supabase_service.dart';
import 'package:np_future_gate/features/cv/screens/cv_input/cv_input_form.dart';

/// Base class for all CV input screens (CV1 through CV19).
///
/// Extracts shared logic: data initialization, save/update operations,
/// error/success display, loading state, ScrollController, and the common
/// Scaffold build structure.
///
/// Subclasses override only template-specific members:
/// - [getEmptyDataSchema] — the empty data map for that CV template
/// - [sectionTitle] — localized section titles for that template
/// - [buildCVPreview] — the specific CV preview widget
abstract class BaseCVInputScreen extends StatefulWidget {
  const BaseCVInputScreen({super.key, this.cvId});

  /// The ID of an existing CV to edit. If null, a new CV is created.
  final String? cvId;
}

/// Base state class providing shared logic for all CV input screens.
///
/// Subclasses must implement the abstract template methods and can override
/// any non-final method to customize behavior for a specific CV template.
abstract class BaseCVInputScreenState<T extends BaseCVInputScreen>
    extends State<T> {
  final CVSupabaseService cvService = CVSupabaseService();

  /// The current CV data being edited.
  Map<String, dynamic> cvData = {};

  /// The currently selected section for inline editing (side panel).
  String? selectedSection;

  /// Whether a loading operation is in progress.
  bool isLoading = false;

  /// Scroll controller for the CV preview area.
  final ScrollController scrollController = ScrollController();

  // ---------------------------------------------------------------------------
  // Template methods — subclasses MUST override these
  // ---------------------------------------------------------------------------

  /// Returns the empty data schema for this CV template.
  ///
  /// Must include the 'mcv' code (e.g., 'CV001') and all template-specific
  /// fields with their default values.
  Map<String, dynamic> getEmptyDataSchema();

  /// Returns the localized title for a given [section] key.
  ///
  /// Used in the AppBar when navigating to the section form.
  String sectionTitle(String section);

  /// Builds the CV preview widget for this template.
  ///
  /// [data] is the current CV data map.
  /// [onSectionTap] is the callback to invoke when a section is tapped.
  Widget buildCVPreview(
      Map<String, dynamic> data, void Function(String) onSectionTap);

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Shared logic
  // ---------------------------------------------------------------------------

  /// Loads existing CV data or falls back to the empty schema.
  Future<void> initializeData() async {
    if (widget.cvId != null) {
      setState(() => isLoading = true);
      try {
        final data = await cvService.getCVData(widget.cvId!);
        setState(() => cvData = data ?? getEmptyDataSchema());
      } catch (e) {
        showError('Không thể tải dữ liệu CV: $e');
        setState(() => cvData = getEmptyDataSchema());
      } finally {
        setState(() => isLoading = false);
      }
    } else {
      cvData = getEmptyDataSchema();
    }
  }

  /// Saves or updates the CV via [CVSupabaseService].
  Future<void> saveCV() async {
    setState(() => isLoading = true);
    try {
      if (widget.cvId != null) {
        await cvService.updateCVData(widget.cvId!, cvData);
        showSuccess('Đã cập nhật CV thành công');
      } else {
        final newId = await cvService.createCV(cvData);
        showSuccess('Đã tạo CV mới: $newId');
        if (!mounted) return;
        Navigator.pop(context, newId);
      }
    } catch (e) {
      showError('Lỗi khi lưu CV: $e');
      debugPrint('Error saving CV: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  /// Displays an error message via a red SnackBar.
  void showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// Displays a success message via a green SnackBar.
  void showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  /// Handles tapping a section — opens the form on a new page.
  void onSectionTap(String section) {
    Navigator.of(context).push(MaterialPageRoute(builder: (ctx) {
      return Scaffold(
        appBar: AppBar(title: Text(sectionTitle(section))),
        body: CV1InputForm(
          section: section,
          data: cvData,
          onDataChanged: (updated) {
            setState(() => cvData = updated);
          },
          onClose: () {
            Navigator.of(ctx).pop();
          },
        ),
      );
    }));
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  /// Returns the AppBar title based on whether we're editing or creating.
  String get appBarTitle =>
      widget.cvId != null ? 'Chỉnh sửa CV' : 'Tạo CV mới';

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Đang tải...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: saveCV,
            tooltip: 'Lưu CV',
          ),
        ],
      ),
      body: selectedSection == null
          ? _buildFullPreview()
          : _buildSplitView(),
    );
  }

  /// Builds the full-width CV preview when no section is selected.
  Widget _buildFullPreview() {
    return Container(
      color: Colors.grey[100],
      child: SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: buildCVPreview(cvData, onSectionTap),
          ),
        ),
      ),
    );
  }

  /// Builds the split view with CV preview on the left and form on the right.
  Widget _buildSplitView() {
    return Row(
      children: [
        // Left: CV Preview (Interactive)
        Expanded(
          flex: 3,
          child: Container(
            color: Colors.grey[100],
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: buildCVPreview(cvData, onSectionTap),
                ),
              ),
            ),
          ),
        ),

        // Right: Input Form
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(-2, 0),
                ),
              ],
            ),
            child: selectedSection != null
                ? CV1InputForm(
                    section: selectedSection!,
                    data: cvData,
                    onDataChanged: (updatedData) {
                      setState(() => cvData = updatedData);
                    },
                    onClose: () => setState(() => selectedSection = null),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

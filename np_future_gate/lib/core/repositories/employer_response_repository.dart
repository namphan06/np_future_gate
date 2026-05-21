import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:np_future_gate/core/models/employer_response_model.dart';
import 'package:np_future_gate/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployerResponseRepository {
  final _client = SupabaseService.instance.client;

  /// Upload file to storage bucket 'email_request'
  Future<String> uploadAttachment(PlatformFile file, String employerId) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final filePath = '$employerId/$fileName';
      
      // On mobile, file.bytes is null - read from file path instead
      final bytes = file.bytes ?? await File(file.path!).readAsBytes();
      
      await _client.storage.from('email_request').uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: _getContentType(file.extension),
            ),
          );

      // Get public URL
      final url = _client.storage.from('email_request').getPublicUrl(filePath);
      
      return url;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      rethrow;
    }
  }

  String _getContentType(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  /// Create employer response
  Future<EmployerResponseModel> createResponse(
    EmployerResponseModel response,
    List<PlatformFile> attachmentFiles,
  ) async {
    try {
      // Upload attachments first
      final List<EmailAttachment> uploadedAttachments = [];
      
      for (var file in attachmentFiles) {
        final url = await uploadAttachment(file, response.employerId);
        uploadedAttachments.add(EmailAttachment(
          url: url,
          type: _getContentType(file.extension),
          name: file.name,
          size: file.size,
        ));
      }

      // Create response with attachments
      final responseWithAttachments = EmployerResponseModel(
        employerId: response.employerId,
        candidateId: response.candidateId,
        jobId: response.jobId,
        responseType: response.responseType,
        message: response.message,
        attachments: uploadedAttachments,
        metadata: response.metadata,
      );

      final data = await _client
          .from('employer_responses')
          .insert(responseWithAttachments.toJson())
          .select()
          .single();

      return EmployerResponseModel.fromJson(data);
    } catch (e) {
      debugPrint('Error creating response: $e');
      rethrow;
    }
  }

  /// Get responses sent by employer
  Future<List<EmployerResponseModel>> getResponsesByEmployer(
    String employerId,
  ) async {
    try {
      final data = await _client
          .from('employer_responses')
          .select()
          .eq('employer_id', employerId)
          .order('created_at', ascending: false);

      return (data as List)
          .map((e) => EmployerResponseModel.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('Error fetching responses: $e');
      return [];
    }
  }

  /// Get responses received by candidate
  Future<List<EmployerResponseModel>> getResponsesForCandidate(
    String candidateId,
  ) async {
    try {
      final data = await _client
          .from('employer_responses')
          .select()
          .eq('candidate_id', candidateId)
          .order('created_at', ascending: false);

      return (data as List)
          .map((e) => EmployerResponseModel.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('Error fetching responses: $e');
      return [];
    }
  }

  /// Delete response
  Future<void> deleteResponse(String responseId) async {
    try {
      await _client.from('employer_responses').delete().eq('id', responseId);
    } catch (e) {
      debugPrint('Error deleting response: $e');
      rethrow;
    }
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Lấy danh sách conversations của user
  Future<List<ConversationModel>> getConversations() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('conversations')
          .select()
          .or('participant1_id.eq.$userId,participant2_id.eq.$userId')
          .order('last_message_at', ascending: false);

      final conversations = (response as List)
          .map((json) => ConversationModel.fromJson(json))
          .toList();

      // Lấy thông tin user khác và unread count
      for (var conversation in conversations) {
        final otherUserId = conversation.participant1Id == userId
            ? conversation.participant2Id
            : conversation.participant1Id;
        final otherUserType = conversation.participant1Id == userId
            ? conversation.participant2Type
            : conversation.participant1Type;

        // Lấy thông tin user
        final userInfo = await _getUserInfo(otherUserId, otherUserType);
        conversation.otherUserName = userInfo['name'] ?? 'Người dùng';
        conversation.otherUserAvatar = userInfo['avatar'];

        // Nếu có job_id, thêm tên job vào tên hiển thị
        if (conversation.jobId != null) {
          final jobInfo = await _getJobInfo(conversation.jobId!);
          if (jobInfo != null) {
            conversation.otherUserName = '${conversation.otherUserName} - ${jobInfo['title']}';
          }
        }

        // Lấy số tin nhắn chưa đọc
        conversation.unreadCount = await getUnreadCount(conversation.id);
      }

      return conversations;
    } catch (e) {
      print('Error getting conversations: $e');
      return [];
    }
  }

  // Lấy hoặc tạo conversation giữa 2 user
  Future<ConversationModel?> getOrCreateConversation({
    required String otherUserId,
    required String otherUserType,
    String? jobId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final currentUserType = await _getCurrentUserType();

      // Kiểm tra xem conversation đã tồn tại chưa
      final existing = await _supabase
          .from('conversations')
          .select()
          .or('and(participant1_id.eq.$userId,participant2_id.eq.$otherUserId),and(participant1_id.eq.$otherUserId,participant2_id.eq.$userId)')
          .maybeSingle();

      if (existing != null) {
        final conversation = ConversationModel.fromJson(existing);
        
        // Nếu có job_id mới và khác với job_id cũ, update conversation
        if (jobId != null && jobId != conversation.jobId) {
          print('🔄 Updating conversation job_id: ${conversation.jobId} → $jobId');
          
          // Gửi system message đánh dấu job CŨ (đã trao đổi)
          if (conversation.jobId != null) {
            final oldJobInfo = await _getJobInfo(conversation.jobId!);
            if (oldJobInfo != null) {
              await _supabase.from('messages').insert({
                'conversation_id': conversation.id,
                'sender_id': userId,
                'sender_type': currentUserType,
                'content': '--- Đã trao đổi về: ${oldJobInfo['title']} ---',
                'message_type': 'system',
              });
            }
          }
          
          // Update job_id trong conversation để hiển thị job MỚI
          await _supabase
              .from('conversations')
              .update({'job_id': jobId})
              .eq('id', conversation.id);
        }
        
        return conversation;
      }

      // Tạo mới
      final newConversation = await _supabase
          .from('conversations')
          .insert({
            'participant1_id': userId,
            'participant1_type': currentUserType,
            'participant2_id': otherUserId,
            'participant2_type': otherUserType,
            'job_id': jobId,
            'status': 'active',
          })
          .select()
          .single();
      
      // Gửi system message cho conversation mới nếu có job
      final conversation = ConversationModel.fromJson(newConversation);
      if (jobId != null) {
        final jobInfo = await _getJobInfo(jobId);
        if (jobInfo != null) {
          await _supabase.from('messages').insert({
            'conversation_id': conversation.id,
            'sender_id': userId,
            'sender_type': currentUserType,
            'content': '--- Đang trao đổi về: ${jobInfo['title']} ---',
            'message_type': 'system',
          });
        }
      }

      return conversation;
    } catch (e) {
      print('Error creating conversation: $e');
      return null;
    }
  }

  // Lấy messages của conversation
  Future<List<MessageModel>> getMessages(String conversationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .eq('is_deleted', false)
          .order('created_at', ascending: true);

      final messages = (response as List)
          .map((json) {
            final message = MessageModel.fromJson(json);
            message.isSentByMe = message.senderId == userId;
            return message;
          })
          .toList();

      return messages;
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }

  // Gửi tin nhắn
  Future<MessageModel?> sendMessage({
    required String conversationId,
    required String content,
    String messageType = 'text',
    String? attachmentUrl,
    String? attachmentName,
    int? attachmentSize,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final userType = await _getCurrentUserType();
      
      print('📤 Sending message: content="$content", sender_id=$userId, sender_type=$userType');

      final response = await _supabase
          .from('messages')
          .insert({
            'conversation_id': conversationId,
            'sender_id': userId,
            'sender_type': userType,
            'content': content,
            'message_type': messageType,
            'attachment_url': attachmentUrl,
            'attachment_name': attachmentName,
            'attachment_size': attachmentSize,
          })
          .select()
          .single();

      final message = MessageModel.fromJson(response);
      message.isSentByMe = true;
      
      print('✅ Message sent successfully: id=${message.id}');

      // Đánh dấu đã đọc
      await markAsRead(conversationId);

      return message;
    } catch (e) {
      print('❌ Error sending message: $e');
      return null;
    }
  }

  // Đánh dấu đã đọc
  Future<void> markAsRead(String conversationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final userType = await _getCurrentUserType();

      // Lấy message cuối cùng
      final lastMessage = await _supabase
          .from('messages')
          .select('id')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (lastMessage == null) return;

      // Upsert với onConflict để update khi duplicate
      await _supabase.from('message_read_status').upsert(
        {
          'conversation_id': conversationId,
          'user_id': userId,
          'user_type': userType,
          'last_read_message_id': lastMessage['id'],
          'last_read_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'conversation_id,user_id', // Unique constraint columns
      );
    } catch (e) {
      print('❌ Error marking as read: $e');
    }
  }

  // Lấy số tin nhắn chưa đọc
  Future<int> getUnreadCount(String conversationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final readStatus = await _supabase
          .from('message_read_status')
          .select('last_read_at')
          .eq('conversation_id', conversationId)
          .eq('user_id', userId)
          .maybeSingle();

      if (readStatus == null) {
        // Chưa đọc message nào, đếm tất cả
        final response = await _supabase
            .from('messages')
            .select('*')
            .eq('conversation_id', conversationId)
            .neq('sender_id', userId)
            .eq('is_deleted', false);

        return (response as List).length;
      }

      final lastReadAt = DateTime.parse(readStatus['last_read_at'] as String);
      final response = await _supabase
          .from('messages')
          .select('*')
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId)
          .gt('created_at', lastReadAt.toIso8601String())
          .eq('is_deleted', false);

      return (response as List).length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  // Stream messages realtime
  Stream<List<MessageModel>> streamMessages(String conversationId) {
    final userId = _supabase.auth.currentUser?.id;
    print('🔑 Current userId: $userId');
    
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true) // Tin cũ trước, mới sau
        .map((data) => data
            .where((json) => 
                json['conversation_id'] == conversationId &&
                json['is_deleted'] == false)
            .map((json) {
              final message = MessageModel.fromJson(json);
              message.isSentByMe = message.senderId == userId;
              print('💬 Message: "${message.content}" | senderId: ${message.senderId} | currentUser: $userId | isSentByMe: ${message.isSentByMe}');
              return message;
            })
            .toList());
  }

  // Stream conversations realtime với user info
  Stream<List<ConversationModel>> streamConversations() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    return _supabase
        .from('conversations')
        .stream(primaryKey: ['id'])
        .order('last_message_at', ascending: false)
        .asyncMap((data) async {
          final conversations = data
              .where((json) =>
                  json['participant1_id'] == userId ||
                  json['participant2_id'] == userId)
              .map((json) => ConversationModel.fromJson(json))
              .toList();

          // Load user info và job info cho mỗi conversation
          for (var conversation in conversations) {
            final otherUserId = conversation.participant1Id == userId
                ? conversation.participant2Id
                : conversation.participant1Id;
            final otherUserType = conversation.participant1Id == userId
                ? conversation.participant2Type
                : conversation.participant1Type;

            // Lấy thông tin user
            final userInfo = await _getUserInfo(otherUserId, otherUserType);
            conversation.otherUserName = userInfo['name'] ?? 'Người dùng';
            conversation.otherUserAvatar = userInfo['avatar'];

            // Nếu có job_id, thêm tên job vào tên hiển thị
            if (conversation.jobId != null) {
              final jobInfo = await _getJobInfo(conversation.jobId!);
              if (jobInfo != null) {
                conversation.otherUserName = '${conversation.otherUserName} - ${jobInfo['title']}';
              }
            }

            // Lấy số tin nhắn chưa đọc
            conversation.unreadCount = await getUnreadCount(conversation.id);
          }

          return conversations;
        });
  }

  // Helper: Lấy thông tin user
  Future<Map<String, String>> _getUserInfo(String userId, String userType) async {
    try {
      print('🔍 Getting user info for: $userId');
      
      // Lấy từ table profiles - dùng full_name và avatar_url trực tiếp
      final profile = await _supabase
          .from('profiles')
          .select('full_name, avatar_url')
          .eq('id', userId)
          .maybeSingle();

      if (profile == null) {
        print('⚠️ User profile not found for ID: $userId');
        return {'name': 'Người dùng', 'avatar': ''}; 
      }

      print('📋 Profile: full_name=${profile['full_name']}, avatar_url=${profile['avatar_url']}');

      // Lấy tên từ full_name column
      final name = profile['full_name'] ?? 'Người dùng';
      
      // Lấy avatar từ avatar_url column
      final avatar = profile['avatar_url'] ?? '';

      print('✅ Loaded user info: $name');
      return {'name': name, 'avatar': avatar};
    } catch (e) {
      print('❌ Error getting user info: $e');
      return {'name': 'Người dùng', 'avatar': ''}; 
    }
  }

  // Helper: Lấy user type của current user
  Future<String> _getCurrentUserType() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 'candidate';

      // Query từ table profiles
      final profile = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      if (profile != null && profile['role'] != null) {
        final role = profile['role'] as String;
        print('✅ Current user type: $role');
        
        // Map role sang user type cho chat
        if (role == 'employer' || role == 'company') return 'employer';
        if (role == 'school') return 'school';
        if (role == 'admin') return 'admin';
        return 'candidate';
      }

      // Mặc định là candidate
      return 'candidate';
    } catch (e) {
      print('❌ Error getting user type: $e');
      return 'candidate';
    }
  }

  // Helper: Lấy thông tin job
  Future<Map<String, dynamic>?> _getJobInfo(String jobId) async {
    try {
      final job = await _supabase
          .from('jobs')
          .select('id, metadata, creator_id')
          .eq('id', jobId)
          .maybeSingle();

      if (job == null) {
        print('⚠️ Job not found: $jobId');
        return null;
      }

      final metadata = job['metadata'] as Map<String, dynamic>?;
      if (metadata == null) {
        print('⚠️ Job metadata is null');
        return null;
      }

      // Trích xuất info từ metadata JSONB
      final title = metadata['title'] ?? 'Công việc';
      final workingRegions = metadata['working_regions'] as List?;
      final location = (workingRegions != null && workingRegions.isNotEmpty) 
          ? workingRegions[0] 
          : 'Không rõ địa điểm';
      
      final salary = metadata['salary'] as Map<String, dynamic>?;
      String salaryRange = 'Thỏa thuận';
      if (salary != null) {
        final min = salary['min'];
        final max = salary['max'];
        if (min != null && max != null) {
          salaryRange = '${min.toStringAsFixed(0)} - ${max.toStringAsFixed(0)} ${salary['currency'] ?? 'VND'}';
        } else if (salary['is_negotiable'] == true) {
          salaryRange = 'Thỏa thuận';
        }
      }

      // Get creator info for company_name
      final creatorId = job['creator_id'];
      final creator = await _supabase
          .from('profiles')
          .select('full_name')
          .eq('id', creatorId)
          .maybeSingle();

      final companyName = creator?['full_name'] ?? 'Công ty';

      print('✅ Loaded job: $title @ $companyName');
      return {
        'id': job['id'],
        'title': title,
        'company_name': companyName,
        'location': location,
        'salary_range': salaryRange,
      };
    } catch (e) {
      print('❌ Error getting job info: $e');
      return null;
    }
  }

  // Public method để lấy job info từ UI
  Future<Map<String, dynamic>?> getJobInfo(String jobId) async {
    return await _getJobInfo(jobId);
  }

  // Xóa conversation
  Future<bool> deleteConversation(String conversationId) async {
    try {
      await _supabase
          .from('conversations')
          .delete()
          .eq('id', conversationId);
      return true;
    } catch (e) {
      print('Error deleting conversation: $e');
      return false;
    }
  }

  // Xóa message
  Future<bool> deleteMessage(String messageId) async {
    try {
      await _supabase
          .from('messages')
          .update({'is_deleted': true})
          .eq('id', messageId);
      return true;
    } catch (e) {
      print('Error deleting message: $e');
      return false;
    }
  }
}

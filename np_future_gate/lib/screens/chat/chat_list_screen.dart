import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/conversation_model.dart';
import '../../core/services/chat_service.dart';
import '../../core/theme/app_main_colors.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  final String adminId = '87a7cd93-5318-4649-b4e9-722193f5347a';
  
  String _searchQuery = '';
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    // Data will be loaded via StreamBuilder
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() => _isLoading = false);
  }

  Future<void> _openAdminChat() async {
    final conversation = await _chatService.getOrCreateConversation(
      otherUserId: adminId,
      otherUserType: 'admin',
    );

    if (conversation != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailScreen(
            conversation: conversation,
            otherUserName: 'Admin Support',
            otherUserAvatar: '',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Tin nhắn',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent, color: AppMainColors.primary),
            onPressed: _openAdminChat,
            tooltip: 'Chat với Admin',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() => _searchQuery = value.toLowerCase());
                    },
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm tin nhắn...',
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Tabs
              TabBar(
                controller: _tabController,
                indicatorColor: AppMainColors.primary,
                indicatorWeight: 3,
                labelColor: AppMainColors.primary,
                unselectedLabelColor: Colors.grey.shade600,
                labelStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Tất cả'),
                  Tab(text: 'Chưa đọc'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConversationList(showUnreadOnly: false),
          _buildConversationList(showUnreadOnly: true),
        ],
      ),
    );
  }

  Widget _buildConversationList({required bool showUnreadOnly}) {
    return StreamBuilder<List<ConversationModel>>(
      stream: _chatService.streamConversations(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Đã xảy ra lỗi',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _loadData,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || _isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        var conversations = snapshot.data!;

        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          conversations = conversations.where((conv) {
            final name = conv.otherUserName?.toLowerCase() ?? '';
            final message = conv.lastMessage?.toLowerCase() ?? '';
            return name.contains(_searchQuery) || message.contains(_searchQuery);
          }).toList();
        }

        // Filter by unread
        if (showUnreadOnly) {
          conversations = conversations.where((conv) => conv.unreadCount > 0).toList();
        }

        if (conversations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  showUnreadOnly ? Icons.mark_chat_read : Icons.chat_bubble_outline,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  showUnreadOnly
                      ? 'Không có tin nhắn chưa đọc'
                      : _searchQuery.isNotEmpty
                          ? 'Không tìm thấy kết quả'
                          : 'Chưa có cuộc trò chuyện nào',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (!showUnreadOnly && _searchQuery.isEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Bắt đầu trò chuyện với nhà tuyển dụng',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              return _buildConversationCard(conversations[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildConversationCard(ConversationModel conversation) {
    final hasUnread = conversation.unreadCount > 0;
    final isActive = conversation.status == 'active';

    return Dismissible(
      key: Key(conversation.id),
      background: Container(
        color: Colors.red.shade400,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xóa cuộc trò chuyện?'),
            content: const Text('Bạn có chắc muốn xóa cuộc trò chuyện này?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Xóa'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        _chatService.deleteConversation(conversation.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa cuộc trò chuyện')),
        );
      },
      child: Material(
        color: hasUnread ? Colors.blue.shade50.withOpacity(0.3) : Colors.white,
        child: InkWell(
          onTap: () async {
            // Load user info before navigating
            await _loadConversationUserInfo(conversation);
            
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatDetailScreen(
                    conversation: conversation,
                    otherUserName: conversation.otherUserName?.isNotEmpty == true 
                        ? conversation.otherUserName! 
                        : 'Người dùng',
                    otherUserAvatar: conversation.otherUserAvatar ?? '',
                  ),
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppMainColors.primary.withOpacity(0.1),
                      backgroundImage: conversation.otherUserAvatar != null &&
                              conversation.otherUserAvatar!.isNotEmpty
                          ? NetworkImage(conversation.otherUserAvatar!)
                          : null,
                      child: conversation.otherUserAvatar == null ||
                              conversation.otherUserAvatar!.isEmpty
                          ? Text(
                              conversation.otherUserName?.substring(0, 1).toUpperCase() ??
                                  '?',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppMainColors.primary,
                              ),
                            )
                          : null,
                    ),
                    if (isActive)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.otherUserName?.isNotEmpty == true
                                  ? conversation.otherUserName!
                                  : 'Người dùng',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (conversation.lastMessageAt != null)
                            Text(
                              _formatTime(conversation.lastMessageAt!),
                              style: TextStyle(
                                fontSize: 12,
                                color: hasUnread
                                    ? AppMainColors.primary
                                    : Colors.grey.shade600,
                                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.lastMessage ?? 'Chưa có tin nhắn',
                              style: TextStyle(
                                fontSize: 14,
                                color: hasUnread ? Colors.black87 : Colors.grey.shade600,
                                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasUnread)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppMainColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                conversation.unreadCount > 99
                                    ? '99+'
                                    : conversation.unreadCount.toString(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadConversationUserInfo(ConversationModel conversation) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final otherUserId = conversation.participant1Id == userId
        ? conversation.participant2Id
        : conversation.participant1Id;
    final otherUserType = conversation.participant1Id == userId
        ? conversation.participant2Type
        : conversation.participant1Type;

    // This will be handled by ChatService
    // We just need to trigger a refresh if needed
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // Today
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE', 'vi').format(dateTime);
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }
}

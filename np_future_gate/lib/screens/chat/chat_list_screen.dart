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
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header - Redesigned (không dùng AppBar)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.blue.shade50.withOpacity(0.3),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Title Row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 20, 16),
                    child: Row(
                      children: [
                        if (Navigator.canPop(context))
                          Container(
                            margin: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 20,
                                color: Colors.black87,
                              ),
                              onPressed: () => Navigator.pop(context),
                              padding: const EdgeInsets.all(10),
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        const Expanded(
                          child: Text(
                            'Tin nhắn',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        // Admin Chat Button - Stylish
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppMainColors.primary,
                                AppMainColors.primary.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppMainColors.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.support_agent_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            onPressed: _openAdminChat,
                            tooltip: 'Hỗ trợ Admin',
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _searchQuery.isNotEmpty
                              ? AppMainColors.primary.withOpacity(0.3)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() => _searchQuery = value.toLowerCase());
                        },
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm tin nhắn...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 15,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: _searchQuery.isNotEmpty
                                ? AppMainColors.primary
                                : Colors.grey.shade500,
                            size: 22,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.close_rounded,
                                    color: Colors.grey.shade600,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Tabs - Modern Design
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: AppMainColors.primary,
                        unselectedLabelColor: Colors.grey.shade600,
                        labelStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        tabs: const [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline, size: 18),
                                SizedBox(width: 6),
                                Text('Tất cả'),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.mark_chat_unread_outlined, size: 18),
                                SizedBox(width: 6),
                                Text('Chưa đọc'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildConversationList(showUnreadOnly: false),
                  _buildConversationList(showUnreadOnly: true),
                ],
              ),
            ),
          ],
        ),
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          SnackBar(
            content: const Text('Đã xóa cuộc trò chuyện'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: hasUnread 
                  ? AppMainColors.primary.withOpacity(0.08)
                  : Colors.black.withOpacity(0.04),
              blurRadius: hasUnread ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: hasUnread 
              ? Border.all(
                  color: AppMainColors.primary.withOpacity(0.2),
                  width: 1.5,
                )
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
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
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar với gradient border nếu unread
                  Stack(
                    children: [
                      // Gradient border cho unread
                      if (hasUnread)
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppMainColors.primary,
                                AppMainColors.primary.withOpacity(0.6),
                              ],
                            ),
                          ),
                        ),
                      // Avatar
                      Container(
                        margin: hasUnread ? const EdgeInsets.all(2) : EdgeInsets.zero,
                        child: CircleAvatar(
                          radius: hasUnread ? 30 : 32,
                          backgroundColor: AppMainColors.primary.withOpacity(0.12),
                          backgroundImage: conversation.otherUserAvatar != null &&
                                  conversation.otherUserAvatar!.isNotEmpty
                              ? NetworkImage(conversation.otherUserAvatar!)
                              : null,
                          child: conversation.otherUserAvatar == null ||
                                  conversation.otherUserAvatar!.isEmpty
                              ? Text(
                                  conversation.otherUserName?.substring(0, 1).toUpperCase() ??
                                      '?',
                                  style: TextStyle(
                                    fontSize: hasUnread ? 22 : 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppMainColors.primary,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      // Online indicator
                      if (isActive)
                        Positioned(
                          right: hasUnread ? 2 : 0,
                          bottom: hasUnread ? 2 : 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.green.shade400,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  
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
                                  fontSize: 17,
                                  fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                                  color: Colors.black87,
                                  letterSpacing: -0.2,
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
                                      : Colors.grey.shade500,
                                  fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                conversation.lastMessage ?? 'Chưa có tin nhắn',
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.3,
                                  color: hasUnread 
                                      ? Colors.black.withOpacity(0.8)
                                      : Colors.grey.shade600,
                                  fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasUnread)
                              Container(
                                margin: const EdgeInsets.only(left: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppMainColors.primary,
                                      AppMainColors.primary.withOpacity(0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppMainColors.primary.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
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

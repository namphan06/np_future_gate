import 'package:flutter/material.dart';
import 'package:np_future_gate/core/services/supabase_service.dart';
import 'package:np_future_gate/core/theme/app_main_colors.dart';
import 'package:np_future_gate/dev_tools/test/data/job_data.dart';

class TestHomePage extends StatefulWidget {
  const TestHomePage({super.key});

  @override
  State<TestHomePage> createState() => _TestHomePageState();
}

class _TestHomePageState extends State<TestHomePage> {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _itemKeys = List.generate(
    mockJobPostings.length,
    (index) => GlobalKey(),
  );

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double _calculateOpacity(int index) {
    try {
      final RenderBox? renderBox =
          _itemKeys[index].currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.hasSize) return 1.0;

      final position = renderBox.localToGlobal(Offset.zero);
      final screenHeight = MediaQuery.of(context).size.height;
      const navbarHeight = 100.0;
      final visibleBottom = screenHeight - navbarHeight;

      final itemBottom = position.dy + renderBox.size.height;

      if (itemBottom > visibleBottom) {
        final overlapDistance = itemBottom - visibleBottom;
        final totalHeight = renderBox.size.height;
        final visiblePercentage =
            1 - (overlapDistance / totalHeight).clamp(0.0, 1.0);
        return (visiblePercentage * 1.2).clamp(0.15, 1.0);
      }

      return 1.0;
    } catch (e) {
      return 1.0;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  @override
  Widget build(BuildContext context) {
    final supabaseService = SupabaseService.instance;
    final currentUser = supabaseService.currentUser;

    return Stack(
      children: [
        Container(
         decoration: const BoxDecoration(
        gradient: AppMainColors.lightGradient,
      ),
          child: SafeArea(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
            // Profile Header
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppMainColors.backgroundLightStart,
                        border: Border.all(
                            color: AppMainColors.primaryLight, width: 2),
                      ),
                      child: currentUser?.userMetadata?['avatar_url'] != null
                          ? ClipOval(
                              child: Image.network(
                                currentUser!.userMetadata!['avatar_url'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.person,
                                    size: 35,
                                    color: AppMainColors.primary,
                                  );
                                },
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              size: 35,
                              color: AppMainColors.primary,
                            ),
                    ),
                    const SizedBox(width: 15),

                    // User Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentUser?.userMetadata?['full_name'] ??
                                'Người dùng',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentUser?.email ?? 'No email',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (currentUser?.userMetadata?['phone'] != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              currentUser!.userMetadata!['phone'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Notification Icon
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Stack(
                          children: [
                            const Icon(
                              Icons.notifications_outlined,
                              color: AppMainColors.primaryDark,
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Bạn có 3 thông báo mới')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Section Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Việc làm hôm nay',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '${mockJobPostings.length} việc',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Job List
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final job = mockJobPostings[index];

                    return AnimatedBuilder(
                      animation: _scrollController,
                      builder: (context, child) {
                        final double opacity = _calculateOpacity(index);
                        return Opacity(opacity: opacity, child: child!);
                      },
                      child: Container(
                        key: _itemKeys[index],
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Xem chi tiết: ${job.title}')),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: Text(
                                            job.company[0],
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: AppMainColors.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              job.title,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              job.company,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color:
                                                    Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.bookmark_border,
                                        color: Colors.grey.shade400,
                                        size: 22,
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  Row(
                                    children: [
                                      Icon(Icons.location_on_outlined,
                                          size: 16,
                                          color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        job.location,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(Icons.work_outline,
                                          size: 16,
                                          color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        job.type,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: job.tags.map((tag) {
                                      return Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppMainColors
                                              .backgroundLightStart,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          tag,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color:
                                                AppMainColors.primaryDark,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),

                                  const SizedBox(height: 10),

                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        job.salary,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                      Text(
                                        _getTimeAgo(job.postedDate),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: mockJobPostings.length,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    // Gradient overlay để tạo sự chuyển tiếp mượt mà với navbar
    Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppMainColors.primaryLight.withValues(alpha: 0),
                AppMainColors.primaryLight.withValues(alpha: 0.3),
                AppMainColors.primaryLight.withValues(alpha: 0.6),
                AppMainColors.primaryLight.withValues(alpha: 0.9),
              ],
              stops: const [0.0, 0.3, 0.6, 1.0],
            ),
          ),
        ),
      ),
    ),
  ],
);
  }
}

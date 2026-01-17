import 'package:flutter/material.dart';
import '../../core/models/career_news_model.dart';
import '../../core/repositories/career_news_repository.dart';
import '../../core/theme/app_main_colors.dart';
import 'career_news_detail_screen.dart';

class CareerNewsScreen extends StatefulWidget {
  const CareerNewsScreen({super.key});

  @override
  State<CareerNewsScreen> createState() => _CareerNewsScreenState();
}

class _CareerNewsScreenState extends State<CareerNewsScreen> with SingleTickerProviderStateMixin {
  final _newsRepo = CareerNewsRepository();
  late TabController _tabController;
  
  List<CareerNewsModel> _featuredNews = [];
  List<CareerNewsModel> _allNews = [];
  List<CareerNewsModel> _filteredNews = [];
  bool _isLoading = true;
  String? _selectedCategory;

  final List<Map<String, dynamic>> _categories = [
    {'value': null, 'label': 'Tất cả', 'icon': Icons.grid_view},
    {'value': 'market_trends', 'label': 'Xu hướng', 'icon': Icons.trending_up},
    {'value': 'career_tips', 'label': 'Mẹo nghề', 'icon': Icons.lightbulb_outline},
    {'value': 'industry_insights', 'label': 'Phân tích', 'icon': Icons.analytics_outlined},
    {'value': 'company_news', 'label': 'Tin công ty', 'icon': Icons.business_outlined},
    {'value': 'events', 'label': 'Sự kiện', 'icon': Icons.event_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!mounted) return;
    setState(() {
      _selectedCategory = _categories[_tabController.index]['value'] as String?;
      _filterNews();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final featured = await _newsRepo.getFeaturedNews(limit: 5);
    final all = await _newsRepo.getPublishedNews(limit: 50);

    setState(() {
      _featuredNews = featured;
      _allNews = all;
      _filteredNews = all;
      _isLoading = false;
    });
  }

  void _filterNews() {
    setState(() {
      if (_selectedCategory == null) {
        _filteredNews = _allNews;
      } else {
        _filteredNews = _allNews
            .where((news) => news.category == _selectedCategory)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tin tức nghề nghiệp',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _tabController.index == index;
                
                return GestureDetector(
                  onTap: () {
                    _tabController.animateTo(index);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppMainColors.primary.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected 
                            ? AppMainColors.primary
                            : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cat['icon'] as IconData,
                          size: 18,
                          color: isSelected 
                              ? AppMainColors.primary
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cat['label'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected 
                                ? AppMainColors.primary
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppMainColors.primary,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 80),
                children: [
                  // Featured News
                  if (_selectedCategory == null && _featuredNews.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber.shade700, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Tin nổi bật',
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _featuredNews.length,
                          itemBuilder: (context, index) {
                            return _buildFeaturedCard(_featuredNews[index]);
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                  // All News
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _selectedCategory == null 
                          ? 'Tất cả tin tức' 
                          : _categories.firstWhere((c) => c['value'] == _selectedCategory)['label'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_filteredNews.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.article_outlined,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có tin tức',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredNews.length,
                      itemBuilder: (context, index) {
                        return _buildNewsCard(_filteredNews[index]);
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildFeaturedCard(CareerNewsModel news) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CareerNewsDetailScreen(newsId: news.id),
          ),
        );
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Stack(
                children: [
                  news.coverImageUrl != null
                      ? Image.network(
                          news.coverImageUrl!,
                          width: double.infinity,
                          height: 130,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) {
                            return Container(
                              height: 130,
                              color: Colors.grey.shade100,
                              child: Icon(Icons.image, size: 40, color: Colors.grey.shade300),
                            );
                          },
                        )
                      : Container(
                          height: 130,
                          color: Colors.grey.shade100,
                          child: Icon(Icons.article, size: 40, color: Colors.grey.shade300),
                        ),
                  // Category badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        news.categoryLabel,
                        style: TextStyle(
                          color: AppMainColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      news.title,
                      style: TextStyle(
                        color: Colors.grey.shade900,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          news.timeAgo,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.visibility, size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          '${news.viewCount}',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
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
    );
  }

  Widget _buildNewsCard(CareerNewsModel news) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CareerNewsDetailScreen(newsId: news.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: news.coverImageUrl != null
                      ? Image.network(
                          news.coverImageUrl!,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) {
                            return Container(
                              width: 90,
                              height: 90,
                              color: Colors.grey.shade100,
                              child: Icon(Icons.image, size: 30, color: Colors.grey.shade300),
                            );
                          },
                        )
                      : Container(
                          width: 90,
                          height: 90,
                          color: Colors.grey.shade100,
                          child: Icon(Icons.article, size: 30, color: Colors.grey.shade300),
                        ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          news.categoryLabel,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Title
                      Text(
                        news.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade900,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Excerpt
                      if (news.excerpt != null)
                        Text(
                          news.excerpt!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 8),

                      // Meta info
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 3),
                          Text(
                            news.timeAgo,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.visibility, size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 3),
                          Text(
                            '${news.viewCount}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
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
}

// Custom delegate for sticky tab bar (now unused, can be removed)
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _StickyTabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}

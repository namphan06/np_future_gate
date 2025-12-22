import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_main_colors.dart';
import '../../core/models/profile_model.dart';
import '../../core/repositories/auth_repository.dart';

class SearchPageSchool extends StatefulWidget {
  const SearchPageSchool({super.key});

  @override
  State<SearchPageSchool> createState() => _SearchPageSchoolState();
}

class _SearchPageSchoolState extends State<SearchPageSchool> {
  final TextEditingController _searchController = TextEditingController();
  final AuthRepository _authRepository = AuthRepository();
  
  List<Profile> _allEmployers = [];
  List<Profile> _filteredEmployers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEmployers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployers() async {
    setState(() => _isLoading = true);
    
    try {
      // Get all profiles with role 'employer'
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('role', 'employer')
          .order('full_name', ascending: true);
      
      final employers = (response as List)
          .map((e) => Profile.fromJson(e))
          .toList();
      
      setState(() {
        _allEmployers = employers;
        _filteredEmployers = employers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  void _filterEmployers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredEmployers = _allEmployers;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredEmployers = _allEmployers.where((employer) {
          final name = employer.fullName?.toLowerCase() ?? '';
          final email = employer.email?.toLowerCase() ?? '';
          final metadata = employer.metadata;
          final companyName = metadata?['company_name']?.toString().toLowerCase() ?? '';
          
          return name.contains(lowerQuery) || 
                 email.contains(lowerQuery) ||
                 companyName.contains(lowerQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Tìm kiếm nhà tuyển dụng',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_filteredEmployers.length} nhà tuyển dụng',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              
              // Search Bar
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm công ty, nhà tuyển dụng...',
                  prefixIcon: const Icon(Icons.search, color: AppMainColors.primary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _filterEmployers('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: _filterEmployers,
              ),
              const SizedBox(height: 24),
              
              // Employer List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : _filteredEmployers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _searchQuery.isEmpty 
                                      ? Icons.business_outlined 
                                      : Icons.search_off_outlined,
                                  size: 80,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'Chưa có nhà tuyển dụng nào'
                                      : 'Không tìm thấy kết quả',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadEmployers,
                            color: AppMainColors.primary,
                            child: ListView.builder(
                              itemCount: _filteredEmployers.length,
                              itemBuilder: (context, index) {
                                final employer = _filteredEmployers[index];
                                return _buildEmployerCard(employer);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmployerCard(Profile employer) {
    final metadata = employer.metadata ?? {};
    final companyName = metadata['company_name']?.toString() ?? 'Công ty';
    final industry = metadata['industry']?.toString();
    final companySize = metadata['company_size']?.toString();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // TODO: Navigate to employer detail or show dialog
          _showEmployerDetails(employer);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 30,
                backgroundImage: employer.avatarUrl != null
                    ? NetworkImage(employer.avatarUrl!)
                    : null,
                backgroundColor: AppMainColors.primary.withOpacity(0.1),
                child: employer.avatarUrl == null
                    ? const Icon(
                        Icons.business,
                        size: 30,
                        color: AppMainColors.primary,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (employer.fullName != null)
                      Text(
                        employer.fullName!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (employer.email != null)
                      Text(
                        employer.email!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (industry != null || companySize != null)
                      const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (industry != null)
                          _buildInfoChip(Icons.business_center, industry),
                        if (companySize != null)
                          _buildInfoChip(Icons.people, companySize),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Arrow
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppMainColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppMainColors.primary),
          const SizedBox(width:4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppMainColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showEmployerDetails(Profile employer) {
    final metadata = employer.metadata ?? {};
    final companyName = metadata['company_name']?.toString() ?? 'Công ty';
    final industry = metadata['industry']?.toString();
    final companySize = metadata['company_size']?.toString();
    final address = metadata['address']?.toString();
    final description = metadata['description']?.toString();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: employer.avatarUrl != null
                  ? NetworkImage(employer.avatarUrl!)
                  : null,
              backgroundColor: AppMainColors.primary.withOpacity(0.1),
              child: employer.avatarUrl == null
                  ? const Icon(Icons.business, color: AppMainColors.primary)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                companyName,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (employer.fullName != null) ...[
                _buildDetailRow('Người đại diện', employer.fullName!),
                const SizedBox(height: 12),
              ],
              if (employer.email != null) ...[
                _buildDetailRow('Email', employer.email!),
                const SizedBox(height: 12),
              ],
              if (industry != null) ...[
                _buildDetailRow('Ngành nghề', industry),
                const SizedBox(height: 12),
              ],
              if (companySize != null) ...[
                _buildDetailRow('Quy mô', companySize),
                const SizedBox(height: 12),
              ],
              if (address != null) ...[
                _buildDetailRow('Địa chỉ', address),
                const SizedBox(height: 12),
              ],
              if (description != null) ...[
                const Text(
                  'Mô tả',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

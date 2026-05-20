import 'package:flutter/material.dart';

/// CV14 - Compact Professional Template
/// Mẫu CV chuyên nghiệp gọn gàng, tối ưu cho 1 trang A4
class Cv14 extends StatelessWidget {
  final Map<String, dynamic>? data;
  final Function(String section)? onSectionTap;

  const Cv14({super.key, this.data, this.onSectionTap});

  @override
  Widget build(BuildContext context) {
    final displayData = data ?? {};
    final personalInfo = displayData['personal_info'] ?? {};

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact Header
          _buildSectionWrapper(
            'cv_name',
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar small
                _buildSectionWrapper(
                  'avatar',
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFF2196F3),
                      image: personalInfo['avatar_url'] != null &&
                              personalInfo['avatar_url'].toString().isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(personalInfo['avatar_url']),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: personalInfo['avatar_url'] == null ||
                            personalInfo['avatar_url'].toString().isEmpty
                        ? const Icon(Icons.person, size: 30, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        personalInfo['full_name'] ?? 'NGUYỄN VĂN A',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      Text(
                        personalInfo['title'] ?? 'Chuyên viên',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Contact Row
          _buildSectionWrapper(
            'personal_info',
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  _buildCompactContact(Icons.email, personalInfo['email'] ?? 'email@example.com'),
                  _buildCompactContact(Icons.phone, personalInfo['phone'] ?? '0123456789'),
                  _buildCompactContact(Icons.location_on, personalInfo['address'] ?? 'TP.HCM'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Summary
          _buildSectionWrapper(
            'summary',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCompactTitle('Giới thiệu'),
                const SizedBox(height: 6),
                Text(
                  displayData['summary'] ?? 'Mô tả ngắn gọn...',
                  style: const TextStyle(fontSize: 12, height: 1.6, color: Color(0xFF444444)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Two Column Layout for compact info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Experience + Education
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionWrapper(
                      'experiences',
                      _buildExperienceSection(displayData['experiences']),
                    ),
                    const SizedBox(height: 14),
                    _buildSectionWrapper(
                      'education',
                      _buildEducationSection(displayData['education']),
                    ),
                    const SizedBox(height: 14),
                    _buildSectionWrapper(
                      'projects',
                      _buildProjectsSection(displayData['projects']),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Right: Skills + Certs + Languages
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionWrapper(
                      'skills',
                      _buildSkillsSection(displayData['skills']),
                    ),
                    const SizedBox(height: 14),
                    _buildSectionWrapper(
                      'certifications',
                      _buildCertsSection(displayData['certifications']),
                    ),
                    const SizedBox(height: 14),
                    _buildSectionWrapper(
                      'activities',
                      _buildActivitiesSection(displayData['activities']),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionWrapper(String sectionKey, Widget child) {
    if (onSectionTap == null) return child;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onSectionTap!(sectionKey),
        behavior: HitTestBehavior.opaque,
        child: child,
      ),
    );
  }

  Widget _buildCompactContact(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0xFF1565C0)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF555555))),
      ],
    );
  }

  Widget _buildCompactTitle(String title) {
    return Container(
      padding: const EdgeInsets.only(bottom: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1565C0), width: 2)),
      ),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1565C0),
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildExperienceSection(List<dynamic>? experiences) {
    final list = experiences ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCompactTitle('Kinh nghiệm'),
        const SizedBox(height: 8),
        if (list.isEmpty)
          _buildExpItem('Developer', 'Công ty ABC', '2020 - Nay', 'Phát triển ứng dụng...')
        else
          ...list.map((e) => _buildExpItem(
            e['position'] ?? '', e['company'] ?? '', e['duration'] ?? '', e['description'] ?? '',
          )),
      ],
    );
  }

  Widget _buildExpItem(String position, String company, String duration, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(position, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Text(duration, style: const TextStyle(fontSize: 10, color: Color(0xFF999999))),
            ],
          ),
          Text(company, style: const TextStyle(fontSize: 11, color: Color(0xFF1565C0))),
          if (desc.isNotEmpty)
            Text(desc, style: const TextStyle(fontSize: 11, height: 1.4, color: Color(0xFF555555))),
        ],
      ),
    );
  }

  Widget _buildEducationSection(List<dynamic>? education) {
    final list = education ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCompactTitle('Học vấn'),
        const SizedBox(height: 8),
        if (list.isEmpty)
          _buildEduItem('Cử nhân CNTT', 'ĐH Bách Khoa', '2015-2019')
        else
          ...list.map((e) => _buildEduItem(e['degree'] ?? '', e['school'] ?? '', e['year'] ?? '')),
      ],
    );
  }

  Widget _buildEduItem(String degree, String school, String year) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(degree, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          Text('$school • $year', style: const TextStyle(fontSize: 10, color: Color(0xFF777777))),
        ],
      ),
    );
  }

  Widget _buildProjectsSection(List<dynamic>? projects) {
    final list = projects ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCompactTitle('Dự án'),
        const SizedBox(height: 8),
        if (list.isEmpty)
          const Text('Chưa có dự án', style: TextStyle(fontSize: 11, color: Color(0xFF999999)))
        else
          ...list.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                if (p['description'] != null)
                  Text(p['description'], style: const TextStyle(fontSize: 10, color: Color(0xFF666666))),
              ],
            ),
          )),
      ],
    );
  }

  Widget _buildSkillsSection(List<dynamic>? skills) {
    final list = skills ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCompactTitle('Kỹ năng'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: list.isEmpty
              ? ['Flutter', 'Dart', 'Git'].map((s) => _buildMiniChip(s)).toList()
              : list.map((s) => _buildMiniChip(s['name'] ?? '')).toList(),
        ),
      ],
    );
  }

  Widget _buildMiniChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF1565C0))),
    );
  }

  Widget _buildCertsSection(List<dynamic>? certs) {
    final list = certs ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCompactTitle('Chứng chỉ'),
        const SizedBox(height: 8),
        if (list.isEmpty)
          const Text('Chưa có', style: TextStyle(fontSize: 11, color: Color(0xFF999999)))
        else
          ...list.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                const Icon(Icons.verified, size: 11, color: Color(0xFF1565C0)),
                const SizedBox(width: 4),
                Expanded(child: Text(c['name'] ?? '', style: const TextStyle(fontSize: 11))),
              ],
            ),
          )),
      ],
    );
  }

  Widget _buildActivitiesSection(List<dynamic>? activities) {
    final list = activities ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCompactTitle('Hoạt động'),
        const SizedBox(height: 8),
        if (list.isEmpty)
          const Text('Chưa có', style: TextStyle(fontSize: 11, color: Color(0xFF999999)))
        else
          ...list.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a['organization'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
                Text(a['role'] ?? '', style: const TextStyle(fontSize: 10, color: Color(0xFF777777))),
              ],
            ),
          )),
      ],
    );
  }
}

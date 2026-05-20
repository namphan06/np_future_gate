import 'package:flutter/material.dart';

/// CV13 - Bold Sidebar Template
/// Mẫu CV với thanh bên nổi bật, phong cách mạnh mẽ
class Cv13 extends StatelessWidget {
  final Map<String, dynamic>? data;
  final Function(String section)? onSectionTap;

  const Cv13({super.key, this.data, this.onSectionTap});

  @override
  Widget build(BuildContext context) {
    final displayData = data ?? {};
    final personalInfo = displayData['personal_info'] ?? {};

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Sidebar (Dark)
        Container(
          width: 180,
          color: const Color(0xFF0F3460),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              _buildSectionWrapper(
                'avatar',
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF00D2D3), width: 3),
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
                      ? const Icon(Icons.person, size: 36, color: Colors.white54)
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              // Contact Info
              _buildSectionWrapper(
                'personal_info',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSidebarTitle('LIÊN HỆ'),
                    const SizedBox(height: 12),
                    _buildSidebarContact(Icons.email, personalInfo['email'] ?? 'email@example.com'),
                    _buildSidebarContact(Icons.phone, personalInfo['phone'] ?? '0123456789'),
                    _buildSidebarContact(Icons.location_on, personalInfo['address'] ?? 'TP.HCM'),
                    if (personalInfo['website'] != null && personalInfo['website'].toString().isNotEmpty)
                      _buildSidebarContact(Icons.language, personalInfo['website']),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Skills
              _buildSectionWrapper(
                'skills',
                _buildSidebarSkills(displayData['skills']),
              ),
              const SizedBox(height: 24),

              // Languages
              _buildSectionWrapper(
                'certifications',
                _buildSidebarCertifications(displayData['certifications']),
              ),
              const SizedBox(height: 24),

              // References
              _buildSectionWrapper(
                'references',
                _buildSidebarReferences(displayData['references']),
              ),
            ],
          ),
        ),

        // Right Content (White)
        Expanded(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name & Title
                _buildSectionWrapper(
                  'cv_name',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        personalInfo['full_name'] ?? 'NGUYỄN VĂN A',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F3460),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D2D3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          personalInfo['title'] ?? 'Chuyên viên',
                          style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Summary
                _buildSectionWrapper(
                  'summary',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMainTitle('GIỚI THIỆU'),
                      const SizedBox(height: 10),
                      Text(
                        displayData['summary'] ?? 'Mô tả ngắn gọn về bản thân...',
                        style: const TextStyle(fontSize: 13, height: 1.7, color: Color(0xFF555555)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Experience
                _buildSectionWrapper(
                  'experiences',
                  _buildExperienceSection(displayData['experiences']),
                ),
                const SizedBox(height: 24),

                // Education
                _buildSectionWrapper(
                  'education',
                  _buildEducationSection(displayData['education']),
                ),
                const SizedBox(height: 24),

                // Awards
                _buildSectionWrapper(
                  'awards',
                  _buildAwardsSection(displayData['awards']),
                ),
              ],
            ),
          ),
        ),
      ],
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

  Widget _buildSidebarTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00D2D3),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Container(width: 30, height: 2, color: const Color(0xFF00D2D3)),
      ],
    );
  }

  Widget _buildSidebarContact(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF00D2D3)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 11, color: Colors.white70), overflow: TextOverflow.ellipsis, maxLines: 2),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarSkills(List<dynamic>? skills) {
    final list = skills ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSidebarTitle('KỸ NĂNG'),
        const SizedBox(height: 12),
        ...((list.isEmpty ? [{'name': 'Flutter', 'level': '90'}, {'name': 'Dart', 'level': '85'}] : list).map((s) {
          final level = int.tryParse(s['level']?.toString() ?? '70') ?? 70;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s['name'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.white)),
                const SizedBox(height: 4),
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: level / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D2D3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        })),
      ],
    );
  }

  Widget _buildSidebarCertifications(List<dynamic>? certs) {
    final list = certs ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSidebarTitle('CHỨNG CHỈ'),
        const SizedBox(height: 12),
        if (list.isEmpty)
          const Text('Chưa có', style: TextStyle(fontSize: 11, color: Colors.white54))
        else
          ...list.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '• ${c['name'] ?? ''}',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          )),
      ],
    );
  }

  Widget _buildSidebarReferences(List<dynamic>? refs) {
    final list = refs ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSidebarTitle('NGƯỜI GIỚI THIỆU'),
        const SizedBox(height: 12),
        if (list.isEmpty)
          const Text('Cung cấp khi yêu cầu', style: TextStyle(fontSize: 11, color: Colors.white54, fontStyle: FontStyle.italic))
        else
          ...list.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r['name'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                Text('${r['position'] ?? ''} - ${r['company'] ?? ''}', style: const TextStyle(fontSize: 10, color: Colors.white54)),
              ],
            ),
          )),
      ],
    );
  }

  Widget _buildMainTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          color: const Color(0xFF00D2D3),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F3460),
              letterSpacing: 1,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildExperienceSection(List<dynamic>? experiences) {
    final list = experiences ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMainTitle('KINH NGHIỆM'),
        const SizedBox(height: 14),
        if (list.isEmpty)
          _buildExpItem('Senior Developer', 'Công ty ABC', '2020 - Nay', 'Phát triển ứng dụng...')
        else
          ...list.map((e) => _buildExpItem(
            e['position'] ?? '', e['company'] ?? '', e['duration'] ?? '', e['description'] ?? '',
          )),
      ],
    );
  }

  Widget _buildExpItem(String position, String company, String duration, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.only(left: 14),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0xFFE0E0E0), width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(position, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F3460))),
          Row(
            children: [
              Flexible(child: Text(company, style: const TextStyle(fontSize: 12, color: Color(0xFF00D2D3)), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Text('| $duration', style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
            ],
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(desc, style: const TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF555555))),
          ],
        ],
      ),
    );
  }

  Widget _buildEducationSection(List<dynamic>? education) {
    final list = education ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMainTitle('HỌC VẤN'),
        const SizedBox(height: 14),
        if (list.isEmpty)
          _buildEduItem('Cử nhân CNTT', 'Đại học Bách Khoa', '2015 - 2019')
        else
          ...list.map((e) => _buildEduItem(e['degree'] ?? '', e['school'] ?? '', e['year'] ?? '')),
      ],
    );
  }

  Widget _buildEduItem(String degree, String school, String year) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 14),
      child: Row(
        children: [
          const Icon(Icons.school, size: 16, color: Color(0xFF0F3460)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(degree, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text('$school • $year', style: const TextStyle(fontSize: 11, color: Color(0xFF777777))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAwardsSection(List<dynamic>? awards) {
    final list = awards ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMainTitle('GIẢI THƯỞNG'),
        const SizedBox(height: 14),
        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 14),
            child: Text('Chưa có giải thưởng', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
          )
        else
          ...list.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 14),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, size: 14, color: Color(0xFFFFD700)),
                const SizedBox(width: 8),
                Expanded(child: Text('${a['name'] ?? ''} (${a['year'] ?? ''})', style: const TextStyle(fontSize: 12))),
              ],
            ),
          )),
      ],
    );
  }
}

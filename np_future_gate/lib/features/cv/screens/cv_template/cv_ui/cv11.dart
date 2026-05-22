import 'package:flutter/material.dart';

/// CV11 - Modern Gradient Template
/// Mẫu CV hiện đại với gradient màu sắc bắt mắt
class Cv11 extends StatelessWidget {

  const Cv11({super.key, this.data, this.onSectionTap});
  final Map<String, dynamic>? data;
  final Function(String section)? onSectionTap;

  @override
  Widget build(BuildContext context) {
    final displayData = data ?? {};
    final personalInfo = displayData['personal_info'] ?? {};

    return Column(
      children: [
        // Gradient Header
        _buildSectionWrapper(
          'cv_name',
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
            ),
            child: Column(
              children: [
                // Avatar
                _buildSectionWrapper(
                  'avatar',
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
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
                        ? const Icon(Icons.person, size: 40, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  personalInfo['full_name'] ?? 'NGUYỄN VĂN A',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    personalInfo['title'] ?? 'Chuyên viên',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Contact Bar
        _buildSectionWrapper(
          'personal_info',
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            color: const Color(0xFF2D3436),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 20,
              runSpacing: 8,
              children: [
                _buildContactChip(Icons.email, personalInfo['email'] ?? 'email@example.com'),
                _buildContactChip(Icons.phone, personalInfo['phone'] ?? '0123456789'),
                _buildContactChip(Icons.location_on, personalInfo['address'] ?? 'TP.HCM'),
              ],
            ),
          ),
        ),

        // Body Content
        Container(
          padding: const EdgeInsets.all(28),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary
              _buildSectionWrapper(
                'summary',
                _buildSection(
                  'Giới thiệu bản thân',
                  Icons.person_outline,
                  Text(
                    displayData['summary'] ?? 'Mô tả ngắn gọn về bản thân...',
                    style: const TextStyle(fontSize: 13, height: 1.7, color: Color(0xFF555555)),
                  ),
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

              // Skills
              _buildSectionWrapper(
                'skills',
                _buildSkillsSection(displayData['skills']),
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

  Widget _buildContactChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white70),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 11, color: Colors.white)),
      ],
    );
  }

  Widget _buildSection(String title, IconData icon, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3436),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        content,
      ],
    );
  }

  Widget _buildExperienceSection(List<dynamic>? experiences) {
    final list = experiences ?? [];
    return _buildSection(
      'Kinh nghiệm',
      Icons.work_outline,
      Column(
        children: list.isEmpty
            ? [_buildExpItem('Senior Developer', 'Công ty ABC', '2020 - Nay', 'Phát triển ứng dụng...')]
            : list.map((e) => _buildExpItem(
                e['position'] ?? '', e['company'] ?? '', e['duration'] ?? '', e['description'] ?? '',
              )).toList(),
      ),
    );
  }

  Widget _buildExpItem(String position, String company, String duration, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(position, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3436))),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(duration, style: const TextStyle(fontSize: 10, color: Color(0xFF667EEA))),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(company, style: const TextStyle(fontSize: 12, color: Color(0xFF764BA2))),
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
    return _buildSection(
      'Học vấn',
      Icons.school_outlined,
      Column(
        children: list.isEmpty
            ? [_buildEduItem('Cử nhân CNTT', 'Đại học Bách Khoa', '2015 - 2019')]
            : list.map((e) => _buildEduItem(e['degree'] ?? '', e['school'] ?? '', e['year'] ?? '')).toList(),
      ),
    );
  }

  Widget _buildEduItem(String degree, String school, String year) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(degree, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text('$school • $year', style: const TextStyle(fontSize: 11, color: Color(0xFF7F8C8D))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection(List<dynamic>? skills) {
    final list = skills ?? [];
    return _buildSection(
      'Kỹ năng',
      Icons.star_outline,
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: list.isEmpty
            ? ['Flutter', 'React', 'Node.js'].map((s) => _buildGradientChip(s)).toList()
            : list.map((s) => _buildGradientChip(s['name'] ?? '')).toList(),
      ),
    );
  }

  Widget _buildGradientChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF667EEA).withValues(alpha: 0.1), const Color(0xFF764BA2).withValues(alpha: 0.1)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF667EEA).withValues(alpha: 0.3)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF667EEA), fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildAwardsSection(List<dynamic>? awards) {
    final list = awards ?? [];
    return _buildSection(
      'Giải thưởng',
      Icons.emoji_events_outlined,
      Column(
        children: list.isEmpty
            ? [const Text('Chưa có giải thưởng', style: TextStyle(fontSize: 12, color: Color(0xFF95A5A6)))]
            : list.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events, size: 14, color: Color(0xFFFFD700)),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${a['name'] ?? ''} (${a['year'] ?? ''})', style: const TextStyle(fontSize: 12))),
                  ],
                ),
              )).toList(),
      ),
    );
  }
}

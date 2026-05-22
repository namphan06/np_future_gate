import 'package:flutter/material.dart';

/// CV19 - Media & Journalism Template
/// Mẫu CV dành cho ngành Truyền thông, Báo chí, Phát thanh
class Cv19 extends StatelessWidget {

  const Cv19({super.key, this.data, this.onSectionTap});
  final Map<String, dynamic>? data;
  final Function(String section)? onSectionTap;

  @override
  Widget build(BuildContext context) {
    final displayData = data ?? {};
    final personalInfo = displayData['personal_info'] ?? {};

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Media themed (Deep Purple + Pink accent)
          _buildSectionWrapper(
            'cv_name',
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)],
                ),
              ),
              child: Row(
                children: [
                  _buildSectionWrapper(
                    'avatar',
                    Container(
                      width: 85,
                      height: 85,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFF4081), width: 3),
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
                          ? const Icon(Icons.person, size: 38, color: Colors.white70)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          personalInfo['full_name'] ?? 'NGUYỄN VĂN A',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.videocam, size: 14, color: Color(0xFFFF4081)),
                            const SizedBox(width: 6),
                            Text(
                              personalInfo['title'] ?? 'Nhà báo / Biên tập viên',
                              style: const TextStyle(fontSize: 13, color: Color(0xFFFF4081)),
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

          // Contact
          _buildSectionWrapper(
            'personal_info',
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 28),
              color: const Color(0xFFF3E5F5),
              child: Wrap(
                spacing: 20,
                runSpacing: 8,
                children: [
                  _buildContact(Icons.email, personalInfo['email'] ?? 'email@example.com'),
                  _buildContact(Icons.phone, personalInfo['phone'] ?? '0123456789'),
                  _buildContact(Icons.location_on, personalInfo['address'] ?? 'TP.HCM'),
                  if (personalInfo['website'] != null && personalInfo['website'].toString().isNotEmpty)
                    _buildContact(Icons.language, personalInfo['website']),
                ],
              ),
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary
                _buildSectionWrapper(
                  'summary',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitle('GIỚI THIỆU', Icons.article_outlined),
                      const SizedBox(height: 10),
                      Text(
                        displayData['summary'] ?? 'Giới thiệu kinh nghiệm trong lĩnh vực truyền thông...',
                        style: const TextStyle(fontSize: 13, height: 1.7, color: Color(0xFF444444)),
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

                // Portfolio / Projects
                _buildSectionWrapper(
                  'projects',
                  _buildPortfolioSection(displayData['projects']),
                ),
                const SizedBox(height: 24),

                // Education
                _buildSectionWrapper(
                  'education',
                  _buildEducationSection(displayData['education']),
                ),
                const SizedBox(height: 24),

                // Skills & Awards
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildSectionWrapper(
                        'skills',
                        _buildSkillsSection(displayData['skills']),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildSectionWrapper(
                        'awards',
                        _buildAwardsSection(displayData['awards']),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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

  Widget _buildContact(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF7B1FA2)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Color(0xFF333333)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7B1FA2), Color(0xFFFF4081)],
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A148C),
              letterSpacing: 0.5,
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
        _buildTitle('KINH NGHIỆM LÀM VIỆC', Icons.work_outline),
        const SizedBox(height: 14),
        if (list.isEmpty)
          _buildExpItem('Biên tập viên', 'Đài truyền hình ABC', '2019 - Nay', 'Biên tập nội dung chương trình...')
        else
          ...list.map((e) => _buildExpItem(
            e['position'] ?? '', e['company'] ?? '', e['duration'] ?? '', e['description'] ?? '',
          )),
      ],
    );
  }

  Widget _buildExpItem(String position, String company, String duration, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCE93D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(position, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF4A148C)))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF7B1FA2), Color(0xFFFF4081)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(duration, style: const TextStyle(fontSize: 10, color: Colors.white)),
              ),
            ],
          ),
          Text(company, style: const TextStyle(fontSize: 12, color: Color(0xFF7B1FA2))),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(desc, style: const TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF555555))),
          ],
        ],
      ),
    );
  }

  Widget _buildPortfolioSection(List<dynamic>? projects) {
    final list = projects ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle('TÁC PHẨM / DỰ ÁN', Icons.collections_bookmark),
        const SizedBox(height: 14),
        if (list.isEmpty)
          const Text('Chưa có tác phẩm', style: TextStyle(fontSize: 12, color: Color(0xFF999999)))
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: list.map((p) => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.play_circle_outline, size: 14, color: Color(0xFFFF4081)),
                      const SizedBox(width: 6),
                      Expanded(child: Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                    ],
                  ),
                  if (p['description'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(p['description'], style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
                    ),
                ],
              ),
            )).toList(),
          ),
      ],
    );
  }

  Widget _buildEducationSection(List<dynamic>? education) {
    final list = education ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle('HỌC VẤN', Icons.school_outlined),
        const SizedBox(height: 14),
        if (list.isEmpty)
          _buildEduItem('Cử nhân Báo chí', 'Học viện Báo chí', '2014 - 2018')
        else
          ...list.map((e) => _buildEduItem(e['degree'] ?? '', e['school'] ?? '', e['year'] ?? '')),
      ],
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
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFF4081)),
          ),
          const SizedBox(width: 12),
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

  Widget _buildSkillsSection(List<dynamic>? skills) {
    final list = skills ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle('KỸ NĂNG', Icons.psychology),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: list.isEmpty
              ? ['Viết bài', 'Biên tập', 'Quay phim', 'Dựng phim'].map((s) => _buildChip(s)).toList()
              : list.map((s) => _buildChip(s['name'] ?? '')).toList(),
        ),
      ],
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF7B1FA2).withValues(alpha: 0.1), const Color(0xFFFF4081).withValues(alpha: 0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCE93D8)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF4A148C))),
    );
  }

  Widget _buildAwardsSection(List<dynamic>? awards) {
    final list = awards ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle('GIẢI THƯỞNG', Icons.emoji_events_outlined),
        const SizedBox(height: 10),
        if (list.isEmpty)
          const Text('Chưa có', style: TextStyle(fontSize: 11, color: Color(0xFF999999)))
        else
          ...list.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                const Icon(Icons.military_tech, size: 14, color: Color(0xFFFFB300)),
                const SizedBox(width: 6),
                Expanded(child: Text('${a['name'] ?? ''} (${a['year'] ?? ''})', style: const TextStyle(fontSize: 11))),
              ],
            ),
          )),
      ],
    );
  }
}

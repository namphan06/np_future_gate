import 'package:flutter/material.dart';

/// CV15 - Education & Teaching Template
/// Mẫu CV dành cho ngành Giáo dục, Giảng viên, Giáo viên
class Cv15 extends StatelessWidget {

  const Cv15({super.key, this.data, this.onSectionTap});
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
          // Header - Education themed (Green)
          _buildSectionWrapper(
            'cv_name',
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
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
                          ? const Icon(Icons.person, size: 40, color: Colors.white70)
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
                            const Icon(Icons.school, size: 16, color: Colors.white70),
                            const SizedBox(width: 6),
                            Text(
                              personalInfo['title'] ?? 'Giảng viên',
                              style: const TextStyle(fontSize: 14, color: Colors.white70),
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

          // Contact Info
          _buildSectionWrapper(
            'personal_info',
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 28),
              color: const Color(0xFFE8F5E9),
              child: Wrap(
                spacing: 20,
                runSpacing: 8,
                children: [
                  _buildContact(Icons.email, personalInfo['email'] ?? 'email@example.com'),
                  _buildContact(Icons.phone, personalInfo['phone'] ?? '0123456789'),
                  _buildContact(Icons.location_on, personalInfo['address'] ?? 'TP.HCM'),
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
                // Teaching Philosophy / Summary
                _buildSectionWrapper(
                  'summary',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitle('TRIẾT LÝ GIÁO DỤC', Icons.auto_stories),
                      const SizedBox(height: 10),
                      Text(
                        displayData['summary'] ?? 'Triết lý giáo dục và phương pháp giảng dạy...',
                        style: const TextStyle(fontSize: 13, height: 1.7, color: Color(0xFF444444)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Teaching Experience
                _buildSectionWrapper(
                  'experiences',
                  _buildTeachingExperience(displayData['experiences']),
                ),
                const SizedBox(height: 24),

                // Education & Qualifications
                _buildSectionWrapper(
                  'education',
                  _buildEducationSection(displayData['education']),
                ),
                const SizedBox(height: 24),

                // Research & Publications (using projects field)
                _buildSectionWrapper(
                  'projects',
                  _buildResearchSection(displayData['projects']),
                ),
                const SizedBox(height: 24),

                // Skills & Certifications
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
                        'certifications',
                        _buildCertsSection(displayData['certifications']),
                      ),
                    ),
                  ],
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
        Icon(icon, size: 14, color: const Color(0xFF2E7D32)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF333333))),
      ],
    );
  }

  Widget _buildTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF2E7D32)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: const Color(0xFFC8E6C9))),
      ],
    );
  }

  Widget _buildTeachingExperience(List<dynamic>? experiences) {
    final list = experiences ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle('KINH NGHIỆM GIẢNG DẠY', Icons.cast_for_education),
        const SizedBox(height: 14),
        if (list.isEmpty)
          _buildExpItem('Giảng viên', 'Đại học ABC', '2018 - Nay', 'Giảng dạy các môn lập trình...')
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
        border: Border.all(color: const Color(0xFFC8E6C9)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(position, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(duration, style: const TextStyle(fontSize: 10, color: Color(0xFF2E7D32))),
              ),
            ],
          ),
          Text(company, style: const TextStyle(fontSize: 12, color: Color(0xFF43A047))),
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
        _buildTitle('HỌC VẤN & BẰNG CẤP', Icons.school),
        const SizedBox(height: 14),
        if (list.isEmpty)
          _buildEduItem('Thạc sĩ Giáo dục', 'Đại học Sư phạm', '2015 - 2017')
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
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF43A047)),
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

  Widget _buildResearchSection(List<dynamic>? projects) {
    final list = projects ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle('NGHIÊN CỨU & CÔNG BỐ', Icons.science),
        const SizedBox(height: 14),
        if (list.isEmpty)
          const Text('Chưa có công bố', style: TextStyle(fontSize: 12, color: Color(0xFF999999)))
        else
          ...list.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.article, size: 14, color: Color(0xFF43A047)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      if (p['description'] != null)
                        Text(p['description'], style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
                    ],
                  ),
                ),
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
        _buildTitle('KỸ NĂNG', Icons.psychology),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: list.isEmpty
              ? ['Giảng dạy', 'Nghiên cứu', 'Quản lý lớp'].map((s) => _buildChip(s)).toList()
              : list.map((s) => _buildChip(s['name'] ?? '')).toList(),
        ),
      ],
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF2E7D32))),
    );
  }

  Widget _buildCertsSection(List<dynamic>? certs) {
    final list = certs ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle('CHỨNG CHỈ', Icons.card_membership),
        const SizedBox(height: 10),
        if (list.isEmpty)
          const Text('Chưa có', style: TextStyle(fontSize: 11, color: Color(0xFF999999)))
        else
          ...list.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                const Icon(Icons.verified, size: 12, color: Color(0xFF43A047)),
                const SizedBox(width: 6),
                Expanded(child: Text('${c['name'] ?? ''} (${c['year'] ?? ''})', style: const TextStyle(fontSize: 11))),
              ],
            ),
          )),
      ],
    );
  }

  Widget _buildAwardsSection(List<dynamic>? awards) {
    final list = awards ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle('GIẢI THƯỞNG & DANH HIỆU', Icons.emoji_events),
        const SizedBox(height: 14),
        if (list.isEmpty)
          const Text('Chưa có', style: TextStyle(fontSize: 12, color: Color(0xFF999999)))
        else
          ...list.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.military_tech, size: 14, color: Color(0xFFFFB300)),
                const SizedBox(width: 8),
                Expanded(child: Text('${a['name'] ?? ''} (${a['year'] ?? ''})', style: const TextStyle(fontSize: 12))),
              ],
            ),
          )),
      ],
    );
  }
}

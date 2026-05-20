import 'package:flutter/material.dart';

/// CV18 - Hospitality & Tourism Template
/// Mẫu CV dành cho ngành Du lịch, Nhà hàng, Khách sạn
class Cv18 extends StatelessWidget {
  final Map<String, dynamic>? data;
  final Function(String section)? onSectionTap;

  const Cv18({super.key, this.data, this.onSectionTap});

  @override
  Widget build(BuildContext context) {
    final displayData = data ?? {};
    final personalInfo = displayData['personal_info'] ?? {};

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Hospitality themed (Warm Coral + Teal)
          _buildSectionWrapper(
            'cv_name',
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF00897B), Color(0xFF26A69A)],
                ),
              ),
              child: Column(
                children: [
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
                          ? const Icon(Icons.person, size: 40, color: Colors.white70)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    personalInfo['full_name'] ?? 'NGUYỄN VĂN A',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.hotel, size: 14, color: Colors.white70),
                      const SizedBox(width: 6),
                      Text(
                        personalInfo['title'] ?? 'Quản lý khách sạn',
                        style: const TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ],
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
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              color: const Color(0xFFE0F2F1),
              child: Wrap(
                alignment: WrapAlignment.center,
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
                // Summary
                _buildSectionWrapper(
                  'summary',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitle('GIỚI THIỆU BẢN THÂN', Icons.person_outline),
                      const SizedBox(height: 10),
                      Text(
                        displayData['summary'] ?? 'Giới thiệu kinh nghiệm trong ngành dịch vụ...',
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

                // Education
                _buildSectionWrapper(
                  'education',
                  _buildEducationSection(displayData['education']),
                ),
                const SizedBox(height: 24),

                // Skills & Languages
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
                      child: Column(
                        children: [
                          _buildSectionWrapper(
                            'certifications',
                            _buildLanguagesSection(displayData['languages']),
                          ),
                          const SizedBox(height: 16),
                          _buildSectionWrapper(
                            'awards',
                            _buildAwardsSection(displayData['awards']),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Activities
                _buildSectionWrapper(
                  'activities',
                  _buildActivitiesSection(displayData['activities']),
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
        Icon(icon, size: 14, color: const Color(0xFF00897B)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF333333))),
      ],
    );
  }

  Widget _buildTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF00897B)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00897B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: const Color(0xFFB2DFDB))),
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
          _buildExpItem('Quản lý nhà hàng', 'Khách sạn 5 sao ABC', '2019 - Nay', 'Quản lý vận hành nhà hàng...')
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
        color: const Color(0xFFF5F5F5),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(position, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF00897B)))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(duration, style: const TextStyle(fontSize: 10, color: Color(0xFF00897B))),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(company, style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
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
        _buildTitle('HỌC VẤN', Icons.school_outlined),
        const SizedBox(height: 14),
        if (list.isEmpty)
          _buildEduItem('Cử nhân Quản trị Du lịch', 'ĐH Du lịch', '2015 - 2019')
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
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF26A69A)),
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
        _buildTitle('KỸ NĂNG', Icons.star_outline),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: list.isEmpty
              ? ['Giao tiếp', 'Quản lý', 'Phục vụ khách hàng'].map((s) => _buildChip(s)).toList()
              : list.map((s) => _buildChip(s['name'] ?? '')).toList(),
        ),
      ],
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2F1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF80CBC4)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF00897B))),
    );
  }

  Widget _buildLanguagesSection(List<dynamic>? languages) {
    final list = languages ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle('NGOẠI NGỮ', Icons.translate),
        const SizedBox(height: 10),
        if (list.isEmpty)
          ...[
            _buildLangItem('Tiếng Anh', 'Thành thạo'),
            _buildLangItem('Tiếng Nhật', 'Giao tiếp'),
          ]
        else
          ...list.map((l) => _buildLangItem(l['name'] ?? '', l['level'] ?? '')),
      ],
    );
  }

  Widget _buildLangItem(String name, String level) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontSize: 12)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(level, style: const TextStyle(fontSize: 10, color: Color(0xFF00897B))),
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
        _buildTitle('GIẢI THƯỞNG', Icons.emoji_events_outlined),
        const SizedBox(height: 10),
        if (list.isEmpty)
          const Text('Chưa có', style: TextStyle(fontSize: 11, color: Color(0xFF999999)))
        else
          ...list.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                const Icon(Icons.star, size: 12, color: Color(0xFFFFB300)),
                const SizedBox(width: 6),
                Expanded(child: Text('${a['name'] ?? ''} (${a['year'] ?? ''})', style: const TextStyle(fontSize: 11))),
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
        _buildTitle('HOẠT ĐỘNG NGOẠI KHÓA', Icons.volunteer_activism),
        const SizedBox(height: 14),
        if (list.isEmpty)
          const Text('Chưa có hoạt động', style: TextStyle(fontSize: 12, color: Color(0xFF999999)))
        else
          ...list.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.circle, size: 6, color: Color(0xFF26A69A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${a['organization'] ?? ''} - ${a['role'] ?? ''}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF555555)),
                  ),
                ),
              ],
            ),
          )),
      ],
    );
  }
}

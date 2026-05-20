import 'package:flutter/material.dart';

/// CV16 - Legal & Law Template
/// Mẫu CV dành cho ngành Luật, Luật sư, Cố vấn pháp lý
class Cv16 extends StatelessWidget {
  final Map<String, dynamic>? data;
  final Function(String section)? onSectionTap;

  const Cv16({super.key, this.data, this.onSectionTap});

  @override
  Widget build(BuildContext context) {
    final displayData = data ?? {};
    final personalInfo = displayData['personal_info'] ?? {};

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Law themed (Dark Navy + Gold)
          _buildSectionWrapper(
            'cv_name',
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: const BoxDecoration(
                color: Color(0xFF1B2838),
                border: Border(
                  bottom: BorderSide(color: Color(0xFFD4AF37), width: 3),
                ),
              ),
              child: Row(
                children: [
                  _buildSectionWrapper(
                    'avatar',
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFD4AF37), width: 2),
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
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.gavel, size: 14, color: Color(0xFFD4AF37)),
                            const SizedBox(width: 6),
                            Text(
                              personalInfo['title'] ?? 'Luật sư',
                              style: const TextStyle(fontSize: 13, color: Color(0xFFD4AF37)),
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
              color: const Color(0xFFF5F5DC),
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
                // Professional Summary
                _buildSectionWrapper(
                  'summary',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitle('TÓM TẮT CHUYÊN MÔN'),
                      const SizedBox(height: 10),
                      Text(
                        displayData['summary'] ?? 'Tóm tắt kinh nghiệm và chuyên môn pháp lý...',
                        style: const TextStyle(fontSize: 13, height: 1.7, color: Color(0xFF333333)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Legal Experience
                _buildSectionWrapper(
                  'experiences',
                  _buildExperienceSection(displayData['experiences']),
                ),
                const SizedBox(height: 24),

                // Education & Bar Admission
                _buildSectionWrapper(
                  'education',
                  _buildEducationSection(displayData['education']),
                ),
                const SizedBox(height: 24),

                // Notable Cases (projects)
                _buildSectionWrapper(
                  'projects',
                  _buildCasesSection(displayData['projects']),
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
        Icon(icon, size: 14, color: const Color(0xFF1B2838)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF333333))),
      ],
    );
  }

  Widget _buildTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFFD4AF37),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B2838),
            letterSpacing: 1,
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
        _buildTitle('KINH NGHIỆM PHÁP LÝ'),
        const SizedBox(height: 14),
        if (list.isEmpty)
          _buildExpItem('Luật sư chính', 'Công ty Luật ABC', '2018 - Nay', 'Tư vấn pháp lý doanh nghiệp...')
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
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(4),
        color: const Color(0xFFFAFAFA),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(position, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B2838)))),
              Text(duration, style: const TextStyle(fontSize: 11, color: Color(0xFFD4AF37))),
            ],
          ),
          Text(company, style: const TextStyle(fontSize: 12, color: Color(0xFF666666), fontStyle: FontStyle.italic)),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(desc, style: const TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF444444))),
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
        _buildTitle('HỌC VẤN & CHỨNG NHẬN HÀNH NGHỀ'),
        const SizedBox(height: 14),
        if (list.isEmpty)
          _buildEduItem('Cử nhân Luật', 'Đại học Luật TP.HCM', '2012 - 2016')
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
          const Icon(Icons.school, size: 16, color: Color(0xFF1B2838)),
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

  Widget _buildCasesSection(List<dynamic>? projects) {
    final list = projects ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle('VỤ VIỆC TIÊU BIỂU'),
        const SizedBox(height: 14),
        if (list.isEmpty)
          const Text('Chưa có vụ việc tiêu biểu', style: TextStyle(fontSize: 12, color: Color(0xFF999999)))
        else
          ...list.map((p) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.gavel, size: 12, color: Color(0xFFD4AF37)),
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
          )),
      ],
    );
  }

  Widget _buildSkillsSection(List<dynamic>? skills) {
    final list = skills ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle('LĨNH VỰC CHUYÊN MÔN'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: list.isEmpty
              ? ['Luật Doanh nghiệp', 'Luật Dân sự', 'Tố tụng'].map((s) => _buildChip(s)).toList()
              : list.map((s) => _buildChip(s['name'] ?? '')).toList(),
        ),
      ],
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5DC),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF1B2838))),
    );
  }

  Widget _buildCertsSection(List<dynamic>? certs) {
    final list = certs ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle('CHỨNG CHỈ'),
        const SizedBox(height: 10),
        if (list.isEmpty)
          const Text('Chưa có', style: TextStyle(fontSize: 11, color: Color(0xFF999999)))
        else
          ...list.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                const Icon(Icons.verified, size: 12, color: Color(0xFFD4AF37)),
                const SizedBox(width: 6),
                Expanded(child: Text('${c['name'] ?? ''} (${c['year'] ?? ''})', style: const TextStyle(fontSize: 11))),
              ],
            ),
          )),
      ],
    );
  }
}

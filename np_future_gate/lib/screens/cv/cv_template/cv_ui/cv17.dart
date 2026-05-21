import 'package:flutter/material.dart';

/// CV17 - Engineering Template
/// Mẫu CV dành cho ngành Kỹ thuật, Xây dựng, Cơ khí
class Cv17 extends StatelessWidget {

  const Cv17({super.key, this.data, this.onSectionTap});
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
          // Header - Engineering themed (Steel Blue + Orange accent)
          _buildSectionWrapper(
            'cv_name',
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF37474F), Color(0xFF455A64)],
                ),
              ),
              child: Column(
                children: [
                  _buildSectionWrapper(
                    'avatar',
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFF6D00), width: 3),
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
                          ? const Icon(Icons.engineering, size: 36, color: Colors.white70)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6D00),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      personalInfo['title'] ?? 'Kỹ sư xây dựng',
                      style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
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
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
              color: const Color(0xFFECEFF1),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 20,
                runSpacing: 6,
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary
                _buildSectionWrapper(
                  'summary',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitle('MỤC TIÊU NGHỀ NGHIỆP', Icons.flag),
                      const SizedBox(height: 10),
                      Text(
                        displayData['summary'] ?? 'Mục tiêu nghề nghiệp trong lĩnh vực kỹ thuật...',
                        style: const TextStyle(fontSize: 13, height: 1.7, color: Color(0xFF444444)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Experience
                _buildSectionWrapper(
                  'experiences',
                  _buildExperienceSection(displayData['experiences']),
                ),
                const SizedBox(height: 22),

                // Projects (Engineering Projects)
                _buildSectionWrapper(
                  'projects',
                  _buildProjectsSection(displayData['projects']),
                ),
                const SizedBox(height: 22),

                // Education
                _buildSectionWrapper(
                  'education',
                  _buildEducationSection(displayData['education']),
                ),
                const SizedBox(height: 22),

                // Technical Skills & Certifications
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
        Icon(icon, size: 14, color: const Color(0xFF37474F)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF333333))),
      ],
    );
  }

  Widget _buildTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6D00),
            borderRadius: BorderRadius.circular(4),
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
              color: Color(0xFF37474F),
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
        _buildTitle('KINH NGHIỆM LÀM VIỆC', Icons.work),
        const SizedBox(height: 14),
        if (list.isEmpty)
          _buildExpItem('Kỹ sư xây dựng', 'Công ty XD ABC', '2019 - Nay', 'Giám sát thi công công trình...')
        else
          ...list.map((e) => _buildExpItem(
            e['position'] ?? '', e['company'] ?? '', e['duration'] ?? '', e['description'] ?? '',
          )),
      ],
    );
  }

  Widget _buildExpItem(String position, String company, String duration, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCFD8DC)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(position, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF37474F)))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6D00).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(duration, style: const TextStyle(fontSize: 10, color: Color(0xFFFF6D00))),
              ),
            ],
          ),
          Text(company, style: const TextStyle(fontSize: 11, color: Color(0xFF78909C))),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(desc, style: const TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF555555))),
          ],
        ],
      ),
    );
  }

  Widget _buildProjectsSection(List<dynamic>? projects) {
    final list = projects ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle('DỰ ÁN KỸ THUẬT', Icons.construction),
        const SizedBox(height: 14),
        if (list.isEmpty)
          const Text('Chưa có dự án', style: TextStyle(fontSize: 12, color: Color(0xFF999999)))
        else
          ...list.map((p) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.architecture, size: 14, color: Color(0xFFFF6D00)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                  ],
                ),
                if (p['description'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(p['description'], style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
                  ),
                if (p['technologies'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Công nghệ: ${p['technologies']}', style: const TextStyle(fontSize: 10, color: Color(0xFFFF6D00))),
                  ),
              ],
            ),
          )),
      ],
    );
  }

  Widget _buildEducationSection(List<dynamic>? education) {
    final list = education ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle('HỌC VẤN', Icons.school),
        const SizedBox(height: 14),
        if (list.isEmpty)
          _buildEduItem('Kỹ sư Xây dựng', 'ĐH Bách Khoa', '2014 - 2019')
        else
          ...list.map((e) => _buildEduItem(e['degree'] ?? '', e['school'] ?? '', e['year'] ?? '')),
      ],
    );
  }

  Widget _buildEduItem(String degree, String school, String year) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFF6D00))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(degree, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                Text('$school • $year', style: const TextStyle(fontSize: 11, color: Color(0xFF78909C))),
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
        _buildTitle('KỸ NĂNG KỸ THUẬT', Icons.build),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: list.isEmpty
              ? ['AutoCAD', 'SAP2000', 'MS Project'].map((s) => _buildChip(s)).toList()
              : list.map((s) => _buildChip(s['name'] ?? '')).toList(),
        ),
      ],
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFECEFF1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFCFD8DC)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF37474F))),
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
                const Icon(Icons.verified, size: 12, color: Color(0xFFFF6D00)),
                const SizedBox(width: 6),
                Expanded(child: Text('${c['name'] ?? ''} (${c['year'] ?? ''})', style: const TextStyle(fontSize: 11))),
              ],
            ),
          )),
      ],
    );
  }
}

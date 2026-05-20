import 'package:flutter/material.dart';

/// CV10 - Elegant Minimalist Template
/// Mẫu CV tối giản sang trọng với typography đẹp và khoảng trắng hài hòa
class Cv10 extends StatelessWidget {
  final Map<String, dynamic>? data;
  final Function(String section)? onSectionTap;

  const Cv10({super.key, this.data, this.onSectionTap});

  @override
  Widget build(BuildContext context) {
    final displayData = data ?? {};
    final personalInfo = displayData['personal_info'] ?? {};

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Name & Title
          _buildSectionWrapper(
            'cv_name',
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  (personalInfo['full_name'] ?? 'NGUYỄN VĂN A').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 6,
                    color: Color(0xFF2C3E50),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  width: 60,
                  height: 2,
                  color: const Color(0xFFBDC3C7),
                ),
                const SizedBox(height: 8),
                Text(
                  personalInfo['title'] ?? 'Chuyên viên',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 3,
                    color: Color(0xFF7F8C8D),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Contact Info Row
          _buildSectionWrapper(
            'personal_info',
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFECF0F1), width: 1),
                  bottom: BorderSide(color: Color(0xFFECF0F1), width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildContactItem(Icons.email_outlined, personalInfo['email'] ?? 'email@example.com'),
                  _buildContactItem(Icons.phone_outlined, personalInfo['phone'] ?? '0123456789'),
                  _buildContactItem(Icons.location_on_outlined, personalInfo['address'] ?? 'TP. Hồ Chí Minh'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Summary
          _buildSectionWrapper(
            'summary',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('GIỚI THIỆU'),
                const SizedBox(height: 12),
                Text(
                  displayData['summary'] ?? 'Mô tả ngắn gọn về bản thân, kinh nghiệm và mục tiêu nghề nghiệp...',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.8,
                    color: Color(0xFF555555),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Experience
          _buildSectionWrapper(
            'experiences',
            _buildExperienceSection(displayData['experiences']),
          ),
          const SizedBox(height: 28),

          // Education
          _buildSectionWrapper(
            'education',
            _buildEducationSection(displayData['education']),
          ),
          const SizedBox(height: 28),

          // Skills
          _buildSectionWrapper(
            'skills',
            _buildSkillsSection(displayData['skills']),
          ),
          const SizedBox(height: 28),

          // Certifications
          _buildSectionWrapper(
            'certifications',
            _buildCertificationsSection(displayData['certifications']),
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

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(height: 1, color: const Color(0xFFECF0F1)),
        ),
      ],
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF7F8C8D)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 11, color: Color(0xFF555555)),
        ),
      ],
    );
  }

  Widget _buildExperienceSection(List<dynamic>? experiences) {
    final list = experiences ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('KINH NGHIỆM'),
        const SizedBox(height: 16),
        if (list.isEmpty)
          _buildExperienceItem('Senior Developer', 'Công ty ABC', '2020 - Nay', 'Phát triển ứng dụng mobile...')
        else
          ...list.map((e) => _buildExperienceItem(
            e['position'] ?? '', e['company'] ?? '', e['duration'] ?? '', e['description'] ?? '',
          )),
      ],
    );
  }

  Widget _buildExperienceItem(String position, String company, String duration, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              duration,
              style: const TextStyle(fontSize: 11, color: Color(0xFF95A5A6)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(position, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF2C3E50))),
                const SizedBox(height: 2),
                Text(company, style: const TextStyle(fontSize: 12, color: Color(0xFF7F8C8D), fontStyle: FontStyle.italic)),
                const SizedBox(height: 6),
                Text(description, style: const TextStyle(fontSize: 12, height: 1.6, color: Color(0xFF555555))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationSection(List<dynamic>? education) {
    final list = education ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('HỌC VẤN'),
        const SizedBox(height: 16),
        if (list.isEmpty)
          _buildEducationItem('Cử nhân CNTT', 'Đại học Bách Khoa', '2015 - 2019')
        else
          ...list.map((e) => _buildEducationItem(e['degree'] ?? '', e['school'] ?? '', e['year'] ?? '')),
      ],
    );
  }

  Widget _buildEducationItem(String degree, String school, String year) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(year, style: const TextStyle(fontSize: 11, color: Color(0xFF95A5A6))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(degree, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF2C3E50))),
                Text(school, style: const TextStyle(fontSize: 12, color: Color(0xFF7F8C8D))),
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
        _buildSectionTitle('KỸ NĂNG'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: list.isEmpty
              ? ['Flutter', 'Dart', 'Firebase'].map((s) => _buildSkillChip(s)).toList()
              : list.map((s) => _buildSkillChip(s['name'] ?? '')).toList(),
        ),
      ],
    );
  }

  Widget _buildSkillChip(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFBDC3C7)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        skill,
        style: const TextStyle(fontSize: 11, color: Color(0xFF2C3E50)),
      ),
    );
  }

  Widget _buildCertificationsSection(List<dynamic>? certifications) {
    final list = certifications ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('CHỨNG CHỈ'),
        const SizedBox(height: 16),
        if (list.isEmpty)
          const Text('Chưa có chứng chỉ', style: TextStyle(fontSize: 12, color: Color(0xFF95A5A6)))
        else
          ...list.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.verified_outlined, size: 14, color: Color(0xFF2C3E50)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${c['name'] ?? ''} - ${c['issuer'] ?? ''} (${c['year'] ?? ''})',
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

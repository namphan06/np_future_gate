import 'package:flutter/material.dart';

/// CV12 - Classic Timeline Template
/// Mẫu CV dòng thời gian cổ điển, rõ ràng và chuyên nghiệp
class Cv12 extends StatelessWidget {
  final Map<String, dynamic>? data;
  final Function(String section)? onSectionTap;

  const Cv12({super.key, this.data, this.onSectionTap});

  @override
  Widget build(BuildContext context) {
    final displayData = data ?? {};
    final personalInfo = displayData['personal_info'] ?? {};

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with dark background
          _buildSectionWrapper(
            'cv_name',
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 32),
              color: const Color(0xFF1A1A2E),
              child: Row(
                children: [
                  // Avatar
                  _buildSectionWrapper(
                    'avatar',
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE94560), width: 3),
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
                          ? const Icon(Icons.person, size: 36, color: Colors.white70)
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
                        Text(
                          personalInfo['title'] ?? 'Chuyên viên',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFFE94560),
                            fontWeight: FontWeight.w500,
                          ),
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
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
              color: const Color(0xFF16213E),
              child: Wrap(
                spacing: 24,
                runSpacing: 8,
                children: [
                  _buildContactItem(Icons.email_outlined, personalInfo['email'] ?? 'email@example.com'),
                  _buildContactItem(Icons.phone_outlined, personalInfo['phone'] ?? '0123456789'),
                  _buildContactItem(Icons.location_on_outlined, personalInfo['address'] ?? 'TP.HCM'),
                  if (personalInfo['website'] != null && personalInfo['website'].toString().isNotEmpty)
                    _buildContactItem(Icons.link, personalInfo['website']),
                ],
              ),
            ),
          ),

          // Body with Timeline
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary
                _buildSectionWrapper(
                  'summary',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTimelineHeader('MỤC TIÊU NGHỀ NGHIỆP'),
                      const SizedBox(height: 12),
                      Text(
                        displayData['summary'] ?? 'Mô tả mục tiêu nghề nghiệp...',
                        style: const TextStyle(fontSize: 13, height: 1.7, color: Color(0xFF444444)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Experience Timeline
                _buildSectionWrapper(
                  'experiences',
                  _buildTimelineExperience(displayData['experiences']),
                ),
                const SizedBox(height: 28),

                // Education Timeline
                _buildSectionWrapper(
                  'education',
                  _buildTimelineEducation(displayData['education']),
                ),
                const SizedBox(height: 28),

                // Skills
                _buildSectionWrapper(
                  'skills',
                  _buildSkillsSection(displayData['skills']),
                ),
                const SizedBox(height: 28),

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

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFFE94560)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }

  Widget _buildTimelineHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFFE94560),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineExperience(List<dynamic>? experiences) {
    final list = experiences ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTimelineHeader('KINH NGHIỆM LÀM VIỆC'),
        const SizedBox(height: 16),
        if (list.isEmpty)
          _buildTimelineItem('Senior Developer', 'Công ty ABC', '2020 - Nay', 'Phát triển ứng dụng mobile...', true)
        else
          ...list.asMap().entries.map((entry) => _buildTimelineItem(
            entry.value['position'] ?? '',
            entry.value['company'] ?? '',
            entry.value['duration'] ?? '',
            entry.value['description'] ?? '',
            entry.key == list.length - 1,
          )),
      ],
    );
  }

  Widget _buildTimelineItem(String title, String subtitle, String duration, String desc, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE94560),
                  border: Border.all(color: const Color(0xFF1A1A2E), width: 2),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFFE94560).withOpacity(0.3),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                      Text(duration, style: const TextStyle(fontSize: 11, color: Color(0xFFE94560))),
                    ],
                  ),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF666666), fontStyle: FontStyle.italic)),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(desc, style: const TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF555555))),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineEducation(List<dynamic>? education) {
    final list = education ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTimelineHeader('HỌC VẤN'),
        const SizedBox(height: 16),
        if (list.isEmpty)
          _buildTimelineItem('Cử nhân CNTT', 'Đại học Bách Khoa', '2015 - 2019', '', true)
        else
          ...list.asMap().entries.map((entry) => _buildTimelineItem(
            entry.value['degree'] ?? '',
            entry.value['school'] ?? '',
            entry.value['year'] ?? '',
            entry.value['detail'] ?? '',
            entry.key == list.length - 1,
          )),
      ],
    );
  }

  Widget _buildSkillsSection(List<dynamic>? skills) {
    final list = skills ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTimelineHeader('KỸ NĂNG'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: list.isEmpty
              ? ['Flutter', 'Dart', 'Firebase'].map((s) => _buildSkillTag(s)).toList()
              : list.map((s) => _buildSkillTag(s['name'] ?? '')).toList(),
        ),
      ],
    );
  }

  Widget _buildSkillTag(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(skill, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildActivitiesSection(List<dynamic>? activities) {
    final list = activities ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTimelineHeader('HOẠT ĐỘNG'),
        const SizedBox(height: 16),
        if (list.isEmpty)
          const Text('Chưa có hoạt động', style: TextStyle(fontSize: 12, color: Color(0xFF999999)))
        else
          ...list.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.circle, size: 6, color: Color(0xFFE94560)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a['organization'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text('${a['role'] ?? ''} • ${a['duration'] ?? ''}', style: const TextStyle(fontSize: 11, color: Color(0xFF777777))),
                    ],
                  ),
                ),
              ],
            ),
          )),
      ],
    );
  }
}

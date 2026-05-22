import 'package:flutter/material.dart';

class Cv2 extends StatelessWidget {

  const Cv2({
    super.key,
    this.data,
    this.onSectionTap,
  });
  final Map<String, dynamic>? data;
  final Function(String section)? onSectionTap;

  @override
  Widget build(BuildContext context) {
    final displayData = data ?? {};
    final personalInfo = displayData['personal_info'] ?? {};

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header: Name and Title (Centered, Blue Theme)
          _buildSectionWrapper(
            'cv_name',
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[800],
                borderRadius: BorderRadius.circular(8),
              ),
              width: double.infinity,
              child: Column(
                children: [
                  Text(
                    personalInfo['full_name'] ?? 'NGUYỄN VĂN B',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (personalInfo['title'] ?? 'Lập trình viên Flutter').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Two Column Layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column (Main Content) - 60%
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionWrapper(
                      'summary',
                      _buildSectionTitle('GIỚI THIỆU', Icons.person),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 20),
                      child: Text(
                        displayData['summary'] ?? 'Mô tả ngắn gọn về bản thân và mục tiêu nghề nghiệp...',
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ),

                    _buildSectionWrapper(
                      'experiences',
                      _buildExperienceSection(displayData['experiences']),
                    ),
                    
                    _buildSectionWrapper(
                      'projects',
                      _buildProjectSection(displayData['projects']),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 20),

              // Right Column (Sidebar info) - 40%
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionWrapper(
                        'avatar',
                        Center(
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.blue[200],
                            backgroundImage: personalInfo['avatar_url'] != null &&
                                    personalInfo['avatar_url']
                                        .toString()
                                        .isNotEmpty
                                ? NetworkImage(personalInfo['avatar_url'])
                                : null,
                            child: personalInfo['avatar_url'] == null ||
                                    personalInfo['avatar_url']
                                        .toString()
                                        .isEmpty
                                ? const Icon(Icons.person,
                                    size: 60, color: Colors.white)
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      _buildSectionWrapper(
                        'personal_info',
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(Icons.email, personalInfo['email'] ?? 'email@example.com'),
                            _buildInfoRow(Icons.phone, personalInfo['phone'] ?? '0987654321'),
                            _buildInfoRow(Icons.location_on, personalInfo['address'] ?? 'Hồ Chí Minh'),
                            _buildInfoRow(Icons.link, personalInfo['website'] ?? 'linkedin.com/in/b'),
                          ],
                        ),
                      ),
                      const Divider(height: 30),

                      _buildSectionWrapper(
                        'education',
                        _buildEducationSection(displayData['education']),
                      ),
                      const Divider(height: 30),

                      _buildSectionWrapper(
                        'skills',
                        _buildSkillsSection(displayData['skills']),
                      ),
                    ],
                  ),
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
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.transparent, width: 1),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[800], size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceSection(List<dynamic>? experiences) {
    final list = experiences ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('KINH NGHIỆM', Icons.work),
        if (list.isEmpty)
          _buildExperienceItem(
            'Công ty ABC',
            'Senior Developer',
            '2020 - Hiện tại',
            'Phát triển ứng dụng mobile...',
          )
        else
          ...list.map((e) => _buildExperienceItem(
            e['company'] ?? '',
            e['position'] ?? '',
            e['duration'] ?? '',
            e['description'] ?? '',
          )),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildExperienceItem(String company, String position, String duration, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            position,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  company, 
                  style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w500),
                  softWrap: true,
                ),
              ),
              const SizedBox(width: 8),
              Text(duration, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildProjectSection(List<dynamic>? projects) {
    final list = projects ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('DỰ ÁN', Icons.folder),
        if (list.isEmpty)
           const Padding(
             padding: EdgeInsets.only(left: 8),
             child: Text('Chưa có dự án nào.'),
           )
        else
          ...list.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p['name'] ?? 'Project Name', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(p['description'] ?? '', style: const TextStyle(fontSize: 13)),
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
        const Text(
          'HỌC VẤN',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 10),
        if (list.isEmpty)
          const Text('Đại học Công Nghệ\nCử nhân CNTT\n2015 - 2019', style: TextStyle(fontSize: 13))
        else
          ...list.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e['school'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(e['degree'] ?? '', style: const TextStyle(fontSize: 13)),
                Text(e['year'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
        const Text(
          'KỸ NĂNG',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: list.isEmpty 
            ? [const Chip(label: Text('Flutter')), const Chip(label: Text('Dart'))]
            : list.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Text(
                  s['name'] ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                ),
              )).toList(),
        ),
      ],
    );
  }
}

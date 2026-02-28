import 'package:flutter/material.dart';

class Cv4 extends StatelessWidget {
  final Map<String, dynamic>? data;
  final Function(String section)? onSectionTap;

  const Cv4({
    super.key,
    this.data,
    this.onSectionTap,
  });

  // Local color constants to match the original template's theme
  static const Color orangeTheme = Color(0xFFEC8F00);
  static const Color darkTheme = Color(0xFF353A3D);
  static const Color lightText = Colors.white70;

  @override
  Widget build(BuildContext context) {
    // Default data for preview if no data provided
    final displayData = data ?? {};
    final personalInfo = displayData['personal_info'] ?? {};
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      child: SingleChildScrollView(
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Column (Sidebar)
              Container(
                width: 140, // 36% of typical screen width would be around 130-150
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: darkTheme),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    _buildSectionWrapper(
                      'avatar',
                      Center(
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            border: Border.all(color: orangeTheme, width: 2),
                          ),
                          child: personalInfo['avatar_url'] != null &&
                                  personalInfo['avatar_url'].toString().isNotEmpty
                              ? Image.network(
                                  personalInfo['avatar_url'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.person, size: 60, color: Colors.white),
                                )
                              : const Icon(Icons.person, size: 60, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    // Name and Title
                    _buildSectionWrapper(
                      'cv_name',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            personalInfo['full_name'] ?? "Nguyễn Văn A",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: orangeTheme,
                                fontSize: 18),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            (personalInfo['title'] ?? "Kỹ sư phần mềm").toUpperCase(),
                            style: const TextStyle(
                                color: orangeTheme,
                                fontWeight: FontWeight.bold,
                                fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Divider(thickness: 1, color: orangeTheme),
                    const SizedBox(height: 10),
                    
                    // Contact Info
                    _buildSectionWrapper(
                      'personal_details',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildContactRow(Icons.phone, personalInfo['phone'] ?? "0123 456 789"),
                          const SizedBox(height: 12),
                          _buildContactRow(Icons.mail, personalInfo['email'] ?? "email@example.com"),
                          const SizedBox(height: 12),
                          if (personalInfo['website'] != null) ...[
                            _buildContactRow(Icons.info, personalInfo['website']),
                            const SizedBox(height: 12),
                          ],
                          _buildContactRow(Icons.location_on, personalInfo['address'] ?? "Hà Nội"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    
                    // Skills (Sidebar)
                    _buildSectionWrapper(
                      'skills',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitleInSidebar('CÁC KỸ NĂNG'),
                          const SizedBox(height: 10),
                          _buildSkills(displayData['skills']),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Interests (Sở thích)
                    _buildSectionWrapper(
                      'interests',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitleInSidebar('SỞ THÍCH'),
                          const SizedBox(height: 10),
                          Text(
                            displayData['interests'] ?? 'Teambuilding, ca hát, văn nghệ, thể thao.',
                            style: const TextStyle(color: lightText, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // References (Người giới thiệu)
                    _buildSectionWrapper(
                      'references',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitleInSidebar('NGƯỜI GIỚI THIỆU'),
                          const SizedBox(height: 10),
                          _buildReferences(displayData['references']),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 15),
              
              // Right Column (Main content)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary (Mục tiêu nghề nghiệp)
                    _buildSectionWrapper(
                      'summary',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMainSectionTitle('MỤC TIÊU NGHỀ NGHIỆP'),
                          const SizedBox(height: 10),
                          Text(
                            displayData['summary'] ?? "Bản tóm tắt mục tiêu nghề nghiệp của bạn...",
                            style: const TextStyle(fontSize: 13, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Experience (Kinh nghiệm)
                    _buildSectionWrapper(
                      'experiences',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMainSectionTitle('KINH NGHIỆM LÀM VIỆC'),
                          const SizedBox(height: 10),
                          _buildExperienceSection(displayData['experiences']),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Education (Học vấn)
                    _buildSectionWrapper(
                      'education',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMainSectionTitle('HỌC VẤN'),
                          const SizedBox(height: 10),
                          _buildEducationSection(displayData['education']),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Awards (Danh hiệu và giải thưởng)
                    _buildSectionWrapper(
                      'awards',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMainSectionTitle('DANH HIỆU VÀ GIẢI THƯỞNG'),
                          const SizedBox(height: 10),
                          _buildAwardsSection(displayData['awards']),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Certifications (Chứng chỉ)
                    _buildSectionWrapper(
                      'certifications',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMainSectionTitle('CHỨNG CHỈ'),
                          const SizedBox(height: 10),
                          _buildCertificationsSection(displayData['certifications']),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Activities (Hoạt động)
                    _buildSectionWrapper(
                      'activities',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMainSectionTitle('HOẠT ĐỘNG'),
                          const SizedBox(height: 10),
                          _buildActivitiesSection(displayData['activities']),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
        child: Container(child: child),
      ),
    );
  }

  Widget _buildMainSectionTitle(String title) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: orangeTheme),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          flex: 3,
          child: Divider(thickness: 1, color: orangeTheme),
        ),
      ],
    );
  }

  Widget _buildSectionTitleInSidebar(String title) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: orangeTheme),
          ),
        ),
        const SizedBox(width: 5),
        const Expanded(
          child: Divider(thickness: 1, color: orangeTheme),
        ),
      ],
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: orangeTheme, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: lightText, fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildSkills(List<dynamic>? skills) {
    final list = skills ?? [];
    if (list.isEmpty) {
      return const Text(
        "- Kỹ năng chuyên môn\n- Kỹ năng mềm",
        style: TextStyle(color: lightText, fontSize: 12),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: list.map((s) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          "- ${s['name'] ?? ""}",
          style: const TextStyle(color: lightText, fontSize: 11),
        ),
      )).toList(),
    );
  }

  Widget _buildReferences(List<dynamic>? refs) {
    final list = refs ?? [];
    if (list.isEmpty) {
      return const Text(
        "Ông Nguyễn Văn A\nCEO công ty A",
        style: TextStyle(color: lightText, fontSize: 11),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: list.map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          "${r['name'] ?? ""}\n${r['position'] ?? ""}\n${r['phone'] ?? ""}",
          style: const TextStyle(color: lightText, fontSize: 11),
        ),
      )).toList(),
    );
  }

  Widget _buildExperienceSection(List<dynamic>? experiences) {
    final list = experiences ?? [];
    if (list.isEmpty) {
      return _buildDetailItem(
        "Kinh nghiệm mẫu",
        "2023 - 2024",
        "Công ty ABC",
        "- Mô tả trách nhiệm công việc của bạn...",
      );
    }
    return Column(
      children: list.map((e) => _buildDetailItem(
        e['position'] ?? "",
        e['duration'] ?? "",
        e['company'] ?? "",
        e['description'] ?? "",
      )).toList(),
    );
  }

  Widget _buildEducationSection(List<dynamic>? education) {
    final list = education ?? [];
    if (list.isEmpty) {
      return _buildDetailItem(
        "Chuyên ngành học của bạn",
        "2018 - 2022",
        "Đại học X",
        "- Tốt nghiệp loại khá/giỏi...",
      );
    }
    return Column(
      children: list.map((e) => _buildDetailItem(
        e['degree'] ?? "",
        e['year'] ?? "",
        e['school'] ?? "",
        "", // no specific note list for education in original, but degree can be major
      )).toList(),
    );
  }

  Widget _buildActivitiesSection(List<dynamic>? activities) {
    final list = activities ?? [];
    if (list.isEmpty) return const SizedBox();
    return Column(
      children: list.map((a) => _buildDetailItem(
        a['role'] ?? "",
        a['duration'] ?? "",
        a['organization'] ?? "",
        a['description'] ?? "",
      )).toList(),
    );
  }

  Widget _buildDetailItem(String title, String date, String subtitle, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: darkTheme),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                date,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: darkTheme),
              ),
            ],
          ),
          Text(
            subtitle,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF666666)),
          ),
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                description,
                style: const TextStyle(fontSize: 12, color: darkTheme),
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
      children: list.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['year'] ?? "",
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: darkTheme),
              ),
              Text(
                item['name'] ?? "",
                style: const TextStyle(fontSize: 12, color: darkTheme),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCertificationsSection(List<dynamic>? certs) {
    final list = certs ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: list.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['year'] ?? "",
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: darkTheme),
              ),
              Text(
                item['name'] ?? "",
                style: const TextStyle(fontSize: 12, color: darkTheme),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

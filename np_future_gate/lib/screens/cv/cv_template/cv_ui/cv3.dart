import 'package:flutter/material.dart';

class Cv3 extends StatelessWidget {
  final Map<String, dynamic>? data;
  final Function(String section)? onSectionTap;

  const Cv3({
    super.key,
    this.data,
    this.onSectionTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayData = data ?? {};
    final personalInfo = displayData['personal_info'] ?? {};

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name and Title (Tech Style)
          _buildSectionWrapper(
            'cv_name',
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2D3748), // Dark slate
                borderRadius: BorderRadius.circular(8),
              ),
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (personalInfo['full_name'] ?? "NGUYỄN VĂN C").toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            fontFamily: 'Courier', // Monospace for tech feel
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          (personalInfo['title'] ?? "Senior Software Engineer").toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF63B3ED), // Light blue
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Courier',
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Avatar if available
                  if (personalInfo['avatar_url'] != null && personalInfo['avatar_url'].isNotEmpty)
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(personalInfo['avatar_url']),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Contact Info Bar
          _buildSectionWrapper(
            'personal_info',
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Wrap(
                spacing: 20,
                runSpacing: 10,
                children: [
                  _buildContactItem(Icons.email, personalInfo['email'] ?? "email@example.com"),
                  _buildContactItem(Icons.phone, personalInfo['phone'] ?? "0987654321"),
                  _buildContactItem(Icons.location_on, personalInfo['address'] ?? "Hồ Chí Minh"),
                  _buildContactItem(Icons.link, personalInfo['website'] ?? "github.com/username"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Main Content: Skills first for Tech CV
          _buildSectionWrapper(
            'skills',
            _buildSkillsSection(displayData['skills']),
          ),
          const Divider(height: 40),

          // Experience
          _buildSectionWrapper(
            'experiences',
            _buildExperienceSection(displayData['experiences']),
          ),
          const Divider(height: 40),

          // Projects
          _buildSectionWrapper(
            'projects',
            _buildProjectSection(displayData['projects']),
          ),
          const Divider(height: 40),

          // Education
          _buildSectionWrapper(
            'education',
            _buildEducationSection(displayData['education']),
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

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF4A5568)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 14, color: Color(0xFF2D3748), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2D3748),
          letterSpacing: 1.0,
          // border: Border(bottom: BorderSide(color: Color(0xFF63B3ED), width: 3)),
        ),
      ),
    );
  }

  Widget _buildSkillsSection(List<dynamic>? skills) {
    final list = skills ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Technical Skills"),
        if (list.isEmpty)
          const Text("Flutter, Dart, Firebase, Git, CI/CD, Clean Architecture")
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: list.map((s) => Chip(
              label: Text(s['name'] ?? ""),
              backgroundColor: const Color(0xFFEBF8FF),
              labelStyle: const TextStyle(color: Color(0xFF2C5282), fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            )).toList(),
          ),
      ],
    );
  }

  Widget _buildExperienceSection(List<dynamic>? experiences) {
    final list = experiences ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Work Experience"),
        if (list.isEmpty)
          _buildExperienceItem(
            "Tech Corp",
            "Senior Developer",
            "2020 - Present",
            "• Led a team of 5 developers.\n• Architected the new mobile app using Flutter.\n• Improved app performance by 40%.",
          )
        else
          ...list.map((e) => _buildExperienceItem(
            e['company'] ?? "",
            e['position'] ?? "",
            e['duration'] ?? "",
            e['description'] ?? "",
          )).toList(),
      ],
    );
  }

  Widget _buildExperienceItem(String company, String position, String duration, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline / Date column
          SizedBox(
            width: 120,
            child: Text(
              duration,
              style: const TextStyle(
                color: Color(0xFF718096),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          // Content column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  position,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  company,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF3182CE), // Blue
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF4A5568)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectSection(List<dynamic>? projects) {
    final list = projects ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Key Projects"),
        if (list.isEmpty)
          const Text("No projects listed.")
        else
          ...list.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p['name'] ?? "Project Name",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  p['description'] ?? "",
                  style: const TextStyle(fontSize: 14, color: Color(0xFF4A5568)),
                ),
              ],
            ),
          )).toList(),
      ],
    );
  }

  Widget _buildEducationSection(List<dynamic>? education) {
    final list = education ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Education"),
        if (list.isEmpty)
          const Text("University of Technology - BS in Computer Science (2015-2019)")
        else
          ...list.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e['school'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(e['degree'] ?? "", style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                Text(e['year'] ?? "", style: const TextStyle(color: Color(0xFF718096), fontWeight: FontWeight.bold)),
              ],
            ),
          )).toList(),
      ],
    );
  }
}

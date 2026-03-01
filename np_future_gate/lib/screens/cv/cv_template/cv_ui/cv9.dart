import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Cv9 extends StatelessWidget {
  final Map<String, dynamic>? data;
  final Function(String section)? onSectionTap;

  const Cv9({
    super.key,
    this.data,
    this.onSectionTap,
  });

  // Medical Theme: Sterile, Professional, Patient-Focused
  static const Color primaryColor = Color(0xFF00796B); // Medical Teal
  static const Color secondaryColor = Color(0xFF0097A7); // Soft Cyan
  static const Color accentColor = Color(0xFFE0F2F1); // Light Mint
  static const Color textColor = Color(0xFF37474F);
  static const Color lightGray = Color(0xFFECEFF1);
  static const Color bgColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    final displayData = data ?? {};
    final personalInfo = displayData['personal_info'] ?? {};

    return Theme(
      data: ThemeData(
        textTheme: GoogleFonts.merriweatherTextTheme(),
      ),
      child: Container(
        color: bgColor,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isNarrow = constraints.maxWidth < 600;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Medical Header
                  _buildHeader(personalInfo, isNarrow),

                  // 2. Main Content
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isNarrow ? 20 : 40, vertical: 50),
                    child: isNarrow 
                      ? _buildNarrowContent(displayData, personalInfo)
                      : _buildWideContent(displayData, personalInfo),
                  ),
                ],
              ),
            );
          }
        ),
      ),
    );
  }

  Widget _buildWideContent(Map<String, dynamic> displayData, Map<String, dynamic> personalInfo) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Primary clinical info
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionWrapper('summary', _buildMainSection('CLINICAL SUMMARY', Text(
                displayData['summary'] ?? "Dedicated medical professional with extensive experience in patient care and clinical research. Committed to providing evidence-based treatment and improving patient outcomes.",
                style: GoogleFonts.lato(fontSize: 14, height: 1.8, color: textColor),
              ))),
              const SizedBox(height: 50),
              _buildSectionWrapper('experiences', _buildMainSection('PRACTICE HISTORY', _buildExperience(displayData['experiences']))),
              const SizedBox(height: 50),
              _buildSectionWrapper('activities', _buildMainSection('MEDICAL VOLUNTEERING', _buildActivities(displayData['activities'] ?? displayData['projects']))),
            ],
          ),
        ),
        const SizedBox(width: 60),
        // Right Column: Sidebar info
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionWrapper('personal_details', _buildSidebarSection('CONTACT DETAILS', _buildContact(personalInfo))),
              const SizedBox(height: 40),
              _buildSectionWrapper('skills', _buildSidebarSection('CORE COMPETENCIES', _buildSimpleList(displayData['skills']))),
              const SizedBox(height: 40),
              _buildSectionWrapper('education', _buildSidebarSection('MEDICAL EDUCATION', _buildEducation(displayData['education']))),
              const SizedBox(height: 40),
              _buildSectionWrapper('certifications', _buildSidebarSection('BOARD CERTIFICATIONS', _buildSimpleList(displayData['certifications']))),
              const SizedBox(height: 40),
              _buildSectionWrapper('languages', _buildSidebarSection('LANGUAGES', _buildSimpleList(displayData['languages']))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowContent(Map<String, dynamic> displayData, Map<String, dynamic> personalInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionWrapper('personal_details', _buildSidebarSection('CONTACT DETAILS', _buildContact(personalInfo))),
        const SizedBox(height: 40),
        _buildSectionWrapper('summary', _buildMainSection('CLINICAL SUMMARY', Text(
          displayData['summary'] ?? "Dedicated medical professional with extensive experience in patient care and clinical research. Committed to providing evidence-based treatment and improving patient outcomes.",
          style: GoogleFonts.lato(fontSize: 14, height: 1.8, color: textColor),
        ))),
        const SizedBox(height: 40),
        _buildSectionWrapper('experiences', _buildMainSection('PRACTICE HISTORY', _buildExperience(displayData['experiences']))),
        const SizedBox(height: 40),
        _buildSectionWrapper('skills', _buildSidebarSection('CORE COMPETENCIES', _buildSimpleList(displayData['skills']))),
        const SizedBox(height: 40),
        _buildSectionWrapper('education', _buildSidebarSection('MEDICAL EDUCATION', _buildEducation(displayData['education']))),
        const SizedBox(height: 40),
        _buildSectionWrapper('activities', _buildMainSection('MEDICAL VOLUNTEERING', _buildActivities(displayData['activities'] ?? displayData['projects']))),
        const SizedBox(height: 40),
        _buildSectionWrapper('certifications', _buildSidebarSection('BOARD CERTIFICATIONS', _buildSimpleList(displayData['certifications']))),
        const SizedBox(height: 40),
        _buildSectionWrapper('languages', _buildSidebarSection('LANGUAGES', _buildSimpleList(displayData['languages']))),
      ],
    );
  }

  Widget _buildHeader(Map<String, dynamic> info, bool isNarrow) {
    String? avatarUrl = info['avatar_url'];
    bool hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty && avatarUrl.startsWith('http');

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: isNarrow ? 20 : 40, vertical: 60),
      child: Flex(
        direction: isNarrow ? Axis.vertical : Axis.horizontal,
        children: [
          // Avatar: Clinical Circle
          _buildSectionWrapper(
            'avatar',
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primaryColor, width: 3),
                boxShadow: [
                  BoxShadow(color: primaryColor.withOpacity(0.1), blurRadius: 20, spreadRadius: 5),
                ],
              ),
              child: ClipOval(
                child: hasAvatar 
                  ? Image.network(avatarUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildAvatarPlaceholder())
                  : _buildAvatarPlaceholder(),
              ),
            ),
          ),
          SizedBox(width: isNarrow ? 0 : 40, height: isNarrow ? 40 : 0),
          // Identity
          Expanded(
            flex: isNarrow ? 0 : 1,
            child: Column(
              crossAxisAlignment: isNarrow ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                _buildSectionWrapper(
                  'cv_name',
                  Text(
                    (info['full_name'] ?? "DR. CLINICAL EXPERT"),
                    style: GoogleFonts.merriweather(
                      fontSize: isNarrow ? 28 : 38,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      letterSpacing: -1,
                    ),
                    textAlign: isNarrow ? TextAlign.center : TextAlign.start,
                  ),
                ),
                const SizedBox(height: 8),
                _buildSectionWrapper(
                  'cv_name',
                  Text(
                    (info['title'] ?? "Senior Consultant Specialist").toUpperCase(),
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w700,
                      color: secondaryColor,
                    ),
                    textAlign: isNarrow ? TextAlign.center : TextAlign.start,
                  ),
                ),
                const SizedBox(height: 20),
                Container(height: 3, width: 120, color: primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: lightGray,
      child: const Icon(Icons.health_and_safety_outlined, size: 70, color: primaryColor),
    );
  }

  Widget _buildMainSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 1),
        ),
        const SizedBox(height: 10),
        Container(height: 1, width: double.infinity, color: primaryColor.withOpacity(0.2)),
        const SizedBox(height: 25),
        content,
      ],
    );
  }

  Widget _buildSidebarSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 4, height: 20, color: primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: primaryColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),
        content,
      ],
    );
  }

  Widget _buildContact(Map<String, dynamic> info) {
    return Column(
      children: [
        _buildContactItem(Icons.phone_android, info['phone'] ?? "+84 000 000 000"),
        _buildContactItem(Icons.alternate_email, info['email'] ?? "health@medical.org"),
        _buildContactItem(Icons.medical_information_outlined, info['address'] ?? "Metropolis Health Center"),
      ],
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: secondaryColor),
          const SizedBox(width: 15),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildSkills(List<dynamic>? list) {
    final items = list ?? [];
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: items.map((s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: accentColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(s['name'] ?? "", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor)),
      )).toList(),
    );
  }

  Widget _buildExperience(List<dynamic>? list) {
    final items = list ?? [];
    return Column(
      children: items.map((exp) => Padding(
        padding: const EdgeInsets.only(bottom: 35),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 4, color: primaryColor.withOpacity(0.3)),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(exp['position'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor))),
                        Text(exp['duration'] ?? "", style: const TextStyle(fontSize: 11, color: secondaryColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(exp['company'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                    const SizedBox(height: 15),
                    Text(exp['description'] ?? "", style: const TextStyle(fontSize: 13, height: 1.7, color: textColor)),
                  ],
                ),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildActivities(List<dynamic>? list) {
    final items = list ?? [];
    return Column(
      children: items.map((act) => Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.circle, size: 8, color: secondaryColor),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(act['role'] ?? act['name'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                  Text(act['description'] ?? "", style: const TextStyle(fontSize: 12, height: 1.5, color: textColor)),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildEducation(List<dynamic>? list) {
    final items = list ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((edu) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(edu['school'] ?? "", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            Text(edu['degree'] ?? "", style: const TextStyle(fontSize: 12, color: textColor)),
            Text(edu['year'] ?? "", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: secondaryColor)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildSimpleList(List<dynamic>? list) {
    final items = list ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle_outline, size: 14, color: primaryColor),
            const SizedBox(width: 10),
            Expanded(child: Text(item['name'] ?? item.toString(), style: const TextStyle(fontSize: 12, color: textColor))),
          ],
        ),
      )).toList(),
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
}

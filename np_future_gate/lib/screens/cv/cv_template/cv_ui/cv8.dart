import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Cv8 extends StatelessWidget {

  const Cv8({
    super.key,
    this.data,
    this.onSectionTap,
  });
  final Map<String, dynamic>? data;
  final Function(String section)? onSectionTap;

  // Finance Theme: Corporate, Solid, Trustworthy
  static const Color primaryColor = Color(0xFF1B3E6A); // Deep Executive Blue
  static const Color secondaryColor = Color(0xFF607D8B); // Professional Gray
  static const Color accentColor = Color(0xFFDAA520);  // Gold (Trust/Wealth)
  static const Color textColor = Color(0xFF212121);
  static const Color lightBlue = Color(0xFFF0F4F8);
  static const Color bgColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    final displayData = data ?? {};
    final personalInfo = displayData['personal_info'] ?? {};

    return Theme(
      data: ThemeData(
        textTheme: GoogleFonts.montserratTextTheme(),
      ),
      child: Container(
        color: bgColor,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isNarrow = constraints.maxWidth < 600;
            return SingleChildScrollView(
              child: Column(
                children: [
                  // 1. Corporate Header
                  _buildHeader(personalInfo, isNarrow),

                  // 2. Main Body
                  Padding(
                    padding: EdgeInsets.all(isNarrow ? 20 : 40),
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
        // Content Column - 65%
        Expanded(
          flex: 65,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionWrapper('summary', _buildSection('EXECUTIVE SUMMARY',
                Text(
                  displayData['summary'] ?? 'Detail-oriented Finance Professional with 7+ years of experience in strategic planning, financial risk management, and ROI analysis.',
                  style: const TextStyle(fontSize: 14, height: 1.7, fontWeight: FontWeight.w400, color: textColor),
                )
              )),
              const SizedBox(height: 40),
              _buildSectionWrapper('experiences', _buildSection('PROFESSIONAL CAREER', _buildExperience(displayData['experiences']))),
              const SizedBox(height: 40),
              _buildSectionWrapper('projects', _buildSection('KEY ACHIEVEMENTS', _buildProjects(displayData['projects'] ?? displayData['activities']))),
            ],
          ),
        ),
        const SizedBox(width: 50),
        // Sidebar Column - 35%
        Expanded(
          flex: 35,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionWrapper('personal_details', _buildSidebarSection('THE ADVISOR', _buildContact(personalInfo))),
              const SizedBox(height: 40),
              _buildSectionWrapper('skills', _buildSidebarSection('COMPETENCIES', _buildSkills(displayData['skills']))),
              const SizedBox(height: 40),
              _buildSectionWrapper('certifications', _buildSidebarSection('CERTIFICATIONS', _buildSimpleList(displayData['certifications']))),
              const SizedBox(height: 40),
              _buildSectionWrapper('education', _buildSidebarSection('EDUCATION', _buildEducation(displayData['education']))),
              const SizedBox(height: 40),
              _buildSectionWrapper(
                'languages',
                _buildSidebarSection('LANGUAGES', _buildSimpleList(displayData['languages'])),
              ),
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
        _buildSectionWrapper('personal_details', _buildSidebarSection('THE ADVISOR', _buildContact(personalInfo))),
        const SizedBox(height: 30),
        _buildSectionWrapper('summary', _buildSection('EXECUTIVE SUMMARY',
          Text(
            displayData['summary'] ?? 'Detail-oriented Finance Professional with 7+ years of experience in strategic planning, financial risk management, and ROI analysis.',
            style: const TextStyle(fontSize: 14, height: 1.7, fontWeight: FontWeight.w400, color: textColor),
          )
        )),
        const SizedBox(height: 30),
        _buildSectionWrapper('experiences', _buildSection('PROFESSIONAL CAREER', _buildExperience(displayData['experiences']))),
        const SizedBox(height: 30),
        _buildSectionWrapper('skills', _buildSidebarSection('COMPETENCIES', _buildSkills(displayData['skills']))),
        const SizedBox(height: 30),
        _buildSectionWrapper('certifications', _buildSidebarSection('CERTIFICATIONS', _buildSimpleList(displayData['certifications']))),
        const SizedBox(height: 30),
        _buildSectionWrapper('projects', _buildSection('KEY ACHIEVEMENTS', _buildProjects(displayData['projects'] ?? displayData['activities']))),
        const SizedBox(height: 30),
        _buildSectionWrapper('education', _buildSidebarSection('EDUCATION', _buildEducation(displayData['education']))),
        const SizedBox(height: 30),
        _buildSectionWrapper(
          'languages',
          _buildSidebarSection('LANGUAGES', _buildSimpleList(displayData['languages'])),
        ),
      ],
    );
  }

  Widget _buildHeader(Map<String, dynamic> info, bool isNarrow) {
    final String? avatarUrl = info['avatar_url'];
    final bool hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty && avatarUrl.startsWith('http');

    return Container(
      width: double.infinity,
      color: primaryColor,
      padding: EdgeInsets.fromLTRB(isNarrow ? 20 : 40, 80, isNarrow ? 20 : 40, 60),
      child: Flex(
        direction: isNarrow ? Axis.vertical : Axis.horizontal,
        mainAxisAlignment: isNarrow ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          // Avatar
          _buildSectionWrapper(
            'avatar',
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 15)]),
              child: ClipOval(child: hasAvatar ? Image.network(avatarUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildAvatarPlaceholder()) : _buildAvatarPlaceholder()),
            ),
          ),
          SizedBox(width: isNarrow ? 0 : 40, height: isNarrow ? 30 : 0),
          // Identity
          Expanded(
            flex: isNarrow ? 0 : 1,
            child: Column(
              crossAxisAlignment: isNarrow ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                _buildSectionWrapper('cv_name', Text((info['full_name'] ?? 'EXECUTIVE PRINCIPAL').toUpperCase(), style: GoogleFonts.montserrat(fontSize: isNarrow ? 28 : 36, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2))),
                const SizedBox(height: 10),
                _buildSectionWrapper('cv_name', Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), color: lightBlue, child: Text((info['title'] ?? 'Managing Director & CF').toUpperCase(), style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 2)))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: Colors.white12,
      child: const Icon(Icons.account_balance, size: 60, color: Colors.white30),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: primaryColor,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Container(height: 2, color: primaryColor, width: 40),
        const SizedBox(height: 25),
        content,
      ],
    );
  }

  Widget _buildSidebarSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: lightBlue,
          child: Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 1.5),
          ),
        ),
        const SizedBox(height: 20),
        content,
      ],
    );
  }

  Widget _buildContact(Map<String, dynamic> info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildContactItem(Icons.phone_outlined, info['phone'] ?? '+84 000 000 000'),
        _buildContactItem(Icons.email_outlined, info['email'] ?? 'finance@corporate.com'),
        _buildContactItem(Icons.location_on_outlined, info['address'] ?? 'Financial Hub'),
        if (info['website'] != null) _buildContactItem(Icons.public_outlined, info['website']),
      ],
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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

  Widget _buildExperience(List<dynamic>? list) {
    final items = list ?? [];
    return Column(
      children: items.map((exp) => Padding(
        padding: const EdgeInsets.only(bottom: 35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(exp['position'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
                ),
                Text(exp['duration'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: secondaryColor)),
              ],
            ),
            const SizedBox(height: 5),
            Text(exp['company'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: accentColor)),
            const SizedBox(height: 15),
            Text(exp['description'] ?? '', style: const TextStyle(fontSize: 13, height: 1.7, color: textColor)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildProjects(List<dynamic>? list) {
    final items = list ?? [];
    return Column(
      children: items.map((p) => Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.arrow_right, color: accentColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['role'] ?? p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryColor)),
                  Text(p['description'] ?? '', style: const TextStyle(fontSize: 12, height: 1.5, color: textColor)),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildSkills(List<dynamic>? list) {
    final items = list ?? [];
    return Column(
      children: items.map((s) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Container(width: 5, height: 5, decoration: const BoxDecoration(color: primaryColor, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Expanded(child: Text(s['name'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor))),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildEducation(List<dynamic>? list) {
    final items = list ?? [];
    return Column(
      children: items.map((edu) => Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(edu['school'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            Text(edu['degree'] ?? '', style: const TextStyle(fontSize: 12, color: secondaryColor)),
            Text(edu['year'] ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor)),
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
        padding: const EdgeInsets.only(bottom: 8),
        child: Text("• ${item['name'] ?? item.toString()}", style: const TextStyle(fontSize: 12, color: textColor)),
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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Cv6 extends StatelessWidget {

  const Cv6({
    super.key,
    this.data,
    this.onSectionTap,
  });
  final Map<String, dynamic>? data;
  final Function(String section)? onSectionTap;

  // Marketing Theme: Vibrant, Dynamic, Result-Oriented
  static const Color primaryColor = Color(0xFFFF5722); // Vibrant Orange/Coral
  static const Color secondaryColor = Color(0xFF1A237E); // Deep Indigo
  static const Color accentColor = Color(0xFFFBE9E7);
  static const Color textColor = Color(0xFF263238);
  static const Color greyColor = Color(0xFF78909C);

  @override
  Widget build(BuildContext context) {
    final displayData = data ?? {};
    final personalInfo = displayData['personal_info'] ?? {};

    return Theme(
      data: ThemeData(
        textTheme: GoogleFonts.montserratTextTheme(),
      ),
      child: Container(
        color: Colors.white,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isNarrow = constraints.maxWidth < 600;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Dynamic Header
                  _buildHeader(personalInfo, isNarrow),

                  // 2. Main Content Body
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isNarrow ? 20 : 30, vertical: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary Section
                        _buildSectionWrapper(
                          'summary',
                          _buildMainSection(
                            'MARKETING OBJECTIVE',
                            Text(
                              displayData['summary'] ??
                                  'Creative and data-driven Growth Marketer with a passion for brand storytelling and performance marketing. Specialized in digital transformation and customer acquisition strategies.',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                height: 1.8,
                                color: textColor.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        if (isNarrow)
                          _buildNarrowContent(displayData, personalInfo)
                        else
                          _buildWideContent(displayData, personalInfo),
                      ],
                    ),
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
        // Left Column (60%)
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionWrapper(
                'experiences',
                _buildMainSection('PROFESSIONAL EXPERIENCE', _buildExperience(displayData['experiences'])),
              ),
              const SizedBox(height: 40),
              _buildSectionWrapper(
                'projects',
                _buildMainSection('KEY CAMPAIGNS & PROJECTS', _buildProjects(displayData['projects'] ?? displayData['activities'])),
              ),
            ],
          ),
        ),
        const SizedBox(width: 40),
        // Right Column (40%)
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionWrapper(
                'personal_details',
                _buildSidebarSection('GET IN TOUCH', _buildContact(personalInfo)),
              ),
              const SizedBox(height: 40),
              _buildSectionWrapper(
                'skills',
                _buildSidebarSection('STRATEGIC SKILLS', _buildSkills(displayData['skills'])),
              ),
              const SizedBox(height: 40),
              _buildSectionWrapper(
                'education',
                _buildSidebarSection('EDUCATION', _buildEducation(displayData['education'])),
              ),
              const SizedBox(height: 40),
              _buildSectionWrapper(
                'awards',
                _buildSidebarSection('HONORS & AWARDS', _buildAwards(displayData['awards'])),
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
        _buildSectionWrapper('personal_details', _buildSidebarSection('GET IN TOUCH', _buildContact(personalInfo))),
        const SizedBox(height: 30),
        _buildSectionWrapper('experiences', _buildMainSection('PROFESSIONAL EXPERIENCE', _buildExperience(displayData['experiences']))),
        const SizedBox(height: 30),
        _buildSectionWrapper('projects', _buildMainSection('KEY CAMPAIGNS & PROJECTS', _buildProjects(displayData['projects'] ?? displayData['activities']))),
        const SizedBox(height: 30),
        _buildSectionWrapper('skills', _buildSidebarSection('STRATEGIC SKILLS', _buildSkills(displayData['skills']))),
        const SizedBox(height: 30),
        _buildSectionWrapper('education', _buildSidebarSection('EDUCATION', _buildEducation(displayData['education']))),
        const SizedBox(height: 30),
        _buildSectionWrapper('awards', _buildSidebarSection('HONORS & AWARDS', _buildAwards(displayData['awards']))),
      ],
    );
  }

  Widget _buildHeader(Map<String, dynamic> info, bool isNarrow) {
    final String? avatarUrl = info['avatar_url'];
    final bool hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty && avatarUrl.startsWith('http');

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: secondaryColor,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(isNarrow ? 20 : 40, 80, isNarrow ? 20 : 40, 60),
            child: Flex(
              direction: isNarrow ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment: isNarrow ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              children: [
                _buildSectionWrapper(
                  'avatar',
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: hasAvatar 
                        ? Image.network(avatarUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildAvatarPlaceholder())
                        : _buildAvatarPlaceholder(),
                    ),
                  ),
                ),
                SizedBox(width: isNarrow ? 0 : 35, height: isNarrow ? 30 : 0),
                Expanded(
                  flex: isNarrow ? 0 : 1,
                  child: _buildSectionWrapper(
                    'cv_name',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (info['full_name'] ?? 'MARKETING PROFESSIONAL').toUpperCase(),
                          style: GoogleFonts.oswald(
                            fontSize: isNarrow ? 36 : 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            (info['title'] ?? 'Global Brand Specialist').toUpperCase(),
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.person, size: 80, color: greyColor),
    );
  }

  Widget _buildMainSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 35, height: 4, color: primaryColor),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.oswald(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: secondaryColor,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),
        content,
      ],
    );
  }

  Widget _buildSidebarSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.oswald(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(width: double.infinity, height: 1, color: secondaryColor.withValues(alpha: 0.1)),
        const SizedBox(height: 20),
        content,
      ],
    );
  }

  Widget _buildContact(Map<String, dynamic> info) {
    return Column(
      children: [
        _buildContactItem(Icons.phone_iphone, info['phone'] ?? '+84 000 000 000'),
        _buildContactItem(Icons.email_outlined, info['email'] ?? 'hello@marketer.com'),
        _buildContactItem(Icons.location_on_outlined, info['address'] ?? 'Ho Chi Minh, Vietnam'),
        if (info['website'] != null) _buildContactItem(Icons.link, info['website']),
      ],
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icon, size: 18, color: greyColor),
          const SizedBox(width: 15),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: textColor))),
        ],
      ),
    );
  }

  Widget _buildExperience(List<dynamic>? list) {
    final items = list ?? [];
    return Column(
      children: items.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(e['position'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor))),
                const SizedBox(width: 8),
                Flexible(child: Text(e['duration'] ?? '', style: const TextStyle(fontSize: 11, color: secondaryColor, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
              ],
            ),
            const SizedBox(height: 4),
            Text(e['company'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: greyColor)),
            const SizedBox(height: 12),
            Text(e['description'] ?? '', style: const TextStyle(fontSize: 13, height: 1.6)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildProjects(List<dynamic>? list) {
    final items = list ?? [];
    return Column(
      children: items.map((p) => Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: accentColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.circle, size: 8, color: secondaryColor),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['role'] ?? p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: secondaryColor.withValues(alpha: 0.1)),
        ),
        child: Text(s['name'] ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: secondaryColor)),
      )).toList(),
    );
  }

  Widget _buildEducation(List<dynamic>? list) {
    final items = list ?? [];
    return Column(
      children: items.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(e['school'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(e['degree'] ?? '', style: const TextStyle(fontSize: 12, color: greyColor)),
            Text(e['year'] ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildAwards(List<dynamic>? list) {
    final items = list ?? [];
    return Column(
      children: items.map((a) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.stars, size: 16, color: primaryColor),
            const SizedBox(width: 8),
            Expanded(child: Text("${a['name']} (${a['year']})", style: const TextStyle(fontSize: 12))),
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

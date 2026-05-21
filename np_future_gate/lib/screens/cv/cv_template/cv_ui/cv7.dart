import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Cv7 extends StatelessWidget {

  const Cv7({
    super.key,
    this.data,
    this.onSectionTap,
  });
  final Map<String, dynamic>? data;
  final Function(String section)? onSectionTap;

  // Design Theme: High-End Editorial, Sophisticated, Minimalist
  static const Color primaryColor = Color(0xFF000000); // Pure Black
  static const Color accentColor = Color(0xFFC5A059);  // Muted Gold
  static const Color bgColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF333333);
  static const Color secondaryColor = Color(0xFF666666);
  static const Color lightGray = Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context) {
    final displayData = data ?? {};
    final personalInfo = displayData['personal_info'] ?? {};

    return Theme(
      data: ThemeData(
        textTheme: GoogleFonts.playfairDisplayTextTheme(),
      ),
      child: Container(
        color: bgColor,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Sleek Top Accent
              Container(height: 10, width: double.infinity, color: primaryColor),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Header: Signature Style
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and Headline (Expanded must wrap the wrapper)
                        Expanded(
                          flex: 3,
                          child: _buildSectionWrapper(
                            'cv_name',
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (personalInfo['full_name'] ?? 'CREATIVE NAME'),
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 64,
                                    fontWeight: FontWeight.w900,
                                    color: primaryColor,
                                    height: 1,
                                    letterSpacing: -2,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Container(width: 80, height: 2, color: accentColor),
                                const SizedBox(height: 25),
                                Text(
                                  (personalInfo['title'] ?? 'Senior Visual Designer').toUpperCase(),
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    letterSpacing: 8,
                                    fontWeight: FontWeight.w300,
                                    color: secondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                        // Avatar: Minimal Frame
                        _buildSectionWrapper(
                          'avatar',
                          _buildAvatar(personalInfo['avatar_url']),
                        ),
                      ],
                    ),

                    const SizedBox(height: 100),

                    // 3. Main Content: Dual Column
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Career & Philosophy
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionWrapper(
                                'summary',
                                _buildVerticalSection('THE PHILOSOPHY', Text(
                                  displayData['summary'] ?? 'Believer in the balance of form and function. Crafting digital experiences that tell compelling stories through thoughtful design systems and visual precision.',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 15,
                                    height: 1.8,
                                    color: textColor,
                                    fontWeight: FontWeight.w400,
                                  ),
                                )),
                              ),
                              const SizedBox(height: 80),
                              _buildSectionWrapper(
                                'experiences',
                                _buildVerticalSection('CAREER HISTORY', _buildExperience(displayData['experiences'])),
                              ),
                              const SizedBox(height: 80),
                              _buildSectionWrapper(
                                'projects',
                                _buildVerticalSection('PORTFOLIO HIGHLIGHTS', _buildRecognition(displayData['projects'] ?? displayData['activities'])),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 100),

                        // Right Sidebar: Contact, Tools, Education
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionWrapper(
                                'personal_details',
                                _buildSidebarSection('THE CONNECTION', _buildContactInfo(personalInfo)),
                              ),
                              const SizedBox(height: 60),
                              _buildSectionWrapper(
                                'skills',
                                _buildSidebarSection('THE ARSENAL', _buildTools(displayData['skills'])),
                              ),
                              const SizedBox(height: 60),
                              _buildSectionWrapper(
                                'education',
                                _buildSidebarSection('ACADEMIC ROOT', _buildEducation(displayData['education'])),
                              ),
                              const SizedBox(height: 60),
                              _buildSectionWrapper(
                                'languages',
                                _buildSidebarSection('LANGUAGES', _buildLanguages(displayData['languages'])),
                              ),
                            ],
                          ),
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
    );
  }

  Widget _buildAvatar(String? avatarUrl) {
    final bool hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty && avatarUrl.startsWith('http');
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        color: lightGray,
        shape: BoxShape.rectangle,
        border: Border.all(color: primaryColor, width: 0.5),
      ),
      child: Center(
        child: hasAvatar 
          ? Image.network(avatarUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (_, __, ___) => const Icon(Icons.palette_outlined, size: 80, color: accentColor))
          : const Icon(Icons.palette_outlined, size: 80, color: accentColor),
      ),
    );
  }

  Widget _buildVerticalSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
            color: accentColor,
          ),
        ),
        const SizedBox(height: 35),
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
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 25),
        content,
      ],
    );
  }

  Widget _buildContactInfo(Map<String, dynamic> info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildContactItem(info['phone'] ?? '+84 000 000 000'),
        _buildContactItem(info['email'] ?? 'design@studio.com'),
        _buildContactItem(info['address'] ?? 'Metropolis City'),
        if (info['website'] != null) _buildContactItem(info['website']),
      ],
    );
  }

  Widget _buildContactItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: GoogleFonts.montserrat(fontSize: 13, color: textColor, fontWeight: FontWeight.w400),
      ),
    );
  }

  Widget _buildTools(List<dynamic>? list) {
    final items = list ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((s) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Container(width: 8, height: 8, color: accentColor),
            const SizedBox(width: 12),
            Expanded(child: Text(s['name'] ?? '', style: GoogleFonts.montserrat(fontSize: 12, color: textColor, fontWeight: FontWeight.w500))),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildExperience(List<dynamic>? list) {
    final items = list ?? [];
    return Column(
      children: items.map((exp) => Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(exp['company'] ?? '', style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold))),
                Text(exp['duration'] ?? '', style: GoogleFonts.montserrat(fontSize: 11, color: secondaryColor, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text((exp['position'] ?? '').toUpperCase(), style: GoogleFonts.montserrat(fontSize: 12, letterSpacing: 2, color: accentColor, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            Text(exp['description'] ?? '', style: GoogleFonts.montserrat(fontSize: 14, height: 1.8, color: textColor)),
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
        padding: const EdgeInsets.only(bottom: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(edu['school'] ?? '', style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold)),
            Text(edu['degree'] ?? '', style: GoogleFonts.montserrat(fontSize: 12, color: secondaryColor)),
            Text(edu['year'] ?? '', style: GoogleFonts.montserrat(fontSize: 11, color: accentColor)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildLanguages(List<dynamic>? list) {
    final items = list ?? [];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items.map((l) => Text(l['name'] ?? l.toString(), style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600))).toList(),
    );
  }

  Widget _buildRecognition(List<dynamic>? list) {
    final items = list ?? [];
    return Column(
      children: items.map((p) => Padding(
        padding: const EdgeInsets.only(bottom: 25),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('— ', style: TextStyle(color: accentColor)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['role'] ?? p['name'] ?? '', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(p['description'] ?? '', style: GoogleFonts.montserrat(fontSize: 13, height: 1.6, color: secondaryColor)),
                ],
              ),
            ),
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

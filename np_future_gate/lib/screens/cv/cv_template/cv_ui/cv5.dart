import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Cv5 extends StatelessWidget {

  const Cv5({
    super.key,
    this.data,
    this.onSectionTap,
  });
  final Map<String, dynamic>? data;
  final Function(String section)? onSectionTap;

  // Business Administration Theme: Corporate, Confident, Results-Driven
  static const Color primaryColor = Color(0xFF0D47A1); // Deep Corporate Blue
  static const Color secondaryColor = Color(0xFF1565C0); // Medium Blue
  static const Color accentColor = Color(0xFF00C853); // Success Green
  static const Color textMain = Color(0xFF1E293B);
  static const Color textLight = Color(0xFF64748B);
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color bgColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    final displayData = data ?? {};
    final personalInfo = displayData['personal_info'] ?? {};

    return Theme(
      data: ThemeData(textTheme: GoogleFonts.interTextTheme()),
      child: Container(
        color: bgColor,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isNarrow = constraints.maxWidth < 600;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(personalInfo, isNarrow),

                  // Body
                  Padding(
                    padding: EdgeInsets.all(isNarrow ? 20 : 36),
                    child: isNarrow
                        ? _buildNarrowContent(displayData)
                        : _buildWideContent(displayData),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> info, bool isNarrow) {
    final String? avatarUrl = info['avatar_url'];
    final bool hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty && avatarUrl.startsWith('http');

    return _buildSectionWrapper(
      'cv_name',
      Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryColor, secondaryColor],
          ),
        ),
        padding: EdgeInsets.fromLTRB(isNarrow ? 20 : 36, 48, isNarrow ? 20 : 36, 40),
        child: Flex(
          direction: isNarrow ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: isNarrow ? CrossAxisAlignment.center : CrossAxisAlignment.center,
          children: [
            // Avatar
            _buildSectionWrapper(
              'avatar',
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12)],
                ),
                child: ClipOval(
                  child: hasAvatar
                      ? Image.network(avatarUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _avatarPlaceholder())
                      : _avatarPlaceholder(),
                ),
              ),
            ),
            SizedBox(width: isNarrow ? 0 : 28, height: isNarrow ? 20 : 0),
            // Name & Title
            Expanded(
              flex: isNarrow ? 0 : 1,
              child: Column(
                crossAxisAlignment: isNarrow ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                children: [
                  Text(
                    (info['full_name'] ?? 'NGUYỄN VĂN A').toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: isNarrow ? 24 : 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                    textAlign: isNarrow ? TextAlign.center : TextAlign.start,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Text(
                      info['title'] ?? 'Quản trị kinh doanh',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500, letterSpacing: 1),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarPlaceholder() {
    return Container(
      color: Colors.white12,
      child: const Icon(Icons.business_center, size: 48, color: Colors.white54),
    );
  }

  Widget _buildWideContent(Map<String, dynamic> displayData) {
    final personalInfo = displayData['personal_info'] ?? {};
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Main content (65%)
        Expanded(
          flex: 65,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionWrapper('summary', _buildSection('MỤC TIÊU NGHỀ NGHIỆP', Icons.flag_outlined,
                Text(displayData['summary'] ?? 'Mục tiêu nghề nghiệp...', style: _bodyStyle()),
              )),
              const SizedBox(height: 32),
              _buildSectionWrapper('experiences', _buildSection('KINH NGHIỆM LÀM VIỆC', Icons.work_outline, _buildExperience(displayData['experiences']))),
              const SizedBox(height: 32),
              _buildSectionWrapper('projects', _buildSection('DỰ ÁN', Icons.folder_outlined, _buildProjects(displayData['projects']))),
              const SizedBox(height: 32),
              _buildSectionWrapper('activities', _buildSection('HOẠT ĐỘNG', Icons.groups_outlined, _buildActivities(displayData['activities']))),
            ],
          ),
        ),
        const SizedBox(width: 36),
        // Right: Sidebar (35%)
        Expanded(
          flex: 35,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionWrapper('personal_info', _buildSidebar('THÔNG TIN LIÊN HỆ', _buildContact(personalInfo))),
              const SizedBox(height: 28),
              _buildSectionWrapper('education', _buildSidebar('HỌC VẤN', _buildEducation(displayData['education']))),
              const SizedBox(height: 28),
              _buildSectionWrapper('skills', _buildSidebar('KỸ NĂNG', _buildSkills(displayData['skills']))),
              const SizedBox(height: 28),
              _buildSectionWrapper('certifications', _buildSidebar('CHỨNG CHỈ', _buildCerts(displayData['certifications']))),
              const SizedBox(height: 28),
              _buildSectionWrapper('awards', _buildSidebar('GIẢI THƯỞNG', _buildAwards(displayData['awards']))),
              const SizedBox(height: 28),
              _buildSectionWrapper('references', _buildSidebar('NGƯỜI GIỚI THIỆU', _buildReferences(displayData['references']))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowContent(Map<String, dynamic> displayData) {
    final personalInfo = displayData['personal_info'] ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionWrapper('personal_info', _buildSidebar('THÔNG TIN LIÊN HỆ', _buildContact(personalInfo))),
        const SizedBox(height: 28),
        _buildSectionWrapper('summary', _buildSection('MỤC TIÊU NGHỀ NGHIỆP', Icons.flag_outlined,
          Text(displayData['summary'] ?? 'Mục tiêu nghề nghiệp...', style: _bodyStyle()),
        )),
        const SizedBox(height: 28),
        _buildSectionWrapper('experiences', _buildSection('KINH NGHIỆM LÀM VIỆC', Icons.work_outline, _buildExperience(displayData['experiences']))),
        const SizedBox(height: 28),
        _buildSectionWrapper('education', _buildSidebar('HỌC VẤN', _buildEducation(displayData['education']))),
        const SizedBox(height: 28),
        _buildSectionWrapper('skills', _buildSidebar('KỸ NĂNG', _buildSkills(displayData['skills']))),
        const SizedBox(height: 28),
        _buildSectionWrapper('projects', _buildSection('DỰ ÁN', Icons.folder_outlined, _buildProjects(displayData['projects']))),
        const SizedBox(height: 28),
        _buildSectionWrapper('certifications', _buildSidebar('CHỨNG CHỈ', _buildCerts(displayData['certifications']))),
        const SizedBox(height: 28),
        _buildSectionWrapper('awards', _buildSidebar('GIẢI THƯỞNG', _buildAwards(displayData['awards']))),
        const SizedBox(height: 28),
        _buildSectionWrapper('references', _buildSidebar('NGƯỜI GIỚI THIỆU', _buildReferences(displayData['references']))),
      ],
    );
  }

  TextStyle _bodyStyle() => GoogleFonts.inter(fontSize: 13, height: 1.7, color: textMain, fontWeight: FontWeight.w400);

  Widget _buildSection(String title, IconData icon, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(6)),
              child: Icon(icon, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: primaryColor, letterSpacing: 0.5), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(height: 2, color: primaryColor, width: 40),
        const SizedBox(height: 16),
        content,
      ],
    );
  }

  Widget _buildSidebar(String title, Widget content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: primaryColor, letterSpacing: 1)),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildContact(Map<String, dynamic> info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _contactItem(Icons.phone_outlined, info['phone'] ?? '0123456789'),
        _contactItem(Icons.email_outlined, info['email'] ?? 'email@example.com'),
        _contactItem(Icons.location_on_outlined, info['address'] ?? 'TP.HCM'),
        if (info['website'] != null && info['website'].toString().isNotEmpty)
          _contactItem(Icons.language, info['website']),
      ],
    );
  }

  Widget _contactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: secondaryColor),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 11, color: textMain))),
        ],
      ),
    );
  }

  Widget _buildExperience(List<dynamic>? list) {
    final items = list ?? [];
    if (items.isEmpty) return Text('Chưa có kinh nghiệm', style: _bodyStyle());
    return Column(
      children: items.map((e) => Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(e['position'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: primaryColor))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: bgLight, borderRadius: BorderRadius.circular(10)),
                  child: Text(e['duration'] ?? e['date'] ?? '', style: GoogleFonts.inter(fontSize: 10, color: secondaryColor, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(e['company'] ?? '', style: GoogleFonts.inter(fontSize: 12, color: accentColor, fontWeight: FontWeight.w600)),
            if (e['description'] != null && e['description'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(e['description'], style: _bodyStyle()),
            ],
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildEducation(List<dynamic>? list) {
    final items = list ?? [];
    if (items.isEmpty) return Text('Chưa có', style: _bodyStyle());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(e['school'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: textMain)),
            Text(e['degree'] ?? e['major'] ?? '', style: GoogleFonts.inter(fontSize: 11, color: textLight)),
            Text(e['year'] ?? e['date'] ?? '', style: GoogleFonts.inter(fontSize: 10, color: secondaryColor, fontWeight: FontWeight.w600)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildSkills(List<dynamic>? list) {
    final items = list ?? [];
    if (items.isEmpty) return Text('Chưa có', style: _bodyStyle());
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items.map((s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: secondaryColor.withValues(alpha: 0.3)),
        ),
        child: Text(s['name'] ?? s.toString(), style: GoogleFonts.inter(fontSize: 10, color: primaryColor, fontWeight: FontWeight.w600)),
      )).toList(),
    );
  }

  Widget _buildCerts(List<dynamic>? list) {
    final items = list ?? [];
    if (items.isEmpty) return Text('Chưa có', style: _bodyStyle());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((c) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.verified, size: 12, color: accentColor),
            const SizedBox(width: 6),
            Expanded(child: Text('${c['name'] ?? ''} (${c['year'] ?? ''})', style: GoogleFonts.inter(fontSize: 11, color: textMain))),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildAwards(List<dynamic>? list) {
    final items = list ?? [];
    if (items.isEmpty) return Text('Chưa có', style: _bodyStyle());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((a) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.emoji_events, size: 12, color: Color(0xFFFFB300)),
            const SizedBox(width: 6),
            Expanded(child: Text('${a['name'] ?? a['title'] ?? ''} (${a['year'] ?? ''})', style: GoogleFonts.inter(fontSize: 11, color: textMain))),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildProjects(List<dynamic>? list) {
    final items = list ?? [];
    if (items.isEmpty) return Text('Chưa có dự án', style: _bodyStyle());
    return Column(
      children: items.map((p) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.folder_open, size: 14, color: secondaryColor),
                const SizedBox(width: 8),
                Expanded(child: Text(p['name'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: primaryColor))),
              ],
            ),
            if (p['description'] != null) ...[
              const SizedBox(height: 6),
              Text(p['description'], style: GoogleFonts.inter(fontSize: 11, height: 1.5, color: textMain)),
            ],
            if (p['technologies'] != null) ...[
              const SizedBox(height: 4),
              Text('Công nghệ: ${p['technologies']}', style: GoogleFonts.inter(fontSize: 10, color: secondaryColor)),
            ],
            if (p['role'] != null) ...[
              const SizedBox(height: 4),
              Text('Vai trò: ${p['role']}', style: GoogleFonts.inter(fontSize: 10, color: textLight)),
            ],
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildActivities(List<dynamic>? list) {
    final items = list ?? [];
    if (items.isEmpty) return Text('Chưa có', style: _bodyStyle());
    return Column(
      children: items.map((a) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.circle, size: 6, color: accentColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a['organization'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: textMain)),
                  Text('${a['role'] ?? a['position'] ?? ''} • ${a['duration'] ?? a['date'] ?? ''}', style: GoogleFonts.inter(fontSize: 10, color: textLight)),
                  if (a['description'] != null)
                    Text(a['description'], style: GoogleFonts.inter(fontSize: 11, height: 1.4, color: textMain)),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildReferences(List<dynamic>? list) {
    final items = list ?? [];
    if (items.isEmpty) return Text('Cung cấp khi yêu cầu', style: GoogleFonts.inter(fontSize: 11, color: textLight, fontStyle: FontStyle.italic));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r['name'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, color: textMain)),
            Text('${r['position'] ?? ''} - ${r['company'] ?? ''}', style: GoogleFonts.inter(fontSize: 10, color: textLight)),
            if (r['phone'] != null) Text(r['phone'], style: GoogleFonts.inter(fontSize: 10, color: secondaryColor)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildSectionWrapper(String sectionKey, Widget child) {
    if (onSectionTap == null) return child;
    return GestureDetector(
      onTap: () => onSectionTap!(sectionKey),
      behavior: HitTestBehavior.opaque,
      child: MouseRegion(cursor: SystemMouseCursors.click, child: child),
    );
  }
}

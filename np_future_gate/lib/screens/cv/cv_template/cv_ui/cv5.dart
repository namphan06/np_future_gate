import 'package:flutter/material.dart';

class Cv5 extends StatelessWidget {
  final Map<String, dynamic>? data;
  final Function(String section)? onSectionTap;

  const Cv5({
    super.key,
    this.data,
    this.onSectionTap,
  });

  // Premium Professional Palette
  static const Color primaryColor = Color(0xFF0E2452);
  static const Color accentColor = Color(0xFF1D4ED8);
  static const Color textMain = Color(0xFF1E293B);
  static const Color textLight = Color(0xFF64748B);
  static const Color bgColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    final displayData = data ?? {};
    final personalInfo = displayData['personal_info'] ?? {};
    Size size = MediaQuery.of(context).size;

    return Container(
      color: bgColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section: Info & Avatar
            _buildSectionWrapper('personal_info', Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (personalInfo['full_name'] ?? "Nguyễn Văn A").toUpperCase(),
                        style: const TextStyle(
                          color: primaryColor,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _infoRow(Icons.calendar_today_rounded, "Ngày sinh", "15/05/1990"), // Assuming static for now as per snippet
                      _infoRow(Icons.person_outline_rounded, "Giới tính", "Nam/Nữ"),
                      _infoRow(Icons.phone_iphone_rounded, "Điện thoại", personalInfo['phone'] ?? "0123456789"),
                      _infoRow(Icons.alternate_email_rounded, "Email", personalInfo['email'] ?? "email@example.com"),
                      _infoRow(Icons.location_on_rounded, "Địa chỉ", personalInfo['address'] ?? "Quận X, TP Y"),
                      if (personalInfo['website'] != null)
                        _infoRow(Icons.language_rounded, "Website", personalInfo['website']),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _buildSectionWrapper('avatar', Container(
                  width: size.width * 0.32,
                  height: size.width * 0.38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[200]!, width: 4),
                    image: personalInfo['avatar_url'] != null && personalInfo['avatar_url'].isNotEmpty
                        ? DecorationImage(image: NetworkImage(personalInfo['avatar_url']), fit: BoxFit.cover)
                        : null,
                  ),
                  child: personalInfo['avatar_url'] == null || personalInfo['avatar_url'].isEmpty
                      ? Icon(Icons.person, size: 80, color: Colors.grey[300])
                      : null,
                )),
              ],
            )),
            
            const SizedBox(height: 32),

            // Objective
            _buildSectionWrapper('summary', _buildSectionTitle("MỤC TIÊU NGHỀ NGHIỆP")),
            _buildSectionWrapper('summary', Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              child: Text(
                displayData['summary'] ?? "Tôi có kinh nghiệm tại vị sự Nhân viên kinh doanh đa ngành. Mong muốn thăng tiến lên Trưởng phòng trong 5 năm tới.",
                style: const TextStyle(fontSize: 14, height: 1.6, color: textMain),
              ),
            )),

            // Education
            _buildSectionWrapper('education', _buildSectionTitle("HỌC VẤN")),
            _buildSectionWrapper('education', _buildEducationList(displayData['education'])),

            // Experience
            _buildSectionWrapper('experiences', _buildSectionTitle("KINH NGHIỆM LÀM VIỆC")),
            _buildSectionWrapper('experiences', _buildWorkExperience(displayData['experiences'])),

            // Activities (Optional in some templates, but keeping structure)
            if (displayData['activities'] != null) ...[
              _buildSectionWrapper('activities', _buildSectionTitle("HOẠT ĐỘNG")),
              _buildSectionWrapper('activities', _buildActivities(displayData['activities'])),
            ],

            // Certificates
            _buildSectionWrapper('certifications', _buildSectionTitle("CHỨNG CHỈ")),
            _buildSectionWrapper('certifications', _buildCertificates(displayData['certifications'])),

            // Awards
            _buildSectionWrapper('awards', _buildSectionTitle("DANH HIỆU VÀ GIẢI THƯỞNG")),
            _buildSectionWrapper('awards', _buildAwards(displayData['awards'])),

            // Skills
            _buildSectionWrapper('skills', _buildSectionTitle("CÁC KỸ NĂNG")),
            _buildSectionWrapper('skills', _buildSkillsList(displayData['skills'])),

            // Hobbies
            _buildSectionWrapper('interests', _buildSectionTitle("SỞ THÍCH")),
            _buildSectionWrapper('interests', Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              child: Text(
                displayData['interests'] ?? "Đọc sách, Du lịch, Thể thao",
                style: const TextStyle(fontSize: 14, color: textMain),
              ),
            )),

            // Projects
            _buildSectionWrapper('projects', _buildSectionTitle("DỰ ÁN")),
            _buildSectionWrapper('projects', _buildProjectsList(displayData['projects'])),

            const SizedBox(height: 24),
            
            // Referees
            _buildSectionWrapper('references', _buildSectionTitle("NGƯỜI GIỚI THIỆU")),
            _buildSectionWrapper('references', _buildReferees(displayData['references'])),
          ],
        ),
      ),
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

  Widget _infoRow(IconData icon, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: accentColor),
          const SizedBox(width: 8),
          Text(
            "$title: ",
            style: const TextStyle(color: textMain, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Expanded(
            child: Text(
              content,
              style: const TextStyle(color: textMain, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            Container(width: 4, height: 24, color: primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ],
        ),
        const Divider(thickness: 1, color: Color(0xFFCBD5E1), height: 16),
      ],
    );
  }

  Widget _buildEducationList(List<dynamic>? list) {
    final items = list ?? [];
    return Column(
      children: items.map((e) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
              child: Text(
                e['year'] ?? e['date'] ?? '',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accentColor),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e['school'] ?? '',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textMain),
                  ),
                  const SizedBox(height: 4),
                  Text(e['major'] ?? '', style: const TextStyle(fontSize: 13, color: textMain)),
                  if (e['degree'] != null || e['detail'] != null)
                    Text(e['degree'] ?? e['detail'] ?? '', style: const TextStyle(fontSize: 12, color: textLight)),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildWorkExperience(List<dynamic>? list) {
    final items = list ?? [];
    return Column(
      children: items.map((e) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
              child: Text(
                e['date'] ?? e['duration'] ?? '',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accentColor),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e['company'] ?? '',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textMain),
                  ),
                  Text(
                    e['position'] ?? '',
                    style: const TextStyle(fontStyle: FontStyle.italic, color: textLight, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  if (e['description'] != null)
                    _buildStepText(e['description']),
                  if (e['details'] != null && e['details'] is List)
                    ... (e['details'] as List).map((d) => _buildStepText(d.toString())),
                ],
              ),
            )
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildStepText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4, color: textMain))),
        ],
      ),
    );
  }

  Widget _buildCertificates(List<dynamic>? list) {
    final items = list ?? [];
    return Column(
      children: items.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Text(e['year'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: accentColor, fontSize: 13)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(e['name'] ?? '', style: const TextStyle(fontSize: 14, color: textMain))),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildAwards(List<dynamic>? list) {
    final items = list ?? [];
    return Column(
      children: items.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Text(e['year'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: accentColor, fontSize: 13)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(e['title'] ?? e['name'] ?? '', style: const TextStyle(fontSize: 14, color: textMain))),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildSkillsList(List<dynamic>? list) {
    final items = list ?? [];
    return Column(
      children: items.map((skill) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 16, color: accentColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    skill['name'] ?? skill.toString(),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textMain),
                  ),
                ),
              ],
            ),
          ),
          const Divider(thickness: 0.5, color: Color(0xFFF1F5F9), height: 1),
        ],
      )).toList(),
    );
  }

  Widget _buildProjectsList(List<dynamic>? list) {
    final items = list ?? [];
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 20),
      itemBuilder: (context, index) => _buildProjectTable(items[index]),
    );
  }

  Widget _buildProjectTable(Map<String, dynamic> project) {
    const labels = {
      "name": "Dự án",
      "client": "Khách hàng",
      "description": "Mô tả dự án",
      "role": "Vai trò",
      "technologies": "Công nghệ sử dụng",
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(130),
          1: FlexColumnWidth(),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: labels.entries.map((entry) {
          final value = project[entry.key] ?? '';
          if (value.toString().isEmpty) return const TableRow(children: [SizedBox(), SizedBox()]);
          
          return TableRow(
            children: [
              Container(
                color: const Color(0xFFF8FAFC),
                padding: const EdgeInsets.all(12),
                child: Text(entry.value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryColor)),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(value.toString(), style: const TextStyle(fontSize: 13, color: textMain, height: 1.4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReferees(List<dynamic>? list) {
    final items = list ?? [];
    if (items.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              "Sẵn sàng cung cấp khi có yêu cầu.",
              style: TextStyle(color: textLight, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textMain)),
            Text(r['position'] ?? '', style: const TextStyle(fontSize: 13, color: textLight)),
            Text("${r['email'] ?? ''} | ${r['phone'] ?? ''}", style: const TextStyle(fontSize: 13, color: textMain)),
            const SizedBox(height: 4),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildActivities(List<dynamic>? list) {
    final items = list ?? [];
    return Column(
      children: items.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 90, child: Text(e['date'] ?? '', style: const TextStyle(fontSize: 12, color: accentColor, fontWeight: FontWeight.bold))),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e['organization'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textMain)),
                  Text(e['position'] ?? '', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                  if (e['details'] != null)
                    ... (e['details'] as List).map((d) => _buildStepText(d.toString())),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}



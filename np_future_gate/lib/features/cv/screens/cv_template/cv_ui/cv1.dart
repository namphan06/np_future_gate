import 'package:flutter/material.dart';

class Cv1 extends StatelessWidget {

  const Cv1({
    super.key,
    this.data,
    this.onSectionTap,
  });
  final Map<String, dynamic>? data;
  final Function(String section)? onSectionTap;

  @override
  Widget build(BuildContext context) {
    // Default data for preview if no data provided
    final displayData = data ?? {};
    final personalInfo = displayData['personal_info'] ?? {};
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Header Section (CV name/title) — split from personal details
              _buildSectionWrapper(
                'cv_name',
                Container(
                  height: 50,
                  decoration: const BoxDecoration(color: Colors.green),
                  child: Row(
                    children: [
                      Container(
                        width: 150,
                        decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            color: Colors.white),
                        child: Center(
                            child: Text(
                          personalInfo['full_name'] ?? 'Nguyễn Văn A',
                          style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                          textAlign: TextAlign.center,
                        )),
                      ),
                      const Spacer(),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Text(
                            personalInfo['title'] ?? 'Nhân viên tư vấn',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column
                  Container(
                    width: 155,
                    decoration: const BoxDecoration(color: Colors.green),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionWrapper(
                          'avatar',
                          Container(
                            width: 155,
                            height: 155,
                            color: Colors.grey[300],
                            child: personalInfo['avatar_url'] != null &&
                                    personalInfo['avatar_url'].toString().isNotEmpty
                                ? Image.network(
                                    personalInfo['avatar_url'],
                                    fit: BoxFit.cover,
                                    width: 155,
                                    height: 155,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.person,
                                            size: 80, color: Colors.white),
                                  )
                                : const Icon(Icons.person,
                                    size: 80, color: Colors.white),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionWrapper(
                                'personal_details',
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildPersonalInfo('Ngày sinh', personalInfo['dob'] ?? '15/05/1990'),
                                    _buildPersonalInfo('Giới tính', personalInfo['gender'] ?? 'Nam'),
                                    _buildPersonalInfo('Số điện thoại', personalInfo['phone'] ?? '0123456789'),
                                    _buildPersonalInfo('Email', personalInfo['email'] ?? 'email@example.com'),
                                    _buildPersonalInfo('Địa chỉ', personalInfo['address'] ?? 'Hà Nội'),
                                    _buildPersonalInfo('Website', personalInfo['website'] ?? 'website.com'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 15),
                              _buildSectionWrapper(
                                'summary',
                                _buildObjective(displayData['summary']),
                              ),
                              const SizedBox(height: 15),
                              _buildSectionWrapper(
                                'skills',
                                _buildSkills(displayData['skills']),
                              ),
                              const SizedBox(height: 245),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Right Column
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionWrapper(
                              'experiences',
                              _buildExperienceSection(displayData['experiences']),
                            ),
                            const SizedBox(height: 10),
                            _buildSectionWrapper(
                              'education',
                              _buildEducationSection(displayData['education']),
                            ),
                            const SizedBox(height: 10),
                            _buildSectionWrapper(
                              'activities',
                              _buildActivitiesSection(displayData['activities']),
                            ),
                            const SizedBox(height: 10),
                            _buildSectionWrapper(
                              'awards',
                              _buildAwardsSection(displayData['awards']),
                            ),
                            const SizedBox(height: 10),
                            _buildSectionWrapper(
                              'certifications',
                              _buildCertificationsSection(displayData['certifications']),
                            ),
                            const SizedBox(height: 10),
                            _buildSectionWrapper(
                              'references',
                              _buildReferencesSection(displayData['references']),
                            ),
                          ],
                        ),
                    ),
                  ),
                ],
              ),
            ],
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
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.transparent, width: 2),
          ),
          child: Stack(
            children: [
              child,
              Positioned.fill(
                child: Container(
                  color: Colors.transparent, // Transparent overlay to catch taps if needed
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfo(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                fontSize: 12),
          ),
          Text(
            content,
            style:
                const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildObjective(String? summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MỤC TIÊU NGHỀ NGHIỆP',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              fontSize: 20),
        ),
        Text(
          summary ?? 'Mục tiêu nghề nghiệp của bạn...',
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildSkills(List<dynamic>? skills) {
    final skillList = skills ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CÁC KỸ NĂNG',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              fontSize: 20),
        ),
        if (skillList.isEmpty)
          _buildSkill('Kỹ năng mẫu')
        else
          ...skillList.map((s) => Column(
            children: [
              _buildSkill(s['name'] ?? ''),
              const SizedBox(height: 10),
            ],
          )),
      ],
    );
  }

  Widget _buildSkill(String label) {
    return Column(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style:
                  const TextStyle(color: Colors.white, fontSize: 15),
            ),
            const SizedBox(
              height: 10,
            ),
            Container(
              width: 100,
              height: 10,
              decoration:
                  BoxDecoration(color: Colors.grey.withValues(alpha: 0.5)),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 10,
                  width: 60,
                  decoration:
                      const BoxDecoration(color: Colors.white),
                ),
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _buildExperienceSection(List<dynamic>? experiences) {
    final list = experiences ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                'KINH NGHIỆM LÀM VIỆC',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
        if (list.isEmpty)
          _buildExperience(
              ['Mô tả công việc...'],
              'Công ty Mẫu',
              '2023 - 2024',
              'Vị trí')
        else
          ...list.map((e) => Column(
            children: [
              _buildExperience(
                (e['description'] as String? ?? '').split('\n'),
                e['company'] ?? '',
                e['duration'] ?? '',
                e['position'] ?? ''
              ),
              const SizedBox(height: 10),
            ],
          )),
      ],
    );
  }

  Widget _buildExperience(
      List<String> item1s, String company, String year, String position) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                company,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Text(year),
          ],
        ),
        const SizedBox(height: 10),
        Text(position),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: item1s.length,
          itemBuilder: (context, index) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '•',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item1s[index],
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildEducationSection(List<dynamic>? education) {
    final list = education ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              'HỌC VẤN',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.green,
              ),
            ),
          ],
        ),
        if (list.isEmpty)
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Trường Đại học Mẫu', 
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text('2020 - 2024'),
                ],
              ),
              Text('Chuyên ngành'),
            ],
          )
        else
          ...list.map((e) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      e['school'] ?? '', 
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(e['year'] ?? ''),
                ],
              ),
              Text(e['degree'] ?? ''),
              const SizedBox(height: 8),
            ],
          )),
      ],
    );
  }

  Widget _buildActivitiesSection(List<dynamic>? activities) {
    final list = activities ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              'HOẠT ĐỘNG',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.green,
              ),
            ),
          ],
        ),
        if (list.isEmpty)
          _buildExperience([], 'Hoạt động mẫu', '2023', 'Vai trò')
        else
          ...list.map((a) => Column(
            children: [
              _buildExperience(
                (a['description'] as String? ?? '').split('\n'),
                a['organization'] ?? '',
                a['duration'] ?? '',
                a['role'] ?? ''
              ),
              const SizedBox(height: 10),
            ],
          )),
      ],
    );
  }

  Widget _buildAwardsSection(List<dynamic>? awards) {
    final list = awards ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                'DANH HIỆU VÀ GIẢI THƯỞNG',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.green,
                ),
                maxLines: 2,
              ),
            ),
          ],
        ),
        if (list.isEmpty)
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text('Giải thưởng mẫu')),
              SizedBox(width: 10),
              Text('2024'),
            ],
          )
        else
          ...list.map((a) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(a['name'] ?? '')),
              const SizedBox(width: 10),
              Text(a['year'] ?? ''),
            ],
          )),
      ],
    );
  }

  Widget _buildCertificationsSection(List<dynamic>? certs) {
    final list = certs ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              'CHỨNG CHỈ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.green,
              ),
            ),
          ],
        ),
        if (list.isEmpty)
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text('Chứng chỉ mẫu')),
              SizedBox(width: 10),
              Text('2024'),
            ],
          )
        else
          ...list.map((c) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(c['name'] ?? '')),
              const SizedBox(width: 10),
              Text(c['year'] ?? ''),
            ],
          )),
      ],
    );
  }

  Widget _buildReferencesSection(List<dynamic>? refs) {
    final list = refs ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              'NGƯỜI GIỚI THIỆU',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.green,
              ),
            ),
          ],
        ),
        if (list.isEmpty)
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ông Nguyễn Văn A'),
              Text('CEO công ty A'),
            ],
          )
        else
          ...list.map((r) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r['name'] ?? ''),
              Text(r['position'] ?? ''),
              Text(r['phone'] ?? ''),
              const SizedBox(height: 8),
            ],
          )),
      ],
    );
  }
}

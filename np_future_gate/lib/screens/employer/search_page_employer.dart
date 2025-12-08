import 'package:flutter/material.dart';
import '../../core/enums/vietnam_provinces.dart';
import '../../core/enums/job_fields.dart';
import '../../core/enums/experience_levels.dart';
import '../../core/theme/app_main_colors.dart';

class SearchPageEmployer extends StatefulWidget {
  const SearchPageEmployer({super.key});

  @override
  State<SearchPageEmployer> createState() => _SearchPageEmployerState();
}

class _SearchPageEmployerState extends State<SearchPageEmployer> {
  // Filter values
  String _selectedExperience = 'Tất cả';
  String _selectedField = 'Tất cả';
  String _selectedSkill = 'Tất cả';
  String _selectedEducation = 'Tất cả';
  String _selectedLocation = 'Tất cả';
  RangeValues _salaryRange = const RangeValues(5, 50);
  RangeValues _ageRange = const RangeValues(22, 45);
  String _selectedGender = 'Tất cả';

  bool _showFilters = false;

  // Mock candidates
  final List<Map<String, dynamic>> _candidates = [
    {
      'name': 'Nguyễn Văn A',
      'title': 'Senior Flutter Developer',
      'experience': '5 năm',
      'field': 'Mobile Development',
      'skills': ['Flutter', 'Dart', 'Firebase'],
      'education': 'Đại học',
      'location': 'Hà Nội',
      'salary': '25 triệu',
      'age': 28,
      'gender': 'Nam',
    },
    {
      'name': 'Trần Thị B',
      'title': 'Backend Developer',
      'experience': '3 năm',
      'field': 'Backend Development',
      'skills': ['Node.js', 'PostgreSQL', 'Docker'],
      'education': 'Đại học',
      'location': 'TP.HCM',
      'salary': '20 triệu',
      'age': 26,
      'gender': 'Nữ',
    },
    {
      'name': 'Lê Văn C',
      'title': 'UI/UX Designer',
      'experience': '2 năm',
      'field': 'Design',
      'skills': ['Figma', 'Adobe XD', 'Photoshop'],
      'education': 'Cao đẳng',
      'location': 'Đà Nẵng',
      'salary': '15 triệu',
      'age': 24,
      'gender': 'Nam',
    },
    {
      'name': 'Phạm Thị D',
      'title': 'Full Stack Developer',
      'experience': '4 năm',
      'field': 'Web Development',
      'skills': ['React', 'Node.js', 'MongoDB'],
      'education': 'Đại học',
      'location': 'Hà Nội',
      'salary': '22 triệu',
      'age': 27,
      'gender': 'Nữ',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tìm kiếm ứng viên',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 15,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Tìm ứng viên theo kỹ năng, vị trí...',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
                              color: _showFilters ? AppMainColors.primary : Colors.grey.shade500,
                            ),
                            onPressed: () {
                              setState(() {
                                _showFilters = !_showFilters;
                              });
                            },
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Filters Panel
              if (_showFilters)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 15,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bộ lọc tìm kiếm',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDropdownFilter(
                          'Kinh nghiệm',
                          _selectedExperience,
                          ['Tất cả', ...ExperienceLevel.valuesList],
                          (value) => setState(() => _selectedExperience = value!),
                        ),
                        const SizedBox(height: 12),
                        _buildDropdownFilter(
                          'Lĩnh vực',
                          _selectedField,
                          ['Tất cả', ...JobField.valuesList],
                          (value) => setState(() => _selectedField = value!),
                        ),
                        const SizedBox(height: 12),
                        _buildDropdownFilter(
                          'Kỹ năng',
                          _selectedSkill,
                          ['Tất cả', 'Flutter', 'React', 'Node.js', 'Python', 'Java', 'UI/UX'],
                          (value) => setState(() => _selectedSkill = value!),
                        ),
                        const SizedBox(height: 12),
                        _buildDropdownFilter(
                          'Bằng cấp',
                          _selectedEducation,
                          ['Tất cả', 'Trung cấp', 'Cao đẳng', 'Đại học', 'Thạc sĩ', 'Tiến sĩ'],
                          (value) => setState(() => _selectedEducation = value!),
                        ),
                        const SizedBox(height: 12),
                        _buildDropdownFilter(
                          'Địa điểm',
                          _selectedLocation,
                          ['Tất cả', ...VietnamProvince.valuesList],
                          (value) => setState(() => _selectedLocation = value!),
                        ),
                        const SizedBox(height: 16),
                        _buildRangeFilter(
                          'Mức lương mong muốn (triệu)',
                          _salaryRange,
                          5,
                          50,
                          (values) => setState(() => _salaryRange = values),
                        ),
                        const SizedBox(height: 16),
                        _buildRangeFilter(
                          'Độ tuổi',
                          _ageRange,
                          18,
                          60,
                          (values) => setState(() => _ageRange = values),
                        ),
                        const SizedBox(height: 12),
                        _buildDropdownFilter(
                          'Giới tính',
                          _selectedGender,
                          ['Tất cả', 'Nam', 'Nữ', 'Khác'],
                          (value) => setState(() => _selectedGender = value!),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedExperience = 'Tất cả';
                                    _selectedField = 'Tất cả';
                                    _selectedSkill = 'Tất cả';
                                    _selectedEducation = 'Tất cả';
                                    _selectedLocation = 'Tất cả';
                                    _salaryRange = const RangeValues(5, 50);
                                    _ageRange = const RangeValues(22, 45);
                                    _selectedGender = 'Tất cả';
                                  });
                                },
                                child: const Text('Xóa bộ lọc'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _showFilters = false;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppMainColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Áp dụng'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // Results
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  itemCount: _candidates.length,
                  itemBuilder: (context, index) {
                    final candidate = _candidates[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.person_outline,
                                  color: Colors.blue,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      candidate['name'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      candidate['title'],
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.bookmark_border,
                                  color: Colors.grey.shade400, size: 22),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (candidate['skills'] as List<String>).map((skill) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppMainColors.backgroundLightStart,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  skill,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppMainColors.primaryDark,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.work_outline,
                                  size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                candidate['experience'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.location_on_outlined,
                                  size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                candidate['location'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                candidate['salary'],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Gradient overlay
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0),
                    Colors.white.withOpacity(0.6),
                    Colors.white.withOpacity(0.85),
                    Colors.white,
                  ],
                  stops: const [0.0, 0.2, 0.4, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownFilter(
    String label,
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item, style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRangeFilter(
    String label,
    RangeValues values,
    double min,
    double max,
    void Function(RangeValues) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              '${values.start.round()} - ${values.end.round()}',
              style: TextStyle(
                fontSize: 12,
                color: AppMainColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        RangeSlider(
          values: values,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          activeColor: AppMainColors.primary,
          inactiveColor: Colors.grey.shade300,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

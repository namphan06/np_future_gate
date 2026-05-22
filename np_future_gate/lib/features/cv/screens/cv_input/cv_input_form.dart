import 'package:flutter/material.dart';
import 'package:np_future_gate/shared/widgets/inputs/speech_text_field.dart';

/// CV Input Form - Form nhập liệu cho từng section của CV
class CV1InputForm extends StatefulWidget {

  const CV1InputForm({
    super.key,
    required this.section,
    required this.data,
    required this.onDataChanged,
    required this.onClose,
  });
  final String section;
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onDataChanged;
  final VoidCallback onClose;

  @override
  State<CV1InputForm> createState() => _CV1InputFormState();
}

class _CV1InputFormState extends State<CV1InputForm> {
  late Map<String, dynamic> _localData;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _localData = Map<String, dynamic>.from(widget.data);
    _rebuildControllersFromData();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    super.dispose();
  }

  void _updateData() {
    widget.onDataChanged(_localData);
  }

  void _rebuildControllersFromData() {
    // Dispose existing
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();

    // Summary
    _createControllerIfNeeded('summary', (_localData['summary'] ?? '').toString());

    // Interests
    _createControllerIfNeeded('interests', (_localData['interests'] ?? '').toString());

    // Personal info
    final info = _localData['personal_info'] ?? {};
    _createControllerIfNeeded('personal_info::full_name', (info['full_name'] ?? '').toString());
    _createControllerIfNeeded('personal_info::title', (info['title'] ?? '').toString());
    _createControllerIfNeeded('personal_info::avatar_url', (info['avatar_url'] ?? '').toString());
    _createControllerIfNeeded('personal_info::email', (info['email'] ?? '').toString());
    _createControllerIfNeeded('personal_info::phone', (info['phone'] ?? '').toString());
    _createControllerIfNeeded('personal_info::address', (info['address'] ?? '').toString());
    _createControllerIfNeeded('personal_info::website', (info['website'] ?? '').toString());
    _createControllerIfNeeded('personal_info::dob', (info['dob'] ?? '').toString());
    _createControllerIfNeeded('personal_info::gender', (info['gender'] ?? '').toString());

    // Lists (experiences, education, skills, certifications, activities, awards, languages, references)
    void createListControllers(String listName, List<Map<String, dynamic>> list, List<String> fields) {
      for (var i = 0; i < list.length; i++) {
        final item = list[i];
        for (final f in fields) {
          _createControllerIfNeeded('$listName::'
              '$i::$f', (item[f] ?? '').toString());
        }
      }
    }

    createListControllers('experiences', List<Map<String, dynamic>>.from(_localData['experiences'] ?? []), ['position', 'company', 'duration', 'description']);
    createListControllers('projects', List<Map<String, dynamic>>.from(_localData['projects'] ?? []), ['name', 'client', 'description', 'team_size', 'position', 'role', 'technologies']);
    createListControllers('education', List<Map<String, dynamic>>.from(_localData['education'] ?? []), ['degree', 'school', 'year', 'detail']);
    createListControllers('skills', List<Map<String, dynamic>>.from(_localData['skills'] ?? []), ['name', 'level']);
    createListControllers('certifications', List<Map<String, dynamic>>.from(_localData['certifications'] ?? []), ['name', 'issuer', 'year']);
    createListControllers('activities', List<Map<String, dynamic>>.from(_localData['activities'] ?? []), ['organization', 'role', 'duration', 'description']);
    createListControllers('awards', List<Map<String, dynamic>>.from(_localData['awards'] ?? []), ['name', 'year', 'note']);
    createListControllers('languages', List<Map<String, dynamic>>.from(_localData['languages'] ?? []), ['name', 'level']);
    createListControllers('references', List<Map<String, dynamic>>.from(_localData['references'] ?? []), ['name', 'position', 'company', 'phone']);
  }

  void _createControllerIfNeeded(String key, String initial) {
    if (_controllers.containsKey(key)) return;
    final c = TextEditingController(text: initial);
    c.addListener(() {
      _applyControllerToData(key, c.text);
      _updateData();
    });
    _controllers[key] = c;
  }

  void _applyControllerToData(String key, String value) {
    final parts = key.split('::');
    if (parts.length == 1) {
      // summary or other top-level
      _localData[parts[0]] = value;
      return;
    }
    if (parts[0] == 'personal_info') {
      _localData['personal_info'] ??= {};
      _localData['personal_info'][parts[1]] = value;
      return;
    }
    // list case: listName::index::field
    if (parts.length == 3) {
      final listName = parts[0];
      final index = int.tryParse(parts[1]) ?? 0;
      final field = parts[2];
      _localData[listName] ??= [];
      final list = List<Map<String, dynamic>>.from(_localData[listName]);
      while (list.length <= index) {
        list.add({});
      }
      list[index][field] = value;
      _localData[listName] = list;
      return;
    }
  }

  TextEditingController? _controllerFor(String key) => _controllers[key];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[700],
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _getSectionTitle(widget.section),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: widget.onClose,
              ),
            ],
          ),
        ),

        // Form Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildFormContent(),
          ),
        ),
      ],
    );
  }

  String _getSectionTitle(String section) {
    switch (section) {
      case 'personal_info':
        return 'Thông tin cá nhân';
      case 'summary':
        return 'Tóm tắt';
      case 'experiences':
        return 'Kinh nghiệm làm việc';
      case 'education':
        return 'Học vấn';
      case 'skills':
        return 'Kỹ năng';
      case 'certifications':
        return 'Chứng chỉ';
      case 'languages':
        return 'Ngôn ngữ';
      case 'references':
        return 'Người tham chiếu';
      case 'interests':
        return 'Sở thích';
      default:
        return section;
    }
  }

  Widget _buildFormContent() {
    switch (widget.section) {
      case 'personal_info':
      case 'personal_details':
        return _buildPersonalDetailsForm();
      case 'cv_name':
        return _buildCvNameForm();
      case 'avatar':
        return _buildAvatarForm();
      case 'summary':
        return _buildSummaryForm();
      case 'interests':
        return _buildInterestsForm();
      case 'experiences':
        return _buildExperiencesForm();
      case 'projects':
        return _buildProjectsForm();
      case 'education':
        return _buildEducationForm();
      case 'skills':
        return _buildSkillsForm();
      case 'certifications':
        return _buildCertificationsForm();
      case 'activities':
        return _buildActivitiesForm();
      case 'awards':
        return _buildAwardsForm();
      case 'languages':
        return _buildLanguagesForm();
      case 'references':
        return _buildReferencesForm();
      default:
        return const Text('Form đang được phát triển...');
    }
  }

  // Personal Info Form
  // CV Name / Title form (header)
  Widget _buildCvNameForm() {
    final info = _localData['personal_info'] ?? {};
    return Column(
      children: [
        _buildTextField(
          label: 'Họ và tên',
          value: info['full_name'],
          controllerKey: 'personal_info::full_name',
          onChanged: (val) {
            info['full_name'] = val;
            _updateData();
          },
          icon: Icons.person,
        ),
        _buildTextField(
          label: 'Chức danh (title)',
          value: info['title'],
          controllerKey: 'personal_info::title',
          onChanged: (val) {
            info['title'] = val;
            _updateData();
          },
          icon: Icons.work,
        ),
      ],
    );
  }

  // Avatar form (separate)
  Widget _buildAvatarForm() {
    final info = _localData['personal_info'] ?? {};
    return Column(
      children: [
        _buildTextField(
          label: 'URL Avatar',
          value: info['avatar_url'],
          controllerKey: 'personal_info::avatar_url',
          onChanged: (val) {
            info['avatar_url'] = val;
            _updateData();
          },
          icon: Icons.image,
        ),
        const SizedBox(height: 8),
        if ((info['avatar_url'] ?? '').toString().isNotEmpty)
          SizedBox(
            height: 160,
            child: Image.network(info['avatar_url'], fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image)),
          ),
      ],
    );
  }

  // Personal details form (email/phone/address/website/dob/gender)
  Widget _buildPersonalDetailsForm() {
    final info = _localData['personal_info'] ?? {};
    return Column(
      children: [
        _buildTextField(
          label: 'Email',
          value: info['email'],
          controllerKey: 'personal_info::email',
          onChanged: (val) {
            info['email'] = val;
            _updateData();
          },
          icon: Icons.email,
        ),
        _buildTextField(
          label: 'Số điện thoại',
          value: info['phone'],
          controllerKey: 'personal_info::phone',
          onChanged: (val) {
            info['phone'] = val;
            _updateData();
          },
          icon: Icons.phone,
        ),
        _buildTextField(
          label: 'Địa chỉ',
          value: info['address'],
          controllerKey: 'personal_info::address',
          onChanged: (val) {
            info['address'] = val;
            _updateData();
          },
          icon: Icons.location_on,
        ),
        _buildTextField(
          label: 'Website',
          value: info['website'],
          controllerKey: 'personal_info::website',
          onChanged: (val) {
            info['website'] = val;
            _updateData();
          },
          icon: Icons.web,
        ),
        _buildTextField(
          label: 'Ngày sinh',
          value: info['dob'],
          controllerKey: 'personal_info::dob',
          onChanged: (val) {
            info['dob'] = val;
            _updateData();
          },
          icon: Icons.cake,
        ),
        _buildTextField(
          label: 'Giới tính',
          value: info['gender'],
          controllerKey: 'personal_info::gender',
          onChanged: (val) {
            info['gender'] = val;
            _updateData();
          },
          icon: Icons.wc,
        ),
      ],
    );
  }

  // Summary Form
  Widget _buildSummaryForm() {
    return _buildTextField(
      label: 'Tóm tắt về bản thân',
      value: _localData['summary'],
      controllerKey: 'summary',
      onChanged: (val) {
        _localData['summary'] = val;
        _updateData();
      },
      maxLines: 8,
      icon: Icons.description,
    );
  }

  // Interests Form
  Widget _buildInterestsForm() {
    return _buildTextField(
      label: 'Sở thích',
      value: _localData['interests'],
      controllerKey: 'interests',
      onChanged: (val) {
        _localData['interests'] = val;
        _updateData();
      },
      maxLines: 5,
      icon: Icons.interests,
    );
  }

  // Experiences Form
  Widget _buildExperiencesForm() {
    final experiences = _localData['experiences'] ?? [];
    return Column(
      children: [
        ...List.generate(experiences.length, (index) {
          return _buildExperienceCard(experiences[index], index);
        }),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              experiences.add({
                'position': '',
                'company': '',
                'duration': '',
                'description': '',
              });
              _rebuildControllersFromData();
              _updateData();
            });
          },
          icon: const Icon(Icons.add),
          label: const Text('Thêm kinh nghiệm'),
        ),
      ],
    );
  }

  Widget _buildExperienceCard(Map<String, dynamic> exp, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Kinh nghiệm ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      (_localData['experiences'] as List).removeAt(index);
                      _rebuildControllersFromData();
                      _updateData();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildTextField(
              label: 'Vị trí',
              value: exp['position'],
              controllerKey: 'experiences::$index::position',
              onChanged: (val) {
                exp['position'] = val;
                _updateData();
              },
            ),
            _buildTextField(
              label: 'Công ty',
              value: exp['company'],
              controllerKey: 'experiences::$index::company',
              onChanged: (val) {
                exp['company'] = val;
                _updateData();
              },
            ),
            _buildTextField(
              label: 'Thời gian (VD: 2020 - 2023)',
              value: exp['duration'],
              controllerKey: 'experiences::$index::duration',
              onChanged: (val) {
                exp['duration'] = val;
                _updateData();
              },
            ),
            _buildTextField(
              label: 'Mô tả công việc',
              value: exp['description'],
              controllerKey: 'experiences::$index::description',
              maxLines: 3,
              onChanged: (val) {
                exp['description'] = val;
                _updateData();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Projects Form
  Widget _buildProjectsForm() {
    final projects = _localData['projects'] ?? [];
    return Column(
      children: [
        ...List.generate(projects.length, (index) {
          return _buildProjectCard(projects[index], index);
        }),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              projects.add({
                'name': '',
                'client': '',
                'description': '',
                'team_size': '',
                'position': '',
                'role': '',
                'technologies': '',
              });
              _rebuildControllersFromData();
              _updateData();
            });
          },
          icon: const Icon(Icons.add),
          label: const Text('Thêm dự án'),
        ),
      ],
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> proj, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Dự án ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      (_localData['projects'] as List).removeAt(index);
                      _rebuildControllersFromData();
                      _updateData();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildTextField(
              label: 'Tên dự án',
              value: proj['name'],
              controllerKey: 'projects::$index::name',
              onChanged: (val) {
                proj['name'] = val;
                _updateData();
              },
            ),
            _buildTextField(
              label: 'Khách hàng',
              value: proj['client'],
              controllerKey: 'projects::$index::client',
              onChanged: (val) {
                proj['client'] = val;
                _updateData();
              },
            ),
            _buildTextField(
              label: 'Mô tả',
              value: proj['description'],
              controllerKey: 'projects::$index::description',
              maxLines: 3,
              onChanged: (val) {
                proj['description'] = val;
                _updateData();
              },
            ),
            _buildTextField(
              label: 'Số lượng thành viên',
              value: proj['team_size'],
              controllerKey: 'projects::$index::team_size',
              onChanged: (val) {
                proj['team_size'] = val;
                _updateData();
              },
            ),
            _buildTextField(
              label: 'Vai trò trong dự án',
              value: proj['role'],
              controllerKey: 'projects::$index::role',
              maxLines: 2,
              onChanged: (val) {
                proj['role'] = val;
                _updateData();
              },
            ),
            _buildTextField(
              label: 'Công nghệ sử dụng',
              value: proj['technologies'],
              controllerKey: 'projects::$index::technologies',
              onChanged: (val) {
                proj['technologies'] = val;
                _updateData();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Education Form
  Widget _buildEducationForm() {
    final education = _localData['education'] ?? [];
    return Column(
      children: [
        ...List.generate(education.length, (index) {
          return _buildEducationCard(education[index], index);
        }),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              education.add({
                'degree': '',
                'school': '',
                'year': '',
                'description': '',
              });
              _rebuildControllersFromData();
              _updateData();
            });
          },
          icon: const Icon(Icons.add),
          label: const Text('Thêm học vấn'),
        ),
      ],
    );
  }

  Widget _buildEducationCard(Map<String, dynamic> edu, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Học vấn ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      (_localData['education'] as List).removeAt(index);
                      _rebuildControllersFromData();
                      _updateData();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildTextField(
              label: 'Bằng cấp',
              value: edu['degree'],
              controllerKey: 'education::$index::degree',
              onChanged: (val) {
                edu['degree'] = val;
                _updateData();
              },
            ),
            _buildTextField(
              label: 'Trường',
              value: edu['school'],
              controllerKey: 'education::$index::school',
              onChanged: (val) {
                edu['school'] = val;
                _updateData();
              },
            ),
            _buildTextField(
              label: 'Năm',
              value: edu['year'],
              controllerKey: 'education::$index::year',
              onChanged: (val) {
                edu['year'] = val;
                _updateData();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Skills Form
  Widget _buildSkillsForm() {
    final skills = _localData['skills'] ?? [];
    return Column(
      children: [
        ...List.generate(skills.length, (index) {
          return _buildSkillCard(skills[index], index);
        }),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              skills.add({
                'name': '',
                'level': 'Intermediate',
              });
              _rebuildControllersFromData();
              _updateData();
            });
          },
          icon: const Icon(Icons.add),
          label: const Text('Thêm kỹ năng'),
        ),
      ],
    );
  }

  Widget _buildSkillCard(Map<String, dynamic> skill, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Tên kỹ năng',
                    value: skill['name'],
                    controllerKey: 'skills::$index::name',
                    onChanged: (val) {
                      skill['name'] = val;
                      _updateData();
                    },
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() {
                  (_localData['skills'] as List).removeAt(index);
                  _rebuildControllersFromData();
                  _updateData();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // Certifications Form
  Widget _buildCertificationsForm() {
    final certs = _localData['certifications'] ?? [];
    return Column(
      children: [
        ...List.generate(certs.length, (index) {
          return _buildCertCard(certs[index], index);
        }),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              certs.add({
                'name': '',
                'issuer': '',
                'year': '',
              });
              _rebuildControllersFromData();
              _updateData();
            });
          },
          icon: const Icon(Icons.add),
          label: const Text('Thêm chứng chỉ'),
        ),
      ],
    );
  }

  Widget _buildCertCard(Map<String, dynamic> cert, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Chứng chỉ ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      (_localData['certifications'] as List).removeAt(index);
                      _rebuildControllersFromData();
                      _updateData();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildTextField(
              label: 'Tên chứng chỉ',
              value: cert['name'],
              controllerKey: 'certifications::$index::name',
              onChanged: (val) {
                cert['name'] = val;
                _updateData();
              },
            ),
            _buildTextField(
              label: 'Tổ chức cấp',
              value: cert['issuer'],
              controllerKey: 'certifications::$index::issuer',
              onChanged: (val) {
                cert['issuer'] = val;
                _updateData();
              },
            ),
            _buildTextField(
              label: 'Năm',
              value: cert['year'],
              controllerKey: 'certifications::$index::year',
              onChanged: (val) {
                cert['year'] = val;
                _updateData();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Activities Form
  Widget _buildActivitiesForm() {
    final activities = _localData['activities'] ?? [];
    return Column(
      children: [
        ...List.generate(activities.length, (index) {
          final a = activities[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Hoạt động ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            (_localData['activities'] as List).removeAt(index);
                            _rebuildControllersFromData();
                            _updateData();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    label: 'Tên hoạt động / tổ chức',
                    value: a['organization'],
                    controllerKey: 'activities::$index::organization',
                    onChanged: (val) {
                      a['organization'] = val;
                      _updateData();
                    },
                  ),
                  _buildTextField(
                    label: 'Vai trò',
                    value: a['role'],
                    controllerKey: 'activities::$index::role',
                    onChanged: (val) {
                      a['role'] = val;
                      _updateData();
                    },
                  ),
                  _buildTextField(
                    label: 'Thời gian',
                    value: a['duration'],
                    controllerKey: 'activities::$index::duration',
                    onChanged: (val) {
                      a['duration'] = val;
                      _updateData();
                    },
                  ),
                  _buildTextField(
                    label: 'Mô tả',
                    value: a['description'],
                    controllerKey: 'activities::$index::description',
                    maxLines: 3,
                    onChanged: (val) {
                      a['description'] = val;
                      _updateData();
                    },
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              activities.add({
                'organization': '',
                'role': '',
                'duration': '',
                'description': '',
              });
              _rebuildControllersFromData();
              _updateData();
            });
          },
          icon: const Icon(Icons.add),
          label: const Text('Thêm hoạt động'),
        ),
      ],
    );
  }

  // Awards Form
  Widget _buildAwardsForm() {
    final awards = _localData['awards'] ?? [];
    return Column(
      children: [
        ...List.generate(awards.length, (index) {
          final a = awards[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Danh hiệu ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            (_localData['awards'] as List).removeAt(index);
                            _rebuildControllersFromData();
                            _updateData();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    label: 'Tên danh hiệu / giải thưởng',
                    value: a['name'],
                    controllerKey: 'awards::$index::name',
                    onChanged: (val) {
                      a['name'] = val;
                      _updateData();
                    },
                  ),
                  _buildTextField(
                    label: 'Năm',
                    value: a['year'],
                    controllerKey: 'awards::$index::year',
                    onChanged: (val) {
                      a['year'] = val;
                      _updateData();
                    },
                  ),
                  _buildTextField(
                    label: 'Mô tả / ghi chú',
                    value: a['note'],
                    controllerKey: 'awards::$index::note',
                    maxLines: 2,
                    onChanged: (val) {
                      a['note'] = val;
                      _updateData();
                    },
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              awards.add({
                'name': '',
                'year': '',
                'note': '',
              });
              _rebuildControllersFromData();
              _updateData();
            });
          },
          icon: const Icon(Icons.add),
          label: const Text('Thêm danh hiệu / giải thưởng'),
        ),
      ],
    );
  }

  // Languages Form
  Widget _buildLanguagesForm() {
    final langs = _localData['languages'] ?? [];
    return Column(
      children: [
        ...List.generate(langs.length, (index) {
          final l = langs[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Ngôn ngữ',
                      value: l['name'],
                      controllerKey: 'languages::$index::name',
                      onChanged: (val) {
                        l['name'] = val;
                        _updateData();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 140,
                    child: _buildTextField(
                      label: 'Trình độ',
                      value: l['level'] ?? 'Intermediate',
                      controllerKey: 'languages::$index::level',
                      onChanged: (val) {
                        l['level'] = val;
                        _updateData();
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        (_localData['languages'] as List).removeAt(index);
                        _rebuildControllersFromData();
                        _updateData();
                      });
                    },
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              langs.add({'name': '', 'level': 'Intermediate'});
              _rebuildControllersFromData();
              _updateData();
            });
          },
          icon: const Icon(Icons.add),
          label: const Text('Thêm ngôn ngữ'),
        ),
      ],
    );
  }

  // References Form
  Widget _buildReferencesForm() {
    final refs = _localData['references'] ?? [];
    return Column(
      children: [
        ...List.generate(refs.length, (index) {
          final r = refs[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Người tham chiếu ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            (_localData['references'] as List).removeAt(index);
                            _rebuildControllersFromData();
                            _updateData();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                    _buildTextField(
                      label: 'Tên',
                      value: r['name'],
                      controllerKey: 'references::$index::name',
                      onChanged: (val) {
                        r['name'] = val;
                        _updateData();
                      },
                    ),
                    _buildTextField(
                      label: 'Chức vụ',
                      value: r['position'],
                      controllerKey: 'references::$index::position',
                      onChanged: (val) {
                        r['position'] = val;
                        _updateData();
                      },
                    ),
                    _buildTextField(
                      label: 'Công ty / Tổ chức',
                      value: r['company'],
                      controllerKey: 'references::$index::company',
                      onChanged: (val) {
                        r['company'] = val;
                        _updateData();
                      },
                    ),
                    _buildTextField(
                      label: 'Số điện thoại / Email',
                      value: r['phone'],
                      controllerKey: 'references::$index::phone',
                      onChanged: (val) {
                        r['phone'] = val;
                        _updateData();
                      },
                    ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              refs.add({'name': '', 'position': '', 'company': '', 'phone': ''});
              _rebuildControllersFromData();
              _updateData();
            });
          },
          icon: const Icon(Icons.add),
          label: const Text('Thêm người tham chiếu'),
        ),
      ],
    );
  }

  // Helper: Build TextField with Speech-to-Text
  Widget _buildTextField({
    required String label,
    dynamic value,
    required Function(String) onChanged,
    int maxLines = 1,
    IconData? icon,
    String? controllerKey,
  }) {
    final TextEditingController? ctrl;
    if (controllerKey != null) {
      _createControllerIfNeeded(controllerKey, value?.toString() ?? '');
      ctrl = _controllerFor(controllerKey);
    } else {
      ctrl = null;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SpeechTextField(
        controller: ctrl ?? TextEditingController(text: value?.toString() ?? ''),
        label: label,
        hint: 'Nhập hoặc nói $label',
        prefixIcon: icon,
        maxLines: maxLines,
      ),
    );
  }
}

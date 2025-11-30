class JobPosting {
  final String id;
  final String title;
  final String company;
  final String location;
  final String salary;
  final String type; // Full-time, Part-time, Internship
  final String level; // Junior, Mid, Senior
  final String logoUrl;
  final DateTime postedDate;
  final List<String> tags;

  JobPosting({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.salary,
    required this.type,
    required this.level,
    required this.logoUrl,
    required this.postedDate,
    required this.tags,
  });
}

// Mock data cho các tin tuyển dụng
final List<JobPosting> mockJobPostings = [
  JobPosting(
    id: '1',
    title: 'Flutter Developer',
    company: 'FPT Software',
    location: 'Hà Nội',
    salary: '15-25 triệu',
    type: 'Full-time',
    level: 'Junior',
    logoUrl: 'https://via.placeholder.com/150/0066CC/FFFFFF?text=FPT',
    postedDate: DateTime.now().subtract(const Duration(hours: 2)),
    tags: ['Flutter', 'Dart', 'Mobile'],
  ),
  JobPosting(
    id: '2',
    title: 'Backend Developer (Node.js)',
    company: 'VNG Corporation',
    location: 'TP. Hồ Chí Minh',
    salary: '20-35 triệu',
    type: 'Full-time',
    level: 'Mid',
    logoUrl: 'https://via.placeholder.com/150/FF6600/FFFFFF?text=VNG',
    postedDate: DateTime.now().subtract(const Duration(hours: 5)),
    tags: ['Node.js', 'MongoDB', 'API'],
  ),
  JobPosting(
    id: '3',
    title: 'UI/UX Designer',
    company: 'Tiki',
    location: 'Hà Nội',
    salary: '12-20 triệu',
    type: 'Full-time',
    level: 'Junior',
    logoUrl: 'https://via.placeholder.com/150/0099FF/FFFFFF?text=Tiki',
    postedDate: DateTime.now().subtract(const Duration(days: 1)),
    tags: ['Figma', 'UI/UX', 'Design'],
  ),
  JobPosting(
    id: '4',
    title: 'React Native Developer',
    company: 'Shopee Vietnam',
    location: 'TP. Hồ Chí Minh',
    salary: '18-30 triệu',
    type: 'Full-time',
    level: 'Mid',
    logoUrl: 'https://via.placeholder.com/150/FF5722/FFFFFF?text=Shopee',
    postedDate: DateTime.now().subtract(const Duration(days: 1)),
    tags: ['React Native', 'JavaScript', 'Mobile'],
  ),
  JobPosting(
    id: '5',
    title: 'Data Analyst Intern',
    company: 'Grab Vietnam',
    location: 'Hà Nội',
    salary: '5-8 triệu',
    type: 'Internship',
    level: 'Junior',
    logoUrl: 'https://via.placeholder.com/150/00B14F/FFFFFF?text=Grab',
    postedDate: DateTime.now().subtract(const Duration(days: 2)),
    tags: ['Python', 'SQL', 'Data Analysis'],
  ),
  JobPosting(
    id: '6',
    title: 'Senior Java Developer',
    company: 'Viettel Software',
    location: 'Hà Nội',
    salary: '30-50 triệu',
    type: 'Full-time',
    level: 'Senior',
    logoUrl: 'https://via.placeholder.com/150/E60012/FFFFFF?text=Viettel',
    postedDate: DateTime.now().subtract(const Duration(days: 2)),
    tags: ['Java', 'Spring Boot', 'Microservices'],
  ),
  JobPosting(
    id: '7',
    title: 'DevOps Engineer',
    company: 'MOMO',
    location: 'TP. Hồ Chí Minh',
    salary: '25-40 triệu',
    type: 'Full-time',
    level: 'Mid',
    logoUrl: 'https://via.placeholder.com/150/A50064/FFFFFF?text=MOMO',
    postedDate: DateTime.now().subtract(const Duration(days: 3)),
    tags: ['Docker', 'Kubernetes', 'AWS'],
  ),
  JobPosting(
    id: '8',
    title: 'QA Tester',
    company: 'VinGroup',
    location: 'Hà Nội',
    salary: '10-18 triệu',
    type: 'Full-time',
    level: 'Junior',
    logoUrl: 'https://via.placeholder.com/150/004EA2/FFFFFF?text=VinGroup',
    postedDate: DateTime.now().subtract(const Duration(days: 3)),
    tags: ['Testing', 'Selenium', 'Manual Test'],
  ),
];

enum EmploymentType {
  fullTime,
  partTime,
  internship,
  freelance,
  contract,
  remote,
  temporary;

  String get displayName {
    switch (this) {
      case EmploymentType.fullTime: return 'Toàn thời gian';
      case EmploymentType.partTime: return 'Bán thời gian';
      case EmploymentType.internship: return 'Thực tập';
      case EmploymentType.freelance: return 'Freelance';
      case EmploymentType.contract: return 'Hợp đồng';
      case EmploymentType.remote: return 'Làm việc từ xa';
      case EmploymentType.temporary: return 'Thời vụ';
    }
  }

  static List<String> get valuesList => values.map((e) => e.displayName).toList();
}

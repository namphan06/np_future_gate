enum ExperienceLevel {
  noExperience,
  underOneYear,
  oneYear,
  twoYears,
  threeYears,
  fourYears,
  fiveYears,
  overFiveYears,
  intern,
  fresher,
  junior,
  middle,
  senior,
  lead,
  manager,
  director;

  String get displayName {
    switch (this) {
      case ExperienceLevel.noExperience: return 'Chưa có kinh nghiệm';
      case ExperienceLevel.underOneYear: return 'Dưới 1 năm';
      case ExperienceLevel.oneYear: return '1 năm';
      case ExperienceLevel.twoYears: return '2 năm';
      case ExperienceLevel.threeYears: return '3 năm';
      case ExperienceLevel.fourYears: return '4 năm';
      case ExperienceLevel.fiveYears: return '5 năm';
      case ExperienceLevel.overFiveYears: return 'Trên 5 năm';
      case ExperienceLevel.intern: return 'Thực tập sinh';
      case ExperienceLevel.fresher: return 'Mới tốt nghiệp';
      case ExperienceLevel.junior: return 'Junior';
      case ExperienceLevel.middle: return 'Middle';
      case ExperienceLevel.senior: return 'Senior';
      case ExperienceLevel.lead: return 'Trưởng nhóm';
      case ExperienceLevel.manager: return 'Quản lý';
      case ExperienceLevel.director: return 'Giám đốc';
    }
  }

  static List<String> get valuesList => values.map((e) => e.displayName).toList();
}

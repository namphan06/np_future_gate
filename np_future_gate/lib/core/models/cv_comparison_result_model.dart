/// Model representing the result of comparing multiple CVs for a job.
class CVComparisonResult {

  CVComparisonResult({
    required this.jobTitle,
    required this.candidates,
    required this.recommendation,
    this.comparisonNotes = '',
  });

  factory CVComparisonResult.fromJson(
    Map<String, dynamic> json,
    List<String> names,
  ) {
    final list = json['candidates'] as List? ?? [];
    final candidates = <CandidateScore>[];

    for (int i = 0; i < list.length; i++) {
      final c = list[i] as Map<String, dynamic>;
      candidates.add(CandidateScore(
        name: _parseString(c['name']) ??
            (i < names.length ? names[i] : 'Ứng viên ${i + 1}'),
        rank: (c['rank'] as num?)?.toInt() ?? (i + 1),
        skillsScore: (c['skills_score'] as num?)?.toDouble() ?? 0,
        experienceScore: (c['experience_score'] as num?)?.toDouble() ?? 0,
        educationScore: (c['education_score'] as num?)?.toDouble() ?? 0,
        overallScore: (c['overall_score'] as num?)?.toDouble() ?? 0,
        potentialScore: (c['potential_score'] as num?)?.toDouble() ?? 0,
        strengths: _parseStringList(c['strengths']),
        weaknesses: _parseStringList(c['weaknesses']),
        summary: _parseString(c['summary']) ?? '',
      ));
    }

    candidates.sort((a, b) => a.rank.compareTo(b.rank));

    return CVComparisonResult(
      jobTitle: _parseString(json['job_title']) ?? '',
      candidates: candidates,
      recommendation: _parseString(json['recommendation']) ?? '',
      comparisonNotes: _parseString(json['comparison_notes']) ?? '',
    );
  }
  final String jobTitle;
  final List<CandidateScore> candidates;
  final String recommendation;
  final String comparisonNotes;

  static String? _parseString(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    if (v is List) return v.join('. ');
    return v.toString();
  }

  static List<String> _parseStringList(dynamic v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    if (v is String) return [v];
    return [];
  }
}

/// Model representing a single candidate's score in a comparison.
class CandidateScore {

  CandidateScore({
    required this.name,
    required this.rank,
    required this.skillsScore,
    required this.experienceScore,
    required this.educationScore,
    required this.overallScore,
    required this.potentialScore,
    required this.strengths,
    required this.weaknesses,
    required this.summary,
  });
  final String name;
  final int rank;
  final double skillsScore;
  final double experienceScore;
  final double educationScore;
  final double overallScore;
  final double potentialScore;
  final List<String> strengths;
  final List<String> weaknesses;
  final String summary;
}

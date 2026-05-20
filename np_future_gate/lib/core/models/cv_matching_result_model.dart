/// Model representing the result of CV-to-Job matching analysis.
class CVMatchingResult {
  final double overallScore;
  final double semanticSimilarity;
  final double keywordMatchScore;
  final String matchingSummary;
  final List<String> matchingPoints;
  final List<String> missingPoints;
  final Map<String, dynamic> parsedData;

  CVMatchingResult({
    required this.overallScore,
    required this.semanticSimilarity,
    required this.keywordMatchScore,
    required this.matchingSummary,
    required this.matchingPoints,
    required this.missingPoints,
    required this.parsedData,
  });

  factory CVMatchingResult.fromMock(double s) => CVMatchingResult(
    overallScore: s,
    semanticSimilarity: s / 100,
    keywordMatchScore: s,
    matchingSummary: 'Không thể phân tích.',
    matchingPoints: [],
    missingPoints: ['Lỗi AI'],
    parsedData: {'Status': 'Mock'},
  );

  Map<String, dynamic> toJson() => {
    'overall_score': overallScore,
    'semantic_similarity': semanticSimilarity,
    'keyword_match_score': keywordMatchScore,
    'matching_summary': matchingSummary,
    'matching_points': matchingPoints,
    'missing_points': missingPoints,
    'parsed_data': parsedData,
  };
}

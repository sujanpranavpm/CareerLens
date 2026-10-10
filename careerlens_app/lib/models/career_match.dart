class CareerMatchResult {
  final String roleId;
  final String roleTitle;
  final double matchPercentage;
  final List<String> matchedSkills;
  final List<String> developingSkills;
  final List<String> missingSkills;

  CareerMatchResult({
    required this.roleId,
    required this.roleTitle,
    required this.matchPercentage,
    this.matchedSkills = const [],
    this.developingSkills = const [],
    this.missingSkills = const [],
  });

  factory CareerMatchResult.fromJson(Map<String, dynamic> json) {
    return CareerMatchResult(
      roleId: json['role_id'] ?? '',
      roleTitle: json['role_title'] ?? '',
      matchPercentage: (json['match_percentage'] as num?)?.toDouble() ?? 0.0,
      matchedSkills: (json['matched_skills'] as List<dynamic>?)
              ?.map((s) => s.toString())
              .toList() ??
          [],
      developingSkills: (json['developing_skills'] as List<dynamic>?)
              ?.map((s) => s.toString())
              .toList() ??
          [],
      missingSkills: (json['missing_skills'] as List<dynamic>?)
              ?.map((s) => s.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role_id': roleId,
      'role_title': roleTitle,
      'match_percentage': matchPercentage,
      'matched_skills': matchedSkills,
      'developing_skills': developingSkills,
      'missing_skills': missingSkills,
    };
  }
}

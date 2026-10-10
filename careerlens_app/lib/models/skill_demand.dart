class SkillDemandItem {
  final String skill;
  final String demandLevel;
  final int frequency;
  final double percentage;

  SkillDemandItem({
    required this.skill,
    required this.demandLevel,
    required this.frequency,
    required this.percentage,
  });

  factory SkillDemandItem.fromJson(Map<String, dynamic> json) {
    return SkillDemandItem(
      skill: json['skill'] ?? '',
      demandLevel: json['demand_level'] ?? 'Low',
      frequency: json['frequency'] ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skill': skill,
      'demand_level': demandLevel,
      'frequency': frequency,
      'percentage': percentage,
    };
  }
}

class IndustryDemandResponse {
  final int totalJdsAnalyzed;
  final String? roleId;
  final List<SkillDemandItem> skills;

  IndustryDemandResponse({
    required this.totalJdsAnalyzed,
    this.roleId,
    required this.skills,
  });

  factory IndustryDemandResponse.fromJson(Map<String, dynamic> json) {
    return IndustryDemandResponse(
      totalJdsAnalyzed: json['total_jds_analyzed'] ?? 0,
      roleId: json['role_id'],
      skills: (json['skills'] as List<dynamic>?)
              ?.map((s) => SkillDemandItem.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

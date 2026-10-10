class SkillTrendItem {
  final String skill;
  final String demandLevel;
  final int frequency;
  final double percentage;
  final double baselinePercentage;
  final double changePercentage;
  final String trendDirection; // "rising", "emerging", "stable", "declining"
  final bool isHotTech;

  SkillTrendItem({
    required this.skill,
    required this.demandLevel,
    required this.frequency,
    required this.percentage,
    required this.baselinePercentage,
    required this.changePercentage,
    required this.trendDirection,
    required this.isHotTech,
  });

  factory SkillTrendItem.fromJson(Map<String, dynamic> json) {
    return SkillTrendItem(
      skill: json['skill'] ?? '',
      demandLevel: json['demand_level'] ?? 'Low',
      frequency: json['frequency'] ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      baselinePercentage: (json['baseline_percentage'] as num?)?.toDouble() ?? 0.0,
      changePercentage: (json['change_percentage'] as num?)?.toDouble() ?? 0.0,
      trendDirection: json['trend_direction'] ?? 'stable',
      isHotTech: json['is_hot_tech'] ?? false,
    );
  }
}

class IndustryTrendsResponse {
  final String roleId;
  final int totalJdsAnalyzed;
  final List<SkillTrendItem> trends;

  IndustryTrendsResponse({
    required this.roleId,
    required this.totalJdsAnalyzed,
    required this.trends,
  });

  factory IndustryTrendsResponse.fromJson(Map<String, dynamic> json) {
    return IndustryTrendsResponse(
      roleId: json['role_id'] ?? 'all',
      totalJdsAnalyzed: json['total_jds_analyzed'] ?? 0,
      trends: (json['trends'] as List<dynamic>?)
              ?.map((t) => SkillTrendItem.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

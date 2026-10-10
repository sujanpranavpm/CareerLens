class SkillGapItem {
  final String skill;
  final double roleImportance;
  final String demandLevel;
  final int demandScore;
  final double gapPriority;
  final double studentProficiency;
  final String status;

  SkillGapItem({
    required this.skill,
    required this.roleImportance,
    required this.demandLevel,
    required this.demandScore,
    required this.gapPriority,
    required this.studentProficiency,
    required this.status,
  });

  factory SkillGapItem.fromJson(Map<String, dynamic> json) {
    return SkillGapItem(
      skill: json['skill'] ?? '',
      roleImportance: (json['role_importance'] as num?)?.toDouble() ?? 1.0,
      demandLevel: json['demand_level'] ?? 'Low',
      demandScore: json['demand_score'] ?? 1,
      gapPriority: (json['gap_priority'] as num?)?.toDouble() ?? 0.0,
      studentProficiency: (json['student_proficiency'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'missing',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skill': skill,
      'role_importance': roleImportance,
      'demand_level': demandLevel,
      'demand_score': demandScore,
      'gap_priority': gapPriority,
      'student_proficiency': studentProficiency,
      'status': status,
    };
  }
}

class SkillGapResponse {
  final int studentId;
  final String roleId;
  final String roleTitle;
  final int totalGaps;
  final List<SkillGapItem> gaps;

  SkillGapResponse({
    required this.studentId,
    required this.roleId,
    required this.roleTitle,
    required this.totalGaps,
    required this.gaps,
  });

  factory SkillGapResponse.fromJson(Map<String, dynamic> json) {
    return SkillGapResponse(
      studentId: json['student_id'] ?? 0,
      roleId: json['role_id'] ?? '',
      roleTitle: json['role_title'] ?? '',
      totalGaps: json['total_gaps'] ?? 0,
      gaps: (json['gaps'] as List<dynamic>?)
              ?.map((g) => SkillGapItem.fromJson(g as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class RoadmapResource {
  final String title;
  final String url;
  final String type;
  final String estimatedTime;

  RoadmapResource({
    required this.title,
    required this.url,
    required this.type,
    required this.estimatedTime,
  });

  factory RoadmapResource.fromJson(Map<String, dynamic> json) {
    return RoadmapResource(
      title: json['title'] ?? '',
      url: json['url'] ?? '',
      type: json['type'] ?? 'Course',
      estimatedTime: json['estimated_time'] ?? '',
    );
  }
}

class RoadmapStep {
  final int step;
  final String skill;
  final String status;
  final List<RoadmapResource> resources;

  RoadmapStep({
    required this.step,
    required this.skill,
    this.status = 'missing',
    this.resources = const [],
  });

  factory RoadmapStep.fromJson(Map<String, dynamic> json) {
    return RoadmapStep(
      step: json['step'] ?? 1,
      skill: json['skill'] ?? '',
      status: json['status'] ?? 'missing',
      resources: (json['resources'] as List<dynamic>?)
              ?.map((r) => RoadmapResource.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class RoadmapResponse {
  final String roleId;
  final String roleTitle;
  final String description;
  final int totalSteps;
  final int pendingSteps;
  final List<RoadmapStep> steps;

  RoadmapResponse({
    required this.roleId,
    required this.roleTitle,
    required this.description,
    required this.totalSteps,
    this.pendingSteps = 0,
    required this.steps,
  });

  factory RoadmapResponse.fromJson(Map<String, dynamic> json) {
    return RoadmapResponse(
      roleId: json['role_id'] ?? '',
      roleTitle: json['role_title'] ?? '',
      description: json['description'] ?? '',
      totalSteps: json['total_steps'] ?? 0,
      pendingSteps: json['pending_steps'] ?? 0,
      steps: (json['steps'] as List<dynamic>?)
              ?.map((s) => RoadmapStep.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

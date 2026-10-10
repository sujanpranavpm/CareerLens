class RoadmapProgress {
  final int studentId;
  final String roleId;
  final int totalSteps;
  final int completedCount;
  final double completionPercentage;
  final List<String> completedSkills;

  RoadmapProgress({
    required this.studentId,
    required this.roleId,
    required this.totalSteps,
    required this.completedCount,
    required this.completionPercentage,
    this.completedSkills = const [],
  });

  factory RoadmapProgress.fromJson(Map<String, dynamic> json) {
    return RoadmapProgress(
      studentId: json['student_id'] ?? 0,
      roleId: json['role_id'] ?? '',
      totalSteps: json['total_steps'] ?? 0,
      completedCount: json['completed_count'] ?? 0,
      completionPercentage: (json['completion_percentage'] as num?)?.toDouble() ?? 0.0,
      completedSkills: (json['completed_skills'] as List<dynamic>?)
              ?.map((s) => s.toString())
              .toList() ??
          [],
    );
  }
}

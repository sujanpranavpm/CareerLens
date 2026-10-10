class RoleSkill {
  final String name;
  final int importance;

  RoleSkill({
    required this.name,
    required this.importance,
  });

  factory RoleSkill.fromJson(Map<String, dynamic> json) {
    return RoleSkill(
      name: json['name'] ?? '',
      importance: json['importance'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'importance': importance,
    };
  }
}

class CareerRole {
  final String id;
  final String title;
  final String onetCode;
  final String description;
  final int skillCount;
  final List<RoleSkill> requiredSkills;

  CareerRole({
    required this.id,
    required this.title,
    this.onetCode = '',
    this.description = '',
    this.skillCount = 0,
    this.requiredSkills = const [],
  });

  factory CareerRole.fromJson(Map<String, dynamic> json) {
    var rawSkills = json['required_skills'] as List<dynamic>?;
    List<RoleSkill> parsedSkills = [];
    if (rawSkills != null) {
      parsedSkills = rawSkills
          .map((s) => RoleSkill.fromJson(s as Map<String, dynamic>))
          .toList();
    }

    return CareerRole(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      onetCode: json['onet_code'] ?? '',
      description: json['description'] ?? '',
      skillCount: json['skill_count'] ?? parsedSkills.length,
      requiredSkills: parsedSkills,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'onet_code': onetCode,
      'description': description,
      'skill_count': skillCount,
      'required_skills': requiredSkills.map((s) => s.toJson()).toList(),
    };
  }
}

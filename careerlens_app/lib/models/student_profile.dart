class SkillItem {
  final String name;
  final int proficiency;

  SkillItem({
    required this.name,
    required this.proficiency,
  });

  factory SkillItem.fromJson(Map<String, dynamic> json) {
    return SkillItem(
      name: json['name'] ?? json['skill_name'] ?? '',
      proficiency: json['proficiency'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'proficiency': proficiency,
    };
  }
}

class ProjectItem {
  final String title;
  final String description;

  ProjectItem({
    required this.title,
    this.description = '',
  });

  factory ProjectItem.fromJson(Map<String, dynamic> json) {
    return ProjectItem(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
    };
  }
}

class CertificationItem {
  final String name;
  final String issuer;
  final int? year;

  CertificationItem({
    required this.name,
    this.issuer = '',
    this.year,
  });

  factory CertificationItem.fromJson(Map<String, dynamic> json) {
    return CertificationItem(
      name: json['name'] ?? '',
      issuer: json['issuer'] ?? '',
      year: json['year'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'issuer': issuer,
      'year': year,
    };
  }
}

class StudentProfile {
  final int? id;
  final String name;
  final String degree;
  final String branch;
  final int year;
  final double cgpa;
  final List<SkillItem> skills;
  final List<ProjectItem> projects;
  final List<CertificationItem> certifications;

  StudentProfile({
    this.id,
    required this.name,
    required this.degree,
    required this.branch,
    required this.year,
    required this.cgpa,
    this.skills = const [],
    this.projects = const [],
    this.certifications = const [],
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: json['id'],
      name: json['name'] ?? '',
      degree: json['degree'] ?? '',
      branch: json['branch'] ?? '',
      year: json['year'] ?? 1,
      cgpa: (json['cgpa'] as num?)?.toDouble() ?? 0.0,
      skills: (json['skills'] as List<dynamic>?)
              ?.map((s) => SkillItem.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      projects: (json['projects'] as List<dynamic>?)
              ?.map((p) => ProjectItem.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      certifications: (json['certifications'] as List<dynamic>?)
              ?.map((c) => CertificationItem.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'degree': degree,
      'branch': branch,
      'year': year,
      'cgpa': cgpa,
      'skills': skills.map((s) => s.toJson()).toList(),
      'projects': projects.map((p) => p.toJson()).toList(),
      'certifications': certifications.map((c) => c.toJson()).toList(),
    };
  }
}

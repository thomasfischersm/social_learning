class GeneratedSkillDegree {
  final String name;
  final String criteria;
  final List<String> lessons;

  GeneratedSkillDegree({
    required this.name,
    required this.criteria,
    required this.lessons,
  });

  factory GeneratedSkillDegree.fromJson(Map<String, dynamic> json) {
    final lessonsJson = json['lessons'] as List<dynamic>? ?? [];
    return GeneratedSkillDegree(
      name: json['name'] as String? ?? '',
      criteria: json['criteria'] as String? ?? '',
      lessons: lessonsJson.map((e) => e.toString()).toList(),
    );
  }
}

class GeneratedSkillDimension {
  final String name;
  final String description;
  final List<GeneratedSkillDegree> degrees;

  GeneratedSkillDimension({
    required this.name,
    required this.description,
    required this.degrees,
  });

  factory GeneratedSkillDimension.fromJson(Map<String, dynamic> json) {
    final degreesJson = json['degrees'] as List<dynamic>? ?? [];
    return GeneratedSkillDimension(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      degrees: degreesJson
          .map((e) => GeneratedSkillDegree.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SkillRubricGenerationResponse {
  final List<GeneratedSkillDimension> dimensions;

  SkillRubricGenerationResponse({required this.dimensions});

  factory SkillRubricGenerationResponse.fromJson(Map<String, dynamic> json) {
    final dimsJson = json['dimensions'] as List<dynamic>? ?? [];
    final dims = dimsJson
        .map((e) => GeneratedSkillDimension.fromJson(e as Map<String, dynamic>))
        .toList();
    return SkillRubricGenerationResponse(dimensions: dims);
  }
}

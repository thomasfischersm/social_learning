import 'dart:convert';

class GeneratedCourse {
  final List<GeneratedLevel> levels;

  GeneratedCourse({required this.levels});

  factory GeneratedCourse.fromJson(Map<String, dynamic> json) {
    final levelsJson = json['levels'] as List<dynamic>? ?? [];
    final levels = levelsJson.map((l) => GeneratedLevel.fromJson(l)).toList();
    return GeneratedCourse(levels: levels);
  }

  factory GeneratedCourse.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString);
    return GeneratedCourse.fromJson(json);
  }
}

class GeneratedLevel {
  final String title;
  final String description;
  final List<GeneratedLesson> lessons;

  GeneratedLevel({
    required this.title,
    required this.description,
    required this.lessons,
  });

  factory GeneratedLevel.fromJson(Map<String, dynamic> json) {
    final lessonsJson = json['lessons'] as List<dynamic>? ?? [];
    final lessons = lessonsJson.map((l) => GeneratedLesson.fromJson(l)).toList();

    return GeneratedLevel(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      lessons: lessons,
    );
  }
}

class GeneratedLesson {
  final String title;
  final String synopsis;
  final String instructions;
  final List<String> graduationRequirements;

  GeneratedLesson({
    required this.title,
    required this.synopsis,
    required this.instructions,
    required this.graduationRequirements,
  });

  factory GeneratedLesson.fromJson(Map<String, dynamic> json) {
    final requirements = (json['graduationRequirements'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList() ??
        [];

    return GeneratedLesson(
      title: json['title'] ?? '',
      synopsis: json['synopsis'] ?? '',
      instructions: json['instructions'] ?? '',
      graduationRequirements: requirements,
    );
  }
}

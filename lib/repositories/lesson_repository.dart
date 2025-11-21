import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/lesson_models.dart';

class LessonRepository {
  LessonRepository._();

  static final LessonRepository instance = LessonRepository._();

  Future<CourseData> loadCourse() async {
    final String manifestRaw = await rootBundle.loadString('assets/data/course_manifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestRaw) as Map<String, dynamic>;
    final List<dynamic> levelFiles = manifestMap['levelFiles'] as List<dynamic>? ?? [];

    final List<LessonData> levels = [];
    for (final dynamic path in levelFiles) {
      if (path is! String || path.isEmpty) continue;
      final String levelRaw = await rootBundle.loadString(path);
      final Map<String, dynamic> levelJson = json.decode(levelRaw) as Map<String, dynamic>;
      levels.add(LessonData.fromJson(levelJson));
    }

    return CourseData(
      courseTitle: manifestMap['courseTitle'] as String? ?? 'Bahasa Inggris Dasar',
      levels: levels,
    );
  }
}

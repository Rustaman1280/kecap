class CourseData {
  CourseData({required this.courseTitle, required this.levels});

  final String courseTitle;
  final List<LessonData> levels;

  factory CourseData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawLevels = json['levels'] as List<dynamic>? ?? [];
    return CourseData(
      courseTitle: json['courseTitle'] as String? ?? 'Bahasa Inggris Dasar',
      levels: rawLevels
          .map((item) => LessonData.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LessonData {
  LessonData({
    required this.levelId,
    required this.levelLabel,
    required this.sectionTitle,
    required this.lessonTitle,
    required this.xpToUnlock,
    required this.nextObjective,
    required this.streak,
    required this.streakGoal,
    required this.heartPercent,
    required this.questions,
  });

  final String levelId;
  final String levelLabel;
  final String sectionTitle;
  final String lessonTitle;
  final int xpToUnlock;
  final String nextObjective;
  final int streak;
  final int streakGoal;
  final double heartPercent;
  final List<QuestionData> questions;

  factory LessonData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawQuestions = json['questions'] as List<dynamic>? ?? [];
    return LessonData(
      levelId: json['levelId'] as String? ?? '',
      levelLabel: json['levelLabel'] as String? ?? 'Level',
      sectionTitle: json['sectionTitle'] as String? ?? 'BAGIAN 1, UNIT 1',
      lessonTitle: json['lessonTitle'] as String? ?? 'Pelajaran baru',
      xpToUnlock: json['xpToUnlock'] as int? ?? 10,
      nextObjective: json['nextObjective'] as String? ?? 'Tujuan berikutnya',
      streak: json['streak'] as int? ?? 0,
      streakGoal: json['streakGoal'] as int? ?? 10,
      heartPercent: (json['heartPercent'] as num?)?.toDouble() ?? 1.0,
      questions: rawQuestions
          .map((item) => QuestionData.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class QuestionData {
  QuestionData({
    required this.id,
    required this.categoryLabel,
    required this.prompt,
    required this.newWord,
    required this.hint,
    required this.answerSlots,
    required this.wordBank,
    required this.correctAnswer,
    required this.feedback,
  });

  final String id;
  final String categoryLabel;
  final String prompt;
  final String newWord;
  final String hint;
  final List<AnswerSlot> answerSlots;
  final List<String> wordBank;
  final List<String> correctAnswer;
  final String feedback;

  factory QuestionData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawSlots = json['answerSlots'] as List<dynamic>? ?? [];
    final List<dynamic> rawWordBank = json['wordBank'] as List<dynamic>? ?? [];
    final List<dynamic> rawCorrect = json['correctAnswer'] as List<dynamic>? ?? [];
    return QuestionData(
      id: json['id'] as String? ?? '',
      categoryLabel: json['categoryLabel'] as String? ?? '',
      prompt: json['prompt'] as String? ?? '',
      newWord: json['newWord'] as String? ?? '',
      hint: json['hint'] as String? ?? '',
        answerSlots: rawSlots.map((item) => AnswerSlot.fromJson(item)).toList(),
      wordBank: rawWordBank.map((word) => word as String? ?? '').toList(),
      correctAnswer: rawCorrect.map((word) => word as String? ?? '').toList(),
      feedback: json['feedback'] as String? ?? '',
    );
  }
}

class AnswerSlot {
  AnswerSlot({required this.text, required this.locked});

  final String text;
  final bool locked;

  factory AnswerSlot.fromJson(dynamic data) {
    if (data is String) {
      final String value = data;
      return AnswerSlot(
        text: value,
        locked: value.trim().isNotEmpty,
      );
    }

    if (data is Map<String, dynamic>) {
      return AnswerSlot(
        text: data['text'] as String? ?? '',
        locked: data['locked'] as bool? ?? false,
      );
    }

    return AnswerSlot(text: '', locked: false);
  }
}

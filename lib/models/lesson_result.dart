class LessonResult {
  const LessonResult({
    required this.completed,
    required this.lessonId,
    required this.xpEarned,
    required this.heartsLeft,
    required this.achievedStreak,
  });

  final bool completed;
  final String lessonId;
  final int xpEarned;
  final int heartsLeft;
  final int achievedStreak;
}

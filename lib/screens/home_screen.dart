import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/lesson_models.dart';
import '../models/lesson_result.dart';
import '../models/user_progress.dart';
import '../repositories/lesson_repository.dart';
import '../services/user_progress_service.dart';
import 'lesson_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.user, super.key});

  final User user;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<CourseData> _courseFuture;
  int _selectedLevelIndex = 0;
  bool _pendingAutoStart = false;
  UserProgress? _userProgress;
  bool _progressLoading = true;
  String? _progressError;

  final UserProgressService _progressService = UserProgressService.instance;

  @override
  void initState() {
    super.initState();
    _courseFuture = LessonRepository.instance.loadCourse();
    _loadProgress();
  }

  void _retry() {
    setState(() {
      _courseFuture = LessonRepository.instance.loadCourse();
    });
  }

  Future<void> _loadProgress() async {
    setState(() {
      _progressLoading = true;
      _progressError = null;
    });
    try {
      final progress = await _progressService.getOrCreateProgress(widget.user);
      if (!mounted) return;
      setState(() {
        _userProgress = progress;
        _selectedLevelIndex = progress.currentLevelIndex;
        _progressLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _progressError = error.toString();
        _progressLoading = false;
      });
    }
  }

  void _startLesson(LessonData lesson, int levelIndex, int totalLevels) {
    if (lesson.questions.isEmpty) {
      return;
    }

    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => LessonScreen(
          lesson: lesson,
        ),
      ),
    )
        .then((result) {
      if (!mounted) return;
      if (result is! LessonResult || !result.completed) {
        return;
      }
      final bool hasNext = levelIndex < totalLevels - 1;
      final int nextIndex = hasNext ? levelIndex + 1 : levelIndex;
      final UserProgress currentProgress = _userProgress ?? UserProgress.initial(widget.user.uid);
      final List<String> completedLevels = List<String>.from(currentProgress.completedLevelIds);
      final bool alreadyCompleted = completedLevels.contains(lesson.levelId);
      final bool shouldRecordCompletion = !alreadyCompleted;

      if (shouldRecordCompletion) {
        completedLevels.add(lesson.levelId);
      }

      final int xpDelta = shouldRecordCompletion ? result.xpEarned : 0;

      setState(() {
        _selectedLevelIndex = nextIndex;
        _pendingAutoStart = hasNext;
        _userProgress = currentProgress.copyWith(
          currentLevelIndex: nextIndex,
          totalXp: currentProgress.totalXp + xpDelta,
          lastStreak: result.achievedStreak,
          heartsLeft: result.heartsLeft,
          completedLevelIds: completedLevels,
        );
      });
      _progressService.updateAfterLesson(
        uid: widget.user.uid,
        newLevelIndex: nextIndex,
        result: result,
        xpDelta: xpDelta,
        completedLevelIds: completedLevels,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050E16),
      bottomNavigationBar: const _BottomNav(),
      body: SafeArea(
        child: FutureBuilder<CourseData>(
          future: _courseFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return _ErrorState(onRetry: _retry, message: 'Gagal memuat soal');
            }

            if (_progressLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_progressError != null) {
              return _ErrorState(onRetry: () => _loadProgress(), message: 'Gagal memuat progres');
            }

            final progress = _userProgress ?? UserProgress.initial(widget.user.uid);
            final course = snapshot.data!;
            if (course.levels.isEmpty) {
              return _ErrorState(onRetry: _retry);
            }

            final levels = course.levels;
            final int selectedIndex = _selectedLevelIndex.clamp(0, levels.length - 1);
            if (selectedIndex != _selectedLevelIndex) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() => _selectedLevelIndex = selectedIndex);
              });
            }
            final lesson = levels[selectedIndex];
            if (_pendingAutoStart) {
              _pendingAutoStart = false;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _startLesson(lesson, selectedIndex, levels.length);
              });
            }

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                _TopStats(
                  user: widget.user,
                  progress: progress,
                ),
                const SizedBox(height: 20),
                _LevelSelector(
                  levels: levels,
                  selectedIndex: selectedIndex,
                  onSelected: (index) => _selectLevel(index, levels.length),
                ),
                const SizedBox(height: 16),
                _LessonCard(
                  lesson: lesson,
                  levelIndex: selectedIndex,
                  onStart: () => _startLesson(lesson, selectedIndex, levels.length),
                ),
                const SizedBox(height: 20),
                _LearningPath(
                  levels: levels,
                  selectedIndex: selectedIndex,
                  onNodeTap: (index) => _handlePathTap(index, levels),
                ),
                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }

  void _selectLevel(int index, int totalLevels) {
    if (index < 0 || index >= totalLevels) return;
    setState(() => _selectedLevelIndex = index);
  }

  void _handlePathTap(int index, List<LessonData> levels) {
    if (index < 0 || index >= levels.length) return;
    final lesson = levels[index];
    setState(() => _selectedLevelIndex = index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startLesson(lesson, index, levels.length);
    });
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry, this.message = 'Gagal memuat data'});

  final VoidCallback onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}

class _TopStats extends StatelessWidget {
  const _TopStats({required this.user, required this.progress});

  final User user;
  final UserProgress progress;

  @override
  Widget build(BuildContext context) {
    final photo = user.photoURL;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF182534), Color(0xFF0F1824)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white10),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 24, offset: Offset(0, 12)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF1A2531),
            backgroundImage: photo != null && photo.isNotEmpty ? NetworkImage(photo) : null,
            child: photo == null || photo.isEmpty
                ? Text(
                    (user.displayName?.isNotEmpty ?? false) ? user.displayName!.characters.first.toUpperCase() : 'K',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? 'Pengguna',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StatBadge(icon: Icons.star, label: '${progress.totalXp} XP', badgeColor: const Color(0xFF4AC3FF)),
                    const SizedBox(width: 8),
                    _StatBadge(icon: Icons.local_fire_department, label: '${progress.lastStreak}', badgeColor: const Color(0xFFFFC845)),
                    const SizedBox(width: 8),
                    _StatBadge(icon: Icons.favorite, label: '${progress.heartsLeft}', badgeColor: const Color(0xFFFF77B6)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.icon,
    required this.label,
    this.badgeColor,
  });

  final IconData icon;
  final String label;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: badgeColor ?? const Color(0xFF1A2531),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson, required this.onStart, required this.levelIndex});

  final LessonData lesson;
  final VoidCallback onStart;
  final int levelIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF6BF071), Color(0xFF2BBE65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                lesson.levelLabel,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('Level ${levelIndex + 1}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ),
              const Spacer(),
              const Icon(Icons.menu_book_outlined, color: Colors.white),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            lesson.sectionTitle,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            lesson.lessonTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${lesson.questions.length} soal • ${lesson.xpToUnlock} XP',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const _ProgressRing(),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  '${lesson.xpToUnlock} XP untuk membuka pelajaran berikutnya',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E1821),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Mulai belajar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white24,
          ),
        ),
        SizedBox(
          width: 70,
          height: 70,
          child: CircularProgressIndicator(
            value: 0.7,
            strokeWidth: 6,
            backgroundColor: Colors.white30,
            valueColor: const AlwaysStoppedAnimation(Color(0xFF0E1821)),
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.star, color: Color(0xFF2BBE65)),
        ),
      ],
    );
  }
}

class _LearningPath extends StatelessWidget {
  const _LearningPath({
    required this.levels,
    required this.selectedIndex,
    required this.onNodeTap,
  });

  final List<LessonData> levels;
  final int selectedIndex;
  final ValueChanged<int> onNodeTap;

  @override
  Widget build(BuildContext context) {
    if (levels.isEmpty) {
      return const SizedBox.shrink();
    }
    final int safeIndex = selectedIndex.clamp(0, levels.length - 1);
    final LessonData highlighted = levels[safeIndex];
    const int maxNodes = 10;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A24),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.route_outlined, color: Colors.white70),
              SizedBox(width: 8),
              Text(
                'Learning Path',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            highlighted.nextObjective,
            style: const TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 20),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: maxNodes,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final bool hasLesson = index < levels.length;
              final lesson = hasLesson ? levels[index] : null;
              final bool isActive = hasLesson && index == safeIndex;
              final bool isCompleted = hasLesson && index < safeIndex;
              final bool isLocked = !hasLesson || index > safeIndex;
              return _PathStep(
                lesson: lesson,
                index: index,
                isActive: isActive,
                isCompleted: isCompleted,
                isLocked: isLocked,
                isLast: index == maxNodes - 1,
                onTap: (!hasLesson || isLocked) ? null : () => onNodeTap(index),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PathStep extends StatelessWidget {
  const _PathStep({
    required this.lesson,
    required this.index,
    required this.isActive,
    required this.isCompleted,
    required this.isLocked,
    required this.isLast,
    required this.onTap,
  });

  final LessonData? lesson;
  final int index;
  final bool isActive;
  final bool isCompleted;
  final bool isLocked;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent = isActive
        ? const Color(0xFFFFB341)
        : (isCompleted ? const Color(0xFF55DF5D) : Colors.white24);

    final bool placeholder = lesson == null;
    final String levelChip = lesson?.levelLabel ?? 'LEVEL ${index + 1}';
    final String lessonTitle = lesson?.lessonTitle ?? 'Segera hadir';
    final String lessonMeta = placeholder
        ? 'Materi akan terbuka nanti'
        : '${lesson!.questions.length} soal • ${lesson!.xpToUnlock} XP';

    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              _PathBubble(
                index: index,
                isActive: isActive,
                isCompleted: isCompleted,
                isLocked: isLocked,
              ),
              if (!isLast)
                Container(
                  width: 3,
                  height: 48,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111B27),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accent.withOpacity(isLocked ? 0.2 : 0.4)),
                boxShadow: [
                  if (isActive)
                    BoxShadow(
                      color: accent.withOpacity(0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    levelChip.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.2,
                      color: Colors.white60,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lessonTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lessonMeta,
                    style: TextStyle(
                      color: placeholder || isLocked ? Colors.white30 : Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                  if (isLocked)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Tuntaskan level sebelumnya',
                        style: TextStyle(color: Colors.white30, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PathBubble extends StatelessWidget {
  const _PathBubble({
    required this.index,
    required this.isActive,
    required this.isCompleted,
    required this.isLocked,
  });

  final int index;
  final bool isActive;
  final bool isCompleted;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final Gradient? gradient = isActive
        ? const LinearGradient(colors: [Color(0xFFFFB341), Color(0xFFFF855E)])
        : null;
    final Color bgColor = isCompleted
        ? const Color(0xFF55DF5D)
        : (isLocked ? const Color(0xFF141E29) : const Color(0xFF1E2A36));
    final Color iconColor = isActive || isCompleted ? Colors.white : (isLocked ? Colors.white24 : Colors.white54);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        color: gradient == null ? bgColor : null,
        border: Border.all(color: Colors.white24, width: 2),
        boxShadow: [
          if (isActive)
            const BoxShadow(
              color: Color(0x40FFB341),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.star_rounded, color: iconColor, size: 30),
          Positioned(
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isLocked ? Colors.white54 : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF0B131B),
      selectedItemColor: const Color(0xFFFFB341),
      unselectedItemColor: Colors.white54,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.leaderboard_outlined), label: 'Leaderboard'),
        BottomNavigationBarItem(icon: Icon(Icons.smart_toy_outlined), label: 'Menu AI'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}

class _LevelSelector extends StatelessWidget {
  const _LevelSelector({required this.levels, required this.selectedIndex, required this.onSelected});

  final List<LessonData> levels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: levels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final lesson = levels[index];
          final bool selected = index == selectedIndex;
          return ChoiceChip(
            label: Text(lesson.levelLabel),
            selected: selected,
            onSelected: (_) => onSelected(index),
            selectedColor: const Color(0xFF55DF5D),
            backgroundColor: const Color(0xFF1A2531),
            labelStyle: TextStyle(
              color: selected ? const Color(0xFF0E1821) : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          );
        },
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/lesson_models.dart';
import '../models/lesson_result.dart';
import '../models/user_progress.dart';
import '../repositories/lesson_repository.dart';
import '../services/auth_service.dart';
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
      setState(() {
        _selectedLevelIndex = nextIndex;
        _pendingAutoStart = hasNext;
        _userProgress = (_userProgress ?? UserProgress.initial(widget.user.uid)).copyWith(
          currentLevelIndex: nextIndex,
          totalXp: (_userProgress?.totalXp ?? 0) + result.xpEarned,
          lastStreak: result.achievedStreak,
          heartsLeft: result.heartsLeft,
        );
      });
      _progressService.updateAfterLesson(
        uid: widget.user.uid,
        newLevelIndex: nextIndex,
        result: result,
      );
      if (!hasNext) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Keren! Kamu sudah menyelesaikan semua level.')),
        );
      }
    });
  }

  void _selectLevel(int index, int total) {
    if (index < 0 || index >= total) return;
    setState(() => _selectedLevelIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1821),
      bottomNavigationBar: const _BottomNav(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopStats(
                    user: widget.user,
                    progress: progress,
                    onSignOut: () => AuthService.instance.signOut(),
                  ),
                  const SizedBox(height: 24),
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
                  const SizedBox(height: 24),
                  _LearningPath(nextObjective: lesson.nextObjective),
                ],
              );
            },
          ),
        ),
      ),
    );
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
  const _TopStats({required this.user, required this.progress, required this.onSignOut});

  final User user;
  final UserProgress progress;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final photo = user.photoURL;
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFF1A2531),
          backgroundImage: photo != null && photo.isNotEmpty ? NetworkImage(photo) : null,
          child: photo == null || photo.isEmpty
              ? Text(
                  (user.displayName?.isNotEmpty ?? false) ? user.displayName!.characters.first.toUpperCase() : 'K',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName ?? 'Pengguna',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 2),
              Text(
                user.email ?? '',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 8),
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
        IconButton(
          onPressed: onSignOut,
          icon: const Icon(Icons.logout),
          tooltip: 'Keluar',
        ),
      ],
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
  const _LearningPath({required this.nextObjective});

  final String nextObjective;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _PathStep(
                  node: PathNode(
                    label: 'Unit saat ini',
                    icon: Icons.star,
                    active: true,
                    ring: true,
                  ),
                ),
                _PathStep(
                  node: PathNode(icon: Icons.star_border, active: false),
                ),
                _PathStep(
                  node: PathNode(icon: Icons.inventory_2, active: false),
                ),
                _PathStep(
                  node: PathNode(icon: Icons.star_border, active: false),
                ),
                _PathStep(
                  node: PathNode(icon: Icons.emoji_nature, active: false),
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            nextObjective,
            style: const TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

class _PathStep extends StatelessWidget {
  const _PathStep({required this.node, this.isLast = false});

  final PathNode node;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        node,
        if (!isLast)
          Container(
            width: 4,
            height: 40,
            margin: const EdgeInsets.only(top: 6, bottom: 6),
            color: Colors.white12,
          ),
      ],
    );
  }
}

class PathNode extends StatelessWidget {
  const PathNode({
    required this.icon,
    this.label,
    this.active = false,
    this.ring = false,
  });

  final IconData icon;
  final String? label;
  final bool active;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final Color activeColor = const Color(0xFF55DF5D);
    final Color inactiveColor = const Color(0xFF1C2835);
    final Color iconColor = active ? Colors.white : Colors.white54;

    return SizedBox(
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (ring)
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: activeColor, width: 6),
              ),
            ),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? activeColor : inactiveColor,
              border: Border.all(color: Colors.white10, width: 2),
            ),
            child: Icon(icon, color: iconColor, size: 30),
          ),
          if (label != null)
            Positioned(
              bottom: 0,
              child: Text(
                label!,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
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
        BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.public), label: ''),
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

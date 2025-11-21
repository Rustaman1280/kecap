import 'package:flutter/material.dart';

import '../models/lesson_models.dart';
import '../models/lesson_result.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({required this.lesson, this.initialQuestionIndex = 0, super.key});

  final LessonData lesson;
  final int initialQuestionIndex;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late int _currentQuestionIndex;
  late List<String> _slots;
  late List<bool> _slotLocked;
  late List<int?> _slotChoiceIndex;
  late List<bool> _choiceUsed;
  late List<bool?> _slotCorrectState;
  static const int _maxHearts = 5;
  int _heartsLeft = _maxHearts;
  int _streak = 0;

  bool _checked = false;
  bool _isCorrect = false;

  QuestionData get _question => widget.lesson.questions[_currentQuestionIndex];
  bool get _isLastQuestion => _currentQuestionIndex >= widget.lesson.questions.length - 1;

  @override
  void initState() {
    super.initState();
    assert(widget.lesson.questions.isNotEmpty, 'LessonScreen membutuhkan minimal satu soal');
    final int maxIndex = widget.lesson.questions.length - 1;
    int index = widget.initialQuestionIndex;
    if (index < 0) index = 0;
    if (index > maxIndex) index = maxIndex;
    _currentQuestionIndex = index;
    _streak = 0;
    _heartsLeft = _maxHearts;
    _hydrateQuestionState();
  }

  void _handleExit({bool completed = false}) {
    Navigator.of(context).pop(
      LessonResult(
        completed: completed,
        lessonId: widget.lesson.levelId,
        xpEarned: completed ? widget.lesson.xpToUnlock : 0,
        heartsLeft: _heartsLeft,
        achievedStreak: _streak,
      ),
    );
  }

  void _hydrateQuestionState() {
    final question = _question;
    final defaults = question.answerSlots.map((slot) => slot.text).toList();
    _slotLocked = question.answerSlots.map((slot) => slot.locked).toList();
    _slots = List<String>.generate(defaults.length, (index) {
      return _slotLocked[index] ? defaults[index] : '';
    });
    _slotChoiceIndex = List<int?>.filled(question.answerSlots.length, null);
    for (int i = 0; i < _slotLocked.length; i++) {
      if (_slotLocked[i]) {
        _slotChoiceIndex[i] = -1; // sentinel for locked slot
      }
    }
    _choiceUsed = List<bool>.filled(question.wordBank.length, false);
    _slotCorrectState = List<bool?>.filled(question.answerSlots.length, null);
    _checked = false;
    _isCorrect = false;
  }

  void _handleChoiceTap(int index) {
    if (_choiceUsed[index]) return;

    final int targetIndex = _findFirstEmptySlot();
    if (targetIndex == -1) {
      return;
    }

    setState(() {
      _slots[targetIndex] = _question.wordBank[index];
      _slotChoiceIndex[targetIndex] = index;
      _choiceUsed[index] = true;
      _checked = false;
      _slotCorrectState = List<bool?>.filled(_slotCorrectState.length, null);
    });
  }

  void _handleSlotTap(int slotIndex) {
    if (_slotLocked[slotIndex]) return;
    final int? sourceIndex = _slotChoiceIndex[slotIndex];
    if (sourceIndex == null || sourceIndex == -1) return;

    setState(() {
      _choiceUsed[sourceIndex] = false;
      _slotChoiceIndex[slotIndex] = null;
      _slots[slotIndex] = '';
      _checked = false;
      _slotCorrectState = List<bool?>.filled(_slotCorrectState.length, null);
    });
  }

  void _resetAttempt() {
    setState(() {
      for (int i = 0; i < _slots.length; i++) {
        if (_slotLocked[i]) continue;
        final int? choiceIndex = _slotChoiceIndex[i];
        if (choiceIndex != null && choiceIndex >= 0) {
          _choiceUsed[choiceIndex] = false;
        }
        _slotChoiceIndex[i] = null;
        _slots[i] = '';
      }
      _checked = false;
      _slotCorrectState = List<bool?>.filled(_slotCorrectState.length, null);
    });
  }

  int _findFirstEmptySlot() {
    for (int i = 0; i < _slots.length; i++) {
      if (_slotLocked[i]) continue;
      if (_slots[i].isEmpty) {
        return i;
      }
    }
    return -1;
  }

  bool get _isAnswerComplete {
    for (int i = 0; i < _slots.length; i++) {
      if (_slotLocked[i]) continue;
      if (_slots[i].isEmpty) return false;
    }
    return true;
  }

  void _checkAnswer() {
    if (_heartsLeft <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hati habis! Keluar lalu coba lagi.')),
      );
      return;
    }

    if (!_isAnswerComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi jawaban terlebih dahulu.')),
      );
      return;
    }

    final List<String> expected = _question.correctAnswer;
    bool isAllCorrect = true;
    final List<bool?> newStates = List<bool?>.from(_slotCorrectState);

    for (int i = 0; i < _slots.length; i++) {
      final bool matched = i < expected.length &&
          _slots[i].trim().toLowerCase() == expected[i].trim().toLowerCase();
      newStates[i] = matched;
      if (!matched) {
        isAllCorrect = false;
      }
    }

    int updatedStreak = _streak;
    int updatedHearts = _heartsLeft;
    if (isAllCorrect) {
      updatedStreak += 1;
    } else {
      updatedStreak = 0;
      if (updatedHearts > 0) {
        updatedHearts -= 1;
      }
    }

    setState(() {
      _checked = true;
      _isCorrect = isAllCorrect;
      _slotCorrectState = newStates;
      _streak = updatedStreak;
      _heartsLeft = updatedHearts;
    });

    if (!isAllCorrect && updatedHearts <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hati habis! Keluar lalu coba ulang pelajaran.')),
      );
    }
  }

  void _advanceOrFinish() {
    if (_isLastQuestion) {
      _handleExit(completed: true);
      return;
    }

    setState(() {
      _currentQuestionIndex += 1;
      _hydrateQuestionState();
    });
  }

  Color _slotColor(int index) {
    final bool locked = _slotLocked[index];
    final bool? status = _slotCorrectState[index];
    if (!_checked || status == null) {
      return locked ? const Color(0xFF1E2B34) : const Color(0xFF111C27);
    }
    return status ? const Color(0xFF143421) : const Color(0xFF3A1C1C);
  }

  Color _slotBorder(int index) {
    final bool locked = _slotLocked[index];
    final bool? status = _slotCorrectState[index];
    if (!_checked || status == null) {
      return locked ? const Color(0xFF2F3C46) : const Color(0xFF1F2B33);
    }
    return status ? const Color(0xFF4BE07C) : const Color(0xFFFF5F5F);
  }

  String _feedbackMessage() {
    if (!_checked) {
      return 'Pilih kata untuk menjawab.';
    }
    if (_isCorrect) {
      return _isLastQuestion ? 'Hebat! Semua soal selesai.' : _question.feedback;
    }
    return 'Masih ada yang salah, coba lagi!';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _handleExit();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF08111A),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LessonTopBar(
                heartsLeft: _heartsLeft,
                maxHearts: _maxHearts,
                onExit: _handleExit,
              ),
              const SizedBox(height: 16),
              _StreakIndicator(current: _streak, goal: widget.lesson.streakGoal),
              const SizedBox(height: 24),
              _LessonHeader(category: _question.categoryLabel, prompt: _question.prompt),
              const SizedBox(height: 8),
              Text(
                'Soal ${_currentQuestionIndex + 1} dari ${widget.lesson.questions.length}',
                style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CharacterSection(newWord: _question.newWord, hint: _question.hint),
                      const SizedBox(height: 24),
                      _AnswerSlotsView(
                        slots: _slots,
                        locked: _slotLocked,
                        slotColor: _slotColor,
                        slotBorder: _slotBorder,
                        onSlotTap: _handleSlotTap,
                        checked: _checked,
                      ),
                      if (_checked && !_isCorrect) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Jawaban benar: ${_question.correctAnswer.join(' ')}',
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ],
                      const SizedBox(height: 24),
                      _ChoiceGrid(
                        choices: _question.wordBank,
                        used: _choiceUsed,
                        onTap: _handleChoiceTap,
                        checked: _checked,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) {
                  final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
                  return SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(curved),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: _checked
                    ? _FeedbackBanner(
                        key: const ValueKey('feedback-popup'),
                        message: _feedbackMessage(),
                        success: _checked && _isCorrect,
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              _PrimaryButton(
                label: !_checked
                    ? 'PERIKSA'
                    : (_isCorrect
                        ? (_isLastQuestion ? 'SELESAI' : 'LANJUTKAN')
                        : 'COBA LAGI'),
                onPressed: !_checked
                    ? _checkAnswer
                    : (_isCorrect ? _advanceOrFinish : _resetAttempt),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class _LessonTopBar extends StatelessWidget {
  const _LessonTopBar({required this.heartsLeft, required this.maxHearts, required this.onExit});

  final int heartsLeft;
  final int maxHearts;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIcon(icon: Icons.close, onTap: onExit),
        const SizedBox(width: 12),
        const _CircleIcon(icon: Icons.volume_up),
        const Spacer(),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) => ScaleTransition(scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack), child: child),
          child: Row(
            key: ValueKey<int>(heartsLeft),
            children: List.generate(maxHearts, (index) {
              final bool filled = index < heartsLeft;
              return Padding(
                padding: EdgeInsets.only(left: index == 0 ? 0 : 4),
                child: Icon(
                  filled ? Icons.favorite : Icons.favorite_border,
                  color: filled ? const Color(0xFFFF77B6) : Colors.white30,
                  size: 20,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF111C27),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _StreakIndicator extends StatelessWidget {
  const _StreakIndicator({required this.current, required this.goal});

  final int current;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final double progress = goal == 0 ? 0 : current / goal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$current BERUNTUN',
              style: const TextStyle(
                color: Color(0xFFFFC845),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.local_fire_department, color: Color(0xFFFFC845), size: 18),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            tween: Tween<double>(begin: 0, end: progress.clamp(0, 1)),
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: const Color(0xFF141F27),
                valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD84D)),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LessonHeader extends StatelessWidget {
  const _LessonHeader({required this.category, required this.prompt});

  final String category;
  final String prompt;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF3F1B5F),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.bubble_chart, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category,
              style: const TextStyle(
                color: Color(0xFFD08BFF),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              prompt,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}

class _CharacterSection extends StatelessWidget {
  const _CharacterSection({required this.newWord, required this.hint});

  final String newWord;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CharacterCard(),
        const SizedBox(width: 16),
        Expanded(child: _SpeechBubble(newWord: newWord, hint: hint)),
      ],
    );
  }
}

class _CharacterCard extends StatelessWidget {
  const _CharacterCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 170,
      decoration: BoxDecoration(
        color: const Color(0xFF182430),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircleAvatar(
            radius: 32,
            backgroundColor: Color(0xFFFFC845),
            child: Icon(Icons.person, size: 36, color: Color(0xFF0E1821)),
          ),
          SizedBox(height: 12),
          Text('Guru', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.newWord, required this.hint});

  final String newWord;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF131E27),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.volume_up, color: Color(0xFF4AC3FF)),
              const SizedBox(width: 10),
              Text(newWord, style: const TextStyle(fontSize: 18)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF101922),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white12),
          ),
          child: Text(
            hint,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }
}

class _AnswerSlotsView extends StatelessWidget {
  const _AnswerSlotsView({
    required this.slots,
    required this.locked,
    required this.slotColor,
    required this.slotBorder,
    required this.onSlotTap,
    required this.checked,
  });

  final List<String> slots;
  final List<bool> locked;
  final Color Function(int index) slotColor;
  final Color Function(int index) slotBorder;
  final void Function(int index) onSlotTap;
  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        slots.length,
        (index) => GestureDetector(
          onTap: () => onSlotTap(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            margin: EdgeInsets.only(bottom: index == slots.length - 1 ? 0 : 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: slotColor(index),
              border: Border.all(color: slotBorder(index), width: 2),
            ),
            alignment: Alignment.centerLeft,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
                      .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                  child: child,
                ),
              ),
              child: Text(
                slots[index].isEmpty ? '...' : slots[index],
                key: ValueKey<String>('slot-$index-${slots[index]}-$checked'),
                style: TextStyle(
                  color: locked[index]
                      ? const Color(0xFF66FF8A)
                      : (slots[index].isEmpty ? Colors.white24 : Colors.white),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceGrid extends StatelessWidget {
  const _ChoiceGrid({required this.choices, required this.used, required this.onTap, required this.checked});

  final List<String> choices;
  final List<bool> used;
  final void Function(int index) onTap;
  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(choices.length, (index) {
        final bool isUsed = used[index];
        return GestureDetector(
          onTap: isUsed ? null : () => onTap(index),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 160),
            scale: isUsed ? 0.94 : 1,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isUsed ? 0.4 : 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF111B24),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFF2A3641)),
                ),
                child: Text(
                  choices[index],
                  key: ValueKey<String>('chip-$index-${used[index]}-$checked'),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({super.key, required this.message, required this.success});

  final String message;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final Color border = success ? const Color(0xFF1C4B24) : const Color(0xFF363636);
    final Color textColor = success ? const Color(0xFF66FF8A) : Colors.white;
    final Gradient gradient = success
        ? const LinearGradient(colors: [Color(0xFF163821), Color(0xFF0E2215)], begin: Alignment.topLeft, end: Alignment.bottomRight)
        : const LinearGradient(colors: [Color(0xFF131C25), Color(0xFF0B1118)], begin: Alignment.topLeft, end: Alignment.bottomRight);
    final Color glow = success ? const Color(0xFF66FF8A) : Colors.black87;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: glow.withOpacity(success ? 0.35 : 0.2),
            blurRadius: success ? 24 : 12,
            spreadRadius: success ? 1 : 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 320),
            alignment: success ? Alignment.topRight : Alignment.topLeft,
            curve: Curves.easeOut,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [glow.withOpacity(0.25), Colors.transparent],
                ),
              ),
            ),
          ),
          Row(
            children: [
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 260),
                tween: Tween<double>(begin: 0.9, end: success ? 1.05 : 1.0),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Icon(
                    success ? Icons.emoji_events : Icons.refresh,
                    color: textColor,
                    key: ValueKey<bool>(success),
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    message,
                    key: ValueKey<String>(message),
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: success ? 60 : 48,
                height: 4,
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFB6F94B),
          foregroundColor: const Color(0xFF0E1821),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Text(label),
      ),
    );
  }
}

class UserProgress {
  const UserProgress({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.currentLevelIndex,
    required this.totalXp,
    required this.lastStreak,
    required this.heartsLeft,
    required this.completedLevelIds,
  });

  final String uid;
  final String displayName;
  final String email;
  final String photoUrl;
  final int currentLevelIndex;
  final int totalXp;
  final int lastStreak;
  final int heartsLeft;
  final List<String> completedLevelIds;

  factory UserProgress.initial(String uid) {
    return UserProgress(
      uid: uid,
      displayName: '',
      email: '',
      photoUrl: '',
      currentLevelIndex: 0,
      totalXp: 0,
      lastStreak: 0,
      heartsLeft: 5,
      completedLevelIds: const [],
    );
  }

  factory UserProgress.fromMap(Map<String, dynamic> map) {
    return UserProgress(
      uid: map['uid'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? '',
      currentLevelIndex: (map['currentLevelIndex'] as num?)?.toInt() ?? 0,
      totalXp: (map['totalXp'] as num?)?.toInt() ?? 0,
      lastStreak: (map['lastStreak'] as num?)?.toInt() ?? 0,
      heartsLeft: (map['heartsLeft'] as num?)?.toInt() ?? 5,
      completedLevelIds: _parseCompletedLevels(map['completedLevelIds']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'currentLevelIndex': currentLevelIndex,
      'totalXp': totalXp,
      'lastStreak': lastStreak,
      'heartsLeft': heartsLeft,
      'completedLevelIds': completedLevelIds,
    };
  }

  UserProgress copyWith({
    String? displayName,
    String? email,
    String? photoUrl,
    int? currentLevelIndex,
    int? totalXp,
    int? lastStreak,
    int? heartsLeft,
    List<String>? completedLevelIds,
  }) {
    return UserProgress(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      currentLevelIndex: currentLevelIndex ?? this.currentLevelIndex,
      totalXp: totalXp ?? this.totalXp,
      lastStreak: lastStreak ?? this.lastStreak,
      heartsLeft: heartsLeft ?? this.heartsLeft,
      completedLevelIds: completedLevelIds ?? this.completedLevelIds,
    );
  }

  static List<String> _parseCompletedLevels(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e as String? ?? '').where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }
}

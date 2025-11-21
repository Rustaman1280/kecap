import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_progress.dart';
import '../services/user_progress_service.dart';
import '../widgets/app_bottom_nav.dart';
import 'ai_hub_screen.dart';
import 'profile_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({required this.user, super.key});

  final User user;

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late final Stream<List<UserProgress>> _leaderboardStream;

  @override
  void initState() {
    super.initState();
    _leaderboardStream = UserProgressService.instance.topXpLeaderboard(limit: 25);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050E16),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 1,
        onTap: _handleBottomNavTap,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            _LeaderboardHeader(user: widget.user),
            const SizedBox(height: 20),
            _LeaderboardSection(stream: _leaderboardStream, currentUid: widget.user.uid),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _handleBottomNavTap(int index) {
    if (index == 1) return;
    if (index == 0) {
      Navigator.of(context).pop();
      return;
    }
    if (index == 2) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AiHubScreen(user: widget.user),
        ),
      );
      return;
    }
    if (index == 3) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProfileScreen(user: widget.user),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Menu ini sedang disiapkan'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _LeaderboardHeader extends StatelessWidget {
  const _LeaderboardHeader({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final photo = user.photoURL;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E2C3A), Color(0xFF0B121A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFF1A2531),
                backgroundImage: photo != null && photo.isNotEmpty ? NetworkImage(photo) : null,
                child: photo == null || photo.isEmpty
                    ? Text(
                        (user.displayName?.isNotEmpty ?? false)
                            ? user.displayName!.characters.first.toUpperCase()
                            : 'K',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Papan Peraih XP',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Lihat siapa yang paling rajin belajar minggu ini',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.emoji_events, color: Color(0xFFFFC845), size: 32),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: const Color(0xFF101923),
            ),
            child: Row(
              children: const [
                Icon(Icons.tips_and_updates, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Raih XP terbanyak untuk masuk Top 3 dan dapatkan badge eksklusif!',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardSection extends StatelessWidget {
  const _LeaderboardSection({required this.stream, required this.currentUid});

  final Stream<List<UserProgress>> stream;
  final String currentUid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserProgress>>(
      stream: stream,
      builder: (context, snapshot) {
        Widget content;
        if (snapshot.connectionState == ConnectionState.waiting) {
          content = const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          content = const _LeaderboardMessage(
            icon: Icons.error_outline,
            message: 'Gagal memuat leaderboard',
          );
        } else {
          final entries = snapshot.data ?? const <UserProgress>[];
          if (entries.isEmpty) {
            content = const _LeaderboardMessage(
              icon: Icons.emoji_events_outlined,
              message: 'Belum ada pemain yang tampil di papan peringkat',
            );
          } else {
            content = _LeaderboardContent(entries: entries, currentUid: currentUid);
          }
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF182434), Color(0xFF0C131D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white10),
            boxShadow: const [
              BoxShadow(color: Color(0x26000000), blurRadius: 24, offset: Offset(0, 12)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.leaderboard_rounded, color: Colors.white70),
                  SizedBox(width: 8),
                  Text(
                    'Top XP Leaderboard',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              content,
            ],
          ),
        );
      },
    );
  }
}

class _LeaderboardContent extends StatelessWidget {
  const _LeaderboardContent({required this.entries, required this.currentUid});

  final List<UserProgress> entries;
  final String currentUid;

  @override
  Widget build(BuildContext context) {
    final podium = entries.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (podium.isNotEmpty) ...[
          _PodiumBar(podium: podium, currentUid: currentUid),
          const SizedBox(height: 20),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 16),
        ],
        ...List.generate(entries.length, (index) {
          final rank = index + 1;
          final user = entries[index];
          final highlight = user.uid == currentUid;
          return Padding(
            padding: EdgeInsets.only(bottom: index == entries.length - 1 ? 0 : 10),
            child: _LeaderboardTile(rank: rank, user: user, highlight: highlight),
          );
        }),
      ],
    );
  }
}

class _LeaderboardMessage extends StatelessWidget {
  const _LeaderboardMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white54),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _PodiumBar extends StatelessWidget {
  const _PodiumBar({required this.podium, required this.currentUid});

  final List<UserProgress> podium;
  final String currentUid;

  @override
  Widget build(BuildContext context) {
    final List<int> order;
    if (podium.length >= 3) {
      order = [1, 0, 2];
    } else {
      order = List<int>.generate(podium.length, (index) => index);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1118),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: order.map((i) {
          final rank = i + 1;
          final user = podium[i];
          final bool highlight = user.uid == currentUid;
          final bool champion = rank == 1;
          return _PodiumBubble(
            rank: rank,
            user: user,
            highlight: highlight,
            champion: champion,
          );
        }).toList(),
      ),
    );
  }
}

class _PodiumBubble extends StatelessWidget {
  const _PodiumBubble({
    required this.rank,
    required this.user,
    required this.highlight,
    required this.champion,
  });

  final int rank;
  final UserProgress user;
  final bool highlight;
  final bool champion;

  @override
  Widget build(BuildContext context) {
    final double avatarSize = champion ? 70 : 60;
    final Color accent = _rankColor(rank);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
              margin: EdgeInsets.only(top: champion ? 18 : 24),
              padding: EdgeInsets.only(top: avatarSize / 2 + 24, left: 12, right: 12, bottom: 16),
              width: champion ? 120 : 100,
              decoration: BoxDecoration(
                color: const Color(0xFF121924),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: highlight ? const Color(0xFF4ADE80) : Colors.white12),
              ),
              child: Text(
                '${user.totalXp} XP',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            Positioned(
              top: 0,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (champion)
                          const Icon(Icons.emoji_events, size: 14, color: Colors.white),
                        if (champion) const SizedBox(width: 4),
                        Text('#$rank', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  CircleAvatar(
                    radius: avatarSize / 2,
                    backgroundColor: Colors.white10,
                    backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                    child: user.photoUrl.isEmpty
                        ? Text(
                            _displayNameFor(user, rank).characters.first.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: champion ? 120 : 100,
          child: Text(
            _displayNameFor(user, rank),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({required this.rank, required this.user, required this.highlight});

  final int rank;
  final UserProgress user;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final Color accent = _rankColor(rank);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFF2E7D32) : const Color(0xFF0D141D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: highlight ? const Color(0xFF55DF5D) : Colors.white12),
        boxShadow: highlight
            ? [const BoxShadow(color: Color(0x262BBE65), blurRadius: 10, offset: Offset(0, 6))]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: highlight ? Colors.white : accent.withOpacity(0.15),
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: highlight ? const Color(0xFF2E7D32) : accent,
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white12,
            backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
            child: user.photoUrl.isEmpty
                ? Text(
                    _displayNameFor(user, rank).characters.first.toUpperCase(),
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
                  _displayNameFor(user, rank),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${user.totalXp} XP',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color _rankColor(int rank) {
  switch (rank) {
    case 1:
      return const Color(0xFFFFC845);
    case 2:
      return const Color(0xFFD1D5DB);
    case 3:
      return const Color(0xFFF59E0B);
    default:
      return const Color(0xFF4AC3FF);
  }
}

String _displayNameFor(UserProgress user, int rank) {
  if (user.displayName.trim().isNotEmpty) {
    return user.displayName.trim();
  }
  if (user.email.trim().isNotEmpty) {
    return user.email.split('@').first;
  }
  return 'Pemain #$rank';
}

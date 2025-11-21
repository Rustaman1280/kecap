import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_progress.dart';
import '../services/auth_service.dart';
import '../services/user_progress_service.dart';
import '../widgets/app_bottom_nav.dart';
import 'ai_hub_screen.dart';
import 'leaderboard_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({required this.user, super.key});

  final User user;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<UserProgress> _progressFuture;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    _progressFuture = UserProgressService.instance.getOrCreateProgress(widget.user);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050E16),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 3,
        onTap: _handleBottomNavTap,
      ),
      body: SafeArea(
        child: FutureBuilder<UserProgress>(
          future: _progressFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return _ProfileError(
                onRetry: () {
                  setState(() {
                    _progressFuture = UserProgressService.instance.getOrCreateProgress(widget.user);
                  });
                },
              );
            }

            final progress = snapshot.data!;
            return RefreshIndicator(
              onRefresh: _refreshProgress,
              child: ListView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  _ProfileHero(user: widget.user, progress: progress),
                  const SizedBox(height: 18),
                  _StatRow(progress: progress),
                  const SizedBox(height: 20),
                  _JourneyCard(progress: progress),
                  const SizedBox(height: 20),
                  const _PreferencesCard(),
                  const SizedBox(height: 20),
                  _SignOutCard(onSignOut: _handleSignOut, signingOut: _signingOut),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _refreshProgress() async {
    final progress = await UserProgressService.instance.getOrCreateProgress(widget.user);
    if (!mounted) return;
    setState(() {
      _progressFuture = Future.value(progress);
    });
  }

  void _handleBottomNavTap(int index) {
    if (index == 3) return;
    if (index == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    if (index == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LeaderboardScreen(user: widget.user),
        ),
      );
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
  }

  Future<void> _handleSignOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      await AuthService.instance.signOut();
    } finally {
      if (!mounted) return;
      setState(() => _signingOut = false);
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.user, required this.progress});

  final User user;
  final UserProgress progress;

  @override
  Widget build(BuildContext context) {
    final photo = user.photoURL;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E2B3B), Color(0xFF0B121A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white10),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 32, offset: Offset(0, 16)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: const Color(0xFF162337),
            backgroundImage: photo != null && photo.isNotEmpty ? NetworkImage(photo) : null,
            child: photo == null || photo.isEmpty
                ? Text(
                    (user.displayName?.isNotEmpty ?? false)
                        ? user.displayName!.characters.first.toUpperCase()
                        : 'K',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName?.isNotEmpty == true ? user.displayName! : 'Pengguna',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email ?? 'Belum ada email',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0x33FFFFFF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${progress.totalXp} XP - Level ${progress.currentLevelIndex + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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

class _StatRow extends StatelessWidget {
  const _StatRow({required this.progress});

  final UserProgress progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Streak',
            value: '${progress.lastStreak} hari',
            icon: Icons.local_fire_department,
            gradient: const [Color(0xFFFF9A62), Color(0xFFFF5E62)],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _StatCard(
            title: 'Hearts',
            value: '${progress.heartsLeft}',
            icon: Icons.favorite,
            gradient: const [Color(0xFFFF77B6), Color(0xFFF44F98)],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _StatCard(
            title: 'Level selesai',
            value: '${progress.completedLevelIds.length}',
            icon: Icons.emoji_events,
            gradient: const [Color(0xFF4AC3FF), Color(0xFF3A73F1)],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value, required this.icon, required this.gradient});

  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({required this.progress});

  final UserProgress progress;

  @override
  Widget build(BuildContext context) {
    const totalLevels = 10;
    final completed = progress.completedLevelIds.length;
    final percent = (completed / totalLevels).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: const Color(0xFF0E1623),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.route_outlined, color: Colors.white70),
              SizedBox(width: 8),
              Text('Perjalanan Belajar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Level ${progress.currentLevelIndex + 1} - ${progress.totalXp} XP', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 10,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF55DF5D)),
            ),
          ),
          const SizedBox(height: 10),
          Text('$completed dari $totalLevels level dituntaskan', style: const TextStyle(color: Colors.white60, fontSize: 13)),
        ],
      ),
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: const Color(0xFF0F1724),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pengaturan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _PreferenceTile(
            icon: Icons.translate,
            title: 'Bahasa UI',
            subtitle: 'Indonesia',
            trailing: const Icon(Icons.chevron_right),
          ),
          _PreferenceTile(
            icon: Icons.notifications_active,
            title: 'Pengingat belajar',
            subtitle: 'Setiap hari pukul 19.00',
            trailing: Switch(value: true, onChanged: (_) {}),
          ),
          _PreferenceTile(
            icon: Icons.shield_outlined,
            title: 'Privasi data',
            subtitle: 'Kendalikan data yang kamu bagikan',
            trailing: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  const _PreferenceTile({required this.icon, required this.title, required this.subtitle, required this.trailing});

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF151E2B),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white70),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _SignOutCard extends StatelessWidget {
  const _SignOutCard({required this.onSignOut, required this.signingOut});

  final Future<void> Function() onSignOut;
  final bool signingOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: const Color(0xFF1A1F2B),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Keluar akun', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 6),
          const Text('Keluar dari akun Google kamu dengan aman.', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: signingOut ? null : onSignOut,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              icon: signingOut
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.logout),
              label: Text(signingOut ? 'Keluar...' : 'Keluar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Gagal memuat profil', style: TextStyle(color: Colors.white70)),
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

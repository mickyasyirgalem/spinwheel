import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAuth = ref.watch(authProvider);
    final uid = userAuth?.uid ?? '';
    final service = ref.watch(firebaseServiceProvider);

    return Scaffold(
      body: Row(
        children: [
          const AppSidebar(currentRoute: '/dashboard'),
          Expanded(
            child: Column(
              children: [
                const AppTopBar(title: 'Dashboard'),
                Expanded(
                  child: StreamBuilder<AppUser?>(
                    stream: service.userStream(uid),
                    builder: (ctx, snap) {
                      final user = snap.data;
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Stats grid ─────────────────────────────────
                            _statsGrid(user),
                            const SizedBox(height: 28),
                            // ── Recent games ───────────────────────────────
                            _recentGames(uid, service),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsGrid(AppUser? user) {
    final stats = [
      _StatData(
        icon: Icons.trending_up_rounded,
        label: "Today's Earnings",
        value: '${(user?.dailyEarnings ?? 0).toStringAsFixed(2)} Birr',
        color: AppTheme.accentGreen,
      ),
      _StatData(
        icon: Icons.verified_rounded,
        label: 'Permission',
        value: (user?.permission ?? false) ? 'Permitted' : 'Restricted',
        color: (user?.permission ?? false)
            ? AppTheme.accentGreen
            : AppTheme.accentRed,
      ),
      _StatData(
        icon: Icons.check_circle_outline_rounded,
        label: 'Completed Games',
        value: '${user?.completedGames ?? 0}',
        color: AppTheme.accentCyan,
      ),
      _StatData(
        icon: Icons.casino_rounded,
        label: 'Total Games',
        value: '${user?.totalGames ?? 0}',
        color: AppTheme.accent,
      ),
      _StatData(
        icon: Icons.account_balance_wallet_rounded,
        label: 'Available Balance',
        value: '${(user?.balance ?? 0).toStringAsFixed(2)} Birr',
        color: AppTheme.accentGold,
      ),
    ];

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final cols = constraints.maxWidth > 800
            ? 5
            : constraints.maxWidth > 500
            ? 3
            : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            childAspectRatio: 1.4,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: stats.length,
          itemBuilder: (ctx, i) => _statCard(stats[i], i),
        );
      },
    );
  }

  Widget _statCard(_StatData s, int i) {
    return Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.glassCard(radius: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: s.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(s.icon, color: s.color, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.value,
                    style: TextStyle(
                      color: s.color,
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.label,
                    style: const TextStyle(
                      color: AppTheme.textSub,
                      fontFamily: 'Outfit',
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate(delay: (i * 80).ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _recentGames(String uid, FirebaseService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history_rounded, color: AppTheme.accent, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Recent 15 Games',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontFamily: 'Outfit',
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        StreamBuilder<List<GameRecord>>(
          stream: service.userGameHistoryStream(uid),
          builder: (ctx, snap) {
            if (!snap.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppTheme.accent),
                ),
              );
            }
            final games = snap.data!;
            if (games.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: AppTheme.glassCard(radius: 16),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.casino_outlined,
                        color: AppTheme.textSub,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No games played today',
                        style: TextStyle(
                          color: AppTheme.textSub,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Container(
              decoration: AppTheme.glassCard(radius: 16),
              child: Column(
                children: games.asMap().entries.map((entry) {
                  final i = entry.key;
                  final g = entry.value;
                  final fmt = DateFormat('MMM d, HH:mm');
                  final isLast = i == games.length - 1;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _statusColor(
                                  g.status,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _statusIcon(g.status),
                                color: _statusColor(g.status),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Game #${g.id.substring(0, 6).toUpperCase()}',
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontFamily: 'Outfit',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${g.entryCount} entries · Pot: ${g.totalPot.toStringAsFixed(0)} Birr · House: ${g.houseEarnings.toStringAsFixed(0)} Birr',
                                    style: const TextStyle(
                                      color: AppTheme.textSub,
                                      fontFamily: 'Outfit',
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (g.results.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: g.results.map((r) {
                                        final medals = ['🥇', '🥈', '🥉'];
                                        final medal = r.round <= 3 ? medals[r.round - 1] : '🏅';
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppTheme.bgDark.withValues(alpha: 0.5),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
                                          ),
                                          child: Text(
                                            '$medal ${r.winnerLabel} (${r.prize.toStringAsFixed(0)} Birr)',
                                            style: const TextStyle(
                                              color: AppTheme.textPrimary,
                                              fontFamily: 'Outfit',
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor(
                                      g.status,
                                    ).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    g.status.toUpperCase(),
                                    style: TextStyle(
                                      color: _statusColor(g.status),
                                      fontFamily: 'Outfit',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  fmt.format(g.createdAt),
                                  style: const TextStyle(
                                    color: AppTheme.textSub,
                                    fontFamily: 'Outfit',
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        const Divider(
                          color: AppTheme.border,
                          height: 1,
                          indent: 18,
                          endIndent: 18,
                        ),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Color _statusColor(String s) => switch (s) {
    'completed' => AppTheme.accentGreen,
    'active' => AppTheme.accentGold,
    _ => AppTheme.textSub,
  };

  IconData _statusIcon(String s) => switch (s) {
    'completed' => Icons.check_circle_rounded,
    'active' => Icons.play_circle_rounded,
    _ => Icons.schedule_rounded,
  };
}

class _StatData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../widgets/spin_wheel.dart';
import '../widgets/entry_panel.dart';
import '../widgets/game_info_panel.dart';
import '../widgets/app_scaffold.dart';
import '../theme/app_theme.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const AppSidebar(currentRoute: '/game'),
          Expanded(
            child: Column(
              children: [
                const AppTopBar(title: 'Spin Wheel'),
                const Expanded(child: _GameBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GameBody extends ConsumerStatefulWidget {
  const _GameBody();

  @override
  ConsumerState<_GameBody> createState() => _GameBodyState();
}

class _GameBodyState extends ConsumerState<_GameBody> {
  bool _dialogShown = false;

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameCtrlProvider);

    // Only show game-over dialog when ALL rounds are finished
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (game.status == GameStatus.finished && !_dialogShown) {
        _dialogShown = true;
        _showGameOver(context, game);
      }
      // Reset when game resets
      if (game.status == GameStatus.idle && _dialogShown) {
        _dialogShown = false;
      }
    });

    return Row(
      children: [
        // ── Left: Wheel ────────────────────────────────────────────────────
        Expanded(
          flex: 3,
          child: Container(
            color: const Color(0xFF080B17),
            child: Stack(
              children: [
                // Background grid pattern
                CustomPaint(
                  painter: _GridPainter(),
                  child: const SizedBox.expand(),
                ),
                // Wheel content
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Wheel
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 520),
                          child: SpinWheelWidget(
                            onSpinDone: (index) {
                              final uid = ref.read(authProvider)?.uid ?? '';
                              ref.read(gameCtrlProvider.notifier).onSpinComplete(index, uid);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  top: 40,
                  left: 40,
                  child: const GameInfoPanel(),
                ),
              ],
            ),
          ),
        ),

        // ── Right: Control panel ───────────────────────────────────────────
        Container(
          width: 380,
          decoration: const BoxDecoration(
            color: Color(0xFF0F111A), // Match sidebar
            border: Border(left: BorderSide(color: AppTheme.border, width: 0.5)),
          ),
          child: const EntryPanel(),
        ),
      ],
    );
  }

  void _showGameOver(BuildContext context, GameState game) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _WinnerDialog(
        results: game.results,
        prizes: game.prizes,
        onRestart: () {
          Navigator.pop(ctx);
          if (mounted) {
            _dialogShown = false;
            ref.read(gameCtrlProvider.notifier).restartGame();
          }
        },
        onDashboard: () {
          Navigator.pop(ctx);
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        },
      ),
    );
  }
}

// ── Game Over Summary Dialog ──────────────────────────────────────────────────
class _WinnerDialog extends StatelessWidget {
  final List<dynamic> results;
  final List<double> prizes;
  final VoidCallback onRestart;
  final VoidCallback onDashboard;

  const _WinnerDialog({
    required this.results,
    required this.prizes,
    required this.onRestart,
    required this.onDashboard,
  });

  @override
  Widget build(BuildContext context) {
    const medals = ['🥇', '🥈', '🥉'];

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: AppTheme.glassCard(radius: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎊', style: TextStyle(fontSize: 52))
                .animate()
                .scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 12),
            const Text(
              'Game Over!',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontFamily: 'Outfit',
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 6),
            Text(
              'All rounds complete',
              style: const TextStyle(
                color: AppTheme.textSub,
                fontFamily: 'Outfit',
                fontSize: 13,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 20),

            // Winner rows
            ...results.asMap().entries.map((entry) {
              final i = entry.key;
              final r = entry.value;
              final medal = i < 3 ? medals[i] : '🎖️';
              final gradients = [
                AppTheme.goldGradient,
                const LinearGradient(colors: [Color(0xFF94A3B8), Color(0xFF64748B)]),
                const LinearGradient(colors: [Color(0xFFCD7F32), Color(0xFF92400E)]),
              ];
              final grad = i < 3 ? gradients[i] : AppTheme.accentGradient;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: grad,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(medal, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.winnerLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              'Round ${r.round}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontFamily: 'Outfit',
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${r.prize.toStringAsFixed(2)} Birr',
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ).animate().slideY(begin: 0.3, end: 0, delay: (200 + i * 100).ms),
              );
            }),

            const SizedBox(height: 20),
            _btn(
              label: 'Play Again',
              icon: Icons.replay_rounded,
              gradient: AppTheme.accentGradient,
              onTap: onRestart,
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onDashboard,
              child: const Text(
                'Back to Dashboard',
                style: TextStyle(
                  color: AppTheme.textSub,
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn({
    required String label,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



// ── Grid background painter ───────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 0.5;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}

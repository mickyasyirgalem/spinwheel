import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

class GameInfoPanel extends ConsumerStatefulWidget {
  const GameInfoPanel({super.key});

  @override
  ConsumerState<GameInfoPanel> createState() => _GameInfoPanelState();
}

class _GameInfoPanelState extends ConsumerState<GameInfoPanel> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameCtrlProvider);

    return Container(
      width: 280,
      decoration: AppTheme.glassCard(radius: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header: Toggle ─────────────────────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.bgPanel.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Text(
                    'Game Info',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppTheme.textSub,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          
          if (_expanded)
            Stack(
              children: [
                // Warm Glow Background
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: AppTheme.warmGlowGradient,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildBody(game),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBody(GameState game) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Game Info',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Outfit',
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 20),

        // ── Stats rows ──────────────────────────────────────────────────────
        _rowStat('TOTAL POT', '${game.pot.toStringAsFixed(2)} Birr'),
        const SizedBox(height: 14),
        _rowStat('ENTRIES', '${game.entries.length}'),
        const SizedBox(height: 14),
        _rowStat(
          'BET / CARTELA',
          '${game.betPerCartela.toStringAsFixed(0)} Birr',
        ),
        const SizedBox(height: 14),
        _rowStat('HOUSE CUT', game.housePercent),

        const SizedBox(height: 20),
        const Divider(color: AppTheme.border, height: 1),
        const SizedBox(height: 18),

        // ── Prizes ─────────────────────────────────────────────────────────
        const Text(
          'PRIZE',
          style: TextStyle(
            color: AppTheme.textSub,
            fontFamily: 'Outfit',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 14),

        ...List.generate(game.rounds, (i) {
          final amount = game.prizes.isNotEmpty && i < game.prizes.length
              ? game.prizes[i]
              : 0.0;
          final percentage = game.totalPrizePool > 0 
              ? (amount / game.totalPrizePool * 100).toStringAsFixed(1)
              : (100 / game.rounds).toStringAsFixed(1);

          final medals = ['🥇', '🥈', '🥉'];
          final medal = i < 3 ? medals[i] : '🏅';

          final gradients = [
            AppTheme.goldGradient,
            const LinearGradient(
              colors: [Color(0xFF94A3B8), Color(0xFF64748B)],
            ),
            const LinearGradient(
              colors: [Color(0xFFCD7F32), Color(0xFF92400E)],
            ),
            const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
            ), // Purple for 4th+
          ];
          final gradient = i < 3 ? gradients[i] : gradients[3];

          String labelSuffix = 'th';
          if (i == 0) {
            labelSuffix = 'st';
          } else if (i == 1) {
            labelSuffix = 'nd';
          } else if (i == 2) {
            labelSuffix = 'rd';
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _prizeRow(
              medal: medal,
              label: '${i + 1}$labelSuffix · $percentage%',
              amount: amount,
              gradient: gradient,
            ),
          );
        }),

        // ── Round indicator / auto-spin countdown ─────────────────────────
        if (game.isGameRunning || game.status == GameStatus.finished) ...[
          const SizedBox(height: 14),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: game.status == GameStatus.finished
                  ? AppTheme.goldGradient
                  : game.isAutoSpinning
                  ? const LinearGradient(
                      colors: [Color(0xFF6B7280), Color(0xFF374151)],
                    )
                  : AppTheme.accentGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  game.status == GameStatus.finished
                      ? Icons.emoji_events_rounded
                      : game.isAutoSpinning
                      ? Icons.hourglass_top_rounded
                      : Icons.sync_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  game.status == GameStatus.finished
                      ? 'Game Finished!'
                      : game.isAutoSpinning
                      ? 'Next spin in 2.5s...'
                      : 'Round ${game.currentRound + 1} of ${game.rounds}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _rowStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppTheme.textSub,
            fontFamily: 'Outfit',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _prizeRow({
    required String medal,
    required String label,
    required double amount,
    required Gradient gradient,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(gradient: gradient, shape: BoxShape.circle),
          child: Text(medal, style: const TextStyle(fontSize: 16)),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSub,
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
        const Spacer(),
        Text(
          amount > 0 ? '${amount.toStringAsFixed(2)} Birr' : '—',
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

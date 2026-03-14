import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/game_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class EntryPanel extends ConsumerStatefulWidget {
  const EntryPanel({super.key});

  @override
  ConsumerState<EntryPanel> createState() => _EntryPanelState();
}

class _EntryPanelState extends ConsumerState<EntryPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _itemIdCtrl = TextEditingController();
  String _selectedCity = 'addis_ababa';

  final Map<String, String> _cities = {
    'addis_ababa': 'የካርድ ቁጥሮች አዲስ አበባ',
    'dire_dawa': 'የካርድ ቁጥሮች ድሬዳዋ',
    'hawassa': 'የካርድ ቁጥሮች ሐዋሳ',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameCtrlProvider.notifier).loadCardNumbers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _itemIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameCtrlProvider);
    final ctrl = ref.read(gameCtrlProvider.notifier);

    return Container(
      decoration: AppTheme.glassCard(radius: 20),
      child: Column(
        children: [
          // ── Tab bar ─────────────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.bgPanel,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.accent,
              indicatorWeight: 2.5,
              labelColor: AppTheme.textPrimary,
              unselectedLabelColor: AppTheme.textSub,
              labelStyle: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: [
                Tab(text: 'Entries ${game.entries.length}'),
                Tab(text: 'Results ${game.results.length}'),
              ],
            ),
          ),

          // ── Tab views ────────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEntriesTab(game, ctrl),
                _buildResultsTab(game),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntriesTab(GameState game, GameCtrl ctrl) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header: Search & City ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.bgPanel,
              border: Border(bottom: BorderSide(color: AppTheme.border.withValues(alpha: 0.5))),
            ),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _itemIdCtrl,
                  style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'Outfit', fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search or add item ID...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppTheme.textSub),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add_box_rounded, color: AppTheme.accent),
                      onPressed: () {
                        ctrl.addEntryById(_itemIdCtrl.text);
                        _itemIdCtrl.clear();
                      },
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onSubmitted: (v) {
                    ctrl.addEntryById(v);
                    _itemIdCtrl.clear();
                  },
                ),
                const SizedBox(height: 10),
                
                // City selector
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgDark.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border.withValues(alpha: 0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCity,
                      dropdownColor: AppTheme.bgCard,
                      isExpanded: true,
                      icon: const Icon(Icons.expand_more_rounded, color: AppTheme.textSub, size: 18),
                      style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'Outfit', fontSize: 13),
                      items: _cities.entries
                          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _selectedCity = v);
                        ctrl.setCity(v);
                        ctrl.loadCardNumbers();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Card numbers list ─────────────────────────────────────────────
          Expanded(
            child: game.isLoadingCards
                ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                : game.allCardNumbers.isEmpty
                    ? const Center(
                        child: Text(
                          'No card numbers found',
                          style: TextStyle(color: AppTheme.textSub, fontFamily: 'Outfit'),
                        ),
                      )
                    : ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context)
                            .copyWith(scrollbars: false),
                        child: ListView.builder(
                          itemCount: game.allCardNumbers.length,
                          itemExtent: 40,
                          itemBuilder: (ctx, i) {
                            final card = game.allCardNumbers[i];
                            final selected =
                                game.entries.any((e) => e.id == card.id);
                            return _cardTile(card, selected, ctrl);
                          },
                        ),
                      ),
          ),

          const SizedBox(height: 10),
          _divider(),

          // ── Bet level ─────────────────────────────────────────────────────
          _sectionLabel('BET PERCENTAGE'),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Level ${_romanLevel(game.betLevel)}',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  _stepBtn(Icons.remove, () => ctrl.setBetLevel(game.betLevel - 1)),
                  const SizedBox(width: 8),
                  _stepBtn(Icons.add, () => ctrl.setBetLevel(game.betLevel + 1)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Bet per cartela ───────────────────────────────────────────────
          _sectionLabel('BET PER CARTELA (BIRR)'),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                game.betPerCartela.toStringAsFixed(0),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                   _stepBtn(Icons.remove, () => ctrl.setBetPerCartela(game.betPerCartela - 5)),
                   const SizedBox(width: 8),
                   _stepBtn(Icons.add, () => ctrl.setBetPerCartela(game.betPerCartela + 5)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Spin rounds ───────────────────────────────────────────────────
          _sectionLabel('SPIN ROUNDS'),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${game.rounds} Round${game.rounds > 1 ? 's' : ''}',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  _stepBtn(Icons.remove, () => ctrl.setRounds(game.rounds - 1)),
                  const SizedBox(width: 8),
                  _stepBtn(Icons.add, () => ctrl.setRounds(game.rounds + 1)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),
          _divider(),

          // ── Available Credit ──────────────────────────────────────────────
          _sectionLabel('AVAILABLE CREDIT'),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${game.availableCredit.toStringAsFixed(2)} Birr',
                style: TextStyle(
                  color: game.availableCredit >= game.houseEarnings ? AppTheme.accent : AppTheme.accentRed,
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (game.availableCredit < game.houseEarnings)
                Text(
                  game.availableCredit <= 0 ? 'RECHARGE NEEDED' : 'INSUFFICIENT CREDIT',
                  style: const TextStyle(
                    color: AppTheme.accentRed,
                    fontFamily: 'Outfit',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Action buttons ────────────────────────────────────────────────
          _buildActionButtons(game, ctrl),
        ],
      ),
    );
  }

  Widget _buildResultsTab(GameState game) {
    if (game.results.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, color: AppTheme.textSub, size: 48),
            SizedBox(height: 12),
            Text(
              'No results yet.\nSpin the wheel to get winners!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSub, fontFamily: 'Outfit', fontSize: 14),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: game.results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final r = game.results[i];
        final medals = ['🥇', '🥈', '🥉'];
        final gradients = [
          AppTheme.goldGradient,
          const LinearGradient(colors: [Color(0xFF94A3B8), Color(0xFF64748B)]),
          const LinearGradient(colors: [Color(0xFFCD7C3A), Color(0xFF92400E)]),
        ];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: gradients[i % 3],
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(medals[i % 3], style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Round ${r.round} Winner',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontFamily: 'Outfit',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      r.winnerLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Outfit',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'PRIZE',
                    style: TextStyle(
                      color: Colors.white70,
                      fontFamily: 'Outfit',
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${r.prize.toStringAsFixed(2)} Birr',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(GameState game, GameCtrl ctrl) {
    final uid = ref.read(authProvider)?.uid ?? '';
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _outlineButton(
                icon: Icons.shuffle_rounded,
                label: 'Shuffle',
                onTap: ctrl.shuffle,
                color: AppTheme.textSub,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _gradientButton(
                label: game.status == GameStatus.roundComplete
                    ? 'NEXT ROUND'
                    : 'START GAME',
                icon: Icons.play_arrow_rounded,
                enabled: game.canStartGame || game.status == GameStatus.roundComplete,
                onTap: () {
                  if (game.status == GameStatus.roundComplete) {
                    ctrl.continueToNextRound();
                  } else {
                    ctrl.startGame(uid);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _outlineButton(
                icon: Icons.clear_all_rounded,
                label: 'Clear Entries',
                onTap: ctrl.clearEntries,
                color: AppTheme.accentRed,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _outlineButton(
                icon: Icons.restart_alt_rounded,
                label: 'Restart Game',
                onTap: ctrl.restartGame,
                color: AppTheme.textSub,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _cardTile(CardEntry card, bool selected, GameCtrl ctrl) {
    return GestureDetector(
      onTap: () => ctrl.toggleEntry(card),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppTheme.accent.withValues(alpha: 0.5) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                card.label,
                style: TextStyle(
                  color: selected ? AppTheme.textPrimary : AppTheme.textSub,
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: AppTheme.accent, size: 16),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.bgDark,
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.textPrimary, size: 16),
      ),
    );
  }

  Widget _outlineButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientButton({
    required String label,
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [Color(0xFFD946EF), Color(0xFFA855F7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: enabled ? null : AppTheme.border,
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: const Color(0xFFA855F7).withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ]
              : [],
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
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(
          text,
          style: const TextStyle(
            color: AppTheme.textSub,
            fontFamily: 'Outfit',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      );

  Widget _divider() => const Divider(color: AppTheme.border, height: 20);

  String _romanLevel(int l) => ['I', 'II', 'III'][l - 1];
}

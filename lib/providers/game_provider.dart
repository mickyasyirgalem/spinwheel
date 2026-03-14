import 'dart:async';
import 'dart:math';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import 'auth_provider.dart';

part 'game_provider.g.dart';



const Map<int, double> _housePercentage = {
  1: 0.20,
  2: 0.25,
  3: 0.30,
};

enum GameStatus { idle, spinning, roundComplete, finished }

class GameState {
  final int betLevel;
  final double betPerCartela;
  final int rounds;
  final String selectedCity;
  final List<CardEntry> allCardNumbers;
  final List<CardEntry> entries;
  final List<CardEntry> activeEntries;
  final List<GameResult> results;
  final GameStatus status;
  final String? activeGameId;
  final int currentRound;
  final double spinAngle;
  final bool isLoadingCards;
  final String? error;
  final bool isAutoSpinning;
  final double availableCredit;
  final double activeHouseEarnings;

  const GameState({
    this.betLevel = 1,
    this.betPerCartela = 20.0,
    this.rounds = 3,
    this.selectedCity = 'addis_ababa',
    this.allCardNumbers = const [],
    this.entries = const [],
    this.activeEntries = const [],
    this.results = const [],
    this.status = GameStatus.idle,
    this.activeGameId,
    this.currentRound = 0,
    this.spinAngle = 0.0,
    this.isLoadingCards = false,
    this.error,
    this.isAutoSpinning = false,
    this.availableCredit = 0.0,
    this.activeHouseEarnings = 0.0,
  });

  GameState copyWith({
    int? betLevel,
    double? betPerCartela,
    int? rounds,
    String? selectedCity,
    List<CardEntry>? allCardNumbers,
    List<CardEntry>? entries,
    List<CardEntry>? activeEntries,
    List<GameResult>? results,
    GameStatus? status,
    String? activeGameId,
    int? currentRound,
    double? spinAngle,
    bool? isLoadingCards,
    String? error,
    bool? isAutoSpinning,
    double? availableCredit,
    double? activeHouseEarnings,
  }) {
    return GameState(
      betLevel: betLevel ?? this.betLevel,
      betPerCartela: betPerCartela ?? this.betPerCartela,
      rounds: rounds ?? this.rounds,
      selectedCity: selectedCity ?? this.selectedCity,
      allCardNumbers: allCardNumbers ?? this.allCardNumbers,
      entries: entries ?? this.entries,
      activeEntries: activeEntries ?? this.activeEntries,
      results: results ?? this.results,
      status: status ?? this.status,
      activeGameId: activeGameId ?? this.activeGameId,
      currentRound: currentRound ?? this.currentRound,
      spinAngle: spinAngle ?? this.spinAngle,
      isLoadingCards: isLoadingCards ?? this.isLoadingCards,
      error: error, // Clear error if not explicitly provided, or pass it if needed, but normally we clear it on success
      isAutoSpinning: isAutoSpinning ?? this.isAutoSpinning,
      availableCredit: availableCredit ?? this.availableCredit,
      activeHouseEarnings: activeHouseEarnings ?? this.activeHouseEarnings,
    );
  }

  double get pot => entries.length * betPerCartela;

  double get houseCutPercentage => _housePercentage[betLevel]!;

  double get houseEarnings {
    if (results.isEmpty) return pot * houseCutPercentage;
    final givenOut = results.fold<double>(0, (sum, r) => sum + r.prize);
    return pot - givenOut;
  }

  double get totalPrizePool => pot * (1 - houseCutPercentage);

  List<double> get prizes {
    if (rounds <= 0) return [];
    
    final total = totalPrizePool;
    if (rounds == 1) return [total];
    if (rounds == 2) return [total * 0.60, total * 0.40];
    if (rounds == 3) return [total * 0.50, total * 0.30, total * 0.20];
    
    // 4+ Rounds: 1st (40%), 2nd (25%), 3rd (15%), others (remaining 20% split)
    final top3Rates = [0.40, 0.25, 0.15];
    final List<double> p = [];
    for (int i = 0; i < rounds; i++) {
      if (i < 3) {
        p.add(total * top3Rates[i]);
      } else {
        final remainingCount = rounds - 3;
        final share = (total * 0.20) / remainingCount;
        p.add(share);
      }
    }
    return p;
  }

  String get housePercent => '${(houseCutPercentage * 100).toStringAsFixed(0)}%';

  int get spinCount => results.length;

  bool get canStartGame =>
      entries.length >= rounds &&
      entries.length >= 2 &&
      status == GameStatus.idle &&
      currentRound == 0 &&
      availableCredit >= houseEarnings;

  int get minEntries => max(2, rounds);

  bool get isGameRunning =>
      status == GameStatus.spinning || status == GameStatus.roundComplete;
}

@Riverpod(keepAlive: true)
class GameCtrl extends _$GameCtrl {
  @override
  GameState build() {
    // Watch user stream for real-time credit updates
    final user = ref.watch(authProvider);
    if (user != null) {
      // Sync available credit in real-time
      final sub = _service.userStream(user.uid).listen((appUser) {
        if (appUser != null && state.availableCredit != appUser.availableCredit) {
          // Use microtask to avoid concurrent modification issues
          Future.microtask(() {
            state = state.copyWith(availableCredit: appUser.availableCredit);
          });
        }
      });
      ref.onDispose(() => sub.cancel());
    }

    return const GameState();
  }

  FirebaseService get _service => ref.read(firebaseServiceProvider);

  Future<void> loadCardNumbers() async {
    state = state.copyWith(isLoadingCards: true);
    try {
      final numbers = await _service.getCardNumbers(state.selectedCity);
      state = state.copyWith(allCardNumbers: numbers, isLoadingCards: false);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load card numbers', isLoadingCards: false);
    }
  }

  void toggleEntry(CardEntry entry) {
    if (state.status != GameStatus.idle || state.currentRound > 0) return;
    final newEntries = List<CardEntry>.from(state.entries);
    if (newEntries.any((e) => e.id == entry.id)) {
      newEntries.removeWhere((e) => e.id == entry.id);
    } else {
      newEntries.add(entry);
    }
    state = state.copyWith(entries: newEntries);
  }

  void addEntryById(String id) {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return;
    if (state.entries.any((e) => e.id == trimmed)) return;
    final newEntries = List<CardEntry>.from(state.entries)..add(CardEntry(id: trimmed, label: trimmed));
    state = state.copyWith(entries: newEntries);
  }

  void clearEntries() {
    state = GameState(availableCredit: state.availableCredit);
  }

  void restartGame() {
    state = state.copyWith(
      activeEntries: List.from(state.entries),
      results: [],
      status: GameStatus.idle,
      currentRound: 0,
      spinAngle: 0.0,
      activeGameId: null, // intentionally null but strictly copyWith ignores nulls unless specified, wait. 
      // Need to fix copyWith to allow clearing activeGameId if needed. But it's simpler to recreate from entries:
    );
    // Overriding nulls by making a fresh state but keeping config & entries
    state = GameState(
      betLevel: state.betLevel,
      betPerCartela: state.betPerCartela,
      rounds: state.rounds,
      selectedCity: state.selectedCity,
      allCardNumbers: state.allCardNumbers,
      entries: state.entries,
      activeEntries: List.from(state.entries),
      availableCredit: state.availableCredit,
    );
  }

  void shuffle() {
    if (state.status != GameStatus.idle && state.status != GameStatus.roundComplete) return;
    final shuffEntries = List<CardEntry>.from(state.entries)..shuffle(Random());
    final shuffActive = List<CardEntry>.from(state.activeEntries)..shuffle(Random());
    state = state.copyWith(entries: shuffEntries, activeEntries: shuffActive);
  }

  void setBetLevel(int level) {
    if (level < 1 || level > 3) return;
    state = state.copyWith(betLevel: level);
  }

  void setCity(String city) {
    state = state.copyWith(selectedCity: city);
  }

  void setBetPerCartela(double val) {
    if (val < 1) return;
    state = state.copyWith(betPerCartela: val);
  }

  void setRounds(int r) {
    if (r < 1) return;
    state = state.copyWith(rounds: r);
  }

  Future<void> startGame(String operatorId) async {
    if (!state.canStartGame) return;
    
    final actEntries = List<CardEntry>.from(state.entries);
    final houseEarnings = state.pot * state.houseCutPercentage;
    
    state = state.copyWith(
      activeEntries: actEntries,
      status: GameStatus.spinning,
      activeHouseEarnings: houseEarnings,
      availableCredit: state.availableCredit - houseEarnings,
    );
    
    final id = await _service.createGame(
      operatorId: operatorId,
      betLevel: state.betLevel,
      betPerCartela: state.betPerCartela,
      rounds: state.rounds,
      entries: state.entries,
      totalPot: state.pot,
      houseEarnings: houseEarnings,
    );
    state = state.copyWith(activeGameId: id);
  }

  Future<void> onSpinComplete(int landedIndex, String operatorId) async {
    if (state.activeEntries.isEmpty) return;

    final safeIndex = landedIndex.clamp(0, state.activeEntries.length - 1);
    final winner = state.activeEntries[safeIndex];
    final prize = state.prizes[state.currentRound];

    final newResults = List<GameResult>.from(state.results)
      ..add(GameResult(
        round: state.currentRound + 1,
        winnerId: winner.id,
        winnerLabel: winner.label,
        prize: prize,
      ));

    final newActive = List<CardEntry>.from(state.activeEntries)..removeAt(safeIndex);

    if (newResults.length >= state.rounds) {
      state = state.copyWith(
        results: newResults,
        activeEntries: newActive,
        status: GameStatus.finished,
      );
      if (state.activeGameId != null) {
        final totalPrizeGiven = newResults.fold<double>(0, (s, r) => s + r.prize);
        final house = state.pot - totalPrizeGiven;
        await _service.saveGameResults(
          gameId: state.activeGameId!,
          results: newResults,
          operatorId: operatorId,
          totalPot: state.pot,
          totalPrize: totalPrizeGiven,
          houseEarnings: house,
          entryCount: state.entries.length,
          betLevel: state.betLevel,
          betPerCartela: state.betPerCartela,
          rounds: state.rounds,
        );
      }
    } else {
      state = state.copyWith(
        results: newResults,
        activeEntries: newActive,
        status: GameStatus.roundComplete,
        currentRound: state.currentRound + 1,
      );
      _scheduleNextRound();
    }
  }

  void _scheduleNextRound() {
    state = state.copyWith(isAutoSpinning: true);
    Timer(const Duration(milliseconds: 2500), () {
      if (state.status == GameStatus.roundComplete) {
        state = state.copyWith(status: GameStatus.spinning, isAutoSpinning: false);
      }
    });
  }

  void continueToNextRound() {
    if (state.status == GameStatus.roundComplete) {
      state = state.copyWith(status: GameStatus.spinning, isAutoSpinning: false);
    }
  }

  void updateSpinAngle(double angle) {
    state = state.copyWith(spinAngle: angle);
  }
}

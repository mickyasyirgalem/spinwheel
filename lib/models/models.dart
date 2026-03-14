class CardEntry {
  final String id;
  final String label;

  const CardEntry({required this.id, required this.label});

  Map<String, dynamic> toMap() => {'id': id, 'label': label};

  factory CardEntry.fromMap(Map<String, dynamic> m) =>
      CardEntry(id: m['id'] as String, label: m['label'] as String);
}

class GameResult {
  final int round;
  final String winnerId;
  final String winnerLabel;
  final double prize;

  const GameResult({
    required this.round,
    required this.winnerId,
    required this.winnerLabel,
    required this.prize,
  });

  Map<String, dynamic> toMap() => {
        'round': round,
        'winnerId': winnerId,
        'winnerLabel': winnerLabel,
        'prize': prize,
      };

  factory GameResult.fromMap(Map<String, dynamic> m) => GameResult(
        round: m['round'] as int,
        winnerId: m['winnerId'] as String,
        winnerLabel: m['winnerLabel'] as String,
        prize: (m['prize'] as num).toDouble(),
      );
}

/// Full user profile stored in Firestore at users/{uid}
class AppUser {
  final String uid;
  final String displayName;
  final String email;
  final double balance;          // accumulated house earnings (running total)
  final bool permission;         // operator permission flag
  final int totalGames;          // all-time games played
  final int completedGames;      // games fully completed
  final double dailyEarnings;    // today's house earnings (reset daily)
  final double totalEarnings;    // all-time house earnings
  final double totalPotHandled;  // total Birr pot processed all-time
  final double availableCredit;   // credit available for play (deducted as house cut)
  final DateTime? lastGameAt;    // timestamp of most recent game

  const AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    this.balance = 0,
    this.permission = false,
    this.totalGames = 0,
    this.completedGames = 0,
    this.dailyEarnings = 0,
    this.totalEarnings = 0,
    this.totalPotHandled = 0,
    this.availableCredit = 0,
    this.lastGameAt,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> m) => AppUser(
        uid: uid,
        displayName: m['displayName'] as String? ?? '',
        email: m['email'] as String? ?? '',
        balance: (m['balance'] as num?)?.toDouble() ?? 0,
        permission: m['permission'] as bool? ?? false,
        totalGames: m['totalGames'] as int? ?? 0,
        completedGames: m['completedGames'] as int? ?? 0,
        dailyEarnings: (m['dailyEarnings'] as num?)?.toDouble() ?? 0,
        totalEarnings: (m['totalEarnings'] as num?)?.toDouble() ?? 0,
        totalPotHandled: (m['totalPotHandled'] as num?)?.toDouble() ?? 0,
        availableCredit: (m['availableCredit'] as num?)?.toDouble() ?? 0,
        lastGameAt: m['lastGameAt'] != null
            ? (m['lastGameAt'] as dynamic).toDate()
            : null,
      );
}

/// A single game record stored in Firestore at games/{gameId}
class GameRecord {
  final String id;
  final String operatorId;
  final int betLevel;
  final double betPerCartela;
  final int rounds;
  final int entryCount;
  final double totalPot;
  final double totalPrize;
  final double houseEarnings;
  final List<CardEntry> entries;
  final List<GameResult> results;
  final String status; // active | completed
  final DateTime createdAt;

  const GameRecord({
    required this.id,
    required this.operatorId,
    required this.betLevel,
    required this.betPerCartela,
    required this.rounds,
    required this.entryCount,
    required this.totalPot,
    required this.totalPrize,
    required this.houseEarnings,
    required this.entries,
    required this.results,
    required this.status,
    required this.createdAt,
  });

  factory GameRecord.fromMap(String id, Map<String, dynamic> m) => GameRecord(
        id: id,
        operatorId: m['operatorId'] as String? ?? '',
        betLevel: m['betLevel'] as int? ?? 1,
        betPerCartela: (m['betPerCartela'] as num?)?.toDouble() ?? 20,
        rounds: m['rounds'] as int? ?? 3,
        entryCount: m['entryCount'] as int? ?? 0,
        totalPot: (m['totalPot'] as num?)?.toDouble() ?? 0,
        totalPrize: (m['totalPrize'] as num?)?.toDouble() ?? 0,
        houseEarnings: (m['houseEarnings'] as num?)?.toDouble() ?? 0,
        entries: (m['entries'] as List<dynamic>? ?? [])
            .map((e) => CardEntry.fromMap(e as Map<String, dynamic>))
            .toList(),
        results: (m['results'] as List<dynamic>? ?? [])
            .map((e) => GameResult.fromMap(e as Map<String, dynamic>))
            .toList(),
        status: m['status'] as String? ?? 'active',
        createdAt: m['createdAt'] != null
            ? (m['createdAt'] as dynamic).toDate()
            : DateTime.now(),
      );

  Map<String, dynamic> toSummaryMap() => {
        'betLevel': betLevel,
        'betPerCartela': betPerCartela,
        'rounds': rounds,
        'entryCount': entryCount,
        'totalPot': totalPot,
        'houseEarnings': houseEarnings,
        'status': status,
        'createdAt': createdAt,
        'winners': results.map((r) => r.winnerLabel).join(', '),
      };
}

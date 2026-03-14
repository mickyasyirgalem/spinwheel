import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/models.dart';

part 'firebase_service.g.dart';

@riverpod
FirebaseService firebaseService(Ref ref) {
  return FirebaseService();
}

@riverpod
Stream<AppUser?> userStream(Ref ref, String uid) {
  return ref.watch(firebaseServiceProvider).userStream(uid);
}

class FirebaseService {
  final _db = FirebaseFirestore.instance;

  // ── Card numbers ──────────────────────────────────────────────────────────
  Future<List<CardEntry>> getCardNumbers(String city) async {
    final snap = await _db.collection('cardNumbers').doc(city).get();
    if (!snap.exists) return _defaultNumbers();
    final data = snap.data()!;
    final list = data['numbers'] as List<dynamic>? ?? [];
    return list
        .map((e) => CardEntry.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  List<CardEntry> _defaultNumbers() {
    return List.generate(
      200,
      (i) => CardEntry(id: '${i + 1}', label: '${i + 1}'),
    );
  }

  Future<String> createGame({
    required String operatorId,
    required int betLevel,
    required double betPerCartela,
    required int rounds,
    required List<CardEntry> entries,
    required double totalPot,
    required double houseEarnings,
  }) async {
    final batch = _db.batch();
    final gameRef = _db.collection('games').doc();
    
    batch.set(gameRef, {
      'operatorId': operatorId,
      'betLevel': betLevel,
      'betPerCartela': betPerCartela,
      'rounds': rounds,
      'entryCount': entries.length,
      'totalPot': totalPot,
      'entries': entries.map((e) => e.toMap()).toList(),
      'results': [],
      'status': 'active',
      'totalPrize': 0,
      'houseEarnings': houseEarnings, // Store expected earnings
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Deduct credit immediately on game start
    batch.update(_db.collection('users').doc(operatorId), {
      'availableCredit': FieldValue.increment(-houseEarnings),
    });

    await batch.commit();
    return gameRef.id;
  }

  Future<void> saveGameResults({
    required String gameId,
    required List<GameResult> results,
    required String operatorId,
    required double totalPot,
    required double totalPrize,
    required double houseEarnings,
    required int entryCount,
    required int betLevel,
    required double betPerCartela,
    required int rounds,
  }) async {
    final batch = _db.batch();
    final now = FieldValue.serverTimestamp();

    // Update game document with full result data
    batch.update(_db.collection('games').doc(gameId), {
      'results': results.map((r) => r.toMap()).toList(),
      'status': 'completed',
      'totalPrize': totalPrize,
      'houseEarnings': houseEarnings,
      'completedAt': now,
    });

    batch.set(_db.collection('users').doc(operatorId), {
      'completedGames': FieldValue.increment(1),
      'totalGames': FieldValue.increment(1),
      'dailyEarnings': FieldValue.increment(houseEarnings),
      'totalEarnings': FieldValue.increment(houseEarnings),
      'totalPotHandled': FieldValue.increment(totalPot),
      'balance': FieldValue.increment(houseEarnings),
      'lastGameAt': now,
    }, SetOptions(merge: true));

    // Save game summary to user's games subcollection for history
    final userGameRef = _db
        .collection('users')
        .doc(operatorId)
        .collection('games')
        .doc(gameId);
    batch.set(userGameRef, {
      'gameId': gameId,
      'betLevel': betLevel,
      'betPerCartela': betPerCartela,
      'rounds': rounds,
      'entryCount': entryCount,
      'totalPot': totalPot,
      'totalPrize': totalPrize,
      'houseEarnings': houseEarnings,
      'winners': results
          .map(
            (r) => {
              'round': r.round,
              'winnerLabel': r.winnerLabel,
              'prize': r.prize,
            },
          )
          .toList(),
      'status': 'completed',
      'completedAt': now,
    });

    await batch.commit();
  }

  // ── User stats ────────────────────────────────────────────────────────────
  Future<AppUser?> getUser(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    print(snap);
    if (!snap.exists) return null;
    return AppUser.fromMap(uid, snap.data()!);
  }

  Stream<AppUser?> userStream(String uid) {
    print('isu$uid');
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return AppUser.fromMap(uid, snap.data()!);
    });
  }

  // ── Recent games (global games collection filtered by operator) ───────────
  Stream<List<GameRecord>> recentGamesStream(
    String operatorId, {
    int limit = 20,
  }) {
    return _db
        .collection('games')
        .where('operatorId', isEqualTo: operatorId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => GameRecord.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // ── User game history (subcollection) ─────────────────────────────────────
  Stream<List<GameRecord>> userGameHistoryStream(String uid, {int limit = 50}) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('games')
        .orderBy('completedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) {
            final data = doc.data();
            return GameRecord(
              id: doc.id,
              operatorId: uid,
              betLevel: data['betLevel'] as int? ?? 1,
              betPerCartela: (data['betPerCartela'] as num?)?.toDouble() ?? 20,
              rounds: data['rounds'] as int? ?? 3,
              entryCount: data['entryCount'] as int? ?? 0,
              totalPot: (data['totalPot'] as num?)?.toDouble() ?? 0,
              totalPrize: (data['totalPrize'] as num?)?.toDouble() ?? 0,
              houseEarnings: (data['houseEarnings'] as num?)?.toDouble() ?? 0,
              entries: [],
              results: (data['winners'] as List<dynamic>? ?? [])
                  .map(
                    (e) => GameResult(
                      round: (e as Map)['round'] as int,
                      winnerId: '',
                      winnerLabel: e['winnerLabel'] as String,
                      prize: (e['prize'] as num).toDouble(),
                    ),
                  )
                  .toList(),
              status: data['status'] as String? ?? 'completed',
              createdAt: data['completedAt'] != null
                  ? (data['completedAt'] as dynamic).toDate()
                  : DateTime.now(),
            );
          }).toList(),
        );
  }

  // ── Create user doc on first login ───────────────────────────────────────
  Future<void> ensureUserDoc(
    String uid,
    String email,
    String displayName,
  ) async {
    final ref = _db.collection('users').doc(uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'email': email,
        'displayName': displayName,
        'balance': 0.0,
        'permission': false,
        'totalGames': 0,
        'completedGames': 0,
        'dailyEarnings': 0.0,
        'totalEarnings': 0.0,
        'totalPotHandled': 0.0,
        'availableCredit': 0.0,
        'lastGameAt': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}

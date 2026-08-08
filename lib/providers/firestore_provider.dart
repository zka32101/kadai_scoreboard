import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kadai_scoreboard/models/index.dart';

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// Challenges (3 fixed: population decline, pension, elderly care)
final challengesProvider = StreamProvider<List<Challenge>>((ref) async* {
  final firestore = ref.watch(firebaseFirestoreProvider);
  try {
    yield* firestore
        .collection('challenges')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Challenge.fromFirestore(doc)).toList());
  } catch (e) {
    yield [];
  }
});

final challengeProvider = FutureProvider.family<Challenge?, String>((ref, id) async {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final doc = await firestore.collection('challenges').doc(id).get();
  if (doc.exists) {
    return Challenge.fromFirestore(doc);
  }
  return null;
});

// UserImpact data
final userImpactProvider =
    FutureProvider.family<List<UserImpact>, String>((ref, userId) async {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final snapshot = await firestore
      .collection('userImpacts')
      .where('userId', isEqualTo: userId)
      .get();
  return snapshot.docs.map((doc) => UserImpact.fromFirestore(doc)).toList();
});

final userImpactByChallengeProvider = FutureProvider.family<UserImpact?, (String, String)>(
  (ref, params) async {
    final (userId, challengeId) = params;
    final firestore = ref.watch(firebaseFirestoreProvider);
    final snapshot = await firestore
        .collection('userImpacts')
        .where('userId', isEqualTo: userId)
        .where('challengeId', isEqualTo: challengeId)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return UserImpact.fromFirestore(snapshot.docs.first);
    }
    return null;
  },
);

/// Upserts a UserImpact record for (userId, challengeId) with the
/// currently-selected policy and result, incrementing shareCount. Mirrors
/// the design doc's `recordShare(userId, challengeId)` Cloud Function until
/// that function is deployed — same write shape, so migrating later is a
/// drop-in swap of the call site.
Future<void> recordShare({
  required FirebaseFirestore firestore,
  required String userId,
  required String challengeId,
  required String selectedPolicy,
  required Map<int, double> result,
}) async {
  final existing = await firestore
      .collection('userImpacts')
      .where('userId', isEqualTo: userId)
      .where('challengeId', isEqualTo: challengeId)
      .limit(1)
      .get();

  if (existing.docs.isNotEmpty) {
    final doc = existing.docs.first;
    final current = UserImpact.fromFirestore(doc).incrementShare();
    await doc.reference.set(current.toFirestore());
  } else {
    final newImpact = UserImpact(
      id: '',
      userId: userId,
      challengeId: challengeId,
      selectedPolicy: selectedPolicy,
      result: result,
      createdAt: DateTime.now(),
      shareCount: 1,
    );
    await firestore.collection('userImpacts').add(newImpact.toFirestore());
  }
}

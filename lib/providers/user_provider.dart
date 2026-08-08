import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kadai_scoreboard/models/user.dart' as user_model;
import 'package:kadai_scoreboard/providers/auth_provider.dart';
import 'package:kadai_scoreboard/providers/firestore_provider.dart';

final userProfileProvider = StreamProvider<user_model.User?>((ref) async* {
  final userAsync = ref.watch(currentUserProvider);
  final firestore = ref.watch(firebaseFirestoreProvider);

  yield* userAsync.when(
    data: (firebaseUser) async* {
      if (firebaseUser != null) {
        yield* firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .snapshots()
            .map((doc) {
          if (doc.exists) {
            return user_model.User.fromFirestore(doc);
          }
          return null;
        });
      } else {
        yield null;
      }
    },
    loading: () async* {
      yield null;
    },
    error: (err, stack) async* {
      yield null;
    },
  );
});

final isProfileCompleteProvider = Provider<bool>((ref) {
  final userProfile = ref.watch(userProfileProvider);
  return userProfile.maybeWhen(
    data: (user) => user != null && user.age > 0,
    orElse: () => false,
  );
});

/// Increments the user's graph view counter. Fire-and-forget from the UI —
/// the paywall gate only needs an approximate, eventually-consistent count.
Future<void> incrementGraphViewCount(FirebaseFirestore firestore, String userId) {
  return firestore.collection('users').doc(userId).update({
    'graphViewCount': FieldValue.increment(1),
  });
}

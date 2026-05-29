import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../app_theme.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── POSTS/EVENTS CRUD ────────────────────────────────────────────────────

  // CREATE — add a new event/news post
  Future<String> createPost(EventModel event) async {
    await _db
        .collection(AppConstants.postsCollection)
        .doc(event.id)
        .set(event.toMap())
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw TimeoutException('Post save timed out.'),
        );
    return event.id;
  }

  // READ — real-time stream of all posts (sorted by date)
  Stream<List<EventModel>> postsStream() {
    return _db
        .collection(AppConstants.postsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList());
  }

  // READ — real-time stream filtered by category
  Stream<List<EventModel>> postsByCategoryStream(String category) {
    return _db
        .collection(AppConstants.postsCollection)
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList());
  }

  // READ — get posts by current user
  Stream<List<EventModel>> myPostsStream(String userId) {
    return _db
        .collection(AppConstants.postsCollection)
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList());
  }

  // READ — get single post by id
  Future<EventModel?> getPost(String id) async {
    final doc =
        await _db.collection(AppConstants.postsCollection).doc(id).get();
    if (doc.exists) return EventModel.fromFirestore(doc);
    return null;
  }

  // UPDATE — update post fields
  Future<void> updatePost(String id, Map<String, dynamic> data) async {
    await _db
        .collection(AppConstants.postsCollection)
        .doc(id)
        .update(data)
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw TimeoutException('Post update timed out.'),
        );
  }

  // DELETE — delete a post
  Future<void> deletePost(String id) async {
    await _db.collection(AppConstants.postsCollection).doc(id).delete();
  }

  // UPDATE — toggle like on a post (uses Firestore transactions for safety)
  Future<void> toggleLike(String postId, String userId) async {
    final postRef = _db.collection(AppConstants.postsCollection).doc(postId);

    await _db.runTransaction((transaction) async {
      final postDoc = await transaction.get(postRef);
      if (!postDoc.exists) return;

      final List<String> likedBy =
          List<String>.from(postDoc.data()!['likedBy'] ?? []);
      int likes = postDoc.data()!['likes'] ?? 0;

      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
        likes = (likes - 1).clamp(0, 9999);
      } else {
        likedBy.add(userId);
        likes += 1;
      }

      transaction.update(postRef, {'likedBy': likedBy, 'likes': likes});
    });
  }

  // ─── USERS ────────────────────────────────────────────────────────────────

  // READ — stream of all users (for admin/browse)
  Stream<List<UserModel>> usersStream() {
    return _db.collection(AppConstants.usersCollection).snapshots().map(
        (snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  // UPDATE — update user profile
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection(AppConstants.usersCollection).doc(uid).update(data);
  }
}

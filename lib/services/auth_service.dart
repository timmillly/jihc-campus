import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../app_theme.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static final Future<void> _googleSignInInitialized =
      _googleSignIn.initialize();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _googleSignInInitialized;

      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Save user to Firestore
      await _saveUserToFirestore(userCredential.user!);

      return userCredential;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await userCredential.user!.updateDisplayName(displayName);
    await _saveUserToFirestore(userCredential.user!, displayName: displayName);

    return userCredential;
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Save user data to Firestore /users collection
  Future<void> _saveUserToFirestore(User user, {String? displayName}) async {
    final userRef =
        _firestore.collection(AppConstants.usersCollection).doc(user.uid);

    final userDoc = await userRef.get();
    if (!userDoc.exists) {
      await userRef.set({
        'email': user.email,
        'displayName': displayName ?? user.displayName ?? 'JIHC Student',
        'photoUrl': user.photoURL,
        'createdAt': Timestamp.now(),
      });
    }
  }

  // Get user document from Firestore
  Future<UserModel?> getUserData(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  // Update profile photo URL in Firestore
  Future<void> updatePhotoUrl(String uid, String photoUrl) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .set({'photoUrl': photoUrl}, SetOptions(merge: true));
  }
}

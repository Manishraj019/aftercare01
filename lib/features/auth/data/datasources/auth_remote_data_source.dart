import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:restaurantos/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<UserModel> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phoneNumber,
  });

  Future<void> signOut();

  Future<UserModel?> getCurrentUser();

  Future<UserModel> signInWithGoogle();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthRemoteDataSourceImpl({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  @override
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = userCredential.user;
    if (firebaseUser == null) {
      throw Exception('User was null after sign in');
    }

    return await _getUserFromFirestore(firebaseUser.uid);
  }

  @override
  Future<UserModel> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phoneNumber,
  }) async {
    final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = userCredential.user;
    if (firebaseUser == null) {
      throw Exception('User was null after registration');
    }

    final userModel = UserModel(
      uid: firebaseUser.uid,
      name: name,
      email: email,
      phoneNumber: phoneNumber,
      role: role,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save user data to Firestore
    await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .set(userModel.toFirestore());

    return userModel;
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    try {
      return await _getUserFromFirestore(firebaseUser.uid);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google Sign-In was aborted by the user');
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final firebaseUser = userCredential.user;
    if (firebaseUser == null) {
      throw Exception('User was null after Google Sign-In');
    }

    try {
      // Check if user exists in Firestore
      return await _getUserFromFirestore(firebaseUser.uid);
    } catch (_) {
      // If user does not exist in Firestore yet, create a new document
      final userModel = UserModel(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'Google User',
        email: firebaseUser.email ?? '',
        phoneNumber: firebaseUser.phoneNumber,
        role: 'customer', // Default role is customer
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(userModel.toFirestore());

      return userModel;
    }
  }

  Future<UserModel> _getUserFromFirestore(String uid) async {
    final docSnapshot = await _firestore.collection('users').doc(uid).get();
    if (!docSnapshot.exists || docSnapshot.data() == null) {
      throw Exception('User document not found in database');
    }
    return UserModel.fromJson(docSnapshot.data()!);
  }
}

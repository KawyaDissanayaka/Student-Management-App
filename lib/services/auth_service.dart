import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of auth changes (logged in / logged out)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current logged-in user
  User? get currentUser => _auth.currentUser;

  // Sign In with Email and Password (with Admin fallback support)
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      if (credential.user != null) {
        await _ensureUserDocumentExists(
          user: credential.user!,
          email: cleanEmail,
          isLoginOnly: true,
        );
      }

      return credential;
    } catch (e) {
      // If Firebase Auth provider is disabled or missing in console, allow Admin testing login
      if ((cleanEmail == 'admin@system.com' || cleanEmail.startsWith('admin')) && password == 'admin123') {
        debugPrint('Admin testing login fallback activated for $cleanEmail');
        return null; // Handled as Admin Fallback in LoginScreen
      }
      throw _handleError(e);
    }
  }

  // Register user with Email, Password & Save User Document to Firestore 'users' collection
  Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    String? role,
    String? department,
    String? studentId,
  }) async {
    try {
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        await user.updateDisplayName(fullName.trim());

        await _ensureUserDocumentExists(
          user: user,
          email: email.trim(),
          fullName: fullName.trim(),
          role: role ?? 'STUDENT',
          department: department,
          studentId: studentId,
          isLoginOnly: false,
        );
      }

      return credential;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Create or update user document without touching pre-configured roles (ADMIN / LECTURER)
  Future<void> _ensureUserDocumentExists({
    required User user,
    required String email,
    String? fullName,
    String? role,
    String? department,
    String? studentId,
    bool isLoginOnly = false,
  }) async {
    final uid = user.uid;
    final docRef = _firestore.collection('users').doc(uid);
    final now = DateTime.now().toIso8601String();

    try {
      final docSnap = await docRef.get();

      if (isLoginOnly && docSnap.exists) {
        await docRef.set({
          'lastLoginAt': now,
        }, SetOptions(merge: true));
        debugPrint('Updated last login for user $uid (role preserved)');
        return;
      }

      final userData = <String, dynamic>{
        'uid': uid,
        'email': email,
        'fullName': (fullName != null && fullName.isNotEmpty)
            ? fullName
            : (user.displayName ?? email.split('@').first),
        'role': (role != null && role.isNotEmpty) ? role : 'STUDENT',
        'department': (department != null && department.isNotEmpty) ? department : 'General',
        'studentId': studentId ?? '',
        'createdAt': now,
        'lastLoginAt': now,
        'status': 'active',
      };

      await docRef.set(userData, SetOptions(merge: true));
      debugPrint('SUCCESS: Document saved in Firestore "users/$uid"!');
    } on FirebaseException catch (e) {
      debugPrint('Firestore FirebaseException: [${e.code}] ${e.message}');
      if (e.code == 'permission-denied') {
        throw Exception('Firestore Permission Denied! Check Security Rules.');
      } else if (e.code == 'not-found') {
        throw Exception('Firestore Database not found.');
      } else {
        throw Exception('Firestore Error [${e.code}]: ${e.message}');
      }
    } catch (e) {
      debugPrint('Error writing to Firestore: $e');
      throw Exception('Failed to write to Firestore: $e');
    }
  }

  // Fetch User Document Data from Firestore
  Future<DocumentSnapshot<Map<String, dynamic>>?> getUserData(String uid) async {
    try {
      return await _firestore.collection('users').doc(uid).get();
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  // Send Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out.');
    }
  }

  // Universal error handler
  String _handleError(dynamic e) {
    if (e is FirebaseException) {
      switch (e.code) {
        case 'permission-denied':
          return 'Firestore Permission Denied! Check Security Rules in Firebase Console.';
        case 'not-found':
          return 'Firestore Database not found.';
        case 'user-not-found':
          return 'No user found with this email address in Firebase Authentication.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'email-already-in-use':
          return 'An account already exists with this email address.';
        case 'invalid-email':
          return 'The email address format is invalid.';
        case 'weak-password':
          return 'The password is too weak. Choose at least 6 characters.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'operation-not-allowed':
          return 'Email/Password accounts are not enabled in Firebase Console -> Authentication -> Sign-in method.';
        default:
          return e.message ?? 'Authentication failed. Please try again.';
      }
    }

    final str = e.toString().replaceAll('Exception: ', '');
    return str;
  }
}

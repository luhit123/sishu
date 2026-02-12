import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../constants/app_constants.dart';
import 'user_service.dart';
import 'notification_service.dart';

/// Authentication service for handling Google Sign-In with Firebase
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService();

  // Cached user model for current session
  UserModel? _cachedUserModel;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is signed in
  bool get isSignedIn => currentUser != null;

  // Get cached user model
  UserModel? get userModel => _cachedUserModel;

  /// Check if current user is admin
  bool get isAdmin {
    if (currentUser == null) return false;
    // Creator always has admin access
    if (currentUser!.uid == AppConstants.creatorUid) return true;
    return _cachedUserModel?.role == UserRole.admin;
  }

  /// Check if current user is doctor
  bool get isDoctor {
    if (currentUser == null) return false;
    return _cachedUserModel?.role == UserRole.doctor;
  }

  /// Check if current user is creator (super admin)
  bool get isCreator {
    return currentUser?.uid == AppConstants.creatorUid;
  }

  /// Get current user's role
  UserRole get currentRole {
    if (currentUser == null) return UserRole.user;
    if (currentUser!.uid == AppConstants.creatorUid) return UserRole.admin;
    return _cachedUserModel?.role ?? UserRole.user;
  }

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Create user in Firestore if not exists and cache the user model
      if (userCredential.user != null) {
        _cachedUserModel = await _userService.createUserIfNotExists(
          userCredential.user!,
        );

        // Save FCM token for push notifications
        await _notificationService.saveToken();
      }

      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  /// Initialize user model (call after auth state changes to signed in)
  Future<void> initializeUserModel() async {
    if (currentUser != null) {
      try {
        _cachedUserModel = await _userService.getUser(currentUser!.uid);
        // If user doesn't exist in Firestore, create them
        if (_cachedUserModel == null) {
          _cachedUserModel = await _userService.createUserIfNotExists(currentUser!);
        }

        // Save FCM token for push notifications
        await _notificationService.saveToken();
      } catch (e) {
        // If Firestore is unavailable, check if user is creator for offline admin access
        print('Error initializing user model: $e');
        // Creator still gets admin access even offline
      }
    }
  }

  /// Refresh user model from Firestore
  Future<void> refreshUserModel() async {
    if (currentUser != null) {
      try {
        _cachedUserModel = await _userService.getUser(currentUser!.uid);
      } catch (e) {
        print('Error refreshing user model: $e');
      }
    }
  }

  /// Sign out from Google and Firebase
  Future<void> signOut() async {
    try {
      // Delete FCM token before sign out
      await _notificationService.deleteToken();

      _cachedUserModel = null; // Clear cached user model
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  /// Get user display name
  String? get displayName => currentUser?.displayName;

  /// Get user email
  String? get email => currentUser?.email;

  /// Get user photo URL
  String? get photoUrl => currentUser?.photoURL;
}

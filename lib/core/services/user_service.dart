import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_model.dart';
import '../models/doctor_profile.dart';
import '../constants/app_constants.dart';

/// Service for managing user data in Firestore
class UserService {
  // Singleton instance
  static UserService? _instance;
  static FirebaseFirestore? _firestore;

  // In-memory cache for doctor profiles
  static List<DoctorProfile>? _doctorProfilesCache;
  static DateTime? _doctorProfilesCacheTime;
  static const _cacheDuration = Duration(minutes: 5);

  factory UserService() {
    _instance ??= UserService._internal();
    return _instance!;
  }

  UserService._internal();

  FirebaseFirestore get _firestoreInstance {
    _firestore ??= FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'sishu',
    );
    return _firestore!;
  }

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestoreInstance.collection('users');

  CollectionReference<Map<String, dynamic>> get _doctorInvitesCollection =>
      _firestoreInstance.collection('doctor_invites');

  CollectionReference<Map<String, dynamic>> get _doctorProfilesCollection =>
      _firestoreInstance.collection('doctor_profiles');

  /// Create user document if it doesn't exist (called on first sign-in)
  Future<UserModel> createUserIfNotExists(User firebaseUser) async {
    final docRef = _usersCollection.doc(firebaseUser.uid);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      // Update last sign-in time and return existing user
      await docRef.update({
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return UserModel.fromFirestore(await docRef.get());
    }

    // Determine initial role
    final isCreator = firebaseUser.uid == AppConstants.creatorUid;
    UserRole initialRole = isCreator ? UserRole.admin : UserRole.user;

    // Check if this email has a pending doctor invite
    if (!isCreator && firebaseUser.email != null) {
      final doctorInvite = await getDoctorInvite(firebaseUser.email!);
      if (doctorInvite != null) {
        initialRole = UserRole.doctor;
        // Copy doctor profile from invite to doctor_profiles collection
        await _copyDoctorProfileFromInvite(firebaseUser.uid, doctorInvite);
        // Remove the invite after it's been used
        await removeDoctorInvite(firebaseUser.email!);
      }
    }

    // Create new user document
    final now = DateTime.now();
    final newUser = UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? 'User',
      photoUrl: firebaseUser.photoURL,
      role: initialRole,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(newUser.toFirestore());
    return newUser;
  }

  // ============================================================================
  // DOCTOR INVITE METHODS
  // ============================================================================

  /// Invite a doctor with full profile (they'll get doctor role when they sign in)
  Future<bool> inviteDoctorWithProfile(DoctorProfile profile, String adminUid) async {
    // Normalize email
    final normalizedEmail = profile.email.toLowerCase().trim();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      return false;
    }

    // Check if requester is admin
    final adminRole = await getUserRole(adminUid);
    if (adminRole != UserRole.admin) {
      return false;
    }

    // Check if user already exists with this email
    final existingUser = await getUserByEmail(normalizedEmail);
    if (existingUser != null) {
      // User already exists, update their role and create/update profile
      await setUserRole(existingUser.uid, UserRole.doctor, adminUid);
      await saveDoctorProfile(existingUser.uid, profile);
      return true;
    }

    // Create doctor invite with profile data
    final inviteData = profile.toFirestore();
    inviteData['invitedBy'] = adminUid;
    inviteData['invitedAt'] = FieldValue.serverTimestamp();

    await _doctorInvitesCollection.doc(normalizedEmail).set(inviteData);
    return true;
  }

  /// Get doctor invite data (returns null if not found)
  Future<Map<String, dynamic>?> getDoctorInvite(String email) async {
    final normalizedEmail = email.toLowerCase().trim();
    final docSnapshot = await _doctorInvitesCollection.doc(normalizedEmail).get();
    if (!docSnapshot.exists) return null;
    return docSnapshot.data();
  }

  /// Check if an email has a pending doctor invite
  Future<bool> checkDoctorInvite(String email) async {
    final invite = await getDoctorInvite(email);
    return invite != null;
  }

  /// Copy doctor profile from invite to doctor_profiles collection
  Future<void> _copyDoctorProfileFromInvite(String uid, Map<String, dynamic> inviteData) async {
    // Remove invite-specific fields
    inviteData.remove('invitedBy');
    inviteData.remove('invitedAt');

    // Update timestamps
    inviteData['updatedAt'] = FieldValue.serverTimestamp();

    await _doctorProfilesCollection.doc(uid).set(inviteData);
    clearDoctorProfilesCache(); // Clear cache so new data is fetched
  }

  /// Remove a doctor invite (after it's been used)
  Future<void> removeDoctorInvite(String email) async {
    final normalizedEmail = email.toLowerCase().trim();
    await _doctorInvitesCollection.doc(normalizedEmail).delete();
  }

  /// Get all pending doctor invites
  Future<List<Map<String, dynamic>>> getPendingDoctorInvites() async {
    final querySnapshot = await _doctorInvitesCollection
        .orderBy('invitedAt', descending: true)
        .get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'email': data['email'] ?? doc.id,
        'name': data['name'] ?? '',
        'specialty': data['specialty'] ?? '',
        'invitedAt': (data['invitedAt'] as Timestamp?)?.toDate(),
      };
    }).toList();
  }

  // ============================================================================
  // DOCTOR PROFILE METHODS
  // ============================================================================

  /// Save doctor profile
  Future<void> saveDoctorProfile(String uid, DoctorProfile profile) async {
    await _doctorProfilesCollection.doc(uid).set(profile.toFirestore());
    clearDoctorProfilesCache(); // Clear cache so new data is fetched
  }

  /// Get doctor profile by UID
  Future<DoctorProfile?> getDoctorProfile(String uid) async {
    final docSnapshot = await _doctorProfilesCollection.doc(uid).get();
    if (!docSnapshot.exists) return null;
    return DoctorProfile.fromFirestore(docSnapshot.data()!);
  }

  /// Get doctor profile by email
  Future<DoctorProfile?> getDoctorProfileByEmail(String email) async {
    final normalizedEmail = email.toLowerCase().trim();
    final querySnapshot = await _doctorProfilesCollection
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();
    if (querySnapshot.docs.isEmpty) return null;
    return DoctorProfile.fromFirestore(querySnapshot.docs.first.data());
  }

  /// Update doctor profile
  Future<void> updateDoctorProfile(String uid, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _doctorProfilesCollection.doc(uid).update(updates);
    clearDoctorProfilesCache(); // Clear cache so new data is fetched
  }

  /// Get all doctor profiles (with caching)
  Future<List<DoctorProfile>> getAllDoctorProfiles({bool forceRefresh = false}) async {
    // Return cached data if valid
    if (!forceRefresh &&
        _doctorProfilesCache != null &&
        _doctorProfilesCacheTime != null &&
        DateTime.now().difference(_doctorProfilesCacheTime!) < _cacheDuration) {
      return _doctorProfilesCache!;
    }

    // Fetch from Firestore with cache preference
    final querySnapshot = await _doctorProfilesCollection
        .get(const GetOptions(source: Source.serverAndCache));

    final profiles = querySnapshot.docs
        .map((doc) => DoctorProfile.fromFirestore(doc.data(), docId: doc.id))
        .toList();

    // Update cache
    _doctorProfilesCache = profiles;
    _doctorProfilesCacheTime = DateTime.now();

    return profiles;
  }

  /// Clear doctor profiles cache (call after adding/editing doctors)
  void clearDoctorProfilesCache() {
    _doctorProfilesCache = null;
    _doctorProfilesCacheTime = null;
  }

  /// Stream of doctor profile for real-time updates
  Stream<DoctorProfile?> doctorProfileStream(String uid) {
    return _doctorProfilesCollection.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return DoctorProfile.fromFirestore(snapshot.data()!);
    });
  }

  /// Stream of ALL doctor profiles for real-time updates (for users)
  Stream<List<DoctorProfile>> allDoctorProfilesStream() {
    return _doctorProfilesCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => DoctorProfile.fromFirestore(doc.data(), docId: doc.id))
          .toList();
    });
  }

  /// Update doctor availability status (doctors can enable both options)
  Future<void> updateDoctorAvailability(String uid, {
    required bool acceptingBookings,
    required bool acceptingInstantCalls,
  }) async {
    await _doctorProfilesCollection.doc(uid).update({
      'acceptingBookings': acceptingBookings,
      'acceptingInstantCalls': acceptingInstantCalls,
      'statusUpdatedAt': FieldValue.serverTimestamp(),
    });
    clearDoctorProfilesCache();
  }

  /// Get user by email
  Future<UserModel?> getUserByEmail(String email) async {
    final normalizedEmail = email.toLowerCase().trim();
    final querySnapshot = await _usersCollection
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();
    if (querySnapshot.docs.isEmpty) return null;
    return UserModel.fromFirestore(querySnapshot.docs.first);
  }

  /// Get user by UID
  Future<UserModel?> getUser(String uid) async {
    final docSnapshot = await _usersCollection.doc(uid).get();
    if (!docSnapshot.exists) return null;
    return UserModel.fromFirestore(docSnapshot);
  }

  /// Get user's role
  Future<UserRole> getUserRole(String uid) async {
    // Creator always has admin role
    if (uid == AppConstants.creatorUid) {
      return UserRole.admin;
    }

    final user = await getUser(uid);
    return user?.role ?? UserRole.user;
  }

  /// Set user's role (admin only operation)
  Future<bool> setUserRole(String uid, UserRole role, String adminUid) async {
    // Check if requester is admin
    final adminRole = await getUserRole(adminUid);
    if (adminRole != UserRole.admin) {
      return false; // Not authorized
    }

    // Prevent changing creator's role
    if (uid == AppConstants.creatorUid) {
      return false; // Cannot change creator's role
    }

    // Prevent non-creator admins from setting admin role
    if (role == UserRole.admin && adminUid != AppConstants.creatorUid) {
      return false; // Only creator can set admin role
    }

    await _usersCollection.doc(uid).update({
      'role': role.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return true;
  }

  /// Get all users (for admin panel)
  Future<List<UserModel>> getAllUsers() async {
    final querySnapshot = await _usersCollection
        .orderBy('createdAt', descending: true)
        .get();
    return querySnapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  /// Get users with doctor role
  Future<List<UserModel>> getDoctors() async {
    final querySnapshot = await _usersCollection
        .where('role', isEqualTo: UserRole.doctor.value)
        .get();
    return querySnapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  /// Stream of user data (for real-time updates)
  Stream<UserModel?> userStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return UserModel.fromFirestore(snapshot);
    });
  }

  /// Stream of all users (for admin panel)
  Stream<List<UserModel>> allUsersStream() {
    return _usersCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  /// Search users by email or display name
  Future<List<UserModel>> searchUsers(String query) async {
    final lowerQuery = query.toLowerCase();
    final allUsers = await getAllUsers();
    return allUsers.where((user) {
      return user.email.toLowerCase().contains(lowerQuery) ||
          user.displayName.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get user statistics
  Future<Map<String, int>> getUserStats() async {
    final users = await getAllUsers();
    return {
      'total': users.length,
      'doctors': users.where((u) => u.role == UserRole.doctor).length,
      'admins': users.where((u) => u.role == UserRole.admin).length,
      'users': users.where((u) => u.role == UserRole.user).length,
    };
  }
}

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Service for tracking user notification read status
class UserNotificationService {
  static final UserNotificationService _instance = UserNotificationService._internal();
  factory UserNotificationService() => _instance;
  UserNotificationService._internal();

  // Use the custom "sishu" database
  static FirebaseFirestore? _firestoreInstance;
  FirebaseFirestore get _firestore {
    _firestoreInstance ??= FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'sishu',
    );
    return _firestoreInstance!;
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream of unread notification count
  Stream<int> unreadCountStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(0);
    }

    // Get user's last read timestamp and count notifications after it
    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .asyncMap((userDoc) async {
      final lastReadAt = (userDoc.data()?['notificationsReadAt'] as Timestamp?)?.toDate();

      // Query notifications sent after lastReadAt
      Query query = _firestore
          .collection('admin_notifications')
          .orderBy('sentAt', descending: true)
          .limit(100);

      if (lastReadAt != null) {
        query = query.where('sentAt', isGreaterThan: Timestamp.fromDate(lastReadAt));
      }

      try {
        final snapshot = await query.get();
        return snapshot.docs.length;
      } catch (e) {
        debugPrint('Error getting unread count: $e');
        return 0;
      }
    });
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'notificationsReadAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
    }
  }

  /// Get unread count once (not stream)
  Future<int> getUnreadCount() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final lastReadAt = (userDoc.data()?['notificationsReadAt'] as Timestamp?)?.toDate();

      Query query = _firestore
          .collection('admin_notifications')
          .orderBy('sentAt', descending: true)
          .limit(100);

      if (lastReadAt != null) {
        query = query.where('sentAt', isGreaterThan: Timestamp.fromDate(lastReadAt));
      }

      final snapshot = await query.get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }
}

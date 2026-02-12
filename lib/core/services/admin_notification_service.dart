import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/admin_notification.dart';

/// Service for admin notification management
class AdminNotificationService {
  // Use the custom "sishu" database
  static FirebaseFirestore? _firestoreInstance;
  FirebaseFirestore get _firestore {
    _firestoreInstance ??= FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'sishu',
    );
    return _firestoreInstance!;
  }

  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get notification history stream
  Stream<List<AdminNotification>> getNotificationHistory({int limit = 50}) {
    return _firestore
        .collection('admin_notifications')
        .orderBy('sentAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AdminNotification.fromFirestore(doc))
            .toList());
  }

  /// Upload notification image
  Future<String?> uploadNotificationImage(File imageFile) async {
    try {
      final fileName = 'notification_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('notifications/$fileName');

      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading notification image: $e');
      return null;
    }
  }

  /// Send notification to targeted users
  Future<Map<String, dynamic>> sendNotification({
    required String title,
    required String body,
    String? imageUrl,
    required NotificationTarget target,
    NotificationType type = NotificationType.general,
    String? referenceId,
    String? referenceType,
    Map<String, dynamic>? extraData,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Call Cloud Function to send notification
      final callable = _functions.httpsCallable('sendAdminNotification');
      final result = await callable.call({
        'title': title,
        'body': body,
        'imageUrl': imageUrl,
        'target': target.name,
        'type': type.name,
        'referenceId': referenceId,
        'referenceType': referenceType,
        'extraData': extraData,
      });

      final data = result.data as Map<String, dynamic>;
      return {
        'success': data['success'] ?? false,
        'sentCount': data['sentCount'] ?? 0,
        'notificationId': data['notificationId'],
      };
    } catch (e) {
      debugPrint('Error sending notification: $e');
      rethrow;
    }
  }

  /// Send notification for new parenting tip
  Future<Map<String, dynamic>> sendTipNotification({
    required String tipId,
    required String tipTitle,
    required String tipSummary,
    String? imageUrl,
  }) async {
    return sendNotification(
      title: 'New Parenting Tip',
      body: tipTitle,
      imageUrl: imageUrl,
      target: NotificationTarget.all,
      type: NotificationType.newTip,
      referenceId: tipId,
      referenceType: 'tip',
      extraData: {
        'tipTitle': tipTitle,
        'tipSummary': tipSummary,
      },
    );
  }

  /// Send notification for new disease info
  Future<Map<String, dynamic>> sendDiseaseNotification({
    required String diseaseId,
    required String diseaseName,
    required String description,
    String? imageUrl,
  }) async {
    return sendNotification(
      title: 'New Health Information',
      body: 'Learn about $diseaseName - symptoms, causes, and home remedies',
      imageUrl: imageUrl,
      target: NotificationTarget.all,
      type: NotificationType.newDisease,
      referenceId: diseaseId,
      referenceType: 'disease',
      extraData: {
        'diseaseName': diseaseName,
        'description': description,
      },
    );
  }

  /// Get notification statistics
  Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final startOfWeek = startOfToday.subtract(Duration(days: now.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);

      final allNotifications = await _firestore
          .collection('admin_notifications')
          .get();

      final todayNotifications = await _firestore
          .collection('admin_notifications')
          .where('sentAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
          .get();

      final weekNotifications = await _firestore
          .collection('admin_notifications')
          .where('sentAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .get();

      final monthNotifications = await _firestore
          .collection('admin_notifications')
          .where('sentAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .get();

      int totalSent = 0;
      for (var doc in allNotifications.docs) {
        totalSent += (doc.data()['sentCount'] as int?) ?? 0;
      }

      return {
        'totalNotifications': allNotifications.size,
        'todayCount': todayNotifications.size,
        'weekCount': weekNotifications.size,
        'monthCount': monthNotifications.size,
        'totalUsersSent': totalSent,
      };
    } catch (e) {
      debugPrint('Error getting notification stats: $e');
      return {
        'totalNotifications': 0,
        'todayCount': 0,
        'weekCount': 0,
        'monthCount': 0,
        'totalUsersSent': 0,
      };
    }
  }

  /// Delete a notification record (admin only)
  Future<void> deleteNotification(String notificationId) async {
    await _firestore
        .collection('admin_notifications')
        .doc(notificationId)
        .delete();
  }
}

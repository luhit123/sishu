import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📞 BACKGROUND: Handling background message: ${message.messageId}');
  debugPrint('📞 BACKGROUND: Message data: ${message.data}');
  
  final data = message.data;
  
  // Handle incoming call notifications
  if (data['type'] == 'incoming_call') {
    debugPrint('📞 BACKGROUND: Incoming call detected, showing CallKit UI');
    
    final callId = data['id'] ?? data['callId'] ?? '';
    final callerName = data['nameCaller'] ?? data['callerName'] ?? 'Unknown';
    final callerPhoto = data['avatar'] ?? data['callerPhoto'] ?? '';
    final callType = int.tryParse(data['callType'] ?? '1') ?? 1;
    
    final params = CallKitParams(
      id: callId,
      nameCaller: callerName,
      avatar: callerPhoto.isNotEmpty ? callerPhoto : null,
      handle: 'Incoming Video Consultation',
      type: callType, // 1 = video, 0 = audio
      textAccept: 'Accept',
      textDecline: 'Decline',
      duration: 60000,
      extra: <String, dynamic>{
        'callId': callId,
      },
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#4CAF50',
        actionColor: '#4CAF50',
        incomingCallNotificationChannelName: 'Incoming Calls',
        missedCallNotificationChannelName: 'Missed Calls',
        isShowFullLockedScreen: true,
      ),
      ios: IOSParams(
        iconName: 'CallKitIcon',
        handleType: 'generic',
        supportsVideo: callType == 1,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
      ),
    );
    
    await FlutterCallkitIncoming.showCallkitIncoming(params);
    debugPrint('📞 BACKGROUND: CallKit UI shown');
  }
}

/// Notification Service for FCM and call notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Use the custom "sishu" database
  static FirebaseFirestore? _firestoreInstance;
  FirebaseFirestore get _firestore {
    _firestoreInstance ??= FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'sishu',
    );
    return _firestoreInstance!;
  }

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;

  // Notification channel for Android
  static const AndroidNotificationChannel _highImportanceChannel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  // Stream controller for incoming call notifications
  final _incomingCallController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onIncomingCall => _incomingCallController.stream;

  /// Initialize FCM and request permissions
  Future<void> initialize() async {
    debugPrint('📞 NotificationService: Initializing...');

    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: !kIsWeb, // Critical alerts not supported on web
    );

    debugPrint('📞 NotificationService: FCM authorization status: ${settings.authorizationStatus}');

    // Initialize local notifications and create channel for Android (not on web)
    if (!kIsWeb) {
      await _initializeLocalNotifications();
    }

    // Get and save FCM token
    await _saveToken();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_updateToken);

    // Set up message handlers (background handler not supported on web)
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      debugPrint('📞 NotificationService: Background message handler set');
    }

    // Handle foreground messages
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    debugPrint('📞 NotificationService: Foreground message listener set');

    // Handle when app is opened from notification
    _openedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    debugPrint('📞 NotificationService: Message opened app listener set');

    // Check if app was opened from a notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('📞 NotificationService: Found initial message, handling...');
      _handleInitialMessage(initialMessage);
    }

    // Get APNs token for iOS VoIP push
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      final apnsToken = await _messaging.getAPNSToken();
      if (apnsToken != null) {
        await _saveVoipToken(apnsToken);
        debugPrint('📞 NotificationService: VoIP token saved for iOS');
      }
    }

    debugPrint('📞 NotificationService: Initialization complete');
  }

  /// Initialize local notifications and create Android notification channel
  Future<void> _initializeLocalNotifications() async {
    // Android initialization
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);

    // Create notification channel for Android
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_highImportanceChannel);
      debugPrint('Android notification channel created');
    }
  }

  /// Get and save FCM token
  Future<void> _saveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _updateToken(token);
      }
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
    }
  }

  /// Update FCM token in Firestore
  Future<void> _updateToken(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Use set with merge to create document if it doesn't exist
      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('FCM token updated for user: ${user.uid}');
    } catch (e) {
      debugPrint('Failed to update FCM token: $e');
    }
  }

  /// Save VoIP token for iOS
  Future<void> _saveVoipToken(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'voipToken': token,
      }, SetOptions(merge: true));
      debugPrint('VoIP token saved');
    } catch (e) {
      debugPrint('Failed to save VoIP token: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📞 NotificationService: Foreground message received');
    debugPrint('📞 NotificationService: Message ID: ${message.messageId}');
    debugPrint('📞 NotificationService: Message data: ${message.data}');
    debugPrint('📞 NotificationService: Message notification: ${message.notification?.title}');

    final data = message.data;
    if (data['type'] == 'incoming_call') {
      debugPrint('📞 NotificationService: INCOMING CALL detected, emitting to stream');
      // Normalize the data to use consistent field names
      // FCM sends 'id' and 'nameCaller' for flutter_callkit_incoming compatibility
      final normalizedData = <String, dynamic>{
        'callId': data['id'] ?? data['callId'],
        'callerName': data['nameCaller'] ?? data['callerName'] ?? 'Unknown',
        'callerPhoto': data['avatar'] ?? data['callerPhoto'],
        'type': 'incoming_call',
      };
      _incomingCallController.add(normalizedData);
      return;
    }

    // Show notification manually when app is in foreground
    final notification = message.notification;
    if (notification != null && !kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _showLocalNotification(notification, message.data);
    }
  }

  /// Show notification using flutter_local_notifications (for foreground)
  Future<void> _showLocalNotification(
    RemoteNotification notification,
    Map<String, dynamic> data,
  ) async {
    AndroidNotificationDetails androidDetails;

    // Check if notification has an image
    if (notification.android?.imageUrl != null || data['imageUrl'] != null) {
      final imageUrl = notification.android?.imageUrl ?? data['imageUrl'];
      try {
        // Download image and create BigPictureStyleInformation
        final response = await HttpClient().getUrl(Uri.parse(imageUrl));
        final httpResponse = await response.close();
        final bytes = await consolidateHttpClientResponseBytes(httpResponse);
        final bigPicture = ByteArrayAndroidBitmap(bytes);

        androidDetails = AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription: 'This channel is used for important notifications.',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          playSound: true,
          enableVibration: true,
          styleInformation: BigPictureStyleInformation(
            bigPicture,
            contentTitle: notification.title,
            summaryText: notification.body,
            hideExpandedLargeIcon: true,
          ),
        );
      } catch (e) {
        debugPrint('Failed to load notification image: $e');
        // Fallback to text-only notification
        androidDetails = const AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription: 'This channel is used for important notifications.',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          playSound: true,
          enableVibration: true,
        );
      }
    } else {
      androidDetails = const AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
      );
    }

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      notification.title,
      notification.body,
      notificationDetails,
      payload: data['referenceId']?.toString(),
    );
  }

  /// Handle when app is opened from notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('📞 NotificationService: App opened from notification: ${message.messageId}');
    debugPrint('📞 NotificationService: Message data: ${message.data}');

    final data = message.data;
    if (data['type'] == 'incoming_call') {
      debugPrint('📞 NotificationService: INCOMING CALL from opened app, emitting to stream');
      // Normalize the data to use consistent field names
      final normalizedData = <String, dynamic>{
        'callId': data['id'] ?? data['callId'],
        'callerName': data['nameCaller'] ?? data['callerName'] ?? 'Unknown',
        'callerPhoto': data['avatar'] ?? data['callerPhoto'],
        'type': 'incoming_call',
      };
      _incomingCallController.add(normalizedData);
    }
  }

  /// Handle initial message (app was terminated)
  void _handleInitialMessage(RemoteMessage message) {
    debugPrint('📞 NotificationService: Initial message (app was terminated): ${message.messageId}');
    debugPrint('📞 NotificationService: Message data: ${message.data}');

    final data = message.data;
    if (data['type'] == 'incoming_call') {
      debugPrint('📞 NotificationService: INCOMING CALL from initial message, emitting to stream (delayed 1s)');
      // Normalize the data to use consistent field names
      final normalizedData = <String, dynamic>{
        'callId': data['id'] ?? data['callId'],
        'callerName': data['nameCaller'] ?? data['callerName'] ?? 'Unknown',
        'callerPhoto': data['avatar'] ?? data['callerPhoto'],
        'type': 'incoming_call',
      };
      // Delay to allow app to fully initialize
      Future.delayed(const Duration(seconds: 1), () {
        _incomingCallController.add(normalizedData);
      });
    }
  }

  /// Manually save/refresh FCM token (call after login)
  Future<void> saveToken() async {
    await _saveToken();
  }

  /// Delete FCM token (on logout)
  Future<void> deleteToken() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': FieldValue.delete(),
          'voipToken': FieldValue.delete(),
        });
      } catch (e) {
        debugPrint('Failed to delete tokens: $e');
      }
    }

    await _messaging.deleteToken();
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  /// Dispose the service
  void dispose() {
    _foregroundSubscription?.cancel();
    _openedAppSubscription?.cancel();
    _incomingCallController.close();
  }
}

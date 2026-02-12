import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/call_model.dart';
import 'hms_service.dart';
import 'signaling_service.dart';
import 'webrtc_service.dart';

/// Call Service - Orchestrates video calling functionality using 100ms
class CallService {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

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
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final HmsService _hmsService = HmsService();

  // WebRTC services
  WebRTCService? _webrtcService;
  SignalingService? _signalingService;

  CallModel? _currentCall;
  String? _callerToken;  // 100ms token for caller
  String? _doctorToken;  // 100ms token for doctor
  Timer? _callTimer;
  int _callDuration = 0;
  StreamSubscription<DocumentSnapshot>? _callDocSubscription;

  // Stream controllers
  final _callStateController = StreamController<CallModel?>.broadcast();
  final _callDurationController = StreamController<int>.broadcast();

  // Getters
  Stream<CallModel?> get currentCallStream => _callStateController.stream;
  Stream<int> get callDurationStream => _callDurationController.stream;
  CallModel? get currentCall => _currentCall;
  String? get callerToken => _callerToken;
  String? get doctorToken => _doctorToken;
  bool get isInCall => _currentCall != null && _currentCall!.isActive;
  WebRTCService? get webrtcService => _webrtcService;

  /// Initialize WebRTC and signaling services
  Future<void> _initializeServices() async {
    _webrtcService ??= WebRTCService();
    _signalingService ??= SignalingService();
    await _webrtcService!.initialize();
  }

  /// Get TURN credentials from Cloud Function
  Future<TurnCredentials?> _getTurnCredentials() async {
    try {
      final callable = _functions.httpsCallable('getTurnCredentials');
      final result = await callable.call();
      final data = result.data as Map<String, dynamic>;
      return TurnCredentials(
        urls: List<String>.from(data['urls'] ?? []),
        username: data['username'] as String? ?? '',
        credential: data['credential'] as String? ?? '',
      );
    } catch (e) {
      debugPrint('Failed to get TURN credentials: $e');
      return null;
    }
  }

  /// One-time cleanup of stale ringing calls
  /// Call this once to mark all old "ringing" calls as "missed"
  Future<int> cleanupStaleCalls() async {
    try {
      final cutoffTime = DateTime.now().subtract(const Duration(seconds: 60));
      final staleCallsQuery = await _firestore
          .collection('calls')
          .where('status', isEqualTo: 'ringing')
          .where('startedAt', isLessThan: Timestamp.fromDate(cutoffTime))
          .get();

      int cleanedCount = 0;
      final batch = _firestore.batch();
      
      for (final doc in staleCallsQuery.docs) {
        batch.update(doc.reference, {
          'status': 'missed',
          'endedAt': FieldValue.serverTimestamp(),
        });
        cleanedCount++;
        debugPrint('📞 Marking stale call as missed: ${doc.id}');
      }

      if (cleanedCount > 0) {
        await batch.commit();
        debugPrint('📞 Cleaned up $cleanedCount stale calls');
      } else {
        debugPrint('📞 No stale calls to clean up');
      }

      return cleanedCount;
    } catch (e) {
      debugPrint('📞 Error cleaning up stale calls: $e');
      return 0;
    }
  }

  /// Force reset call state (use if call gets stuck)
  Future<void> forceResetCallState() async {
    debugPrint('📞 Force resetting call state');
    _callTimer?.cancel();
    _callTimer = null;
    _callDocSubscription?.cancel();
    _callDocSubscription = null;
    await _hmsService.leaveRoom();
    _currentCall = null;
    _callerToken = null;
    _doctorToken = null;
    _callDuration = 0;
    _callStateController.add(null);
    _callDurationController.add(0);
    debugPrint('📞 Call state reset complete');
  }

  /// Initiate a call to a doctor
  Future<CallModel?> initiateCall({
    required String doctorId,
    required String doctorName,
    String? doctorPhoto,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Clean up any existing call state first
    if (_currentCall != null) {
      debugPrint('📞 Cleaning up existing call state before new call');
      await _cleanupCall(_currentCall?.id);
    }

    try {
      // Create call record in Firestore
      final callRef = _firestore.collection('calls').doc();
      final callModel = CallModel(
        id: callRef.id,
        callerId: user.uid,
        callerName: user.displayName ?? 'User',
        callerPhoto: user.photoURL,
        doctorId: doctorId,
        doctorName: doctorName,
        doctorPhoto: doctorPhoto,
        status: CallStatus.ringing,
        startedAt: DateTime.now(),
      );

      await callRef.set(callModel.toFirestore());
      _currentCall = callModel;
      _callStateController.add(_currentCall);

      // Create 100ms room and get tokens
      debugPrint('📞 CALLER: Creating 100ms room for call ${callModel.id}');
      final roomData = await _hmsService.createRoom(
        callId: callModel.id,
        callerId: user.uid,
        doctorId: doctorId,
      );

      if (roomData != null) {
        _callerToken = roomData['callerToken'] as String?;
        _doctorToken = roomData['doctorToken'] as String?;
        debugPrint('📞 CALLER: 100ms room created, tokens received');
      } else {
        debugPrint('📞 CALLER: Failed to create 100ms room');
        throw Exception('Failed to create video call room');
      }

      // Send push notification to doctor via Cloud Function
      try {
        debugPrint('📞 CALLER: Sending call notification to doctor $doctorId');
        final callable = _functions.httpsCallable('sendCallNotification');
        final result = await callable.call({
          'callId': callModel.id,
          'doctorId': doctorId,
          'callerName': callModel.callerName,
          'callerPhoto': callModel.callerPhoto ?? '',
        });
        debugPrint('📞 CALLER: Call notification result: ${result.data}');
      } catch (e) {
        debugPrint('📞 CALLER: Failed to send call notification: $e');
        // Continue anyway - doctor might still see the call if app is open
      }

      // Listen for call status changes in Firestore
      _callDocSubscription = _firestore
          .collection('calls')
          .doc(callModel.id)
          .snapshots()
          .listen((snapshot) {
        if (!snapshot.exists) return;

        final data = snapshot.data();
        if (data == null) return;

        final status = data['status'] as String?;
        debugPrint('📞 CALLER: Firestore status changed to: $status');

        if (status != null) {
          _handleCallStatusChange(status);
        }
      });

      return callModel;
    } catch (e) {
      debugPrint('Failed to initiate call: $e');
      await endCall();
      rethrow;
    }
  }

  /// Accept an incoming call
  Future<void> acceptCall(CallModel call) async {
    try {
      await _initializeServices();

      _currentCall = call;
      _callStateController.add(_currentCall);

      // Get TURN credentials
      final turnCredentials = await _getTurnCredentials();

      // Create peer connection
      await _webrtcService!.initPeerConnection(turnCredentials: turnCredentials);

      // Get local media and add to peer connection
      await _webrtcService!.addLocalStream();

      // Set up ICE candidate listener
      _webrtcService!.onIceCandidate.listen((candidate) {
        _signalingService!.writeDoctorIceCandidate(
          callId: call.id,
          candidate: candidate,
        );
      });

      // Get offer directly (already exists when accepting call)
      debugPrint('📞 DOCTOR: Getting offer for call ${call.id}');
      final offer = await _signalingService!.getOffer(call.id);
      if (offer == null) {
        debugPrint('📞 DOCTOR: ERROR - No offer found!');
        throw Exception('No offer found for call');
      }
      debugPrint('📞 DOCTOR: Got offer, setting remote description');

      await _webrtcService!.setRemoteDescription(offer);
      debugPrint('📞 DOCTOR: Remote description set, creating answer');

      // Create and send answer
      final answer = await _webrtcService!.createAnswer();
      debugPrint('📞 DOCTOR: Answer created, writing to Firebase');
      await _signalingService!.writeAnswer(
        callId: call.id,
        answer: answer,
      );
      debugPrint('📞 DOCTOR: Answer written to Firebase');

      // Listen for caller's ICE candidates
      _signalingService!.listenForCallerCandidates(call.id);
      _signalingService!.onIceCandidate.listen((candidate) async {
        await _webrtcService!.addIceCandidate(candidate);
      });

      // Update call status
      debugPrint('📞 DOCTOR: Updating status to answered in RTDB');
      await _signalingService!.updateCallStatus(
        callId: call.id,
        status: 'answered',
      );
      debugPrint('📞 DOCTOR: Status updated in RTDB');

      // Update Firestore
      debugPrint('📞 DOCTOR: Updating Firestore');
      await _firestore.collection('calls').doc(call.id).update({
        'status': 'answered',
        'answeredAt': FieldValue.serverTimestamp(),
      });
      debugPrint('📞 DOCTOR: Firestore updated');

      _currentCall = call.copyWith(
        status: CallStatus.answered,
        answeredAt: DateTime.now(),
      );
      _callStateController.add(_currentCall);
      debugPrint('📞 DOCTOR: Call state emitted, navigating to video call');

      // Listen for connection state
      _webrtcService!.connectionState.listen((state) {
        if (state == WebRTCConnectionState.connected) {
          _startCallTimer();
        }
      });

      // Listen for call status changes
      _signalingService!.listenForCallStatus(call.id);
      _signalingService!.onCallStatusChanged.listen((status) {
        _handleCallStatusChange(status);
      });
    } catch (e) {
      debugPrint('Failed to accept call: $e');
      await endCall();
      rethrow;
    }
  }

  /// Decline an incoming call
  Future<void> declineCall(String callId) async {
    try {
      // Initialize signaling service if needed to update status
      _signalingService ??= SignalingService();

      await _signalingService!.updateCallStatus(
        callId: callId,
        status: 'declined',
      );

      await _firestore.collection('calls').doc(callId).update({
        'status': 'declined',
        'endedAt': FieldValue.serverTimestamp(),
      });

      await _cleanupCall(callId);
    } catch (e) {
      debugPrint('Failed to decline call: $e');
    }
  }

  /// End the current call
  Future<void> endCall() async {
    if (_currentCall == null) return;

    try {
      final callId = _currentCall!.id;

      // Stop timer
      _callTimer?.cancel();
      _callTimer = null;

      debugPrint('📞 Ending call: $callId');

      // Update signaling status first
      await _signalingService?.updateCallStatus(
        callId: callId,
        status: 'ended',
      );
      debugPrint('📞 Signaling status updated to ended');

      // Update Firestore with duration
      await _firestore.collection('calls').doc(callId).update({
        'status': 'ended',
        'endedAt': FieldValue.serverTimestamp(),
        'duration': _callDuration,
      });
      debugPrint('📞 Firestore status updated to ended');

      // Wait a moment to ensure the other party receives the status update
      // before we clean up the signaling room
      await Future.delayed(const Duration(seconds: 1));

      await _cleanupCall(callId);
      debugPrint('📞 Cleanup complete');
    } catch (e) {
      debugPrint('Failed to end call: $e');
      await _cleanupCall(_currentCall?.id);
    }
  }

  /// Handle call status changes from signaling
  void _handleCallStatusChange(String status) {
    debugPrint('📞 _handleCallStatusChange called with status: $status');
    if (_currentCall == null) {
      debugPrint('📞 _currentCall is null, ignoring status change');
      return;
    }

    switch (status) {
      case 'answered':
        debugPrint('📞 CALLER: Call answered! Updating state and emitting to stream');
        _currentCall = _currentCall!.copyWith(
          status: CallStatus.answered,
          answeredAt: DateTime.now(),
        );
        _callStateController.add(_currentCall);
        debugPrint('📞 CALLER: State emitted, UI should navigate to video call');
        break;
      case 'declined':
        debugPrint('📞 Call declined, updating state');
        _currentCall = _currentCall!.copyWith(
          status: CallStatus.declined,
          endedAt: DateTime.now(),
        );
        _callStateController.add(_currentCall);
        Future.delayed(const Duration(milliseconds: 100), () {
          endCall();
        });
        break;
      case 'missed':
        debugPrint('📞 Call missed, updating state');
        _currentCall = _currentCall!.copyWith(
          status: CallStatus.missed,
          endedAt: DateTime.now(),
        );
        _callStateController.add(_currentCall);
        Future.delayed(const Duration(milliseconds: 100), () {
          endCall();
        });
        break;
      case 'ended':
        debugPrint('📞 Call ended, updating state and cleaning up');
        _currentCall = _currentCall!.copyWith(
          status: CallStatus.ended,
          endedAt: DateTime.now(),
        );
        _callStateController.add(_currentCall);
        Future.delayed(const Duration(milliseconds: 100), () {
          endCall();
        });
        break;
    }
  }

  /// Start call timer
  void _startCallTimer() {
    _callDuration = 0;
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _callDuration++;
      _callDurationController.add(_callDuration);
    });
  }

  /// Clean up after call ends
  Future<void> _cleanupCall(String? callId) async {
    // Cancel subscriptions
    _signalingService?.cancelSubscriptions();

    // Clean up signaling data
    if (callId != null) {
      await _signalingService?.cleanupCallRoom(callId);
    }

    // Close WebRTC connection
    await _webrtcService?.close();

    // Reset state
    _currentCall = null;
    _callDuration = 0;
    _callStateController.add(null);
    _callDurationController.add(0);
  }

  /// Get call history for current user
  Stream<List<CallModel>> getCallHistory() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    // Query calls where user is either caller or doctor
    return _firestore
        .collection('calls')
        .where(Filter.or(
          Filter('callerId', isEqualTo: user.uid),
          Filter('doctorId', isEqualTo: user.uid),
        ))
        .orderBy('startedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => CallModel.fromFirestore(doc)).toList();
        });
  }

  /// Get doctor's incoming call stream (for doctors only)
  /// Only returns calls that started within the last 60 seconds to prevent stale calls
  Stream<CallModel?> getIncomingCallStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    // Query only ringing calls for this doctor
    // The timestamp filter is applied in the map to use current time
    return _firestore
        .collection('calls')
        .where('doctorId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'ringing')
        .orderBy('startedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          
          final call = CallModel.fromFirestore(snapshot.docs.first);
          
          // Calculate cutoff time NOW (not when stream was created)
          final cutoffTime = DateTime.now().subtract(const Duration(seconds: 60));
          
          // Check if call is too old
          if (call.startedAt.isBefore(cutoffTime)) {
            debugPrint('📞 Ignoring stale call: ${call.id} (started ${DateTime.now().difference(call.startedAt).inSeconds}s ago)');
            return null;
          }
          
          debugPrint('📞 Valid incoming call: ${call.id} from ${call.callerName}');
          return call;
        });
  }

  /// Get a specific call by ID
  Future<CallModel?> getCallById(String callId) async {
    try {
      final doc = await _firestore.collection('calls').doc(callId).get();
      if (doc.exists) {
        return CallModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting call by ID: $e');
      return null;
    }
  }

  /// Toggle mute
  void toggleMute() {
    _webrtcService?.toggleMute();
  }

  /// Toggle video
  void toggleVideo() {
    _webrtcService?.toggleVideo();
  }

  /// Toggle speaker
  Future<void> toggleSpeaker() async {
    await _webrtcService?.toggleSpeaker();
  }

  /// Switch camera
  Future<void> switchCamera() async {
    await _webrtcService?.switchCamera();
  }

  /// Dispose the service
  void dispose() {
    _callTimer?.cancel();
    _signalingService?.dispose();
    _webrtcService?.dispose();
    _callStateController.close();
    _callDurationController.close();
  }
}

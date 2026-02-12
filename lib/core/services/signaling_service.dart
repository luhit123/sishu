import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/call_model.dart';

/// Signaling Service for WebRTC using Firebase Realtime Database
class SignalingService {
  // Use the correct regional database URL
  final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://sishu-4bbfb-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  StreamSubscription<DatabaseEvent>? _offerSubscription;
  StreamSubscription<DatabaseEvent>? _answerSubscription;
  StreamSubscription<DatabaseEvent>? _callerCandidatesSubscription;
  StreamSubscription<DatabaseEvent>? _doctorCandidatesSubscription;
  StreamSubscription<DatabaseEvent>? _statusSubscription;

  // Stream controllers for signaling events
  final _offerController = StreamController<SessionDescription>.broadcast();
  final _answerController = StreamController<SessionDescription>.broadcast();
  final _iceCandidateController = StreamController<IceCandidate>.broadcast();
  final _callStatusController = StreamController<String>.broadcast();

  // Getters for streams
  Stream<SessionDescription> get onOffer => _offerController.stream;
  Stream<SessionDescription> get onAnswer => _answerController.stream;
  Stream<IceCandidate> get onIceCandidate => _iceCandidateController.stream;
  Stream<String> get onCallStatusChanged => _callStatusController.stream;

  /// Get reference to a call room
  DatabaseReference _getCallRef(String callId) {
    return _database.ref('calls/$callId');
  }

  /// Create a new call room and write the offer
  Future<void> createCallRoom({
    required String callId,
    required SessionDescription offer,
  }) async {
    final callRef = _getCallRef(callId);
    await callRef.child('offer').set(offer.toMap());
    await callRef.child('status').set('ringing');
  }

  /// Write answer to call room
  Future<void> writeAnswer({
    required String callId,
    required SessionDescription answer,
  }) async {
    final callRef = _getCallRef(callId);
    debugPrint('📞 SignalingService: Writing answer to Firebase for $callId');
    await callRef.child('answer').set(answer.toMap());
    debugPrint('📞 SignalingService: Answer written successfully');
  }

  /// Write ICE candidate for caller
  Future<void> writeCallerIceCandidate({
    required String callId,
    required IceCandidate candidate,
  }) async {
    final callRef = _getCallRef(callId);
    await callRef.child('candidates/caller').push().set(candidate.toMap());
  }

  /// Write ICE candidate for doctor
  Future<void> writeDoctorIceCandidate({
    required String callId,
    required IceCandidate candidate,
  }) async {
    final callRef = _getCallRef(callId);
    await callRef.child('candidates/doctor').push().set(candidate.toMap());
  }

  /// Update call status
  Future<void> updateCallStatus({
    required String callId,
    required String status,
  }) async {
    final callRef = _getCallRef(callId);
    debugPrint('📞 SignalingService: Updating status to $status for $callId');
    await callRef.child('status').set(status);
    debugPrint('📞 SignalingService: Status updated successfully');
  }

  /// Listen for offer (doctor side)
  void listenForOffer(String callId) {
    final offerRef = _getCallRef(callId).child('offer');

    _offerSubscription = offerRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        _offerController.add(SessionDescription.fromMap(data));
      }
    });
  }

  /// Listen for answer (caller side)
  void listenForAnswer(String callId) {
    final answerRef = _getCallRef(callId).child('answer');
    debugPrint('📞 SignalingService: Setting up answer listener for $callId');

    _answerSubscription = answerRef.onValue.listen((event) {
      debugPrint('📞 SignalingService: Answer event received, value exists: ${event.snapshot.value != null}');
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        debugPrint('📞 SignalingService: Emitting answer to stream');
        _answerController.add(SessionDescription.fromMap(data));
      }
    });
  }

  /// Listen for caller ICE candidates (doctor side)
  void listenForCallerCandidates(String callId) {
    final candidatesRef = _getCallRef(callId).child('candidates/caller');

    _callerCandidatesSubscription = candidatesRef.onChildAdded.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        _iceCandidateController.add(IceCandidate.fromMap(data));
      }
    });
  }

  /// Listen for doctor ICE candidates (caller side)
  void listenForDoctorCandidates(String callId) {
    final candidatesRef = _getCallRef(callId).child('candidates/doctor');

    _doctorCandidatesSubscription = candidatesRef.onChildAdded.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        _iceCandidateController.add(IceCandidate.fromMap(data));
      }
    });
  }

  /// Listen for call status changes
  void listenForCallStatus(String callId) {
    final statusRef = _getCallRef(callId).child('status');
    debugPrint('📞 SignalingService: Setting up status listener for $callId');

    _statusSubscription = statusRef.onValue.listen((event) {
      debugPrint('📞 SignalingService: Status event received: ${event.snapshot.value}');
      if (event.snapshot.value != null) {
        debugPrint('📞 SignalingService: Emitting status to stream: ${event.snapshot.value}');
        _callStatusController.add(event.snapshot.value as String);
      }
    });
  }

  /// Get current call status
  Future<String?> getCallStatus(String callId) async {
    final snapshot = await _getCallRef(callId).child('status').get();
    return snapshot.value as String?;
  }

  /// Get the offer directly (for accepting calls)
  Future<SessionDescription?> getOffer(String callId) async {
    final snapshot = await _getCallRef(callId).child('offer').get();
    if (snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return SessionDescription.fromMap(data);
    }
    return null;
  }

  /// Check if call room exists
  Future<bool> callRoomExists(String callId) async {
    final snapshot = await _getCallRef(callId).get();
    return snapshot.exists;
  }

  /// Clean up signaling data for a call
  Future<void> cleanupCallRoom(String callId) async {
    try {
      await _getCallRef(callId).remove();
    } catch (e) {
      debugPrint('Error cleaning up call room: $e');
    }
  }

  /// Cancel all subscriptions for a call
  void cancelSubscriptions() {
    _offerSubscription?.cancel();
    _answerSubscription?.cancel();
    _callerCandidatesSubscription?.cancel();
    _doctorCandidatesSubscription?.cancel();
    _statusSubscription?.cancel();

    _offerSubscription = null;
    _answerSubscription = null;
    _callerCandidatesSubscription = null;
    _doctorCandidatesSubscription = null;
    _statusSubscription = null;
  }

  /// Dispose the service
  void dispose() {
    cancelSubscriptions();
    _offerController.close();
    _answerController.close();
    _iceCandidateController.close();
    _callStatusController.close();
  }
}

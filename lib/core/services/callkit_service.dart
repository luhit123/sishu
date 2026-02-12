import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:uuid/uuid.dart';
import '../models/call_model.dart';

/// CallKit actions
enum CallKitAction {
  accept,
  decline,
  end,
  mute,
  unmute,
}

/// CallKit Service for native call UI
class CallKitService {
  static final CallKitService _instance = CallKitService._internal();
  factory CallKitService() => _instance;
  CallKitService._internal();

  final _uuid = const Uuid();
  String? _currentCallId;

  // Stream controllers for call actions
  final _callActionController = StreamController<CallKitAction>.broadcast();
  final _callAcceptedController = StreamController<String>.broadcast();
  final _callDeclinedController = StreamController<String>.broadcast();

  // Getters
  Stream<CallKitAction> get onCallAction => _callActionController.stream;
  Stream<String> get onCallAccepted => _callAcceptedController.stream;
  Stream<String> get onCallDeclined => _callDeclinedController.stream;

  /// Initialize CallKit listeners
  Future<void> initialize() async {
    debugPrint('📞 CallKitService: Initializing...');

    // Listen for CallKit events
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event == null) return;

      debugPrint('📞 CallKitService: Event received: ${event.event}');
      debugPrint('📞 CallKitService: Event body: ${event.body}');

      switch (event.event) {
        case Event.actionCallAccept:
          final callId = event.body['id'] as String?;
          if (callId != null) {
            _callAcceptedController.add(callId);
            _callActionController.add(CallKitAction.accept);
          }
          break;

        case Event.actionCallDecline:
          final callId = event.body['id'] as String?;
          if (callId != null) {
            _callDeclinedController.add(callId);
            _callActionController.add(CallKitAction.decline);
          }
          break;

        case Event.actionCallEnded:
          _callActionController.add(CallKitAction.end);
          break;

        case Event.actionCallToggleMute:
          final isMuted = event.body['isMuted'] as bool? ?? false;
          _callActionController.add(isMuted ? CallKitAction.mute : CallKitAction.unmute);
          break;

        default:
          debugPrint('📞 CallKitService: Unhandled event: ${event.event}');
          break;
      }
    });

    debugPrint('📞 CallKitService: Initialization complete');
  }

  /// Show incoming call UI
  Future<void> showIncomingCall({
    required String callId,
    required String callerName,
    String? callerPhoto,
    bool hasVideo = true,
  }) async {
    debugPrint('📞 CallKitService: showIncomingCall called');
    debugPrint('📞 CallKitService: callId=$callId, callerName=$callerName, hasVideo=$hasVideo');
    _currentCallId = callId;

    final params = CallKitParams(
      id: callId,
      nameCaller: callerName,
      avatar: callerPhoto,
      handle: 'Incoming Video Consultation',
      type: hasVideo ? 1 : 0, // 1 = video, 0 = audio
      textAccept: 'Accept',
      textDecline: 'Decline',
      duration: 60000, // 60 seconds ring timeout
      extra: <String, dynamic>{
        'callId': callId,
      },
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#4CAF50',
        backgroundUrl: null,
        actionColor: '#4CAF50',
        incomingCallNotificationChannelName: 'Incoming Calls',
        missedCallNotificationChannelName: 'Missed Calls',
      ),
      ios: IOSParams(
        iconName: 'CallKitIcon',
        handleType: 'generic',
        supportsVideo: hasVideo,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: false,
        supportsHolding: false,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: null,
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
    debugPrint('📞 CallKitService: showCallkitIncoming completed');
  }

  /// Show outgoing call UI
  Future<void> showOutgoingCall({
    required String callId,
    required String calleeName,
    String? calleePhoto,
    bool hasVideo = true,
  }) async {
    _currentCallId = callId;

    final params = CallKitParams(
      id: callId,
      nameCaller: calleeName,
      avatar: calleePhoto,
      handle: 'Video Consultation',
      type: hasVideo ? 1 : 0,
      extra: <String, dynamic>{
        'callId': callId,
      },
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        backgroundColor: '#4CAF50',
        actionColor: '#4CAF50',
      ),
      ios: IOSParams(
        iconName: 'CallKitIcon',
        handleType: 'generic',
        supportsVideo: hasVideo,
      ),
    );

    await FlutterCallkitIncoming.startCall(params);
  }

  /// Update call state to connected
  Future<void> setCallConnected() async {
    if (_currentCallId != null) {
      await FlutterCallkitIncoming.setCallConnected(_currentCallId!);
    }
  }

  /// End the current call
  Future<void> endCall() async {
    if (_currentCallId != null) {
      await FlutterCallkitIncoming.endCall(_currentCallId!);
      _currentCallId = null;
    }
  }

  /// End all calls
  Future<void> endAllCalls() async {
    await FlutterCallkitIncoming.endAllCalls();
    _currentCallId = null;
  }

  /// Get active calls
  Future<List<dynamic>> getActiveCalls() async {
    return await FlutterCallkitIncoming.activeCalls();
  }

  /// Check if there's an active call
  Future<bool> hasActiveCall() async {
    final calls = await getActiveCalls();
    return calls.isNotEmpty;
  }

  /// Generate a unique call UUID
  String generateCallId() {
    return _uuid.v4();
  }

  /// Dispose the service
  void dispose() {
    _callActionController.close();
    _callAcceptedController.close();
    _callDeclinedController.close();
  }
}

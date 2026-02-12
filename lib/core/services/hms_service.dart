import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hmssdk_flutter/hmssdk_flutter.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// 100ms Video Call Service
/// Handles video calling using 100ms SDK for fast, reliable connections
class HmsService implements HMSUpdateListener, HMSActionResultListener {
  static final HmsService _instance = HmsService._internal();
  factory HmsService() => _instance;
  HmsService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  HMSSDK? _hmsSdk;
  bool _isInitialized = false;
  bool _isJoined = false;

  // Local and remote tracks
  HMSVideoTrack? _localVideoTrack;
  HMSAudioTrack? _localAudioTrack;
  HMSVideoTrack? _remoteVideoTrack;
  HMSAudioTrack? _remoteAudioTrack;
  HMSPeer? _localPeer;
  HMSPeer? _remotePeer;

  // Stream controllers for UI updates
  final _localVideoController = StreamController<HMSVideoTrack?>.broadcast();
  final _remoteVideoController = StreamController<HMSVideoTrack?>.broadcast();
  final _connectionStateController = StreamController<HmsConnectionState>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  // Getters for streams
  Stream<HMSVideoTrack?> get localVideoStream => _localVideoController.stream;
  Stream<HMSVideoTrack?> get remoteVideoStream => _remoteVideoController.stream;
  Stream<HmsConnectionState> get connectionState => _connectionStateController.stream;
  Stream<String> get errors => _errorController.stream;

  // Getters for current state
  HMSVideoTrack? get localVideoTrack => _localVideoTrack;
  HMSVideoTrack? get remoteVideoTrack => _remoteVideoTrack;
  bool get isJoined => _isJoined;
  bool get isMuted => _localAudioTrack?.isMute ?? false;
  bool get isVideoOff => _localVideoTrack?.isMute ?? false;

  /// Initialize the 100ms SDK
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('📞 HmsService: Already initialized');
      return;
    }

    debugPrint('📞 HmsService: Initializing...');

    _hmsSdk = HMSSDK();
    await _hmsSdk!.build();
    _hmsSdk!.addUpdateListener(listener: this);

    _isInitialized = true;
    debugPrint('📞 HmsService: Initialized successfully');
  }

  /// Get auth token from Cloud Function
  Future<String?> _getAuthToken({
    required String roomId,
    required String role,
    required String userId,
  }) async {
    try {
      debugPrint('📞 HmsService: Getting auth token for room $roomId');
      final callable = _functions.httpsCallable('getHmsToken');
      final result = await callable.call({
        'roomId': roomId,
        'role': role,
        'userId': userId,
      });
      return result.data['token'] as String?;
    } catch (e) {
      debugPrint('📞 HmsService: Failed to get auth token: $e');
      return null;
    }
  }

  /// Create room and get tokens from Cloud Function
  Future<Map<String, dynamic>?> createRoom({
    required String callId,
    required String callerId,
    required String doctorId,
  }) async {
    try {
      debugPrint('📞 HmsService: Creating room for call $callId');
      final callable = _functions.httpsCallable('createHmsRoom');
      final result = await callable.call({
        'callId': callId,
        'callerId': callerId,
        'doctorId': doctorId,
      });
      debugPrint('📞 HmsService: Room created successfully');
      return result.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('📞 HmsService: Failed to create room: $e');
      return null;
    }
  }

  /// Join a room with auth token
  Future<bool> joinRoom({
    required String authToken,
    required String userName,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    debugPrint('📞 HmsService: Joining room as $userName');
    _connectionStateController.add(HmsConnectionState.connecting);

    final config = HMSConfig(
      authToken: authToken,
      userName: userName,
    );

    await _hmsSdk!.join(config: config);
    return true;
  }

  /// Leave the current room
  Future<void> leaveRoom() async {
    debugPrint('📞 HmsService: Leaving room');

    if (_isJoined) {
      await _hmsSdk?.leave();
    }

    _cleanup();
  }

  /// Toggle local audio mute
  Future<void> toggleMute() async {
    if (_localAudioTrack != null) {
      await _hmsSdk?.toggleMicMuteState();
      debugPrint('📞 HmsService: Toggled mute');
    }
  }

  /// Toggle local video
  Future<void> toggleVideo() async {
    if (_localVideoTrack != null) {
      await _hmsSdk?.toggleCameraMuteState();
      debugPrint('📞 HmsService: Toggled video');
    }
  }

  /// Switch camera (front/back)
  Future<void> switchCamera() async {
    await _hmsSdk?.switchCamera();
    debugPrint('📞 HmsService: Switched camera');
  }

  /// Clean up resources
  void _cleanup() {
    _localVideoTrack = null;
    _localAudioTrack = null;
    _remoteVideoTrack = null;
    _remoteAudioTrack = null;
    _localPeer = null;
    _remotePeer = null;
    _isJoined = false;

    _localVideoController.add(null);
    _remoteVideoController.add(null);
    _connectionStateController.add(HmsConnectionState.disconnected);
  }

  /// Dispose the service
  Future<void> dispose() async {
    debugPrint('📞 HmsService: Disposing...');

    if (_isJoined) {
      await leaveRoom();
    }

    _hmsSdk?.removeUpdateListener(listener: this);
    _hmsSdk?.destroy();
    _hmsSdk = null;
    _isInitialized = false;

    await _localVideoController.close();
    await _remoteVideoController.close();
    await _connectionStateController.close();
    await _errorController.close();

    debugPrint('📞 HmsService: Disposed');
  }

  // ============ HMSUpdateListener Implementation ============

  @override
  void onJoin({required HMSRoom room}) {
    debugPrint('📞 HmsService: Joined room ${room.id}');
    _isJoined = true;
    _connectionStateController.add(HmsConnectionState.connected);
  }

  @override
  void onRoomUpdate({required HMSRoom room, required HMSRoomUpdate update}) {
    debugPrint('📞 HmsService: Room update: $update');
  }

  @override
  void onPeerUpdate({required HMSPeer peer, required HMSPeerUpdate update}) {
    debugPrint('📞 HmsService: Peer update: ${peer.name} - $update');

    if (peer.isLocal) {
      _localPeer = peer;
    } else {
      if (update == HMSPeerUpdate.peerJoined) {
        _remotePeer = peer;
        debugPrint('📞 HmsService: Remote peer joined: ${peer.name}');
      } else if (update == HMSPeerUpdate.peerLeft) {
        _remotePeer = null;
        _remoteVideoTrack = null;
        _remoteAudioTrack = null;
        _remoteVideoController.add(null);
        debugPrint('📞 HmsService: Remote peer left');
      }
    }
  }

  @override
  void onTrackUpdate({
    required HMSTrack track,
    required HMSTrackUpdate trackUpdate,
    required HMSPeer peer,
  }) {
    debugPrint('📞 HmsService: Track update: ${track.kind} from ${peer.name} - $trackUpdate');

    if (peer.isLocal) {
      // Local tracks
      if (track.kind == HMSTrackKind.kHMSTrackKindVideo) {
        _localVideoTrack = track as HMSVideoTrack;
        _localVideoController.add(_localVideoTrack);
      } else if (track.kind == HMSTrackKind.kHMSTrackKindAudio) {
        _localAudioTrack = track as HMSAudioTrack;
      }
    } else {
      // Remote tracks
      if (track.kind == HMSTrackKind.kHMSTrackKindVideo) {
        if (trackUpdate == HMSTrackUpdate.trackAdded) {
          _remoteVideoTrack = track as HMSVideoTrack;
          _remoteVideoController.add(_remoteVideoTrack);
          debugPrint('📞 HmsService: Remote video track added');
        } else if (trackUpdate == HMSTrackUpdate.trackRemoved) {
          _remoteVideoTrack = null;
          _remoteVideoController.add(null);
          debugPrint('📞 HmsService: Remote video track removed');
        }
      } else if (track.kind == HMSTrackKind.kHMSTrackKindAudio) {
        if (trackUpdate == HMSTrackUpdate.trackAdded) {
          _remoteAudioTrack = track as HMSAudioTrack;
        } else if (trackUpdate == HMSTrackUpdate.trackRemoved) {
          _remoteAudioTrack = null;
        }
      }
    }
  }

  @override
  void onHMSError({required HMSException error}) {
    debugPrint('📞 HmsService: Error: ${error.message}');
    _errorController.add(error.message ?? 'Unknown error');
    _connectionStateController.add(HmsConnectionState.failed);
  }

  @override
  void onMessage({required HMSMessage message}) {
    debugPrint('📞 HmsService: Message: ${message.message}');
  }

  @override
  void onRoleChangeRequest({required HMSRoleChangeRequest roleChangeRequest}) {
    debugPrint('📞 HmsService: Role change request');
  }

  @override
  void onUpdateSpeakers({required List<HMSSpeaker> updateSpeakers}) {
    // Speaker updates
  }

  @override
  void onReconnecting() {
    debugPrint('📞 HmsService: Reconnecting...');
    _connectionStateController.add(HmsConnectionState.reconnecting);
  }

  @override
  void onReconnected() {
    debugPrint('📞 HmsService: Reconnected');
    _connectionStateController.add(HmsConnectionState.connected);
  }

  @override
  void onChangeTrackStateRequest({
    required HMSTrackChangeRequest hmsTrackChangeRequest,
  }) {
    debugPrint('📞 HmsService: Track change request');
  }

  @override
  void onRemovedFromRoom({
    required HMSPeerRemovedFromPeer hmsPeerRemovedFromPeer,
  }) {
    debugPrint('📞 HmsService: Removed from room');
    _cleanup();
  }

  @override
  void onAudioDeviceChanged({
    HMSAudioDevice? currentAudioDevice,
    List<HMSAudioDevice>? availableAudioDevice,
  }) {
    debugPrint('📞 HmsService: Audio device changed');
  }

  @override
  void onSessionStoreAvailable({HMSSessionStore? hmsSessionStore}) {
    debugPrint('📞 HmsService: Session store available');
  }

  @override
  void onPeerListUpdate({
    required List<HMSPeer> addedPeers,
    required List<HMSPeer> removedPeers,
  }) {
    debugPrint('📞 HmsService: Peer list update - added: ${addedPeers.length}, removed: ${removedPeers.length}');
  }

  // ============ HMSActionResultListener Implementation ============

  @override
  void onSuccess({
    HMSActionResultListenerMethod methodType = HMSActionResultListenerMethod.unknown,
    Map<String, dynamic>? arguments,
  }) {
    debugPrint('📞 HmsService: Action success: $methodType');
  }

  @override
  void onException({
    HMSActionResultListenerMethod methodType = HMSActionResultListenerMethod.unknown,
    Map<String, dynamic>? arguments,
    required HMSException hmsException,
  }) {
    debugPrint('📞 HmsService: Action exception: $methodType - ${hmsException.message}');
  }
}

/// Connection state for HMS
enum HmsConnectionState {
  idle,
  connecting,
  connected,
  reconnecting,
  disconnected,
  failed,
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../models/call_model.dart';

/// Connection state for WebRTC
enum WebRTCConnectionState {
  idle,
  connecting,
  connected,
  reconnecting,
  disconnected,
  failed,
}

/// WebRTC Service for managing peer connections (Singleton)
class WebRTCService {
  // Singleton pattern
  static final WebRTCService _instance = WebRTCService._internal();
  factory WebRTCService() => _instance;
  WebRTCService._internal();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  // Renderers for video display
  RTCVideoRenderer? _localRenderer;
  RTCVideoRenderer? _remoteRenderer;
  bool _renderersInitialized = false;

  RTCVideoRenderer get localRenderer => _localRenderer!;
  RTCVideoRenderer get remoteRenderer => _remoteRenderer!;

  // Stream controllers for events
  StreamController<WebRTCConnectionState>? _connectionStateController;
  StreamController<MediaStream?>? _localStreamController;
  StreamController<MediaStream?>? _remoteStreamController;
  StreamController<IceCandidate>? _iceCandidateController;

  // Getters for streams
  Stream<WebRTCConnectionState> get connectionState => _connectionStateController!.stream;
  Stream<MediaStream?> get localStream => _localStreamController!.stream;
  Stream<MediaStream?> get remoteStream => _remoteStreamController!.stream;
  Stream<IceCandidate> get onIceCandidate => _iceCandidateController!.stream;

  // Current state
  WebRTCConnectionState _currentState = WebRTCConnectionState.idle;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isSpeakerOn = true;
  bool _isFrontCamera = true;

  // Getters for state
  bool get isMuted => _isMuted;
  bool get isVideoEnabled => _isVideoEnabled;
  bool get isSpeakerOn => _isSpeakerOn;
  bool get isFrontCamera => _isFrontCamera;
  MediaStream? get currentLocalStream => _localStream;
  MediaStream? get currentRemoteStream => _remoteStream;

  /// Initialize the WebRTC service
  Future<void> initialize() async {
    debugPrint('📞 WebRTCService: Initializing...');

    // Create stream controllers if needed
    _connectionStateController ??= StreamController<WebRTCConnectionState>.broadcast();
    _localStreamController ??= StreamController<MediaStream?>.broadcast();
    _remoteStreamController ??= StreamController<MediaStream?>.broadcast();
    _iceCandidateController ??= StreamController<IceCandidate>.broadcast();

    // Initialize renderers if not already done
    if (!_renderersInitialized) {
      debugPrint('📞 WebRTCService: Creating new renderers');
      _localRenderer = RTCVideoRenderer();
      _remoteRenderer = RTCVideoRenderer();
      await _localRenderer!.initialize();
      await _remoteRenderer!.initialize();
      _renderersInitialized = true;
      debugPrint('📞 WebRTCService: Renderers initialized');
    } else {
      debugPrint('📞 WebRTCService: Reusing existing renderers');
    }
  }

  /// Get ICE server configuration with TURN credentials
  /// Optimized for Indian networks (Jio, Airtel) with CGNAT
  Map<String, dynamic> _getIceServerConfig(TurnCredentials? turnCredentials) {
    final iceServers = <Map<String, dynamic>>[];

    // Add TURN servers FIRST (prioritize relay for faster connection on CGNAT networks)
    if (turnCredentials != null && turnCredentials.urls.isNotEmpty) {
      debugPrint('📞 WebRTCService: Adding TURN servers (prioritized)');

      // Only add the most reliable TURN URLs to speed up connection
      final priorityUrls = turnCredentials.urls.where((url) =>
        url.contains('turn:') || url.contains('turns:')
      ).take(3).toList(); // Limit to 3 TURN servers

      for (final url in priorityUrls) {
        debugPrint('📞 WebRTCService: Adding TURN URL: $url');
        iceServers.add({
          'urls': url,
          'username': turnCredentials.username,
          'credential': turnCredentials.credential,
        });
      }
    }

    // Add ONE STUN server as fallback (for direct P2P when possible)
    iceServers.add({'urls': 'stun:stun.l.google.com:19302'});

    if (iceServers.length == 1) {
      debugPrint('📞 WebRTCService: WARNING - No TURN credentials, using STUN only');
    }

    debugPrint('📞 WebRTCService: Total ICE servers configured: ${iceServers.length}');

    return {
      'iceServers': iceServers,
      'sdpSemantics': 'unified-plan',
      'iceCandidatePoolSize': 10, // Pre-fetch candidates for faster connection
    };
  }

  /// Create peer connection
  Future<void> initPeerConnection({TurnCredentials? turnCredentials}) async {
    _updateState(WebRTCConnectionState.connecting);

    final config = _getIceServerConfig(turnCredentials);

    _peerConnection = await createPeerConnection(config);

    // Set up event listeners
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null && _iceCandidateController != null && !_iceCandidateController!.isClosed) {
        _iceCandidateController!.add(IceCandidate(
          candidate: candidate.candidate!,
          sdpMid: candidate.sdpMid,
          sdpMLineIndex: candidate.sdpMLineIndex,
        ));
      }
    };

    _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
      debugPrint('ICE Connection State: $state');
      switch (state) {
        case RTCIceConnectionState.RTCIceConnectionStateConnected:
        case RTCIceConnectionState.RTCIceConnectionStateCompleted:
          _updateState(WebRTCConnectionState.connected);
          break;
        case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
          _updateState(WebRTCConnectionState.reconnecting);
          break;
        case RTCIceConnectionState.RTCIceConnectionStateFailed:
          _updateState(WebRTCConnectionState.failed);
          break;
        case RTCIceConnectionState.RTCIceConnectionStateClosed:
          _updateState(WebRTCConnectionState.disconnected);
          break;
        default:
          break;
      }
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        if (_renderersInitialized) {
          _remoteRenderer?.srcObject = _remoteStream;
        }
        if (_remoteStreamController != null && !_remoteStreamController!.isClosed) {
          _remoteStreamController!.add(_remoteStream);
        }
      }
    };

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      debugPrint('Peer Connection State: $state');
    };
  }

  /// Get local media stream (camera + microphone)
  Future<MediaStream> getUserMedia() async {
    final constraints = {
      'audio': true,
      'video': {
        'facingMode': _isFrontCamera ? 'user' : 'environment',
        'width': {'ideal': 1280},
        'height': {'ideal': 720},
      },
    };

    _localStream = await navigator.mediaDevices.getUserMedia(constraints);
    if (_renderersInitialized) {
      _localRenderer?.srcObject = _localStream;
    }
    if (_localStreamController != null && !_localStreamController!.isClosed) {
      _localStreamController!.add(_localStream);
    }

    return _localStream!;
  }

  /// Add local stream to peer connection
  Future<void> addLocalStream() async {
    if (_localStream == null) {
      await getUserMedia();
    }

    for (final track in _localStream!.getTracks()) {
      await _peerConnection?.addTrack(track, _localStream!);
    }
  }

  /// Create offer (caller side)
  Future<SessionDescription> createOffer() async {
    final description = await _peerConnection!.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': true,
    });

    await _peerConnection!.setLocalDescription(description);

    return SessionDescription(
      type: description.type!,
      sdp: description.sdp!,
    );
  }

  /// Create answer (callee side)
  Future<SessionDescription> createAnswer() async {
    final description = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(description);

    return SessionDescription(
      type: description.type!,
      sdp: description.sdp!,
    );
  }

  /// Set remote description
  Future<void> setRemoteDescription(SessionDescription description) async {
    final rtcDescription = RTCSessionDescription(
      description.sdp,
      description.type,
    );
    await _peerConnection?.setRemoteDescription(rtcDescription);
  }

  /// Add ICE candidate
  Future<void> addIceCandidate(IceCandidate candidate) async {
    final rtcCandidate = RTCIceCandidate(
      candidate.candidate,
      candidate.sdpMid,
      candidate.sdpMLineIndex,
    );
    await _peerConnection?.addCandidate(rtcCandidate);
  }

  /// Toggle mute
  void toggleMute() {
    _isMuted = !_isMuted;
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !_isMuted;
    });
  }

  /// Toggle video
  void toggleVideo() {
    _isVideoEnabled = !_isVideoEnabled;
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = _isVideoEnabled;
    });
  }

  /// Toggle speaker
  Future<void> toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    await Helper.setSpeakerphoneOn(_isSpeakerOn);
  }

  /// Switch camera
  Future<void> switchCamera() async {
    if (_localStream != null) {
      final videoTrack = _localStream!.getVideoTracks().first;
      await Helper.switchCamera(videoTrack);
      _isFrontCamera = !_isFrontCamera;
    }
  }

  /// Restart ICE (for network changes)
  Future<void> restartIce() async {
    try {
      await _peerConnection?.restartIce();
    } catch (e) {
      debugPrint('ICE restart failed: $e');
    }
  }

  /// Update connection state
  void _updateState(WebRTCConnectionState state) {
    _currentState = state;
    if (_connectionStateController != null && !_connectionStateController!.isClosed) {
      _connectionStateController!.add(state);
    }
  }

  /// Close all connections and clean up (keeps renderers for reuse)
  Future<void> close() async {
    debugPrint('📞 WebRTCService: Closing connection...');

    // Stop all tracks
    _localStream?.getTracks().forEach((track) {
      track.stop();
    });
    _remoteStream?.getTracks().forEach((track) {
      track.stop();
    });

    // Dispose streams
    await _localStream?.dispose();
    await _remoteStream?.dispose();

    // Close peer connection
    await _peerConnection?.close();

    // Clear renderer sources (but don't dispose renderers)
    if (_renderersInitialized) {
      _localRenderer?.srcObject = null;
      _remoteRenderer?.srcObject = null;
    }

    // Reset state
    _localStream = null;
    _remoteStream = null;
    _peerConnection = null;
    _isMuted = false;
    _isVideoEnabled = true;
    _isSpeakerOn = true;
    _isFrontCamera = true;

    _updateState(WebRTCConnectionState.idle);
    debugPrint('📞 WebRTCService: Connection closed');
  }

  /// Full dispose - only call when app is shutting down
  Future<void> dispose() async {
    debugPrint('📞 WebRTCService: Full dispose...');
    await close();

    // Dispose renderers
    if (_renderersInitialized) {
      await _localRenderer?.dispose();
      await _remoteRenderer?.dispose();
      _localRenderer = null;
      _remoteRenderer = null;
      _renderersInitialized = false;
    }

    // Close stream controllers
    await _connectionStateController?.close();
    await _localStreamController?.close();
    await _remoteStreamController?.close();
    await _iceCandidateController?.close();
    _connectionStateController = null;
    _localStreamController = null;
    _remoteStreamController = null;
    _iceCandidateController = null;

    debugPrint('📞 WebRTCService: Fully disposed');
  }
}

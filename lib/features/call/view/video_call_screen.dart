import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/call_model.dart';
import '../../../core/services/call_service.dart';
import '../../../core/services/webrtc_service.dart';
import '../widgets/call_controls.dart';
import 'call_end_screen.dart';

/// Video Call Screen - Active video call UI
class VideoCallScreen extends StatefulWidget {
  final CallModel call;

  const VideoCallScreen({
    super.key,
    required this.call,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final CallService _callService = CallService();
  WebRTCService? _webrtcService;

  bool _showControls = true;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isSpeakerOn = true;
  int _callDuration = 0;
  bool _hasNavigated = false;

  Timer? _hideControlsTimer;
  StreamSubscription<int>? _durationSubscription;
  StreamSubscription<WebRTCConnectionState>? _connectionSubscription;
  StreamSubscription<CallModel?>? _callSubscription;

  WebRTCConnectionState _connectionState = WebRTCConnectionState.connecting;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _webrtcService = _callService.webrtcService;

    // Listen for call duration updates
    _durationSubscription = _callService.callDurationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _callDuration = duration;
        });
      }
    });

    // Listen for connection state changes
    if (_webrtcService != null) {
      _connectionSubscription = _webrtcService!.connectionState.listen((state) {
        if (mounted) {
          setState(() {
            _connectionState = state;
          });
          // If connection is closed or failed, end the call
          if (state == WebRTCConnectionState.disconnected ||
              state == WebRTCConnectionState.failed) {
            debugPrint('📞 VideoCall: Connection state changed to $state, ending call');
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted && (_connectionState == WebRTCConnectionState.disconnected ||
                  _connectionState == WebRTCConnectionState.failed)) {
                _handleCallEnded();
              }
            });
          }
        }
      });
    }

    // Listen for call end
    _callSubscription = _callService.currentCallStream.listen((call) {
      debugPrint('📞 VideoCall: Call stream update - call: ${call?.id}, status: ${call?.status}, hasEnded: ${call?.hasEnded}');
      if (call == null || call.hasEnded) {
        debugPrint('📞 VideoCall: Call ended detected via stream');
        _handleCallEnded();
      }
    });

    _startHideControlsTimer();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _durationSubscription?.cancel();
    _connectionSubscription?.cancel();
    _callSubscription?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideControlsTimer();
    }
  }

  void _toggleMute() {
    _callService.toggleMute();
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  void _toggleVideo() {
    _callService.toggleVideo();
    setState(() {
      _isVideoEnabled = !_isVideoEnabled;
    });
  }

  void _toggleSpeaker() async {
    await _callService.toggleSpeaker();
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
  }

  void _switchCamera() async {
    await _callService.switchCamera();
  }

  void _endCall() {
    _callService.endCall();
  }

  void _handleCallEnded() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    
    debugPrint('📞 VideoCall: Call ended, navigating to end screen');
    
    // Navigate to call end screen with completed status
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => CallEndScreen(
          call: widget.call,
          endType: CallEndType.completed,
          callDuration: _callDuration,
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String get _connectionStatusText {
    switch (_connectionState) {
      case WebRTCConnectionState.connecting:
        return 'Connecting...';
      case WebRTCConnectionState.reconnecting:
        return 'Reconnecting...';
      case WebRTCConnectionState.failed:
        return 'Connection failed';
      case WebRTCConnectionState.disconnected:
        return 'Disconnected';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Remote Video (Full Screen)
            _buildRemoteVideo(),

            // Local Video (Picture-in-Picture)
            _buildLocalVideo(),

            // Connection Status Overlay
            if (_connectionState != WebRTCConnectionState.connected)
              _buildConnectionOverlay(),

            // Controls Overlay
            if (_showControls) _buildControlsOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildRemoteVideo() {
    if (_webrtcService == null) {
      return Container(color: Colors.black);
    }

    return Positioned.fill(
      child: RTCVideoView(
        _webrtcService!.remoteRenderer,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
      ),
    );
  }

  Widget _buildLocalVideo() {
    if (_webrtcService == null || !_isVideoEnabled) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      right: 20,
      child: GestureDetector(
        onTap: _switchCamera,
        child: Container(
          width: 120,
          height: 160,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: RTCVideoView(
              _webrtcService!.localRenderer,
              mirror: true,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_connectionState == WebRTCConnectionState.connecting ||
                  _connectionState == WebRTCConnectionState.reconnecting)
                const CircularProgressIndicator(
                  color: Colors.white,
                ),
              if (_connectionState == WebRTCConnectionState.failed)
                const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 48,
                ),
              const SizedBox(height: 16),
              Text(
                _connectionStatusText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.5),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withValues(alpha: 0.7),
            ],
            stops: const [0.0, 0.2, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    // Back Button
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        // Minimize to PiP (if supported) or just hide controls
                        _toggleControls();
                      },
                    ),

                    const Spacer(),

                    // Call Info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          widget.call.getOtherPartyName(
                            _callService.currentCall?.callerId ?? '',
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDuration(_callDuration),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Switch Camera Button
                    IconButton(
                      icon: const Icon(
                        Icons.cameraswitch_rounded,
                        color: Colors.white,
                      ),
                      onPressed: _switchCamera,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Bottom Controls
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: CallControls(
                  isMuted: _isMuted,
                  isVideoEnabled: _isVideoEnabled,
                  isSpeakerOn: _isSpeakerOn,
                  onToggleMute: _toggleMute,
                  onToggleVideo: _toggleVideo,
                  onToggleSpeaker: _toggleSpeaker,
                  onEndCall: _endCall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

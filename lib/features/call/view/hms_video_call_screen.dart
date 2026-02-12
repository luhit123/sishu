import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hmssdk_flutter/hmssdk_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/call_model.dart';
import '../../../core/services/hms_service.dart';
import '../widgets/call_controls.dart';
import 'call_end_screen.dart';

/// HMS Video Call Screen - Active video call UI using 100ms SDK
class HmsVideoCallScreen extends StatefulWidget {
  final CallModel call;
  final String authToken;
  final bool isCaller;

  const HmsVideoCallScreen({
    super.key,
    required this.call,
    required this.authToken,
    required this.isCaller,
  });

  @override
  State<HmsVideoCallScreen> createState() => _HmsVideoCallScreenState();
}

class _HmsVideoCallScreenState extends State<HmsVideoCallScreen> {
  final HmsService _hmsService = HmsService();

  bool _showControls = true;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  int _callDuration = 0;
  bool _hasNavigated = false;

  Timer? _hideControlsTimer;
  Timer? _durationTimer;
  StreamSubscription<HmsConnectionState>? _connectionSubscription;
  StreamSubscription<HMSVideoTrack?>? _localVideoSubscription;
  StreamSubscription<HMSVideoTrack?>? _remoteVideoSubscription;
  StreamSubscription<String>? _errorSubscription;

  HmsConnectionState _connectionState = HmsConnectionState.connecting;
  HMSVideoTrack? _localVideoTrack;
  HMSVideoTrack? _remoteVideoTrack;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _initializeCall();
    _startHideControlsTimer();
  }

  Future<void> _initializeCall() async {
    debugPrint('📞 HmsVideoCall: Initializing...');

    // Subscribe to service streams
    _connectionSubscription = _hmsService.connectionState.listen((state) {
      if (mounted) {
        setState(() {
          _connectionState = state;
        });

        if (state == HmsConnectionState.connected) {
          _startDurationTimer();
        } else if (state == HmsConnectionState.disconnected ||
            state == HmsConnectionState.failed) {
          debugPrint('📞 HmsVideoCall: Connection state: $state, ending call');
          Future.delayed(const Duration(seconds: 2), _handleCallEnded);
        }
      }
    });

    _localVideoSubscription = _hmsService.localVideoStream.listen((track) {
      if (mounted) {
        setState(() {
          _localVideoTrack = track;
        });
      }
    });

    _remoteVideoSubscription = _hmsService.remoteVideoStream.listen((track) {
      if (mounted) {
        setState(() {
          _remoteVideoTrack = track;
        });
        if (track != null) {
          debugPrint('📞 HmsVideoCall: Remote video received');
        }
      }
    });

    _errorSubscription = _hmsService.errors.listen((error) {
      debugPrint('📞 HmsVideoCall: Error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    // Join the room
    final userName = widget.isCaller ? widget.call.callerName : widget.call.doctorName;
    await _hmsService.joinRoom(
      authToken: widget.authToken,
      userName: userName,
    );
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDuration++;
        });
      }
    });
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _durationTimer?.cancel();
    _connectionSubscription?.cancel();
    _localVideoSubscription?.cancel();
    _remoteVideoSubscription?.cancel();
    _errorSubscription?.cancel();
    _hmsService.leaveRoom();
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
    _hmsService.toggleMute();
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  void _toggleVideo() {
    _hmsService.toggleVideo();
    setState(() {
      _isVideoEnabled = !_isVideoEnabled;
    });
  }

  void _switchCamera() {
    _hmsService.switchCamera();
  }

  void _endCall() {
    _hmsService.leaveRoom();
    _handleCallEnded();
  }

  void _handleCallEnded() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    debugPrint('📞 HmsVideoCall: Call ended, navigating to end screen');

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
      case HmsConnectionState.connecting:
        return 'Connecting...';
      case HmsConnectionState.reconnecting:
        return 'Reconnecting...';
      case HmsConnectionState.failed:
        return 'Connection failed';
      case HmsConnectionState.disconnected:
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
            if (_connectionState != HmsConnectionState.connected)
              _buildConnectionOverlay(),

            // Controls Overlay
            if (_showControls) _buildControlsOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildRemoteVideo() {
    if (_remoteVideoTrack == null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                child: Text(
                  widget.isCaller
                      ? (widget.call.doctorName.isNotEmpty
                          ? widget.call.doctorName[0].toUpperCase()
                          : 'D')
                      : (widget.call.callerName.isNotEmpty
                          ? widget.call.callerName[0].toUpperCase()
                          : 'U'),
                  style: const TextStyle(
                    fontSize: 40,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.isCaller ? widget.call.doctorName : widget.call.callerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_connectionState == HmsConnectionState.connected)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Waiting for video...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Positioned.fill(
      child: HMSVideoView(
        track: _remoteVideoTrack!,
        scaleType: ScaleType.SCALE_ASPECT_FILL,
      ),
    );
  }

  Widget _buildLocalVideo() {
    if (_localVideoTrack == null || !_isVideoEnabled) {
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
            child: HMSVideoView(
              track: _localVideoTrack!,
              scaleType: ScaleType.SCALE_ASPECT_FILL,
              setMirror: true,
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
              if (_connectionState == HmsConnectionState.connecting ||
                  _connectionState == HmsConnectionState.reconnecting)
                const CircularProgressIndicator(
                  color: Colors.white,
                ),
              if (_connectionState == HmsConnectionState.failed)
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
                      onPressed: _toggleControls,
                    ),

                    const Spacer(),

                    // Call Info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          widget.isCaller
                              ? widget.call.doctorName
                              : widget.call.callerName,
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
                  isSpeakerOn: true, // 100ms handles speaker automatically
                  onToggleMute: _toggleMute,
                  onToggleVideo: _toggleVideo,
                  onToggleSpeaker: () {}, // 100ms handles speaker automatically
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

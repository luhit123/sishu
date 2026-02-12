import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/call_model.dart';
import '../../../core/services/call_service.dart';
import 'video_call_screen.dart';
import 'call_end_screen.dart';

/// Outgoing Call Screen - Shows calling animation while waiting for doctor to answer
class OutgoingCallScreen extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final String? doctorPhoto;

  const OutgoingCallScreen({
    super.key,
    required this.doctorId,
    required this.doctorName,
    this.doctorPhoto,
  });

  @override
  State<OutgoingCallScreen> createState() => _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends State<OutgoingCallScreen>
    with SingleTickerProviderStateMixin {
  final CallService _callService = CallService();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  CallModel? _call;
  bool _isConnecting = true;
  String _statusText = 'Connecting...';
  Timer? _timeoutTimer;
  bool _hasNavigated = false;

  StreamSubscription<CallModel?>? _callSubscription;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();

    // Set up pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initiateCall();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timeoutTimer?.cancel();
    _callSubscription?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _initiateCall() async {
    try {
      _call = await _callService.initiateCall(
        doctorId: widget.doctorId,
        doctorName: widget.doctorName,
        doctorPhoto: widget.doctorPhoto,
      );

      if (!mounted) return;

      setState(() {
        _isConnecting = false;
        _statusText = 'Ringing...';
      });

      // Listen for call state changes
      _callSubscription = _callService.currentCallStream.listen((call) {
        debugPrint('📞 OutgoingCallScreen: Received call state: ${call?.status}');
        if (_hasNavigated) return;
        
        if (call == null) {
          debugPrint('📞 OutgoingCallScreen: Call is null, handling ended');
          _handleCallEnded(CallEndType.failed);
        } else if (call.status == CallStatus.answered) {
          debugPrint('📞 OutgoingCallScreen: Call answered! Navigating to video call');
          _navigateToVideoCall();
        } else if (call.status == CallStatus.declined) {
          debugPrint('📞 OutgoingCallScreen: Call declined by doctor');
          _handleCallEnded(CallEndType.declined);
        } else if (call.status == CallStatus.ended) {
          debugPrint('📞 OutgoingCallScreen: Call ended');
          _handleCallEnded(CallEndType.declined);
        }
      });

      // Set timeout for no answer
      _timeoutTimer = Timer(const Duration(seconds: 60), () {
        if (mounted && !_hasNavigated && _call?.status == CallStatus.ringing) {
          _handleNoAnswer();
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusText = 'Failed to connect';
        });
        _showError('Failed to initiate call: $e');
      }
    }
  }

  void _navigateToVideoCall() {
    if (_hasNavigated) return;
    _hasNavigated = true;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => VideoCallScreen(call: _call!),
      ),
    );
  }

  void _handleNoAnswer() {
    if (_hasNavigated) return;
    _hasNavigated = true;
    
    _callService.endCall();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CallEndScreen(
          call: _call!,
          endType: CallEndType.missed,
        ),
      ),
    );
  }

  void _handleCallEnded(CallEndType endType) {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    
    if (_call != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CallEndScreen(
            call: _call!,
            endType: endType,
          ),
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _cancelCall() {
    _callService.endCall();
    if (!_hasNavigated) {
      Navigator.of(context).pop();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // Doctor Avatar with pulse animation
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: _buildAvatar(),
                );
              },
            ),

            const SizedBox(height: 32),

            // Doctor Name
            Text(
              'Dr. ${widget.doctorName}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            // Status Text
            Text(
              _statusText,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 18,
              ),
            ),

            const Spacer(),

            // Cancel Button
            Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: GestureDetector(
                onTap: _cancelCall,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.call_end_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.2),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 3,
        ),
      ),
      child: widget.doctorPhoto != null
          ? ClipOval(
              child: Image.network(
                widget.doctorPhoto!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
              ),
            )
          : _buildDefaultAvatar(),
    );
  }

  Widget _buildDefaultAvatar() {
    final initial = widget.doctorName.isNotEmpty
        ? widget.doctorName[0].toUpperCase()
        : 'D';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 64,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

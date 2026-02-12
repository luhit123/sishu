import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/call_model.dart';
import '../../../core/services/call_service.dart';
import 'video_call_screen.dart';

/// Incoming Call Screen - Backup UI for when CallKit is not available
class IncomingCallScreen extends StatefulWidget {
  final CallModel call;

  const IncomingCallScreen({
    super.key,
    required this.call,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  final CallService _callService = CallService();
  late AnimationController _ringController;
  late Animation<double> _ringAnimation;

  bool _isAccepting = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();

    // Set up ring animation
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _ringAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ringController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _acceptCall() async {
    if (_isAccepting) return;

    setState(() {
      _isAccepting = true;
    });

    try {
      debugPrint('📞 IncomingCallScreen: Accepting call ${widget.call.id}');
      await _callService.acceptCall(widget.call);
      debugPrint('📞 IncomingCallScreen: Call accepted, navigating to video call');

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => VideoCallScreen(call: widget.call),
          ),
        );
      }
    } catch (e) {
      debugPrint('📞 IncomingCallScreen: Failed to accept call: $e');
      if (mounted) {
        setState(() {
          _isAccepting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept call: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _declineCall() async {
    await _callService.declineCall(widget.call.id);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // "Incoming Video Call" label
            Text(
              'Incoming Video Call',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 40),

            // Caller Avatar with ring animation
            AnimatedBuilder(
              animation: _ringAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _ringAnimation.value,
                  child: _buildAvatar(),
                );
              },
            ),

            const SizedBox(height: 32),

            // Caller Name
            Text(
              widget.call.callerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            // "wants to video call"
            Text(
              'wants to video call',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),

            const Spacer(),

            // Accept / Decline Buttons
            Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Decline Button
                  _buildActionButton(
                    icon: Icons.call_end_rounded,
                    color: AppColors.error,
                    label: 'Decline',
                    onTap: _declineCall,
                  ),

                  // Accept Button
                  _buildActionButton(
                    icon: Icons.videocam_rounded,
                    color: AppColors.success,
                    label: 'Accept',
                    onTap: _acceptCall,
                    isLoading: _isAccepting,
                  ),
                ],
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
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.5),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
      child: widget.call.callerPhoto != null
          ? ClipOval(
              child: Image.network(
                widget.call.callerPhoto!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
              ),
            )
          : _buildDefaultAvatar(),
    );
  }

  Widget _buildDefaultAvatar() {
    final initial = widget.call.callerName.isNotEmpty
        ? widget.call.callerName[0].toUpperCase()
        : 'U';
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

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: isLoading ? null : onTap,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : Icon(
                    icon,
                    color: Colors.white,
                    size: 36,
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

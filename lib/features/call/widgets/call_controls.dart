import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Call Controls Widget - Mute, Video, Speaker, End Call buttons
class CallControls extends StatelessWidget {
  final bool isMuted;
  final bool isVideoEnabled;
  final bool isSpeakerOn;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleVideo;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onEndCall;

  const CallControls({
    super.key,
    required this.isMuted,
    required this.isVideoEnabled,
    required this.isSpeakerOn,
    required this.onToggleMute,
    required this.onToggleVideo,
    required this.onToggleSpeaker,
    required this.onEndCall,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Mute Button
        _ControlButton(
          icon: isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
          label: isMuted ? 'Unmute' : 'Mute',
          isActive: !isMuted,
          onTap: onToggleMute,
        ),

        // Video Button
        _ControlButton(
          icon: isVideoEnabled ? Icons.videocam_rounded : Icons.videocam_off_rounded,
          label: isVideoEnabled ? 'Video' : 'Video Off',
          isActive: isVideoEnabled,
          onTap: onToggleVideo,
        ),

        // End Call Button
        _EndCallButton(onTap: onEndCall),

        // Speaker Button
        _ControlButton(
          icon: isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
          label: isSpeakerOn ? 'Speaker' : 'Speaker Off',
          isActive: isSpeakerOn,
          onTap: onToggleSpeaker,
        ),

        // Placeholder for alignment (or could add more controls)
        const SizedBox(width: 56),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : AppColors.textPrimary,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _EndCallButton extends StatelessWidget {
  final VoidCallback onTap;

  const _EndCallButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.call_end_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'End',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Compact call controls for smaller spaces
class CompactCallControls extends StatelessWidget {
  final bool isMuted;
  final bool isVideoEnabled;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleVideo;
  final VoidCallback onEndCall;

  const CompactCallControls({
    super.key,
    required this.isMuted,
    required this.isVideoEnabled,
    required this.onToggleMute,
    required this.onToggleVideo,
    required this.onEndCall,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CompactButton(
          icon: isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
          isActive: !isMuted,
          onTap: onToggleMute,
        ),
        const SizedBox(width: 20),
        _CompactButton(
          icon: isVideoEnabled ? Icons.videocam_rounded : Icons.videocam_off_rounded,
          isActive: isVideoEnabled,
          onTap: onToggleVideo,
        ),
        const SizedBox(width: 20),
        GestureDetector(
          onTap: onEndCall,
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.call_end_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _CompactButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : AppColors.textPrimary,
          size: 24,
        ),
      ),
    );
  }
}

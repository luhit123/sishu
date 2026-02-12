import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/call_model.dart';

/// Call End Screen - Shows after call ends with thank you message and rating
class CallEndScreen extends StatefulWidget {
  final CallModel call;
  final CallEndType endType;
  final int? callDuration;

  const CallEndScreen({
    super.key,
    required this.call,
    required this.endType,
    this.callDuration,
  });

  @override
  State<CallEndScreen> createState() => _CallEndScreenState();
}

enum CallEndType {
  completed,  // Call completed successfully
  declined,   // Doctor declined the call
  missed,     // Call was not answered
  failed,     // Technical issue
}

class _CallEndScreenState extends State<CallEndScreen> with SingleTickerProviderStateMixin {
  int _doctorRating = 0;
  int _qualityRating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;
  bool _showRating = false;
  
  // Check if current user is the doctor in this call
  bool get _isDoctor {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return currentUserId == widget.call.doctorId;
  }

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();

    // Show rating section for completed calls after a delay (only for patients, not doctors)
    if (widget.endType == CallEndType.completed && !_isDoctor) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _showRating = true);
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_doctorRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please rate the doctor')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final firestore = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'sishu',
      );

      // Save rating to Firestore
      await firestore.collection('call_ratings').add({
        'callId': widget.call.id,
        'userId': user.uid,
        'doctorId': widget.call.doctorId,
        'doctorRating': _doctorRating,
        'qualityRating': _qualityRating,
        'feedback': _feedbackController.text.trim(),
        'callDuration': widget.callDuration,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update doctor's average rating
      await _updateDoctorRating(widget.call.doctorId, _doctorRating);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your feedback!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      debugPrint('Error submitting rating: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit rating')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _updateDoctorRating(String doctorId, int rating) async {
    try {
      final firestore = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'sishu',
      );

      final docRef = firestore.collection('doctors').doc(doctorId);

      await firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (doc.exists) {
          final data = doc.data()!;
          final currentRating = (data['rating'] as num?)?.toDouble() ?? 0.0;
          final totalRatings = (data['totalRatings'] as int?) ?? 0;

          final newTotalRatings = totalRatings + 1;
          final newRating = ((currentRating * totalRatings) + rating) / newTotalRatings;

          transaction.update(docRef, {
            'rating': newRating,
            'totalRatings': newTotalRatings,
          });
        }
      });
    } catch (e) {
      debugPrint('Error updating doctor rating: $e');
    }
  }

  void _skip() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: _buildContent(),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (widget.endType) {
      case CallEndType.completed:
        return AppColors.background;
      case CallEndType.declined:
      case CallEndType.missed:
        return const Color(0xFFFFF5F5);
      case CallEndType.failed:
        return const Color(0xFFFFF5F5);
    }
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 60),
            _buildIcon(),
            const SizedBox(height: 32),
            _buildTitle(),
            const SizedBox(height: 16),
            _buildMessage(),
            const SizedBox(height: 24),
            if (widget.callDuration != null && widget.endType == CallEndType.completed)
              _buildDurationBadge(),
            // Only show rating for patients, not doctors
            if (widget.endType == CallEndType.completed && _showRating && !_isDoctor) ...[
              const SizedBox(height: 40),
              _buildRatingSection(),
            ],
            const SizedBox(height: 40),
            _buildActions(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    Color bgColor;
    Color iconColor;

    switch (widget.endType) {
      case CallEndType.completed:
        icon = Icons.check_circle_rounded;
        bgColor = AppColors.success.withValues(alpha: 0.1);
        iconColor = AppColors.success;
        break;
      case CallEndType.declined:
        icon = Icons.phone_missed_rounded;
        bgColor = AppColors.warning.withValues(alpha: 0.1);
        iconColor = AppColors.warning;
        break;
      case CallEndType.missed:
        icon = Icons.phone_disabled_rounded;
        bgColor = AppColors.textSecondary.withValues(alpha: 0.1);
        iconColor = AppColors.textSecondary;
        break;
      case CallEndType.failed:
        icon = Icons.error_outline_rounded;
        bgColor = AppColors.error.withValues(alpha: 0.1);
        iconColor = AppColors.error;
        break;
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 60, color: iconColor),
    );
  }

  Widget _buildTitle() {
    String title;
    switch (widget.endType) {
      case CallEndType.completed:
        title = 'Call Completed!';
        break;
      case CallEndType.declined:
        title = 'Call Declined';
        break;
      case CallEndType.missed:
        title = 'Call Not Answered';
        break;
      case CallEndType.failed:
        title = 'Connection Failed';
        break;
    }

    return Text(
      title,
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMessage() {
    String message;
    
    if (_isDoctor) {
      // Messages for doctors
      switch (widget.endType) {
        case CallEndType.completed:
          message = 'Thank you for your consultation, Dr. ${widget.call.doctorName}! Your dedication to patient care makes a difference. Have a great day!';
          break;
        case CallEndType.declined:
          message = 'You declined the call from ${widget.call.callerName}. They will be notified that you are currently unavailable.';
          break;
        case CallEndType.missed:
          message = 'You missed a call from ${widget.call.callerName}. Consider following up when you are available.';
          break;
        case CallEndType.failed:
          message = 'The call connection failed. Please check your internet connection and try again.';
          break;
      }
    } else {
      // Messages for patients/users
      switch (widget.endType) {
        case CallEndType.completed:
          message = 'Thank you for using XoruCare! We hope your consultation with Dr. ${widget.call.doctorName} was helpful. Your child\'s health is our priority.';
          break;
        case CallEndType.declined:
          message = 'Dr. ${widget.call.doctorName} is currently unavailable. Please try again later or choose another doctor.';
          break;
        case CallEndType.missed:
          message = 'Dr. ${widget.call.doctorName} couldn\'t answer your call. They might be with another patient. Please try again in a few minutes.';
          break;
        case CallEndType.failed:
          message = 'We encountered a technical issue. Please check your internet connection and try again.';
          break;
      }
    }

    return Text(
      message,
      style: const TextStyle(
        fontSize: 16,
        color: AppColors.textSecondary,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDurationBadge() {
    final minutes = (widget.callDuration ?? 0) ~/ 60;
    final seconds = (widget.callDuration ?? 0) % 60;
    final duration = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            'Call duration: $duration',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return AnimatedOpacity(
      opacity: _showRating ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.textSecondary.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text(
              'How was your experience?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            // Doctor Rating
            const Text(
              'Rate the Doctor',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            _buildStarRating(
              rating: _doctorRating,
              onRatingChanged: (rating) => setState(() => _doctorRating = rating),
            ),

            const SizedBox(height: 24),

            // Call Quality Rating
            const Text(
              'Video/Audio Quality',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            _buildStarRating(
              rating: _qualityRating,
              onRatingChanged: (rating) => setState(() => _qualityRating = rating),
            ),

            const SizedBox(height: 24),

            // Feedback Text
            TextField(
              controller: _feedbackController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Share your feedback (optional)',
                hintStyle: TextStyle(color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating({
    required int rating,
    required ValueChanged<int> onRatingChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return GestureDetector(
          onTap: () => onRatingChanged(starIndex),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedScale(
              scale: rating >= starIndex ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Icon(
                rating >= starIndex ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 40,
                color: rating >= starIndex ? Colors.amber : AppColors.textHint,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildActions() {
    // Show rating submission for patients only
    if (widget.endType == CallEndType.completed && _showRating && !_isDoctor) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitRating,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Submit Rating',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _skip,
            child: const Text(
              'Skip',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      );
    }

    // For declined/missed/failed calls
    String buttonText;
    switch (widget.endType) {
      case CallEndType.declined:
      case CallEndType.missed:
        buttonText = 'Find Another Doctor';
        break;
      case CallEndType.failed:
        buttonText = 'Try Again';
        break;
      default:
        buttonText = 'Go Home';
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _skip,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _skip,
          child: const Text(
            'Go Home',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

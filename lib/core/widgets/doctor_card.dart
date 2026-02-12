import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/doctor_profile.dart';

/// Card displaying doctor info for users
class DoctorCard extends StatelessWidget {
  final DoctorProfile profile;
  final VoidCallback? onTap;
  final bool showFullDetails;

  const DoctorCard({
    super.key,
    required this.profile,
    this.onTap,
    this.showFullDetails = false,
  });

  Color get _statusColor {
    if (profile.acceptingBookings && profile.acceptingInstantCalls) {
      return AppColors.success; // Both enabled - green
    } else if (profile.acceptingInstantCalls) {
      return AppColors.primary; // Instant only - blue
    } else if (profile.acceptingBookings) {
      return AppColors.success; // Booking only - green
    } else {
      return AppColors.textSecondary; // Offline - gray
    }
  }

  String get _statusText {
    if (profile.acceptingBookings && profile.acceptingInstantCalls) {
      return 'Available';
    } else if (profile.acceptingInstantCalls) {
      return 'Instant';
    } else if (profile.acceptingBookings) {
      return 'Booking';
    } else {
      return 'Offline';
    }
  }

  IconData get _statusIcon {
    if (profile.acceptingBookings && profile.acceptingInstantCalls) {
      return Icons.check_circle_rounded;
    } else if (profile.acceptingInstantCalls) {
      return Icons.phone_in_talk_rounded;
    } else if (profile.acceptingBookings) {
      return Icons.calendar_month_rounded;
    } else {
      return Icons.do_not_disturb_rounded;
    }
  }

  String get _buttonText {
    if (profile.acceptingInstantCalls) {
      return 'Call Now';
    } else if (profile.acceptingBookings) {
      return 'Book Consultation';
    } else {
      return 'Currently Offline';
    }
  }

  Color get _buttonColor {
    if (profile.acceptingInstantCalls) {
      return AppColors.primary;
    } else if (profile.acceptingBookings) {
      return AppColors.success;
    } else {
      return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textSecondary.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Photo
                    _buildPhoto(),
                    const SizedBox(width: 14),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dr. ${profile.name}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (profile.specialty != null) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                profile.specialty!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                          if (profile.degree != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              profile.degree!,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Status, Verified Badge & Experience
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _statusIcon,
                                color: _statusColor,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _statusText,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (profile.isVerified) ...[
                          const SizedBox(height: 6),
                          const Icon(
                            Icons.verified_rounded,
                            color: AppColors.success,
                            size: 18,
                          ),
                        ],
                        if (profile.experienceYears != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            '${profile.experienceYears} yrs',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                // Additional Info
                if (showFullDetails) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.local_hospital_outlined,
                    profile.clinicName ?? 'Clinic not specified',
                  ),
                  if (_getLocation() != null)
                    _buildDetailRow(
                      Icons.location_on_outlined,
                      _getLocation()!,
                    ),
                  if (profile.registrationNumber != null)
                    _buildDetailRow(
                      Icons.badge_outlined,
                      'Reg: ${profile.registrationNumber}',
                    ),
                ] else ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (profile.clinicName != null) ...[
                        Icon(
                          Icons.local_hospital_outlined,
                          size: 14,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            profile.clinicName!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (_getLocation() != null) ...[
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _getLocation()!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],

                // Consult Button
                if (onTap != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: profile.isOffline ? null : onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _buttonColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.textSecondary.withValues(alpha: 0.2),
                        disabledForegroundColor: AppColors.textSecondary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _statusIcon,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _buttonText,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: profile.photoUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                profile.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
              ),
            )
          : _buildDefaultAvatar(),
    );
  }

  Widget _buildDefaultAvatar() {
    final initial = profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'D';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: AppColors.success,
          fontSize: 28,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _getLocation() {
    final parts = [profile.district, profile.state]
        .where((e) => e != null && e.isNotEmpty)
        .toList();
    return parts.isNotEmpty ? parts.join(', ') : null;
  }
}

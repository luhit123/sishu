import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/doctor_profile.dart';

/// Card displaying doctor info for admin management
class DoctorAdminCard extends StatelessWidget {
  final UserModel user;
  final DoctorProfile? profile;
  final VoidCallback onEdit;

  const DoctorAdminCard({
    super.key,
    required this.user,
    required this.profile,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final name = profile?.name ?? user.displayName;
    final photoUrl = profile?.photoUrl ?? user.photoUrl;
    final specialty = profile?.specialty;
    final degree = profile?.degree;
    final clinic = profile?.clinicName;
    final location = _getLocation();

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
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Photo
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: photoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildDefaultAvatar(name),
                          ),
                        )
                      : _buildDefaultAvatar(name),
                ),
                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dr. $name',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (specialty != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          specialty,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (degree != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          degree,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (clinic != null) ...[
                            Icon(
                              Icons.local_hospital_outlined,
                              size: 12,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                clinic,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textHint,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          if (location != null && clinic != null)
                            const SizedBox(width: 8),
                          if (location != null) ...[
                            Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                location,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textHint,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Edit Button
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _getLocation() {
    if (profile == null) return null;
    final parts = [profile!.district, profile!.state]
        .where((e) => e != null && e.isNotEmpty)
        .toList();
    return parts.isNotEmpty ? parts.join(', ') : null;
  }

  Widget _buildDefaultAvatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'D';
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
}

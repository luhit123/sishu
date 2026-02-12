import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../../core/constants/app_constants.dart';

/// Tile displaying user info with role management controls
class UserRoleTile extends StatelessWidget {
  final UserModel user;
  final bool isCreator;
  final String currentUserUid;
  final Function(UserRole) onRoleChanged;

  const UserRoleTile({
    super.key,
    required this.user,
    required this.isCreator,
    required this.currentUserUid,
    required this.onRoleChanged,
  });

  bool get _isUserCreator => user.uid == AppConstants.creatorUid;
  bool get _isCurrentUser => user.uid == currentUserUid;

  Color get _roleColor {
    switch (user.role) {
      case UserRole.admin:
        return AppColors.lavender;
      case UserRole.doctor:
        return AppColors.success;
      case UserRole.user:
        return AppColors.secondary;
    }
  }

  String get _roleLabel {
    switch (user.role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.doctor:
        return 'Doctor';
      case UserRole.user:
        return 'User';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              _buildAvatar(),
              const SizedBox(width: 12),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_isUserCreator) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.softYellow,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'CREATOR',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                        if (_isCurrentUser) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'YOU',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Role badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _roleColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _roleLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _roleColor,
                  ),
                ),
              ),
            ],
          ),

          // Role controls (if can modify)
          if (_canModifyRole()) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _buildRoleControls(),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [_roleColor, _roleColor.withValues(alpha: 0.7)],
        ),
      ),
      child: user.photoUrl != null
          ? ClipOval(
              child: Image.network(
                user.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
              ),
            )
          : _buildDefaultAvatar(),
    );
  }

  Widget _buildDefaultAvatar() {
    final initial = user.displayName.isNotEmpty
        ? user.displayName[0].toUpperCase()
        : 'U';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  bool _canModifyRole() {
    // Cannot modify creator's role
    if (_isUserCreator) return false;
    // Cannot modify your own role
    if (_isCurrentUser) return false;
    return true;
  }

  Widget _buildRoleControls() {
    return Row(
      children: [
        const Text(
          'Set role:',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Wrap(
            spacing: 8,
            children: [
              _buildRoleChip(UserRole.user),
              _buildRoleChip(UserRole.doctor),
              if (isCreator) _buildRoleChip(UserRole.admin),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleChip(UserRole role) {
    final isSelected = user.role == role;
    final color = _getColorForRole(role);

    return InkWell(
      onTap: isSelected ? null : () => onRoleChanged(role),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color,
            width: isSelected ? 0 : 1,
          ),
        ),
        child: Text(
          role.value.substring(0, 1).toUpperCase() + role.value.substring(1),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }

  Color _getColorForRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return AppColors.lavender;
      case UserRole.doctor:
        return AppColors.success;
      case UserRole.user:
        return AppColors.secondary;
    }
  }
}

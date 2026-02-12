import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/models/doctor_profile.dart';

/// Doctor Dashboard - accessible only to users with doctor role
class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  DoctorProfile? _profile;
  bool _isLoading = true;
  bool _isUpdatingStatus = false;
  StreamSubscription<DoctorProfile?>? _profileSubscription;

  @override
  void initState() {
    super.initState();
    _setupProfileStream();
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }

  void _setupProfileStream() {
    final uid = _authService.currentUser?.uid;
    if (uid != null) {
      _profileSubscription = _userService.doctorProfileStream(uid).listen(
        (profile) {
          if (mounted) {
            setState(() {
              _profile = profile;
              _isLoading = false;
            });
          }
        },
        onError: (e) {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        },
      );
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateAvailability({
    required bool acceptingBookings,
    required bool acceptingInstantCalls,
  }) async {
    final uid = _authService.currentUser?.uid;
    if (uid == null || _isUpdatingStatus) return;

    setState(() => _isUpdatingStatus = true);

    try {
      await _userService.updateDoctorAvailability(
        uid,
        acceptingBookings: acceptingBookings,
        acceptingInstantCalls: acceptingInstantCalls,
      );
      if (mounted) {
        final statusText = _getStatusText(acceptingBookings, acceptingInstantCalls);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status: $statusText'),
            backgroundColor: (acceptingBookings || acceptingInstantCalls)
                ? AppColors.success
                : AppColors.textSecondary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingStatus = false);
      }
    }
  }

  String _getStatusText(bool acceptingBookings, bool acceptingInstantCalls) {
    if (acceptingBookings && acceptingInstantCalls) {
      return 'Accepting Bookings & Instant Calls';
    } else if (acceptingBookings) {
      return 'Taking Consultations';
    } else if (acceptingInstantCalls) {
      return 'Receiving Instant Calls';
    } else {
      return 'Offline';
    }
  }

  void _restartStream() {
    _profileSubscription?.cancel();
    setState(() => _isLoading = true);
    _setupProfileStream();
  }

  Widget _buildStatusSelector() {
    final acceptingBookings = _profile?.acceptingBookings ?? false;
    final acceptingInstantCalls = _profile?.acceptingInstantCalls ?? false;
    final isAvailable = acceptingBookings || acceptingInstantCalls;

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
              const Text(
                'Your Availability',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (_isUpdatingStatus)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Booking Consultations Toggle
          _buildAvailabilityToggle(
            icon: Icons.calendar_month_rounded,
            title: 'Taking Consultations',
            subtitle: 'Accept appointment bookings',
            color: AppColors.success,
            isEnabled: acceptingBookings,
            onChanged: _isUpdatingStatus
                ? null
                : (value) => _updateAvailability(
                      acceptingBookings: value,
                      acceptingInstantCalls: acceptingInstantCalls,
                    ),
          ),

          const SizedBox(height: 12),

          // Instant Calls Toggle
          _buildAvailabilityToggle(
            icon: Icons.phone_in_talk_rounded,
            title: 'Instant Calls',
            subtitle: 'Receive calls right now',
            color: AppColors.primary,
            isEnabled: acceptingInstantCalls,
            onChanged: _isUpdatingStatus
                ? null
                : (value) => _updateAvailability(
                      acceptingBookings: acceptingBookings,
                      acceptingInstantCalls: value,
                    ),
          ),

          const SizedBox(height: 16),

          // Current Status Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isAvailable
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isAvailable ? Icons.check_circle_rounded : Icons.do_not_disturb_rounded,
                  size: 18,
                  color: isAvailable ? AppColors.success : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  _getStatusText(acceptingBookings, acceptingInstantCalls),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isAvailable ? AppColors.success : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isEnabled,
    required void Function(bool)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isEnabled ? color.withValues(alpha: 0.1) : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnabled ? color : AppColors.textSecondary.withValues(alpha: 0.2),
          width: isEnabled ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isEnabled ? color : AppColors.textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isEnabled ? Colors.white : AppColors.textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isEnabled ? color : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isEnabled,
            onChanged: onChanged,
            activeColor: color,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Doctor Dashboard',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: _restartStream,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async {}, // Real-time updates via stream
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Status Selector (prominent at top)
                    _buildStatusSelector(),
                    const SizedBox(height: 20),

                    // Profile Card
                    _buildProfileCard(),
                    const SizedBox(height: 24),

                    // Quick Stats
                    _buildSectionTitle('Today\'s Overview'),
                    const SizedBox(height: 12),
                    _buildQuickStats(),
                    const SizedBox(height: 24),

                    // Quick Actions
                    _buildSectionTitle('Quick Actions'),
                    const SizedBox(height: 12),
                    _buildQuickActions(),
                    const SizedBox(height: 24),

                    // Recent Activity (placeholder)
                    _buildSectionTitle('Recent Consultations'),
                    const SizedBox(height: 12),
                    _buildRecentActivity(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProfileCard() {
    final userName = _profile?.name ?? _authService.displayName ?? 'Doctor';
    final specialty = _profile?.specialty;
    final degree = _profile?.degree;
    final clinic = _profile?.clinicName;
    final location = _profile != null
        ? [_profile!.district, _profile!.state]
            .where((e) => e != null && e.isNotEmpty)
            .join(', ')
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.success, AppColors.success.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Profile Photo
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _profile?.photoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          _profile!.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                        ),
                      )
                    : _buildDefaultAvatar(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. $userName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (specialty != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        specialty,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                    if (degree != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        degree,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Verified Badge
              if (_profile?.isVerified == true)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
            ],
          ),

          // Additional Info
          if (clinic != null || location != null) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 12),
            if (clinic != null)
              _buildInfoRow(Icons.local_hospital_outlined, clinic),
            if (location != null && location.isNotEmpty)
              _buildInfoRow(Icons.location_on_outlined, location),
            if (_profile?.registrationNumber != null)
              _buildInfoRow(Icons.badge_outlined, 'Reg: ${_profile!.registrationNumber}'),
          ],
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return const Center(
      child: Icon(
        Icons.medical_services_rounded,
        color: Colors.white,
        size: 32,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Pending',
            '5',
            Icons.pending_actions_rounded,
            AppColors.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Today',
            '12',
            Icons.calendar_today_rounded,
            AppColors.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Completed',
            '8',
            Icons.check_circle_outline_rounded,
            AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
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
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        _buildActionTile(
          icon: Icons.video_call_rounded,
          title: 'Start Consultation',
          subtitle: 'Begin a video call with a patient',
          color: AppColors.primary,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Consultation feature coming soon'),
                backgroundColor: AppColors.info,
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildActionTile(
          icon: Icons.assignment_rounded,
          title: 'View Appointments',
          subtitle: 'See your scheduled appointments',
          color: AppColors.secondary,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Appointments feature coming soon'),
                backgroundColor: AppColors.info,
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildActionTile(
          icon: Icons.history_rounded,
          title: 'Patient History',
          subtitle: 'Access patient consultation records',
          color: AppColors.lavender,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Patient history feature coming soon'),
                backgroundColor: AppColors.info,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.textSecondary.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 12),
          const Text(
            'No recent consultations',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your consultation history will appear here',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

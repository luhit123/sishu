import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/user_service.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/doctor_profile.dart';
import '../widgets/doctor_admin_card.dart';
import 'edit_doctor_screen.dart';
import 'add_doctor_screen.dart';

/// Screen to list and manage all doctors (Admin only)
class DoctorsListScreen extends StatefulWidget {
  const DoctorsListScreen({super.key});

  @override
  State<DoctorsListScreen> createState() => _DoctorsListScreenState();
}

class _DoctorsListScreenState extends State<DoctorsListScreen> {
  final UserService _userService = UserService();
  List<Map<String, dynamic>> _doctors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() => _isLoading = true);
    try {
      // Get all users with doctor role
      final doctorUsers = await _userService.getDoctors();

      // Get profiles for each doctor
      final doctorsWithProfiles = <Map<String, dynamic>>[];
      for (final user in doctorUsers) {
        final profile = await _userService.getDoctorProfile(user.uid);
        doctorsWithProfiles.add({
          'user': user,
          'profile': profile,
        });
      }

      if (mounted) {
        setState(() {
          _doctors = doctorsWithProfiles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading doctors: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _editDoctor(UserModel user, DoctorProfile? profile) async {
    if (profile == null) {
      // Create a basic profile from user data
      profile = DoctorProfile(
        name: user.displayName,
        email: user.email,
        photoUrl: user.photoUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      // Save the basic profile first
      await _userService.saveDoctorProfile(user.uid, profile);
    }

    if (!mounted) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditDoctorScreen(
          doctorUid: user.uid,
          profile: profile!,
        ),
      ),
    );

    if (result == true) {
      _loadDoctors();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Manage Doctors',
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
            onPressed: _loadDoctors,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AddDoctorScreen()),
          );
          if (result == true) {
            _loadDoctors();
          }
        },
        backgroundColor: AppColors.success,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Doctor'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _doctors.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadDoctors,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _doctors.length,
                      itemBuilder: (context, index) {
                        final doctor = _doctors[index];
                        final user = doctor['user'] as UserModel;
                        final profile = doctor['profile'] as DoctorProfile?;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: DoctorAdminCard(
                            user: user,
                            profile: profile,
                            onEdit: () => _editDoctor(user, profile),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          const Text(
            'No doctors yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the button below to add a doctor',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

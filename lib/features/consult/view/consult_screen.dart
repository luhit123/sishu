import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/user_service.dart';
import '../../../core/models/doctor_profile.dart';
import '../../../core/widgets/doctor_card.dart';
import '../../call/view/outgoing_call_screen.dart';

/// Consult Screen - Shows list of available doctors to users
class ConsultScreen extends StatefulWidget {
  const ConsultScreen({super.key});

  @override
  State<ConsultScreen> createState() => _ConsultScreenState();
}

class _ConsultScreenState extends State<ConsultScreen> {
  final UserService _userService = UserService();
  List<DoctorProfile> _doctors = [];
  List<DoctorProfile> _filteredDoctors = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedSpecialty;
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<List<DoctorProfile>>? _doctorsSubscription;

  // Get unique specialties from doctors
  List<String> get _specialties {
    final specs = _doctors
        .where((d) => d.specialty != null && d.specialty!.isNotEmpty)
        .map((d) => d.specialty!)
        .toSet()
        .toList();
    specs.sort();
    return specs;
  }

  @override
  void initState() {
    super.initState();
    _setupDoctorsStream();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _doctorsSubscription?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _setupDoctorsStream() {
    _doctorsSubscription = _userService.allDoctorProfilesStream().listen(
      (profiles) {
        if (mounted) {
          setState(() {
            _doctors = profiles;
            _filterDoctors();
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
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterDoctors();
    });
  }

  Future<void> _refreshDoctors() async {
    // Cancel current subscription and restart for a fresh connection
    await _doctorsSubscription?.cancel();
    _setupDoctorsStream();
  }

  void _filterDoctors() {
    _filteredDoctors = _doctors.where((doctor) {
      // Filter by search query
      final matchesSearch = _searchQuery.isEmpty ||
          doctor.name.toLowerCase().contains(_searchQuery) ||
          (doctor.specialty?.toLowerCase().contains(_searchQuery) ?? false) ||
          (doctor.clinicName?.toLowerCase().contains(_searchQuery) ?? false) ||
          (doctor.district?.toLowerCase().contains(_searchQuery) ?? false);

      // Filter by specialty
      final matchesSpecialty = _selectedSpecialty == null ||
          doctor.specialty == _selectedSpecialty;

      return matchesSearch && matchesSpecialty;
    }).toList();
  }

  void _showDoctorDetails(DoctorProfile doctor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DoctorDetailsSheet(
        profile: doctor,
        doctorId: doctor.uid ?? '',
        onBookConsultation: () {
          Navigator.pop(context);
          _showBookingDialog(doctor);
        },
        onVideoCall: () {
          Navigator.pop(context);
          _initiateVideoCall(doctor);
        },
      ),
    );
  }

  Future<void> _initiateVideoCall(DoctorProfile doctor) async {
    if (doctor.uid == null || doctor.uid!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot call this doctor. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Request camera and microphone permissions
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (cameraStatus.isDenied || micStatus.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera and microphone permissions are required for video calls'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OutgoingCallScreen(
            doctorId: doctor.uid!,
            doctorName: doctor.name,
            doctorPhoto: doctor.photoUrl,
          ),
        ),
      );
    }
  }

  void _showBookingDialog(DoctorProfile doctor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Book Consultation'),
        content: Text(
          'Booking consultation with Dr. ${doctor.name} will be available soon!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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
          'Consult a Doctor',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search and Filter Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.textSecondary.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search doctors, specialties...',
                        hintStyle: TextStyle(color: AppColors.textHint),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.textSecondary,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear_rounded,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),

                  // Specialty Filter
                  if (_specialties.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildFilterChip(
                            label: 'All',
                            isSelected: _selectedSpecialty == null,
                            onTap: () {
                              setState(() {
                                _selectedSpecialty = null;
                                _filterDoctors();
                              });
                            },
                          ),
                          ..._specialties.map((specialty) => _buildFilterChip(
                                label: specialty,
                                isSelected: _selectedSpecialty == specialty,
                                onTap: () {
                                  setState(() {
                                    _selectedSpecialty = specialty;
                                    _filterDoctors();
                                  });
                                },
                              )),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Results Count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    '${_filteredDoctors.length} ${_filteredDoctors.length == 1 ? 'doctor' : 'doctors'} available',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    color: AppColors.textSecondary,
                    iconSize: 20,
                    onPressed: _refreshDoctors,
                  ),
                ],
              ),
            ),

            // Doctors List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredDoctors.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _refreshDoctors,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _filteredDoctors.length,
                            itemBuilder: (context, index) {
                              final doctor = _filteredDoctors[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: DoctorCard(
                                  profile: doctor,
                                  onTap: () => _showDoctorDetails(doctor),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
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
          Text(
            _searchQuery.isNotEmpty || _selectedSpecialty != null
                ? 'No doctors match your search'
                : 'No doctors available',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedSpecialty != null
                ? 'Try adjusting your filters'
                : 'Check back later',
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

// ============================================================================
// DOCTOR DETAILS SHEET
// ============================================================================

class _DoctorDetailsSheet extends StatelessWidget {
  final DoctorProfile profile;
  final String doctorId;
  final VoidCallback onBookConsultation;
  final VoidCallback onVideoCall;

  const _DoctorDetailsSheet({
    required this.profile,
    required this.doctorId,
    required this.onBookConsultation,
    required this.onVideoCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textHint.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Doctor Header
                  Row(
                    children: [
                      // Photo
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: profile.photoUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.network(
                                  profile.photoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                                ),
                              )
                            : _buildDefaultAvatar(),
                      ),
                      const SizedBox(width: 16),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Dr. ${profile.name}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (profile.isVerified)
                                  const Icon(
                                    Icons.verified_rounded,
                                    color: AppColors.success,
                                    size: 22,
                                  ),
                              ],
                            ),
                            if (profile.specialty != null) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  profile.specialty!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                            if (profile.degree != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                profile.degree!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Stats Row
                  if (profile.experienceYears != null) ...[
                    Row(
                      children: [
                        _buildStatItem(
                          icon: Icons.work_outline_rounded,
                          value: '${profile.experienceYears}+ Years',
                          label: 'Experience',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Details Section
                  if (profile.clinicName != null ||
                      profile.clinicAddress != null ||
                      profile.district != null ||
                      profile.registrationNumber != null) ...[
                    const Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailItem(
                      Icons.local_hospital_outlined,
                      'Clinic',
                      profile.clinicName ?? 'Not specified',
                    ),
                    if (profile.clinicAddress != null)
                      _buildDetailItem(
                        Icons.map_outlined,
                        'Address',
                        profile.clinicAddress!,
                      ),
                    if (_getLocation() != null)
                      _buildDetailItem(
                        Icons.location_on_outlined,
                        'Location',
                        _getLocation()!,
                      ),
                    if (profile.registrationNumber != null)
                      _buildDetailItem(
                        Icons.badge_outlined,
                        'Registration',
                        profile.registrationNumber!,
                      ),
                    const SizedBox(height: 24),
                  ],

                  // Action Buttons
                  Row(
                    children: [
                      // Video Call Button (only if accepting instant calls)
                      if (profile.acceptingInstantCalls)
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: ElevatedButton.icon(
                              onPressed: onVideoCall,
                              icon: const Icon(Icons.videocam_rounded),
                              label: const Text('Video Call'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (profile.acceptingInstantCalls)
                        const SizedBox(width: 12),
                      // Book Consultation Button
                      Expanded(
                        child: SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: onBookConsultation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Book Consultation',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Availability Badge
                  if (profile.acceptingInstantCalls) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Available for instant calls',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    final initial = profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'D';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: AppColors.success,
          fontSize: 36,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
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

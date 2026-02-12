import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/user_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/doctor_profile.dart';

/// Screen to edit an existing doctor's profile
class EditDoctorScreen extends StatefulWidget {
  final String doctorUid;
  final DoctorProfile profile;

  const EditDoctorScreen({
    super.key,
    required this.doctorUid,
    required this.profile,
  });

  @override
  State<EditDoctorScreen> createState() => _EditDoctorScreenState();
}

class _EditDoctorScreenState extends State<EditDoctorScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _specialtyController;
  late TextEditingController _degreeController;
  late TextEditingController _registrationController;
  late TextEditingController _clinicNameController;
  late TextEditingController _clinicAddressController;
  late TextEditingController _experienceController;
  late TextEditingController _districtController;

  String? _selectedState;
  String? _photoUrl;
  File? _selectedImage;
  bool _isLoading = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.profile.name);
    _emailController = TextEditingController(text: widget.profile.email);
    _phoneController = TextEditingController(text: widget.profile.phone ?? '');
    _specialtyController = TextEditingController(text: widget.profile.specialty ?? '');
    _degreeController = TextEditingController(text: widget.profile.degree ?? '');
    _registrationController = TextEditingController(text: widget.profile.registrationNumber ?? '');
    _clinicNameController = TextEditingController(text: widget.profile.clinicName ?? '');
    _clinicAddressController = TextEditingController(text: widget.profile.clinicAddress ?? '');
    _experienceController = TextEditingController(
      text: widget.profile.experienceYears?.toString() ?? '',
    );
    _districtController = TextEditingController(text: widget.profile.district ?? '');
    _selectedState = widget.profile.state;
    _photoUrl = widget.profile.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _specialtyController.dispose();
    _degreeController.dispose();
    _registrationController.dispose();
    _clinicNameController.dispose();
    _clinicAddressController.dispose();
    _experienceController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              if (_photoUrl != null || _selectedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete_rounded, color: AppColors.error),
                  title: const Text('Remove Photo', style: TextStyle(color: AppColors.error)),
                  onTap: () {
                    setState(() {
                      _selectedImage = null;
                      _photoUrl = null;
                    });
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return _photoUrl;

    setState(() => _isUploadingImage = true);

    try {
      final fileName = 'doctor_${widget.doctorUid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child('doctor_photos/$fileName');

      await ref.putFile(_selectedImage!);
      final url = await ref.getDownloadURL();

      setState(() => _isUploadingImage = false);
      return url;
    } catch (e) {
      setState(() => _isUploadingImage = false);
      _showError('Failed to upload image: $e');
      return _photoUrl;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Upload image if new one selected
    final uploadedPhotoUrl = await _uploadImage();

    final updates = <String, dynamic>{
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim().toLowerCase(),
      'phone': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      'specialty': _specialtyController.text.trim().isNotEmpty ? _specialtyController.text.trim() : null,
      'degree': _degreeController.text.trim().isNotEmpty ? _degreeController.text.trim() : null,
      'registrationNumber': _registrationController.text.trim().isNotEmpty ? _registrationController.text.trim() : null,
      'state': _selectedState,
      'district': _districtController.text.trim().isNotEmpty ? _districtController.text.trim() : null,
      'clinicName': _clinicNameController.text.trim().isNotEmpty ? _clinicNameController.text.trim() : null,
      'clinicAddress': _clinicAddressController.text.trim().isNotEmpty ? _clinicAddressController.text.trim() : null,
      'experienceYears': _experienceController.text.trim().isNotEmpty ? int.tryParse(_experienceController.text.trim()) : null,
      'photoUrl': uploadedPhotoUrl,
    };

    try {
      await _userService.updateDoctorProfile(widget.doctorUid, updates);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Doctor profile updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Error updating profile: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
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
          'Edit Doctor',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Photo Section
              _buildPhotoSection(),
              const SizedBox(height: 24),

              // Basic Information Section
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _nameController,
                label: 'Full Name *',
                hint: 'Dr. John Doe',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _emailController,
                label: 'Email Address *',
                hint: 'doctor@example.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                enabled: false, // Email cannot be changed
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: '+91 98765 43210',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),

              // Professional Information Section
              _buildSectionTitle('Professional Information'),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _specialtyController,
                label: 'Specialty',
                hint: 'e.g., Pediatrician, Cardiologist',
                icon: Icons.medical_services_outlined,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _degreeController,
                label: 'Degree / Qualification',
                hint: 'MBBS, MD, etc.',
                icon: Icons.school_outlined,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _registrationController,
                label: 'Registration Number',
                hint: 'Medical council registration',
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _experienceController,
                label: 'Years of Experience',
                hint: '5',
                icon: Icons.work_outline,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),

              // Location Section
              _buildSectionTitle('Location'),
              const SizedBox(height: 12),

              _buildDropdown(
                label: 'State',
                hint: 'Select state',
                icon: Icons.location_on_outlined,
                value: _selectedState,
                items: IndianStates.list,
                onChanged: (value) => setState(() => _selectedState = value),
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _districtController,
                label: 'District / City',
                hint: 'Mumbai',
                icon: Icons.location_city_outlined,
              ),
              const SizedBox(height: 24),

              // Clinic Information Section
              _buildSectionTitle('Clinic Information'),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _clinicNameController,
                label: 'Clinic / Hospital Name',
                hint: 'City Hospital',
                icon: Icons.local_hospital_outlined,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _clinicAddressController,
                label: 'Clinic Address',
                hint: '123 Main Street, Mumbai',
                icon: Icons.map_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading || _isUploadingImage
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _isUploadingImage ? 'Uploading photo...' : 'Saving...',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_rounded, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    image: _selectedImage != null
                        ? DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover,
                          )
                        : _photoUrl != null
                            ? DecorationImage(
                                image: NetworkImage(_photoUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                  ),
                  child: _selectedImage == null && _photoUrl == null
                      ? const Icon(
                          Icons.person_rounded,
                          size: 48,
                          color: AppColors.textHint,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to change photo',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
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
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          enabled: enabled,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textHint),
            prefixIcon: Icon(icon, color: AppColors.textSecondary),
            filled: true,
            fillColor: enabled ? AppColors.surface : AppColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.textSecondary.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.textSecondary.withValues(alpha: 0.1),
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String hint,
    required IconData icon,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          hint: Text(hint, style: TextStyle(color: AppColors.textHint)),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.textSecondary.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

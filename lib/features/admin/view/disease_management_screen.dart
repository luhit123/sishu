import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/disease_service.dart';
import '../../../core/services/gpt_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/admin_notification_service.dart';
import '../../../core/models/disease.dart';
import '../../../core/models/parenting_tip.dart';

/// Admin screen for managing diseases with AI generation
class DiseaseManagementScreen extends StatefulWidget {
  const DiseaseManagementScreen({super.key});

  @override
  State<DiseaseManagementScreen> createState() => _DiseaseManagementScreenState();
}

class _DiseaseManagementScreenState extends State<DiseaseManagementScreen> {
  final DiseaseService _diseaseService = DiseaseService();
  final GPTService _gptService = GPTService();
  StreamSubscription<List<Disease>>? _diseasesSubscription;
  List<Disease> _diseases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupDiseasesStream();
  }

  @override
  void dispose() {
    _diseasesSubscription?.cancel();
    super.dispose();
  }

  void _setupDiseasesStream() {
    _diseasesSubscription = _diseaseService.allDiseasesStream().listen(
      (diseases) {
        if (mounted) {
          setState(() {
            _diseases = diseases;
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

  void _showAddDiseaseDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddEditDiseaseSheet(
        hasApiKey: _gptService.hasApiKey,
        onSave: (disease) async {
          await _diseaseService.addDisease(disease);
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Disease added successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
      ),
    );
  }

  void _showEditDiseaseDialog(Disease disease) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddEditDiseaseSheet(
        disease: disease,
        hasApiKey: _gptService.hasApiKey,
        onSave: (updatedDisease) async {
          await _diseaseService.updateDisease(disease.id, updatedDisease.toFirestore());
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Disease updated successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
      ),
    );
  }

  void _deleteDisease(Disease disease) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Disease'),
        content: Text('Are you sure you want to delete "${disease.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _diseaseService.deleteDisease(disease.id);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Disease deleted'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Manage Diseases',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDiseaseDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Disease'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _diseases.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _diseases.length,
                    itemBuilder: (context, index) {
                      final disease = _diseases[index];
                      return _DiseaseAdminCard(
                        disease: disease,
                        onEdit: () => _showEditDiseaseDialog(disease),
                        onDelete: () => _deleteDisease(disease),
                        onToggleActive: () =>
                            _diseaseService.toggleDiseaseActive(disease.id, !disease.isActive),
                        onToggleCommon: () =>
                            _diseaseService.toggleDiseaseCommon(disease.id, !disease.isCommon),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medical_services_outlined, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          const Text(
            'No diseases yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the button below to add disease info',
            style: TextStyle(fontSize: 14, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DISEASE ADMIN CARD
// ============================================================================

class _DiseaseAdminCard extends StatefulWidget {
  final Disease disease;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;
  final VoidCallback onToggleCommon;

  const _DiseaseAdminCard({
    required this.disease,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
    required this.onToggleCommon,
  });

  @override
  State<_DiseaseAdminCard> createState() => _DiseaseAdminCardState();
}

class _DiseaseAdminCardState extends State<_DiseaseAdminCard> {
  final AdminNotificationService _notificationService = AdminNotificationService();
  bool _isSendingNotification = false;

  Future<void> _sendNotification() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Send Notification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send push notification to all users about:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New Health Information',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.disease.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSendingNotification = true);

    try {
      final result = await _notificationService.sendDiseaseNotification(
        diseaseId: widget.disease.id,
        diseaseName: widget.disease.name,
        description: widget.disease.description,
        imageUrl: widget.disease.imageUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification sent to ${result['sentCount']} users'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingNotification = false);
      }
    }
  }

  Disease get disease => widget.disease;

  Color _getSeverityColor(DiseaseSeverity severity) {
    switch (severity) {
      case DiseaseSeverity.mild:
        return AppColors.success;
      case DiseaseSeverity.moderate:
        return AppColors.warning;
      case DiseaseSeverity.severe:
        return AppColors.error;
      case DiseaseSeverity.critical:
        return Colors.red.shade900;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: disease.isActive ? AppColors.surface : AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: disease.isCommon ? Border.all(color: AppColors.warning, width: 2) : null,
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
          onTap: widget.onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getSeverityColor(disease.severity).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        disease.severity.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getSeverityColor(disease.severity),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        disease.category.displayName,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                    const Spacer(),
                    if (disease.isCommon)
                      const Icon(Icons.star_rounded, color: AppColors.warning, size: 20),
                    if (!disease.isActive)
                      const Icon(Icons.visibility_off_rounded, color: AppColors.textHint, size: 20),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  disease.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: disease.isActive ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  disease.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: disease.isActive ? AppColors.textSecondary : AppColors.textHint,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.visibility_rounded, size: 14, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(
                      '${disease.viewCount} views',
                      style: TextStyle(fontSize: 12, color: AppColors.textHint),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: _isSendingNotification
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.notifications_active_rounded, color: AppColors.info),
                      onPressed: _isSendingNotification ? null : _sendNotification,
                      tooltip: 'Send notification',
                      iconSize: 22,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                    IconButton(
                      icon: Icon(
                        disease.isCommon ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: disease.isCommon ? AppColors.warning : AppColors.textHint,
                      ),
                      onPressed: widget.onToggleCommon,
                      tooltip: disease.isCommon ? 'Remove from common' : 'Mark as common',
                      iconSize: 22,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                    IconButton(
                      icon: Icon(
                        disease.isActive ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                        color: disease.isActive ? AppColors.success : AppColors.textHint,
                      ),
                      onPressed: widget.onToggleActive,
                      tooltip: disease.isActive ? 'Hide' : 'Show',
                      iconSize: 22,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                      onPressed: widget.onDelete,
                      tooltip: 'Delete',
                      iconSize: 22,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ADD/EDIT DISEASE SHEET - With AI Generation & Custom Prompt
// ============================================================================

class _AddEditDiseaseSheet extends StatefulWidget {
  final Disease? disease;
  final Function(Disease) onSave;
  final bool hasApiKey;

  const _AddEditDiseaseSheet({
    this.disease,
    required this.onSave,
    required this.hasApiKey,
  });

  @override
  State<_AddEditDiseaseSheet> createState() => _AddEditDiseaseSheetState();
}

class _AddEditDiseaseSheetState extends State<_AddEditDiseaseSheet> {
  final _formKey = GlobalKey<FormState>();
  final GPTService _gptService = GPTService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _symptomsController;
  late TextEditingController _causesController;
  late TextEditingController _preventionController;
  late TextEditingController _remediesController;
  late TextEditingController _whenToDoctorController;
  late TextEditingController _imageUrlController;
  late TextEditingController _customPromptController;

  late DiseaseCategory _category;
  late DiseaseSeverity _severity;
  late List<AgeGroup> _selectedAgeGroups;
  late bool _isCommon;
  ImageStyle _imageStyle = ImageStyle.realistic;

  bool _isSaving = false;
  bool _isGenerating = false;
  bool _isGeneratingImage = false;
  bool _useAI = true;
  String? _errorMessage;

  bool get isEditing => widget.disease != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.disease?.name ?? '');
    _descriptionController = TextEditingController(text: widget.disease?.description ?? '');
    _symptomsController = TextEditingController(text: widget.disease?.symptoms.join('\n') ?? '');
    _causesController = TextEditingController(text: widget.disease?.causes.join('\n') ?? '');
    _preventionController = TextEditingController(text: widget.disease?.prevention.join('\n') ?? '');
    _remediesController = TextEditingController(text: widget.disease?.homeRemedies.join('\n') ?? '');
    _whenToDoctorController = TextEditingController(text: widget.disease?.whenToSeeDoctor ?? '');
    _imageUrlController = TextEditingController(text: widget.disease?.imageUrl ?? '');
    _customPromptController = TextEditingController();

    _category = widget.disease?.category ?? DiseaseCategory.fever;
    _severity = widget.disease?.severity ?? DiseaseSeverity.mild;
    _selectedAgeGroups = widget.disease?.affectedAgeGroups ?? [AgeGroup.allAges];
    _isCommon = widget.disease?.isCommon ?? true;

    _useAI = !isEditing && widget.hasApiKey;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _symptomsController.dispose();
    _causesController.dispose();
    _preventionController.dispose();
    _remediesController.dispose();
    _whenToDoctorController.dispose();
    _imageUrlController.dispose();
    _customPromptController.dispose();
    super.dispose();
  }

  Future<void> _generateWithAI() async {
    if (_nameController.text.trim().isEmpty && _customPromptController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Enter a disease name or custom prompt');
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final prompt = _customPromptController.text.trim().isNotEmpty
          ? _customPromptController.text.trim()
          : 'Generate detailed information about "${_nameController.text.trim()}" disease for children';

      final fullPrompt = '''$prompt

Generate comprehensive information about this childhood disease. Include:
- A clear description of the disease
- Common symptoms (list each on new line)
- Main causes (list each on new line)
- Prevention methods (list each on new line)
- Safe home remedies for children (list each on new line)
- When parents should consult a doctor

Target audience: Indian parents
Focus on: ${_category.displayName} conditions
Severity level: ${_severity.displayName}
Age groups: ${_selectedAgeGroups.map((a) => a.displayName).join(', ')}

Respond ONLY with a valid JSON object (no markdown, no explanation) in this exact format:
{
  "name": "Disease name",
  "description": "Clear 2-3 sentence description",
  "symptoms": ["symptom 1", "symptom 2", "symptom 3"],
  "causes": ["cause 1", "cause 2"],
  "prevention": ["prevention tip 1", "prevention tip 2"],
  "homeRemedies": ["remedy 1", "remedy 2"],
  "whenToSeeDoctor": "Clear guidance on when to seek medical help"
}''';

      final response = await _gptService.chat(userMessage: fullPrompt);

      // Parse the JSON response
      String cleanedResponse = response.trim();
      if (cleanedResponse.startsWith('```json')) {
        cleanedResponse = cleanedResponse.substring(7);
      }
      if (cleanedResponse.startsWith('```')) {
        cleanedResponse = cleanedResponse.substring(3);
      }
      if (cleanedResponse.endsWith('```')) {
        cleanedResponse = cleanedResponse.substring(0, cleanedResponse.length - 3);
      }
      cleanedResponse = cleanedResponse.trim();

      final json = jsonDecode(cleanedResponse) as Map<String, dynamic>;

      final diseaseName = json['name'] ?? _nameController.text;

      setState(() {
        _nameController.text = diseaseName;
        _descriptionController.text = json['description'] ?? '';
        _symptomsController.text = (json['symptoms'] as List?)?.map((e) => e.toString()).join('\n') ?? '';
        _causesController.text = (json['causes'] as List?)?.map((e) => e.toString()).join('\n') ?? '';
        _preventionController.text = (json['prevention'] as List?)?.map((e) => e.toString()).join('\n') ?? '';
        _remediesController.text = (json['homeRemedies'] as List?)?.map((e) => e.toString()).join('\n') ?? '';
        _whenToDoctorController.text = json['whenToSeeDoctor'] ?? '';
        _isGenerating = false;
      });

      // Auto-generate image after content is generated
      if (diseaseName.isNotEmpty) {
        _generateImage(diseaseName);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Content generated! Generating image...'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _generateImage(String diseaseName) async {
    if (!_gptService.hasApiKey) return;

    setState(() => _isGeneratingImage = true);

    try {
      // Build safe, educational prompt that won't trigger safety filters

      // Category-specific safe visual elements (focus on wellness/care, not illness)
      String categoryVisuals = '';
      switch (_category) {
        case DiseaseCategory.respiratory:
          categoryVisuals = 'steam vaporizer, honey and lemon, warm soup, soft tissues, humidifier';
          break;
        case DiseaseCategory.digestive:
          categoryVisuals = 'ORS drink, bananas, rice porridge, probiotic yogurt, water bottle';
          break;
        case DiseaseCategory.skin:
          categoryVisuals = 'aloe vera plant, gentle lotion bottle, soft cotton cloth, calamine lotion';
          break;
        case DiseaseCategory.infectious:
          categoryVisuals = 'hand sanitizer, soap and water, face mask, vitamin C fruits';
          break;
        case DiseaseCategory.allergies:
          categoryVisuals = 'air purifier, antihistamine medicine box, clean bedding, dust-free room';
          break;
        case DiseaseCategory.fever:
          categoryVisuals = 'digital thermometer, cold compress, paracetamol syrup, water glass, cooling pad';
          break;
        case DiseaseCategory.nutritional:
          categoryVisuals = 'colorful fruits, green vegetables, milk glass, vitamin supplements, balanced meal plate';
          break;
        case DiseaseCategory.developmental:
          categoryVisuals = 'educational toys, colorful books, therapy balls, building blocks';
          break;
        case DiseaseCategory.other:
          categoryVisuals = 'first aid kit, medicine cabinet, health chart, stethoscope';
          break;
      }

      // Severity-based color palette
      String colorPalette = '';
      switch (_severity) {
        case DiseaseSeverity.mild:
          colorPalette = 'soft pastel colors, light green and blue tones, calming atmosphere';
          break;
        case DiseaseSeverity.moderate:
          colorPalette = 'warm orange and yellow tones, hopeful atmosphere';
          break;
        case DiseaseSeverity.severe:
          colorPalette = 'professional medical blue and white tones, clinical but caring';
          break;
        case DiseaseSeverity.critical:
          colorPalette = 'hospital blue and white, professional medical setting';
          break;
      }

      final imagePrompt = '''Create an educational healthcare illustration about "$diseaseName" awareness and prevention.

ILLUSTRATION CONCEPT:
A clean, professional wellness infographic-style illustration showing healthcare items and remedies associated with treating $diseaseName.

VISUAL ELEMENTS TO INCLUDE:
- Main items: $categoryVisuals
- Background: Clean Indian home kitchen or bedroom setting
- Additional: Caring parent's hands arranging the items, wellness books, health tips poster on wall

STYLE: ${_imageStyle.promptStyle}

COLOR SCHEME: $colorPalette

COMPOSITION:
- Flat lay or organized arrangement of wellness items
- Bright, well-lit, clean aesthetic
- Professional healthcare education style
- Warm, reassuring, and informative mood
- Focus on PREVENTION and CARE items, not illness

STRICT REQUIREMENTS:
- NO people's faces or full bodies
- NO sick or unwell individuals
- NO medical procedures or symptoms shown
- NO text, watermarks, or logos
- Focus ONLY on wellness items, remedies, and care products
- Safe, family-friendly, educational content
- Stock photo quality for health education''';

      final tempImageUrl = await _gptService.generateImage(prompt: imagePrompt);

      // Upload to Firebase Storage for permanent URL
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uploading image to storage...'),
            backgroundColor: AppColors.info,
            duration: Duration(seconds: 1),
          ),
        );
      }

      final permanentUrl = await _storageService.uploadImageFromUrl(
        imageUrl: tempImageUrl,
        folder: 'diseases',
        fileName: 'disease_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        setState(() {
          _imageUrlController.text = permanentUrl;
          _isGeneratingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image generated and saved!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image generation failed: ${e.toString()}'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _isGeneratingImage = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uploading image...'),
            backgroundColor: AppColors.info,
            duration: Duration(seconds: 1),
          ),
        );
      }

      // Upload to Firebase Storage
      final file = File(pickedFile.path);
      final bytes = await file.readAsBytes();

      final downloadUrl = await _storageService.uploadImageBytes(
        bytes: bytes,
        folder: 'diseases',
        fileName: 'disease_${DateTime.now().millisecondsSinceEpoch}',
        contentType: 'image/jpeg',
      );

      if (mounted) {
        setState(() {
          _imageUrlController.text = downloadUrl;
          _isGeneratingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final disease = Disease(
      id: widget.disease?.id ?? '',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      affectedAgeGroups: _selectedAgeGroups,
      severity: _severity,
      symptoms: _symptomsController.text.split('\n').where((s) => s.trim().isNotEmpty).toList(),
      causes: _causesController.text.split('\n').where((s) => s.trim().isNotEmpty).toList(),
      prevention: _preventionController.text.split('\n').where((s) => s.trim().isNotEmpty).toList(),
      homeRemedies: _remediesController.text.split('\n').where((s) => s.trim().isNotEmpty).toList(),
      whenToSeeDoctor: _whenToDoctorController.text.trim(),
      imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
      isCommon: _isCommon,
      isActive: widget.disease?.isActive ?? true,
      viewCount: widget.disease?.viewCount ?? 0,
      createdAt: widget.disease?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await widget.onSave(disease);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Form(
            key: _formKey,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.1)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        isEditing ? 'Edit Disease' : 'Add Disease',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isSaving || _isGenerating ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(isEditing ? 'Update' : 'Add'),
                      ),
                    ],
                  ),
                ),

                // Form Fields
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Mode Toggle
                      if (!isEditing && widget.hasApiKey) ...[
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _useAI = true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      color: _useAI ? AppColors.primary : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.auto_awesome, size: 20,
                                            color: _useAI ? Colors.white : AppColors.textSecondary),
                                        const SizedBox(width: 8),
                                        Text('AI Generate',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: _useAI ? Colors.white : AppColors.textSecondary,
                                            )),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _useAI = false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      color: !_useAI ? AppColors.primary : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.edit_note_rounded, size: 20,
                                            color: !_useAI ? Colors.white : AppColors.textSecondary),
                                        const SizedBox(width: 8),
                                        Text('Manual',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: !_useAI ? Colors.white : AppColors.textSecondary,
                                            )),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Category & Severity
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<DiseaseCategory>(
                              value: _category,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(),
                              ),
                              items: DiseaseCategory.values.map((c) {
                                return DropdownMenuItem(value: c, child: Text(c.displayName));
                              }).toList(),
                              onChanged: (v) => setState(() => _category = v!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<DiseaseSeverity>(
                              value: _severity,
                              decoration: const InputDecoration(
                                labelText: 'Severity',
                                border: OutlineInputBorder(),
                              ),
                              items: DiseaseSeverity.values.map((s) {
                                return DropdownMenuItem(value: s, child: Text(s.displayName));
                              }).toList(),
                              onChanged: (v) => setState(() => _severity = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Age Groups
                      const Text('Affected Age Groups',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AgeGroup.values.map((age) {
                          final isSelected = _selectedAgeGroups.contains(age);
                          return FilterChip(
                            label: Text(age.displayName),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedAgeGroups.add(age);
                                } else {
                                  _selectedAgeGroups.remove(age);
                                }
                              });
                            },
                            selectedColor: AppColors.primary.withValues(alpha: 0.2),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Custom Prompt (AI mode)
                      if (_useAI && !isEditing && widget.hasApiKey) ...[
                        TextFormField(
                          controller: _customPromptController,
                          decoration: InputDecoration(
                            labelText: 'Custom Prompt (optional)',
                            hintText: 'e.g., "Tell me about common cold with Indian home remedies"',
                            border: const OutlineInputBorder(),
                            prefixIcon: Icon(Icons.psychology_rounded, color: AppColors.secondary),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),

                        // Generate Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isGenerating ? null : _generateWithAI,
                            icon: _isGenerating
                                ? const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.auto_awesome),
                            label: Text(_isGenerating ? 'Generating...' : 'Generate with AI'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: AppColors.error, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(_errorMessage!,
                                      style: TextStyle(color: AppColors.error, fontSize: 13)),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                      ],

                      // Disease Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Disease Name *',
                          hintText: 'e.g., Common Cold, Chickenpox',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description *',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                        validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Symptoms
                      TextFormField(
                        controller: _symptomsController,
                        decoration: const InputDecoration(
                          labelText: 'Symptoms (one per line)',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),

                      // Causes
                      TextFormField(
                        controller: _causesController,
                        decoration: const InputDecoration(
                          labelText: 'Causes (one per line)',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Prevention
                      TextFormField(
                        controller: _preventionController,
                        decoration: const InputDecoration(
                          labelText: 'Prevention Tips (one per line)',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),

                      // Home Remedies
                      TextFormField(
                        controller: _remediesController,
                        decoration: const InputDecoration(
                          labelText: 'Home Remedies (one per line)',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),

                      // When to See Doctor
                      TextFormField(
                        controller: _whenToDoctorController,
                        decoration: const InputDecoration(
                          labelText: 'When to See a Doctor',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Image Style Selector (for AI mode)
                      if (_useAI && widget.hasApiKey) ...[
                        DropdownButtonFormField<ImageStyle>(
                          value: _imageStyle,
                          decoration: InputDecoration(
                            labelText: 'Image Style',
                            border: const OutlineInputBorder(),
                            prefixIcon: Icon(Icons.palette_rounded, color: AppColors.secondary),
                          ),
                          items: ImageStyle.values.map((style) {
                            return DropdownMenuItem(
                              value: style,
                              child: Text(style.displayName),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _imageStyle = v!),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Image Preview & Generation
                      if (_imageUrlController.text.isNotEmpty) ...[
                        const Text(
                          'Generated Image:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                _imageUrlController.text,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    height: 200,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Center(child: CircularProgressIndicator()),
                                  );
                                },
                                errorBuilder: (_, __, ___) => Container(
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.broken_image_rounded, size: 48, color: AppColors.textHint),
                                  ),
                                ),
                              ),
                            ),
                            if (_isGeneratingImage)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black45,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(color: Colors.white),
                                        SizedBox(height: 12),
                                        Text('Generating new image...', style: TextStyle(color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (_useAI && widget.hasApiKey)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isGeneratingImage
                                      ? null
                                      : () => _generateImage(_nameController.text),
                                  icon: const Icon(Icons.auto_awesome, size: 18),
                                  label: const Text('AI Generate'),
                                ),
                              ),
                            if (_useAI && widget.hasApiKey)
                              const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isGeneratingImage ? null : _pickImage,
                                icon: const Icon(Icons.upload_rounded, size: 18),
                                label: const Text('Upload'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => setState(() => _imageUrlController.clear()),
                                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                label: const Text('Remove'),
                                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ] else ...[
                        // Image buttons when no image yet
                        const Text(
                          'Add Image',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (_useAI && widget.hasApiKey && _nameController.text.isNotEmpty)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isGeneratingImage
                                      ? null
                                      : () => _generateImage(_nameController.text),
                                  icon: _isGeneratingImage
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.auto_awesome, size: 18),
                                  label: Text(_isGeneratingImage ? 'Generating...' : 'AI Generate'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            if (_useAI && widget.hasApiKey && _nameController.text.isNotEmpty)
                              const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isGeneratingImage ? null : _pickImage,
                                icon: _isGeneratingImage && !(_useAI && widget.hasApiKey)
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.upload_rounded, size: 18),
                                label: const Text('Upload Image'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Common Toggle
                      SwitchListTile(
                        value: _isCommon,
                        onChanged: (v) => setState(() => _isCommon = v),
                        title: const Text('Mark as Common Disease'),
                        subtitle: const Text('Will be shown in common diseases list'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

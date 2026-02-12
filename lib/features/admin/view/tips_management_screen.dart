import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/tip_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/gpt_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/admin_notification_service.dart';
import '../../../core/models/parenting_tip.dart';
import '../../../core/models/app_language.dart';

/// Admin screen for managing parenting tips
class TipsManagementScreen extends StatefulWidget {
  const TipsManagementScreen({super.key});

  @override
  State<TipsManagementScreen> createState() => _TipsManagementScreenState();
}

class _TipsManagementScreenState extends State<TipsManagementScreen> {
  final TipService _tipService = TipService();
  final AuthService _authService = AuthService();
  final GPTService _gptService = GPTService();
  StreamSubscription<List<ParentingTip>>? _tipsSubscription;
  List<ParentingTip> _tips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupTipsStream();
  }

  @override
  void dispose() {
    _tipsSubscription?.cancel();
    super.dispose();
  }

  void _setupTipsStream() {
    _tipsSubscription = _tipService.allTipsStream().listen(
      (tips) {
        if (mounted) {
          setState(() {
            _tips = tips;
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

  void _showAddTipDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddEditTipSheet(
        hasApiKey: _gptService.hasApiKey,
        onSave: (tip) async {
          await _tipService.addTip(tip);
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tip added successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        createdBy: _authService.currentUser?.uid ?? '',
      ),
    );
  }

  void _showEditTipDialog(ParentingTip tip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddEditTipSheet(
        tip: tip,
        hasApiKey: _gptService.hasApiKey,
        onSave: (updatedTip) async {
          await _tipService.updateTip(tip.id, updatedTip.toFirestore());
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tip updated successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        createdBy: _authService.currentUser?.uid ?? '',
      ),
    );
  }

  void _deleteTip(ParentingTip tip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Tip'),
        content: Text('Are you sure you want to delete "${tip.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _tipService.deleteTip(tip.id);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tip deleted'),
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
          'Manage Tips',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTipDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Tip'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _tips.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tips.length,
                    itemBuilder: (context, index) {
                      final tip = _tips[index];
                      return _TipAdminCard(
                        tip: tip,
                        onEdit: () => _showEditTipDialog(tip),
                        onDelete: () => _deleteTip(tip),
                        onToggleActive: () => _tipService.toggleTipActive(tip.id, !tip.isActive),
                        onToggleFeatured: () => _tipService.toggleTipFeatured(tip.id, !tip.isFeatured),
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
          Icon(Icons.lightbulb_outline_rounded, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          const Text(
            'No tips yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the button below to add your first tip',
            style: TextStyle(fontSize: 14, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TIP ADMIN CARD
// ============================================================================

class _TipAdminCard extends StatefulWidget {
  final ParentingTip tip;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;
  final VoidCallback onToggleFeatured;

  const _TipAdminCard({
    required this.tip,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
    required this.onToggleFeatured,
  });

  @override
  State<_TipAdminCard> createState() => _TipAdminCardState();
}

class _TipAdminCardState extends State<_TipAdminCard> {
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
                    'New Parenting Tip',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.tip.title,
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
      final result = await _notificationService.sendTipNotification(
        tipId: widget.tip.id,
        tipTitle: widget.tip.title,
        tipSummary: widget.tip.displaySummary,
        imageUrl: widget.tip.imageUrl,
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

  ParentingTip get tip => widget.tip;

  Color _getCategoryColor(TipCategory category) {
    switch (category) {
      case TipCategory.nutrition:
        return AppColors.primary;
      case TipCategory.sleep:
        return AppColors.lavender;
      case TipCategory.development:
        return AppColors.peach;
      case TipCategory.health:
        return AppColors.success;
      case TipCategory.safety:
        return AppColors.error;
      case TipCategory.bonding:
        return AppColors.secondary;
      case TipCategory.behavior:
        return AppColors.warning;
      case TipCategory.education:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: tip.isActive ? AppColors.surface : AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: tip.isFeatured
            ? Border.all(color: AppColors.warning, width: 2)
            : null,
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
                    // Category Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(tip.category).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tip.category.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getCategoryColor(tip.category),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Age Group
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tip.ageGroup.displayName,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Status indicators
                    if (tip.isFeatured)
                      const Icon(Icons.star_rounded, color: AppColors.warning, size: 20),
                    if (!tip.isActive)
                      const Icon(Icons.visibility_off_rounded, color: AppColors.textHint, size: 20),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  tip.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: tip.isActive ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  tip.displaySummary,
                  style: TextStyle(
                    fontSize: 13,
                    color: tip.isActive ? AppColors.textSecondary : AppColors.textHint,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 14, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(
                      '${tip.readTimeMinutes} min read',
                      style: TextStyle(fontSize: 12, color: AppColors.textHint),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.visibility_rounded, size: 14, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(
                      '${tip.viewCount} views',
                      style: TextStyle(fontSize: 12, color: AppColors.textHint),
                    ),
                    const Spacer(),
                    // Action buttons
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
                        tip.isFeatured ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: tip.isFeatured ? AppColors.warning : AppColors.textHint,
                      ),
                      onPressed: widget.onToggleFeatured,
                      tooltip: tip.isFeatured ? 'Remove from featured' : 'Mark as featured',
                      iconSize: 22,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                    IconButton(
                      icon: Icon(
                        tip.isActive ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                        color: tip.isActive ? AppColors.success : AppColors.textHint,
                      ),
                      onPressed: widget.onToggleActive,
                      tooltip: tip.isActive ? 'Hide tip' : 'Show tip',
                      iconSize: 22,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                      onPressed: widget.onDelete,
                      tooltip: 'Delete tip',
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
// ADD/EDIT TIP SHEET - With AI Generation
// ============================================================================

class _AddEditTipSheet extends StatefulWidget {
  final ParentingTip? tip;
  final Function(ParentingTip) onSave;
  final String createdBy;
  final bool hasApiKey;

  const _AddEditTipSheet({
    this.tip,
    required this.onSave,
    required this.createdBy,
    required this.hasApiKey,
  });

  @override
  State<_AddEditTipSheet> createState() => _AddEditTipSheetState();
}

class _AddEditTipSheetState extends State<_AddEditTipSheet> {
  final _formKey = GlobalKey<FormState>();
  final GPTService _gptService = GPTService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();

  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _summaryController;
  late TextEditingController _imageUrlController;
  late TextEditingController _readTimeController;
  late TextEditingController _tagsController;
  late TextEditingController _customPromptController;
  late TipCategory _category;
  late AgeGroup _ageGroup;
  late bool _isFeatured;
  AppLanguage _language = AppLanguage.english;
  ImageStyle _imageStyle = ImageStyle.realistic;

  bool _isSaving = false;
  bool _isGenerating = false;
  bool _isUploadingImage = false;
  bool _useAI = true; // Default to AI mode when adding new
  String? _errorMessage;

  bool get isEditing => widget.tip != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.tip?.title ?? '');
    _contentController = TextEditingController(text: widget.tip?.content ?? '');
    _summaryController = TextEditingController(text: widget.tip?.summary ?? '');
    _imageUrlController = TextEditingController(text: widget.tip?.imageUrl ?? '');
    _readTimeController = TextEditingController(
      text: widget.tip?.readTimeMinutes.toString() ?? '3',
    );
    _tagsController = TextEditingController(
      text: widget.tip?.tags.join(', ') ?? '',
    );
    _customPromptController = TextEditingController();
    _category = widget.tip?.category ?? TipCategory.development;
    _ageGroup = widget.tip?.ageGroup ?? AgeGroup.allAges;
    _isFeatured = widget.tip?.isFeatured ?? false;

    // Default to Custom mode when editing
    _useAI = !isEditing && widget.hasApiKey;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _summaryController.dispose();
    _imageUrlController.dispose();
    _readTimeController.dispose();
    _tagsController.dispose();
    _customPromptController.dispose();
    super.dispose();
  }

  Future<void> _generateWithAI() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final customPrompt = _customPromptController.text.trim();
      final generatedTip = await _gptService.generateTip(
        category: _category,
        ageGroup: _ageGroup,
        language: _language,
        imageStyle: _imageStyle,
        customPrompt: customPrompt.isNotEmpty ? customPrompt : null,
      );

      setState(() {
        _titleController.text = generatedTip.title;
        _summaryController.text = generatedTip.summary;
        _contentController.text = generatedTip.content;
        _tagsController.text = generatedTip.tags.join(', ');
        _readTimeController.text = generatedTip.readTimeMinutes.toString();
        if (generatedTip.imageUrl != null) {
          _imageUrlController.text = generatedTip.imageUrl!;
        }
        _isGenerating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(generatedTip.imageUrl != null
                ? 'Tip & image generated! Review and edit before saving.'
                : 'Tip generated! Review and edit before saving.'),
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

  Future<void> _generateImage() async {
    if (!_gptService.hasApiKey) return;
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title first'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isUploadingImage = true);

    try {
      final title = _titleController.text.trim();
      final imagePrompt = '''Create an image for a parenting article about "$title".
Topic: ${_category.displayName} for ${_ageGroup.displayName} age group.
Feature Indian parents and children in a warm home/family setting.
${_imageStyle.promptStyle}
No text, watermarks, or logos in image.
Safe, family-friendly content.''';

      final tempImageUrl = await _gptService.generateImage(prompt: imagePrompt);

      // Upload to Firebase Storage for permanent URL
      final permanentUrl = await _storageService.uploadImageFromUrl(
        imageUrl: tempImageUrl,
        folder: 'tips',
        fileName: 'tip_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        setState(() {
          _imageUrlController.text = permanentUrl;
          _isUploadingImage = false;
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
        setState(() => _isUploadingImage = false);
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

      setState(() => _isUploadingImage = true);

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
        folder: 'tips',
        fileName: 'tip_${DateTime.now().millisecondsSinceEpoch}',
        contentType: 'image/jpeg',
      );

      if (mounted) {
        setState(() {
          _imageUrlController.text = downloadUrl;
          _isUploadingImage = false;
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
        setState(() => _isUploadingImage = false);
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

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final tip = ParentingTip(
      id: widget.tip?.id ?? '',
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      summary: _summaryController.text.trim().isEmpty ? null : _summaryController.text.trim(),
      category: _category,
      ageGroup: _ageGroup,
      imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
      readTimeMinutes: int.tryParse(_readTimeController.text) ?? 3,
      tags: tags,
      isActive: widget.tip?.isActive ?? true,
      isFeatured: _isFeatured,
      viewCount: widget.tip?.viewCount ?? 0,
      createdBy: widget.tip?.createdBy ?? widget.createdBy,
      createdAt: widget.tip?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await widget.onSave(tip);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
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
                        isEditing ? 'Edit Tip' : 'Add New Tip',
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
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
                      // Mode Toggle (only for new tips)
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
                                        Icon(
                                          Icons.auto_awesome,
                                          size: 20,
                                          color: _useAI ? Colors.white : AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'AI Generate',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: _useAI ? Colors.white : AppColors.textSecondary,
                                          ),
                                        ),
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
                                        Icon(
                                          Icons.edit_note_rounded,
                                          size: 20,
                                          color: !_useAI ? Colors.white : AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Custom',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: !_useAI ? Colors.white : AppColors.textSecondary,
                                          ),
                                        ),
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

                      // Category & Age Group Row (always visible)
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<TipCategory>(
                              value: _category,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(),
                              ),
                              items: TipCategory.values.map((c) {
                                return DropdownMenuItem(
                                  value: c,
                                  child: Text(c.displayName),
                                );
                              }).toList(),
                              onChanged: (v) => setState(() => _category = v!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<AgeGroup>(
                              value: _ageGroup,
                              decoration: const InputDecoration(
                                labelText: 'Age Group',
                                border: OutlineInputBorder(),
                              ),
                              items: AgeGroup.values.map((a) {
                                return DropdownMenuItem(
                                  value: a,
                                  child: Text(a.displayName),
                                );
                              }).toList(),
                              onChanged: (v) => setState(() => _ageGroup = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Language & Image Style Selectors (for AI generation)
                      if (_useAI && !isEditing && widget.hasApiKey) ...[
                        DropdownButtonFormField<AppLanguage>(
                          value: _language,
                          decoration: InputDecoration(
                            labelText: 'Generate in Language',
                            border: const OutlineInputBorder(),
                            prefixIcon: Icon(Icons.translate_rounded, color: AppColors.primary),
                          ),
                          items: AppLanguage.values.map((lang) {
                            return DropdownMenuItem(
                              value: lang,
                              child: Text(lang.displayName),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _language = v!),
                        ),
                        const SizedBox(height: 16),

                        // Image Style Selector
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

                        // Custom Prompt Field
                        TextFormField(
                          controller: _customPromptController,
                          decoration: InputDecoration(
                            labelText: 'Custom Prompt (optional)',
                            hintText: 'e.g., "Write about importance of breastfeeding for newborns"',
                            border: const OutlineInputBorder(),
                            prefixIcon: Icon(Icons.psychology_rounded, color: AppColors.secondary),
                            helperText: 'Leave empty for auto-generated topic based on category & age',
                            helperMaxLines: 2,
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // AI Generate Button (when in AI mode and creating new)
                      if (_useAI && !isEditing && widget.hasApiKey) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isGenerating ? null : _generateWithAI,
                            icon: _isGenerating
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.auto_awesome),
                            label: Text(_isGenerating ? 'Generating...' : 'Generate with GPT-4o'),
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
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(color: AppColors.error, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          'Generated content (edit before saving):',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          hintText: 'Enter tip title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Summary
                      TextFormField(
                        controller: _summaryController,
                        decoration: const InputDecoration(
                          labelText: 'Summary (optional)',
                          hintText: 'Short summary for card display',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      // Content
                      TextFormField(
                        controller: _contentController,
                        decoration: const InputDecoration(
                          labelText: 'Content *',
                          hintText: 'Full tip content',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 8,
                        validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Image Preview and Upload Section
                      if (_imageUrlController.text.isNotEmpty) ...[
                        const Text(
                          'Tip Image:',
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
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _imageUrlController.text,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    height: 180,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 180,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.broken_image_rounded, size: 48, color: AppColors.textHint),
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (_isUploadingImage)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black45,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(color: Colors.white),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (widget.hasApiKey)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isUploadingImage ? null : _generateImage,
                                  icon: const Icon(Icons.auto_awesome, size: 18),
                                  label: const Text('AI Generate'),
                                ),
                              ),
                            if (widget.hasApiKey)
                              const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isUploadingImage ? null : _pickImage,
                                icon: const Icon(Icons.upload_rounded, size: 18),
                                label: const Text('Upload'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  setState(() => _imageUrlController.clear());
                                },
                                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                label: const Text('Remove'),
                                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ] else ...[
                        // Image buttons when no image
                        const Text(
                          'Add Image (optional)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (widget.hasApiKey && _titleController.text.isNotEmpty)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isUploadingImage ? null : _generateImage,
                                  icon: _isUploadingImage
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.auto_awesome, size: 18),
                                  label: Text(_isUploadingImage ? 'Generating...' : 'AI Generate'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            if (widget.hasApiKey && _titleController.text.isNotEmpty)
                              const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isUploadingImage ? null : _pickImage,
                                icon: const Icon(Icons.upload_rounded, size: 18),
                                label: const Text('Upload'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Read Time & Featured Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _readTimeController,
                              decoration: const InputDecoration(
                                labelText: 'Read time (min)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SwitchListTile(
                              value: _isFeatured,
                              onChanged: (v) => setState(() => _isFeatured = v),
                              title: const Text('Featured'),
                              subtitle: const Text('Show in marquee'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Tags
                      TextFormField(
                        controller: _tagsController,
                        decoration: const InputDecoration(
                          labelText: 'Tags (comma separated)',
                          hintText: 'feeding, newborn, tips',
                          border: OutlineInputBorder(),
                        ),
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

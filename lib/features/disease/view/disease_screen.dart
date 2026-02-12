import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/disease_service.dart';
import '../../../core/models/disease.dart';
import '../../../core/models/parenting_tip.dart';
import 'disease_detail_screen.dart';

/// Disease information screen - Learn about common childhood diseases
class DiseaseScreen extends StatefulWidget {
  const DiseaseScreen({super.key});

  @override
  State<DiseaseScreen> createState() => _DiseaseScreenState();
}

class _DiseaseScreenState extends State<DiseaseScreen> {
  final DiseaseService _diseaseService = DiseaseService();
  StreamSubscription<List<Disease>>? _diseasesSubscription;
  List<Disease> _allDiseases = [];
  List<Disease> _filteredDiseases = [];
  bool _isLoading = true;

  AgeGroup? _selectedAgeGroup;
  DiseaseCategory? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupDiseasesStream();
  }

  @override
  void dispose() {
    _diseasesSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _setupDiseasesStream() {
    _diseasesSubscription = _diseaseService.activeDiseases().listen(
      (diseases) {
        if (mounted) {
          setState(() {
            _allDiseases = diseases;
            _applyFilters();
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

  void _applyFilters() {
    List<Disease> filtered = _allDiseases;

    // Filter by age group
    if (_selectedAgeGroup != null) {
      filtered = filtered
          .where((d) => d.affectedAgeGroups.contains(_selectedAgeGroup))
          .toList();
    }

    // Filter by category
    if (_selectedCategory != null) {
      filtered =
          filtered.where((d) => d.category == _selectedCategory).toList();
    }

    // Filter by search query
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered
          .where((d) =>
              d.name.toLowerCase().contains(query) ||
              d.description.toLowerCase().contains(query) ||
              d.symptoms.any((s) => s.toLowerCase().contains(query)))
          .toList();
    }

    _filteredDiseases = filtered;
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FilterSheet(
        selectedAgeGroup: _selectedAgeGroup,
        selectedCategory: _selectedCategory,
        onApply: (ageGroup, category) {
          setState(() {
            _selectedAgeGroup = ageGroup;
            _selectedCategory = category;
            _applyFilters();
          });
          Navigator.pop(context);
        },
        onClear: () {
          setState(() {
            _selectedAgeGroup = null;
            _selectedCategory = null;
            _applyFilters();
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Common Diseases',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list_rounded, color: AppColors.textPrimary),
                onPressed: _showFilters,
              ),
              if (_selectedAgeGroup != null || _selectedCategory != null)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surface,
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _applyFilters());
                },
                decoration: InputDecoration(
                  hintText: 'Search diseases, symptoms...',
                  hintStyle: TextStyle(color: AppColors.textHint),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _applyFilters());
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),

            // Active Filters Chips
            if (_selectedAgeGroup != null || _selectedCategory != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    if (_selectedAgeGroup != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(_selectedAgeGroup!.displayName),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            setState(() {
                              _selectedAgeGroup = null;
                              _applyFilters();
                            });
                          },
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          labelStyle: const TextStyle(color: AppColors.primary, fontSize: 12),
                          deleteIconColor: AppColors.primary,
                        ),
                      ),
                    if (_selectedCategory != null)
                      Chip(
                        label: Text(_selectedCategory!.displayName),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            _selectedCategory = null;
                            _applyFilters();
                          });
                        },
                        backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                        labelStyle: const TextStyle(color: AppColors.secondary, fontSize: 12),
                        deleteIconColor: AppColors.secondary,
                      ),
                  ],
                ),
              ),

            // Disease List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredDiseases.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredDiseases.length,
                          itemBuilder: (context, index) {
                            return _DiseaseCard(
                              disease: _filteredDiseases[index],
                              onTap: () => _openDiseaseDetail(_filteredDiseases[index]),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDiseaseDetail(Disease disease) {
    _diseaseService.incrementViewCount(disease.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiseaseDetailScreen(disease: disease),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          const Text(
            'No diseases found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'Try a different search term'
                : 'No diseases match your filters',
            style: TextStyle(fontSize: 14, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DISEASE CARD
// ============================================================================

class _DiseaseCard extends StatelessWidget {
  final Disease disease;
  final VoidCallback onTap;

  const _DiseaseCard({required this.disease, required this.onTap});

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

  IconData _getCategoryIcon(DiseaseCategory category) {
    switch (category) {
      case DiseaseCategory.respiratory:
        return Icons.air_rounded;
      case DiseaseCategory.digestive:
        return Icons.restaurant_rounded;
      case DiseaseCategory.skin:
        return Icons.face_rounded;
      case DiseaseCategory.infectious:
        return Icons.coronavirus_rounded;
      case DiseaseCategory.allergies:
        return Icons.grass_rounded;
      case DiseaseCategory.fever:
        return Icons.thermostat_rounded;
      case DiseaseCategory.nutritional:
        return Icons.food_bank_rounded;
      case DiseaseCategory.developmental:
        return Icons.child_care_rounded;
      case DiseaseCategory.other:
        return Icons.medical_services_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            child: Row(
              children: [
                // Disease Image or Category Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: disease.imageUrl != null && disease.imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: CachedNetworkImage(
                            imageUrl: disease.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              _getCategoryIcon(disease.category),
                              color: AppColors.primary,
                              size: 32,
                            ),
                          ),
                        )
                      : Icon(
                          _getCategoryIcon(disease.category),
                          color: AppColors.primary,
                          size: 32,
                        ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              disease.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getSeverityColor(disease.severity).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              disease.severity.displayName,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _getSeverityColor(disease.severity),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        disease.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.local_hospital_rounded, size: 14, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text(
                            disease.category.displayName,
                            style: TextStyle(fontSize: 11, color: AppColors.textHint),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.visibility_rounded, size: 14, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text(
                            '${disease.viewCount}',
                            style: TextStyle(fontSize: 11, color: AppColors.textHint),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// FILTER SHEET
// ============================================================================

class _FilterSheet extends StatefulWidget {
  final AgeGroup? selectedAgeGroup;
  final DiseaseCategory? selectedCategory;
  final Function(AgeGroup?, DiseaseCategory?) onApply;
  final VoidCallback onClear;

  const _FilterSheet({
    this.selectedAgeGroup,
    this.selectedCategory,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late AgeGroup? _ageGroup;
  late DiseaseCategory? _category;

  @override
  void initState() {
    super.initState();
    _ageGroup = widget.selectedAgeGroup;
    _category = widget.selectedCategory;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Filter Diseases',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: widget.onClear,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Age Group Filter
          const Text(
            'Age Group',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AgeGroup.values.map((age) {
              final isSelected = _ageGroup == age;
              return ChoiceChip(
                label: Text(age.displayName),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _ageGroup = selected ? age : null);
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Category Filter
          const Text(
            'Category',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DiseaseCategory.values.map((cat) {
              final isSelected = _category == cat;
              return ChoiceChip(
                label: Text(cat.displayName),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _category = selected ? cat : null);
                },
                selectedColor: AppColors.secondary.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.secondary : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Apply Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onApply(_ageGroup, _category),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Apply Filters'),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

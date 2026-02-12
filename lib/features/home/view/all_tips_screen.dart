import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/tip_service.dart';
import '../../../core/models/parenting_tip.dart';
import 'tip_detail_screen.dart';

/// Screen showing all parenting tips with filters
class AllTipsScreen extends StatefulWidget {
  final TipCategory? initialCategory;

  const AllTipsScreen({super.key, this.initialCategory});

  @override
  State<AllTipsScreen> createState() => _AllTipsScreenState();
}

class _AllTipsScreenState extends State<AllTipsScreen> {
  final TipService _tipService = TipService();
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<List<ParentingTip>>? _tipsSubscription;

  List<ParentingTip> _allTips = [];
  List<ParentingTip> _filteredTips = [];
  bool _isLoading = true;
  String _searchQuery = '';
  TipCategory? _selectedCategory;
  AgeGroup? _selectedAgeGroup;
  String _sortBy = 'newest'; // newest, oldest, popular

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _setupTipsStream();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tipsSubscription?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _setupTipsStream() {
    _tipsSubscription = _tipService.activeTipsStream().listen(
      (tips) {
        if (mounted) {
          setState(() {
            _allTips = tips;
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

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _applyFilters();
    });
  }

  void _applyFilters() {
    var filtered = _allTips.where((tip) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final matchesSearch = tip.title.toLowerCase().contains(_searchQuery) ||
            tip.content.toLowerCase().contains(_searchQuery) ||
            tip.tags.any((tag) => tag.toLowerCase().contains(_searchQuery));
        if (!matchesSearch) return false;
      }

      // Category filter
      if (_selectedCategory != null && tip.category != _selectedCategory) {
        return false;
      }

      // Age group filter
      if (_selectedAgeGroup != null && tip.ageGroup != _selectedAgeGroup) {
        return false;
      }

      return true;
    }).toList();

    // Apply sorting
    switch (_sortBy) {
      case 'oldest':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'popular':
        filtered.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        break;
      case 'newest':
      default:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    _filteredTips = filtered;
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterSheet(
        selectedCategory: _selectedCategory,
        selectedAgeGroup: _selectedAgeGroup,
        sortBy: _sortBy,
        onApply: (category, ageGroup, sort) {
          setState(() {
            _selectedCategory = category;
            _selectedAgeGroup = ageGroup;
            _sortBy = sort;
            _applyFilters();
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedAgeGroup = null;
      _sortBy = 'newest';
      _searchController.clear();
      _searchQuery = '';
      _applyFilters();
    });
  }

  bool get _hasActiveFilters =>
      _selectedCategory != null || _selectedAgeGroup != null || _sortBy != 'newest';

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
          'Parenting Tips',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.clear_all_rounded, color: AppColors.textSecondary),
              onPressed: _clearFilters,
              tooltip: 'Clear filters',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search & Filter Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  // Search Bar
                  Expanded(
                    child: Container(
                      height: 48,
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
                          hintText: 'Search tips...',
                          hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary, size: 18),
                                  onPressed: () => _searchController.clear(),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Filter Button
                  InkWell(
                    onTap: _showFilterSheet,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _hasActiveFilters ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.textSecondary.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: _hasActiveFilters ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Category Chips
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildCategoryChip(null, 'All'),
                  ...TipCategory.values.map((c) => _buildCategoryChip(c, c.displayName)),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Results count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    '${_filteredTips.length} tips',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const Spacer(),
                  Text(
                    _sortBy == 'newest'
                        ? 'Newest first'
                        : _sortBy == 'oldest'
                            ? 'Oldest first'
                            : 'Most popular',
                    style: TextStyle(color: AppColors.textHint, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Tips List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredTips.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _filteredTips.length,
                          itemBuilder: (context, index) {
                            final tip = _filteredTips[index];
                            return _TipListCard(
                              tip: tip,
                              onTap: () {
                                _tipService.incrementViewCount(tip.id);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TipDetailScreen(tip: tip),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(TipCategory? category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCategory = category;
            _applyFilters();
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
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
          Icon(Icons.search_off_rounded, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          const Text(
            'No tips found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your filters',
            style: TextStyle(fontSize: 14, color: AppColors.textHint),
          ),
          if (_hasActiveFilters) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear filters'),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// TIP LIST CARD
// ============================================================================

class _TipListCard extends StatelessWidget {
  final ParentingTip tip;
  final VoidCallback onTap;

  const _TipListCard({required this.tip, required this.onTap});

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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                if (tip.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: tip.imageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 80,
                        height: 80,
                        color: AppColors.background,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        color: _getCategoryColor(tip.category).withValues(alpha: 0.1),
                        child: Icon(
                          Icons.lightbulb_rounded,
                          color: _getCategoryColor(tip.category),
                          size: 32,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(tip.category).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.lightbulb_rounded,
                      color: _getCategoryColor(tip.category),
                      size: 32,
                    ),
                  ),

                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category & Date
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(tip.category).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tip.category.displayName,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _getCategoryColor(tip.category),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatDate(tip.createdAt),
                            style: TextStyle(fontSize: 11, color: AppColors.textHint),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Title
                      Text(
                        tip.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Summary
                      Text(
                        tip.displaySummary,
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Meta info
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 12, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text(
                            '${tip.readTimeMinutes} min',
                            style: TextStyle(fontSize: 11, color: AppColors.textHint),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.child_care_rounded, size: 12, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text(
                            tip.ageGroup.displayName,
                            style: TextStyle(fontSize: 11, color: AppColors.textHint),
                          ),
                        ],
                      ),
                    ],
                  ),
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
// FILTER SHEET
// ============================================================================

class _FilterSheet extends StatefulWidget {
  final TipCategory? selectedCategory;
  final AgeGroup? selectedAgeGroup;
  final String sortBy;
  final Function(TipCategory?, AgeGroup?, String) onApply;

  const _FilterSheet({
    this.selectedCategory,
    this.selectedAgeGroup,
    required this.sortBy,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late TipCategory? _category;
  late AgeGroup? _ageGroup;
  late String _sort;

  @override
  void initState() {
    super.initState();
    _category = widget.selectedCategory;
    _ageGroup = widget.selectedAgeGroup;
    _sort = widget.sortBy;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Text(
                  'Filter & Sort',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _category = null;
                      _ageGroup = null;
                      _sort = 'newest';
                    });
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Age Group
            const Text(
              'Age Group',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildChip(null, 'All Ages', _ageGroup == null, () => setState(() => _ageGroup = null)),
                ...AgeGroup.values.map((a) => _buildChip(
                      a,
                      a.displayName,
                      _ageGroup == a,
                      () => setState(() => _ageGroup = a),
                    )),
              ],
            ),
            const SizedBox(height: 24),

            // Sort By
            const Text(
              'Sort By',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildChip('newest', 'Newest', _sort == 'newest', () => setState(() => _sort = 'newest')),
                _buildChip('oldest', 'Oldest', _sort == 'oldest', () => setState(() => _sort = 'oldest')),
                _buildChip('popular', 'Popular', _sort == 'popular', () => setState(() => _sort = 'popular')),
              ],
            ),
            const SizedBox(height: 32),

            // Apply Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => widget.onApply(_category, _ageGroup, _sort),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(dynamic value, String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

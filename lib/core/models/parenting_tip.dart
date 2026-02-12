import 'package:cloud_firestore/cloud_firestore.dart';

/// Categories for parenting tips
enum TipCategory {
  nutrition('Nutrition', 'nutrition'),
  sleep('Sleep', 'sleep'),
  development('Development', 'development'),
  health('Health', 'health'),
  safety('Safety', 'safety'),
  bonding('Bonding', 'bonding'),
  behavior('Behavior', 'behavior'),
  education('Education', 'education');

  final String displayName;
  final String value;

  const TipCategory(this.displayName, this.value);

  static TipCategory fromString(String? value) {
    return TipCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TipCategory.development,
    );
  }
}

/// Age groups for filtering tips
enum AgeGroup {
  newborn('0-3 months', 'newborn'),
  infant('3-6 months', 'infant'),
  baby('6-12 months', 'baby'),
  toddler('1-2 years', 'toddler'),
  preschool('2-4 years', 'preschool'),
  allAges('All Ages', 'all');

  final String displayName;
  final String value;

  const AgeGroup(this.displayName, this.value);

  static AgeGroup fromString(String? value) {
    return AgeGroup.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AgeGroup.allAges,
    );
  }
}

/// Parenting tip model
class ParentingTip {
  final String id;
  final String title;
  final String content;
  final String? summary; // Short summary for card display
  final TipCategory category;
  final AgeGroup ageGroup;
  final String? imageUrl;
  final int readTimeMinutes;
  final List<String> tags;
  final bool isActive;
  final bool isFeatured;
  final int viewCount;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  ParentingTip({
    required this.id,
    required this.title,
    required this.content,
    this.summary,
    required this.category,
    this.ageGroup = AgeGroup.allAges,
    this.imageUrl,
    this.readTimeMinutes = 3,
    this.tags = const [],
    this.isActive = true,
    this.isFeatured = false,
    this.viewCount = 0,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory ParentingTip.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ParentingTip(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      summary: data['summary'],
      category: TipCategory.fromString(data['category']),
      ageGroup: AgeGroup.fromString(data['ageGroup']),
      imageUrl: data['imageUrl'],
      readTimeMinutes: data['readTimeMinutes'] ?? 3,
      tags: data['tags'] != null ? List<String>.from(data['tags']) : [],
      isActive: data['isActive'] ?? true,
      isFeatured: data['isFeatured'] ?? false,
      viewCount: data['viewCount'] ?? 0,
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'summary': summary,
      'category': category.value,
      'ageGroup': ageGroup.value,
      'imageUrl': imageUrl,
      'readTimeMinutes': readTimeMinutes,
      'tags': tags,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'viewCount': viewCount,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated fields
  ParentingTip copyWith({
    String? id,
    String? title,
    String? content,
    String? summary,
    TipCategory? category,
    AgeGroup? ageGroup,
    String? imageUrl,
    int? readTimeMinutes,
    List<String>? tags,
    bool? isActive,
    bool? isFeatured,
    int? viewCount,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ParentingTip(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      category: category ?? this.category,
      ageGroup: ageGroup ?? this.ageGroup,
      imageUrl: imageUrl ?? this.imageUrl,
      readTimeMinutes: readTimeMinutes ?? this.readTimeMinutes,
      tags: tags ?? this.tags,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      viewCount: viewCount ?? this.viewCount,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get display text for summary or truncated content
  String get displaySummary {
    if (summary != null && summary!.isNotEmpty) {
      return summary!;
    }
    if (content.length > 100) {
      return '${content.substring(0, 100)}...';
    }
    return content;
  }
}

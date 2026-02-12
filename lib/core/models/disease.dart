import 'package:cloud_firestore/cloud_firestore.dart';
import 'parenting_tip.dart'; // For AgeGroup enum

/// Severity level of a disease
enum DiseaseSeverity {
  mild('Mild', 'mild'),
  moderate('Moderate', 'moderate'),
  severe('Severe', 'severe'),
  critical('Critical', 'critical');

  final String displayName;
  final String value;

  const DiseaseSeverity(this.displayName, this.value);

  static DiseaseSeverity fromString(String? value) {
    return DiseaseSeverity.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DiseaseSeverity.mild,
    );
  }
}

/// Disease category
enum DiseaseCategory {
  respiratory('Respiratory', 'respiratory'),
  digestive('Digestive', 'digestive'),
  skin('Skin', 'skin'),
  infectious('Infectious', 'infectious'),
  allergies('Allergies', 'allergies'),
  fever('Fever & Cold', 'fever'),
  nutritional('Nutritional', 'nutritional'),
  developmental('Developmental', 'developmental'),
  other('Other', 'other');

  final String displayName;
  final String value;

  const DiseaseCategory(this.displayName, this.value);

  static DiseaseCategory fromString(String? value) {
    return DiseaseCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DiseaseCategory.other,
    );
  }
}

/// Disease model for common childhood diseases
class Disease {
  final String id;
  final String name;
  final String description;
  final DiseaseCategory category;
  final List<AgeGroup> affectedAgeGroups;
  final DiseaseSeverity severity;
  final List<String> symptoms;
  final List<String> causes;
  final List<String> prevention;
  final List<String> homeRemedies;
  final String whenToSeeDoctor;
  final String? imageUrl;
  final bool isCommon;
  final bool isActive;
  final int viewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Disease({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.affectedAgeGroups,
    this.severity = DiseaseSeverity.mild,
    this.symptoms = const [],
    this.causes = const [],
    this.prevention = const [],
    this.homeRemedies = const [],
    this.whenToSeeDoctor = '',
    this.imageUrl,
    this.isCommon = true,
    this.isActive = true,
    this.viewCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory Disease.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Disease(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: DiseaseCategory.fromString(data['category']),
      affectedAgeGroups: (data['affectedAgeGroups'] as List?)
              ?.map((e) => AgeGroup.fromString(e))
              .toList() ??
          [AgeGroup.allAges],
      severity: DiseaseSeverity.fromString(data['severity']),
      symptoms: List<String>.from(data['symptoms'] ?? []),
      causes: List<String>.from(data['causes'] ?? []),
      prevention: List<String>.from(data['prevention'] ?? []),
      homeRemedies: List<String>.from(data['homeRemedies'] ?? []),
      whenToSeeDoctor: data['whenToSeeDoctor'] ?? '',
      imageUrl: data['imageUrl'],
      isCommon: data['isCommon'] ?? true,
      isActive: data['isActive'] ?? true,
      viewCount: data['viewCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'category': category.value,
      'affectedAgeGroups': affectedAgeGroups.map((e) => e.value).toList(),
      'severity': severity.value,
      'symptoms': symptoms,
      'causes': causes,
      'prevention': prevention,
      'homeRemedies': homeRemedies,
      'whenToSeeDoctor': whenToSeeDoctor,
      'imageUrl': imageUrl,
      'isCommon': isCommon,
      'isActive': isActive,
      'viewCount': viewCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated fields
  Disease copyWith({
    String? id,
    String? name,
    String? description,
    DiseaseCategory? category,
    List<AgeGroup>? affectedAgeGroups,
    DiseaseSeverity? severity,
    List<String>? symptoms,
    List<String>? causes,
    List<String>? prevention,
    List<String>? homeRemedies,
    String? whenToSeeDoctor,
    String? imageUrl,
    bool? isCommon,
    bool? isActive,
    int? viewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Disease(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      affectedAgeGroups: affectedAgeGroups ?? this.affectedAgeGroups,
      severity: severity ?? this.severity,
      symptoms: symptoms ?? this.symptoms,
      causes: causes ?? this.causes,
      prevention: prevention ?? this.prevention,
      homeRemedies: homeRemedies ?? this.homeRemedies,
      whenToSeeDoctor: whenToSeeDoctor ?? this.whenToSeeDoctor,
      imageUrl: imageUrl ?? this.imageUrl,
      isCommon: isCommon ?? this.isCommon,
      isActive: isActive ?? this.isActive,
      viewCount: viewCount ?? this.viewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

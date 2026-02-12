import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/disease.dart';
import '../models/parenting_tip.dart';

/// Service for managing diseases in Firestore
class DiseaseService {
  static DiseaseService? _instance;
  static FirebaseFirestore? _firestore;

  factory DiseaseService() {
    _instance ??= DiseaseService._internal();
    return _instance!;
  }

  DiseaseService._internal();

  FirebaseFirestore get _firestoreInstance {
    _firestore ??= FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'sishu',
    );
    return _firestore!;
  }

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestoreInstance.collection('diseases');

  // ============================================================================
  // READ OPERATIONS
  // ============================================================================

  /// Get all active diseases as stream
  Stream<List<Disease>> activeDiseases() {
    return _collection
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Disease.fromFirestore(doc)).toList());
  }

  /// Get all diseases (for admin) as stream
  Stream<List<Disease>> allDiseasesStream() {
    return _collection.orderBy('updatedAt', descending: true).snapshots().map(
        (snapshot) =>
            snapshot.docs.map((doc) => Disease.fromFirestore(doc)).toList());
  }

  /// Get diseases by category
  Stream<List<Disease>> diseasesByCategory(DiseaseCategory category) {
    return _collection
        .where('isActive', isEqualTo: true)
        .where('category', isEqualTo: category.value)
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Disease.fromFirestore(doc)).toList());
  }

  /// Get diseases by age group
  Stream<List<Disease>> diseasesByAgeGroup(AgeGroup ageGroup) {
    return _collection
        .where('isActive', isEqualTo: true)
        .where('affectedAgeGroups', arrayContains: ageGroup.value)
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Disease.fromFirestore(doc)).toList());
  }

  /// Get common diseases
  Stream<List<Disease>> commonDiseases() {
    return _collection
        .where('isActive', isEqualTo: true)
        .where('isCommon', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Disease.fromFirestore(doc)).toList());
  }

  /// Get a single disease by ID
  Future<Disease?> getDisease(String id) async {
    final doc = await _collection.doc(id).get();
    if (doc.exists) {
      return Disease.fromFirestore(doc);
    }
    return null;
  }

  /// Search diseases by name
  Future<List<Disease>> searchDiseases(String query) async {
    final queryLower = query.toLowerCase();
    final snapshot = await _collection.where('isActive', isEqualTo: true).get();

    return snapshot.docs
        .map((doc) => Disease.fromFirestore(doc))
        .where((disease) =>
            disease.name.toLowerCase().contains(queryLower) ||
            disease.description.toLowerCase().contains(queryLower) ||
            disease.symptoms.any((s) => s.toLowerCase().contains(queryLower)))
        .toList();
  }

  // ============================================================================
  // WRITE OPERATIONS
  // ============================================================================

  /// Add a new disease
  Future<String> addDisease(Disease disease) async {
    final docRef = await _collection.add(disease.toFirestore());
    return docRef.id;
  }

  /// Update an existing disease
  Future<void> updateDisease(String id, Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.now();
    await _collection.doc(id).update(data);
  }

  /// Delete a disease
  Future<void> deleteDisease(String id) async {
    await _collection.doc(id).delete();
  }

  /// Toggle disease active status
  Future<void> toggleDiseaseActive(String id, bool isActive) async {
    await _collection.doc(id).update({
      'isActive': isActive,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Toggle disease common status
  Future<void> toggleDiseaseCommon(String id, bool isCommon) async {
    await _collection.doc(id).update({
      'isCommon': isCommon,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Increment view count
  Future<void> incrementViewCount(String id) async {
    await _collection.doc(id).update({
      'viewCount': FieldValue.increment(1),
    });
  }
}
